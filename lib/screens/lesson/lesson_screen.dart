import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:englishmaster/config/colors.dart';
import 'package:englishmaster/services/api_service.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';

class LessonScreen extends StatefulWidget {
  final String lessonId;
  const LessonScreen({super.key, required this.lessonId});

  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen> with TickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  final FlutterTts _flutterTts = FlutterTts();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final stt.SpeechToText _speech = stt.SpeechToText();

  bool _isLoading = true;
  List<dynamic> _questions = [];
  int _currentIndex = 0;
  int _hearts = 5;
  double _progress = 0.0;
  bool _isChecked = false;
  bool _isCorrect = false;
  bool _showFeedback = false;

  bool _isListening = false;
  String _spokenText = "";
  bool _speechAvailable = false;

  String? _selectedOptionId;
  List<String> _selectedWords = [];
  String _inputValue = "";

  String? _selectedLeft;
  String? _selectedRight;
  List<String> _matchedPairs = [];

  late AnimationController _progressController;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _initTts();
    _initSpeech();
    _loadLessonData();
  }

  @override
  void dispose() {
    _progressController.dispose();
    _flutterTts.stop();
    _audioPlayer.dispose();
    _speech.stop();
    super.dispose();
  }

  void _initTts() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setPitch(1.0);
    await _flutterTts.setSpeechRate(0.5);
    if (Platform.isIOS) {
      await _flutterTts.setIosAudioCategory(IosTextToSpeechAudioCategory.playback, [
        IosTextToSpeechAudioCategoryOptions.allowBluetooth,
        IosTextToSpeechAudioCategoryOptions.allowBluetoothA2DP,
        IosTextToSpeechAudioCategoryOptions.mixWithOthers
      ], IosTextToSpeechAudioMode.voicePrompt);
    }
  }

  void _initSpeech() async {
    try {
      _speechAvailable = await _speech.initialize(
        onStatus: (status) {
          print('Speech status: $status');
          if (status == 'done' || status == 'notListening') {
            if (mounted) setState(() => _isListening = false);
          }
        },
        onError: (errorNotification) {
          print('Speech error: $errorNotification');
          if (mounted) setState(() => _isListening = false);
        },
      );
      if (mounted) setState(() {});
    } catch (e) {
      print("Speech init error: $e");
    }
  }

  Future<void> _speak(String text) async {
    if (text.isNotEmpty) await _flutterTts.speak(text);
  }

  Future<void> _playSound(bool isCorrect) async {
    try {
      final source = AssetSource(isCorrect ? 'audio/correct.mp3' : 'audio/wrong.mp3');
      await _audioPlayer.play(source);
    } catch (e) {
      print("Audio Error: $e");
    }
  }

  double _calculateSimilarity(String s1, String s2) {
    if (s1.isEmpty) return s2.isEmpty ? 1.0 : 0.0;
    if (s2.isEmpty) return 0.0;

    s1 = s1.toLowerCase().trim();
    s2 = s2.toLowerCase().trim();

    List<int> costs = List<int>.filled(s2.length + 1, 0);
    for (int i = 0; i <= s1.length; i++) {
      int lastValue = i;
      for (int j = 0; j <= s2.length; j++) {
        if (i == 0) {
          costs[j] = j;
        } else {
          if (j > 0) {
            int newValue = costs[j - 1];
            if (s1.codeUnitAt(i - 1) != s2.codeUnitAt(j - 1)) {
              newValue = (newValue < lastValue ? newValue : lastValue) + 1;
            }
            costs[j - 1] = lastValue;
            lastValue = newValue;
          }
        }
      }
      if (i > 0) costs[s2.length] = lastValue;
    }

    int distance = costs[s2.length];
    int maxLength = max(s1.length, s2.length);
    return (maxLength - distance) / maxLength;
  }

  void _listen() async {
    if (!_speechAvailable) {
      var status = await Permission.microphone.request();
      if (status != PermissionStatus.granted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Cần quyền Micro để thu âm")));
        return;
      }
      bool available = await _speech.initialize();
      if (mounted) setState(() => _speechAvailable = available);
    }

    if (_isListening) {
      _speech.stop();
      setState(() => _isListening = false);
    } else {
      setState(() {
        _isListening = true;
        _spokenText = "";
      });

      _speech.listen(
        onResult: (val) {
          setState(() {
            _spokenText = val.recognizedWords;
          });

          if (val.finalResult) {
            Future.delayed(const Duration(milliseconds: 500), () {
              if (!_isChecked && _isListening) {
                _speech.stop();
                setState(() => _isListening = false);
                _handleCheck(); // Gọi hàm kiểm tra ngay lập tức
              }
            });
          }
        },
        localeId: 'en_US',
        listenFor: const Duration(seconds: 10),
        pauseFor: const Duration(seconds: 2), // Ngừng nói 2 giây là chốt đơn
        partialResults: true,
        cancelOnError: true,
      );
    }
  }

  void _loadLessonData() async {
    try {
      final results = await Future.wait([
        _apiService.getLessonById(widget.lessonId),
        _apiService.getVocabulariesByLesson(widget.lessonId),
        _apiService.getExercisesByLesson(widget.lessonId),
      ]);

      final vocabularies = results[1] as List<dynamic>;
      final exercises = results[2] as List<dynamic>;
      List<dynamic> transformedQuestions = [];

      for (var vocab in vocabularies) {
        final otherVocabs = vocabularies.where((v) => v['_id'] != vocab['_id']).toList()..shuffle();
        final wrongChoices = otherVocabs.take(2).toList();
        List<Map<String, dynamic>> choices = [
          {'id': vocab['_id'], 'text': vocab['word'], 'image': vocab['imageUrl'] ?? '', 'isCorrect': true},
          ...wrongChoices.map((v) => {'id': v['_id'], 'text': v['word'], 'image': v['imageUrl'] ?? '', 'isCorrect': false})
        ];
        choices.shuffle();
        transformedQuestions.add({
          'id': 'vocab-${vocab['_id']}',
          'type': 'vocabulary',
          'question': 'Đâu là "${vocab['meaning'] ?? vocab['word']}"?',
          'correctAnswer': vocab['_id'],
          'choices': choices,
        });
      }

      for (var exercise in exercises) {
        String type = exercise['type'];
        String questionType = 'multiple_choice';
        if (type == 'multiple-choice') questionType = 'multiple_choice';
        else if (type == 'fill-in-blank') questionType = 'fill_in_blank';
        else if (type == 'translation') questionType = 'translate_build';
        else if (type == 'listening') questionType = 'listen_write';
        else if (type == 'matching') questionType = 'match_pairs';
        else if (type == 'speaking') questionType = 'speaking';

        Map<String, dynamic> q = {
          'id': 'ex-${exercise['_id']}',
          'type': questionType,
          'question': exercise['question'],
          'correctAnswer': exercise['correctAnswer'],
          'audioText': exercise['question'],
        };

        if (questionType == 'match_pairs') {
          try {
            Map<String, dynamic> pairs = jsonDecode(exercise['correctAnswer']);
            List<Map<String, String>> left = [];
            List<Map<String, String>> right = [];
            int idx = 0;
            pairs.forEach((key, value) {
              String leftId = 'l$idx'; String rightId = 'r$idx';
              left.add({'id': leftId, 'text': key});
              right.add({'id': rightId, 'text': value, 'matchWith': leftId});
              idx++;
            });
            right.shuffle();
            q['leftColumn'] = left; q['rightColumn'] = right;
          } catch (e) { continue; }
        } else if (questionType == 'translate_build') {
          String answer = exercise['correctAnswer'].toString();
          List<String> words = answer.split(' ');
          words.add("is"); words.add("the"); words.shuffle();
          q['correctAnswer'] = answer.split(' ');
          q['wordBank'] = words;
          q['audioText'] = answer;
        } else if (questionType == 'multiple_choice') {
          if (exercise['options'] != null) {
            q['choices'] = (exercise['options'] as List).map((opt) {
              return {'id': opt['_id'] ?? opt['text'], 'text': opt['text'], 'image': ''};
            }).toList();
            var correctOpt = (exercise['options'] as List).firstWhere((opt) => opt['isCorrect'] == true, orElse: () => null);
            if (correctOpt != null) q['correctAnswer'] = correctOpt['_id'] ?? correctOpt['text'];
          }
        }
        transformedQuestions.add(q);
      }

      if (mounted) {
        setState(() {
          _questions = transformedQuestions;
          _isLoading = false;
          _updateProgress();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi tải: $e")));
        setState(() => _isLoading = false);
      }
    }
  }

  void _updateProgress() {
    if (_questions.isEmpty) return;
    double target = (_currentIndex) / _questions.length;
    _progressAnimation = Tween<double>(begin: _progress, end: target).animate(_progressController);
    _progressController.forward(from: 0);
    setState(() => _progress = target);
  }

  void _handleCheck() {
    if (_questions.isEmpty) return;
    final q = _questions[_currentIndex];
    bool correct = false;
    String type = q['type'];

    if (type == 'vocabulary' || type == 'multiple_choice') {
      correct = _selectedOptionId == q['correctAnswer'];
    } else if (type == 'translate_build') {
      String userAnswer = _selectedWords.join(' ').trim();
      String trueAnswer = (q['correctAnswer'] as List).join(' ').trim();
      correct = userAnswer.toLowerCase() == trueAnswer.toLowerCase();
    } else if (type == 'match_pairs') {
      correct = _matchedPairs.length == (q['leftColumn'].length + q['rightColumn'].length);
    } else if (type == 'listen_write' || type == 'fill_in_blank') {
      correct = _inputValue.trim().toLowerCase() == q['correctAnswer'].toString().toLowerCase();
    } else if (type == 'speaking') {
      String target = q['correctAnswer'].toString();
      String spoken = _spokenText;

      double similarity = _calculateSimilarity(spoken, target);

      correct = similarity >= 0.5;

      if (_spokenText.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Chưa nhận diện được giọng nói!")));
        return;
      }
      print("Target: $target | Spoken: $spoken | Score: ${similarity * 100}%");
    }

    setState(() {
      _isChecked = true;
      _isCorrect = correct;
      _showFeedback = true;
      if (!correct) _hearts = (_hearts - 1).clamp(0, 5);
    });

    _playSound(correct);
  }

  void _handleContinue() {
    if (_currentIndex < _questions.length - 1) {
      setState(() {
        _currentIndex++;
        _isChecked = false;
        _showFeedback = false;
        _isCorrect = false;
        _selectedOptionId = null;
        _selectedWords = [];
        _inputValue = "";
        _selectedLeft = null;
        _selectedRight = null;
        _matchedPairs = [];
        _spokenText = "";
        _updateProgress();
      });

      final nextQ = _questions[_currentIndex];
      if ((nextQ['type'] == 'listen_write' || nextQ['type'] == 'speaking') && nextQ['audioText'] != null) {
        Future.delayed(const Duration(milliseconds: 500), () => _speak(nextQ['audioText']));
      }
    } else {
      _showCompletionDialog();
      _playSound(true);
    }
  }

  void _showCompletionDialog() async {
    try {
      await _apiService.updateProgress(widget.lessonId, _hearts);
      print("Đã cập nhật tiến độ");
    } catch (e) {
      print("Lỗi cập nhật tiến độ: $e");
    }
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/images/success.gif', height: 150, errorBuilder: (c,e,s)=>const Icon(Icons.emoji_events, size: 80, color: Colors.orange)),
            const SizedBox(height: 20),
            const Text("Hoàn thành bài học!", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.orange)),
            const SizedBox(height: 10),
            Text("Bạn nhận được: $_hearts kinh nghiệm", style: const TextStyle(color: Colors.grey)),
          ],
        ),
        actions: [
          Center(
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx); // Đóng Dialog
                Navigator.pop(context, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text("TIẾP TỤC", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(backgroundColor: Colors.white, body: Center(child: CircularProgressIndicator()));
    if (_questions.isEmpty) return const Scaffold(backgroundColor: Colors.white, body: Center(child: Text("Bài học trống")));
    if (_currentIndex >= _questions.length) return const Scaffold(body: Center(child: Text("Lỗi dữ liệu")));

    final q = _questions[_currentIndex];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.close, color: Colors.grey), onPressed: () => Navigator.pop(context)),
        title: Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: (_currentIndex + (_isChecked ? 1 : 0)) / _questions.length,
                  minHeight: 16,
                  backgroundColor: Colors.grey[200],
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
            ),
            const SizedBox(width: 16),
            const Icon(Icons.favorite, color: Colors.red),
            const SizedBox(width: 4),
            Text("$_hearts", style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("CÂU HỎI", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 16),
                  if (q['type'] != 'speaking')
                    Row(
                      children: [
                        if (!q['type'].toString().contains('match'))
                          Image.asset('assets/images/LinhThuTini.gif', height: 60, errorBuilder: (c,e,s) => const SizedBox()),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    q['question'] ?? '',
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF3C3C3C)),
                                  ),
                                ),
                                if(q['audioText'] != null)
                                  IconButton(
                                    icon: const Icon(Icons.volume_up, color: Colors.blue),
                                    onPressed: () => _speak(q['audioText']),
                                  )
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 30),
                  _buildQuestionContent(q),
                ],
              ),
            ),
          ),
          _buildFooter(q),
        ],
      ),
    );
  }

  Widget _buildQuestionContent(dynamic q) {
    switch (q['type']) {
      case 'vocabulary':
      case 'multiple_choice':
        return _buildVocabularyQuestion(q);
      case 'translate_build':
        return _buildTranslateBuildQuestion(q);
      case 'match_pairs':
        return _buildMatchPairsQuestion(q);
      case 'listen_write':
      case 'fill_in_blank':
        return _buildTextInputQuestion(q);
      case 'speaking':
        return _buildSpeakingQuestion(q);
      default:
        return Text("Dạng câu hỏi: ${q['type']} chưa hỗ trợ hiển thị");
    }
  }

  Widget _buildSpeakingQuestion(dynamic q) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text("Nói câu này:", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 16),



          GestureDetector(
            onTap: () => _speak(q['correctAnswer'] ?? q['question']),
            child: Container(
              width: 100, height: 100,
              decoration: BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 15, spreadRadius: 5)]
              ),
              child: const Icon(Icons.volume_up, color: Colors.white, size: 50),
            ),
          ),
          const SizedBox(height: 40),

          if (!_isChecked)
            Column(
              children: [
                GestureDetector(
                  onTap: _listen, // Bấm để bắt đầu nói và tự chấm
                  child: Container(
                    width: 80, height: 80,
                    decoration: BoxDecoration(
                        color: _isListening ? Colors.red : AppColors.primary,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [BoxShadow(color: (_isListening ? Colors.red : AppColors.primary).withOpacity(0.4), blurRadius: 10, offset: const Offset(0,5))]
                    ),
                    child: Icon(_isListening ? Icons.mic_off : Icons.mic, color: Colors.white, size: 40),
                  ),
                ),
                const SizedBox(height: 12),
                Text(_isListening ? "Đang nghe..." : "Bấm để nói", style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold)),
              ],
            ),

          if (_spokenText.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 20),
              padding: const EdgeInsets.all(16),
              width: double.infinity,
              decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey[300]!)),
              child: Column(
                children: [
                  const Text("Bạn đã nói:", style: TextStyle(color: Colors.grey, fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(_spokenText, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87), textAlign: TextAlign.center),
                ],
              ),
            )
        ],
      ),
    );
  }

  Widget _buildVocabularyQuestion(dynamic q) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 0.9,
      physics: const NeverScrollableScrollPhysics(),
      children: (q['choices'] as List).map<Widget>((choice) {
        bool isSelected = _selectedOptionId == choice['id'];
        bool isCorrectAnswer = choice['id'] == q['correctAnswer'];
        Color borderColor = Colors.grey[300]!;
        Color bgColor = Colors.white;
        if (_isChecked) {
          if (isSelected) {
            borderColor = _isCorrect ? AppColors.primary : Colors.red;
            bgColor = _isCorrect ? const Color(0xFFD7FFB8) : const Color(0xFFFFDFE0);
          } else if (isCorrectAnswer) {
            borderColor = AppColors.primary;
          }
        } else if (isSelected) {
          borderColor = Colors.blue;
          bgColor = Colors.blue[50]!;
        }
        return GestureDetector(
          onTap: _isChecked ? null : () {
            setState(() => _selectedOptionId = choice['id']);
            _speak(choice['text']);
          },
          child: Container(
            decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: borderColor, width: 2), boxShadow: [BoxShadow(color: Colors.grey[200]!, offset: const Offset(0, 4))]),
            child: Stack(children: [
              Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                if (choice['image'] != null && choice['image'].toString().isNotEmpty) Center(child: Image.network(ApiService.getValidImageUrl(choice['image']), height: 60, errorBuilder: (c,e,s) => const Icon(Icons.image, size: 40, color: Colors.grey))),
                const SizedBox(height: 8),
                Center(child: Text(choice['text'], textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
              ]),
              Positioned(top: 4, right: 4, child: GestureDetector(onTap: () => _speak(choice['text']), child: Container(padding: const EdgeInsets.all(4), decoration: BoxDecoration(color: Colors.blue[50], shape: BoxShape.circle), child: const Icon(Icons.volume_up, size: 18, color: Colors.blue))))
            ]),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTranslateBuildQuestion(dynamic q) {
    return Column(children: [
      Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12), decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey[300]!, width: 2))), constraints: const BoxConstraints(minHeight: 60), child: Wrap(spacing: 8, runSpacing: 8, children: _selectedWords.map((word) => GestureDetector(onTap: _isChecked ? null : () => setState(() => _selectedWords.remove(word)), child: Chip(label: Text(word), backgroundColor: Colors.blue, labelStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)))).toList())),
      const SizedBox(height: 40),
      Wrap(spacing: 8, runSpacing: 12, alignment: WrapAlignment.center, children: (q['wordBank'] as List).map<Widget>((word) {
        bool isUsed = _selectedWords.contains(word);
        return GestureDetector(onTap: (isUsed || _isChecked) ? null : () { setState(() => _selectedWords.add(word)); _speak(word); }, child: Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), decoration: BoxDecoration(color: isUsed ? Colors.grey[200] : Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: isUsed ? Colors.transparent : Colors.grey[300]!, width: 2), boxShadow: isUsed ? [] : [BoxShadow(color: Colors.grey[300]!, offset: const Offset(0, 3))]), child: Text(word, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: isUsed ? Colors.transparent : Colors.black))));
      }).toList())
    ]);
  }

  Widget _buildMatchPairsQuestion(dynamic q) {
    List<dynamic> leftItems = q['leftColumn'];
    List<dynamic> rightItems = q['rightColumn'];
    return Row(children: [Expanded(child: Column(children: leftItems.map<Widget>((item) => _buildPairItem(item, true)).toList())), const SizedBox(width: 20), Expanded(child: Column(children: rightItems.map<Widget>((item) => _buildPairItem(item, false)).toList()))]);
  }

  Widget _buildPairItem(dynamic item, bool isLeft) {
    String id = item['id'];
    bool isSelected = isLeft ? _selectedLeft == id : _selectedRight == id;
    bool isMatched = _matchedPairs.contains(id);
    Color borderColor = Colors.grey[300]!; Color bgColor = Colors.white; Color textColor = Colors.black;
    if (isMatched) { bgColor = Colors.green[100]!; borderColor = Colors.green; textColor = Colors.green; } else if (isSelected) { borderColor = Colors.blue; bgColor = Colors.blue[50]!; }
    return GestureDetector(onTap: (isMatched || _isChecked) ? null : () => _handlePairClick(id, isLeft, item['text']), child: AnimatedContainer(duration: const Duration(milliseconds: 200), margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.symmetric(vertical: 16), width: double.infinity, decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: borderColor, width: 2), boxShadow: isMatched ? [] : [BoxShadow(color: Colors.grey[300]!, offset: const Offset(0, 3))]), child: Text(item['text'], textAlign: TextAlign.center, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor))));
  }

  void _handlePairClick(String id, bool isLeft, String text) {
    setState(() { if (isLeft) _selectedLeft = id; else _selectedRight = id; });
    if (!isLeft) _speak(text);
    if (_selectedLeft != null && _selectedRight != null) {
      final q = _questions[_currentIndex];
      final rightItem = (q['rightColumn'] as List).firstWhere((r) => r['id'] == _selectedRight);
      if (rightItem['matchWith'] == _selectedLeft) {
        setState(() { _matchedPairs.add(_selectedLeft!); _matchedPairs.add(_selectedRight!); _selectedLeft = null; _selectedRight = null; });
        _playSound(true);
      } else {
        _playSound(false);
        Future.delayed(const Duration(milliseconds: 500), () { setState(() { _selectedLeft = null; _selectedRight = null; }); setState(() => _hearts = (_hearts - 1).clamp(0, 5)); });
      }
    }
  }

  Widget _buildTextInputQuestion(dynamic q) {
    return Column(children: [
      if (q['type'] == 'listen_write') GestureDetector(onTap: () => _speak(q['audioText'] ?? ""), child: Container(width: 80, height: 80, decoration: BoxDecoration(color: Colors.blue, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 10, spreadRadius: 2)]), child: const Icon(Icons.volume_up, color: Colors.white, size: 40))),
      const SizedBox(height: 30),
      TextField(enabled: !_isChecked, onChanged: (val) => _inputValue = val, decoration: InputDecoration(hintText: "Nhập câu trả lời...", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), filled: true, fillColor: Colors.grey[100]))
    ]);
  }

  Widget _buildFooter(dynamic q) {
    Color bannerColor = _isChecked ? (_isCorrect ? const Color(0xFFD7FFB8) : const Color(0xFFFFDFE0)) : Colors.white;
    Color titleColor = _isChecked ? (_isCorrect ? const Color(0xFF58A700) : const Color(0xFFEA2B2B)) : Colors.transparent;
    bool isButtonDisabled = false;
    if (q['type'] == 'vocabulary' && _selectedOptionId == null) isButtonDisabled = true;
    if (q['type'] == 'translate_build' && _selectedWords.isEmpty) isButtonDisabled = true;
    if (q['type'] == 'match_pairs' && _matchedPairs.length < (q['leftColumn'].length + q['rightColumn'].length)) isButtonDisabled = true;
    if (q['type'] == 'speaking' && _spokenText.isEmpty) isButtonDisabled = true;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: bannerColor, border: Border(top: BorderSide(color: Colors.grey[200]!, width: 2))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_showFeedback) ...[
            Row(children: [Icon(_isCorrect ? Icons.check_circle : Icons.cancel, color: titleColor, size: 30), const SizedBox(width: 10), Text(_isCorrect ? "Chính xác!" : "Chưa đúng!", style: TextStyle(color: titleColor, fontSize: 20, fontWeight: FontWeight.bold))]),
            if (!_isCorrect && q['correctAnswer'] is String) Padding(padding: const EdgeInsets.only(top: 8.0), child: Text("Đáp án đúng: ${q['correctAnswer']}", style: const TextStyle(color: Color(0xFFEA2B2B), fontSize: 16))),
            const SizedBox(height: 16),
          ],
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (isButtonDisabled && !_isChecked) ? null : (_isChecked ? _handleContinue : _handleCheck),
              style: ElevatedButton.styleFrom(
                backgroundColor: _isChecked ? (_isCorrect ? const Color(0xFF58CC02) : const Color(0xFFFF4B4B)) : const Color(0xFF58CC02),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: Text(_isChecked ? "TIẾP TỤC" : "KIỂM TRA", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}