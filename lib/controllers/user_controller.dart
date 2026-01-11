import 'package:get/get.dart';
import 'package:englishmaster/services/api_service.dart';

class UserController extends GetxController {
  final ApiService _apiService = ApiService();

  final _isLoading = false.obs;
  final _streak = 0.obs;
  final _gems = 0.obs;
  final _xp = 0.obs;
  final _hearts = 5.obs;
  final _name = ''.obs;
  final _email = ''.obs;
  final _avatar = Rxn<String>();

  bool get isLoading => _isLoading.value;
  int get streak => _streak.value;
  int get gems => _gems.value;
  int get xp => _xp.value;
  int get hearts => _hearts.value;
  String get name => _name.value;
  String get email => _email.value;
  String? get avatar => _avatar.value;

  @override
  void onInit() {
    super.onInit();
    fetchUserProfile();
  }

  Future<void> fetchUserProfile() async {
    try {
      _isLoading.value = true;
      final result = await _apiService.getUserProfile();

      if (result.success && result.data != null) {
        _parseUserData(result.data);
      } else {
        print('❌ Error fetching user profile: ${result.message}');
      }
    } catch (e) {
      print('❌ Exception in fetchUserProfile: $e');
    } finally {
      _isLoading.value = false;
    }
  }

  void _parseUserData(dynamic data) {
    Map<String, dynamic> userData = {};

    if (data is Map) {
      if (data['data'] != null && data['data'] is Map) {
        var innerData = data['data'];
        if (innerData['user'] != null && innerData['user'] is Map) {
          userData = Map<String, dynamic>.from(innerData['user']);
        } else {
          userData = Map<String, dynamic>.from(innerData);
        }
      } else if (data['user'] != null && data['user'] is Map) {
        userData = Map<String, dynamic>.from(data['user']);
      } else {
        userData = Map<String, dynamic>.from(data);
      }
    }

    _name.value = userData['name'] ?? userData['username'] ?? 'User';
    _email.value = userData['email'] ?? '';
    _avatar.value = userData['avatar'];

    if (userData['streak'] != null) {
      if (userData['streak'] is Map) {
        _streak.value = userData['streak']['count'] ?? 0;
      } else {
        _streak.value = int.tryParse(userData['streak'].toString()) ?? 0;
      }
    }

    if (userData['gems'] != null) {
      if (userData['gems'] is Map) {
        _gems.value = userData['gems']['amount'] ?? 0;
      } else {
        _gems.value = int.tryParse(userData['gems'].toString()) ?? 0;
      }
    } else if (userData['gem'] != null) {
      if (userData['gem'] is Map) {
        _gems.value = userData['gem']['amount'] ?? 0;
      } else {
        _gems.value = int.tryParse(userData['gem'].toString()) ?? 0;
      }
    }

    if (userData['xp'] != null) {
      if (userData['xp'] is Map) {
        _xp.value = userData['xp']['total'] ?? 0;
      } else {
        _xp.value = int.tryParse(userData['xp'].toString()) ?? 0;
      }
    }

  }

  void updateGems(int newAmount) {
    _gems.value = newAmount;
  }

  void decreaseGems(int amount) {
    if (_gems.value >= amount) {
      _gems.value -= amount;
    }
  }

  void increaseGems(int amount) {
    _gems.value += amount;
  }

  void updateStreak(int newStreak) {
    _streak.value = newStreak;
  }

  void updateXP(int newXP) {
    _xp.value = newXP;
  }

  void decreaseHearts(int amount) {
    if (_hearts.value > 0) {
      _hearts.value -= amount;
      if (_hearts.value < 0) _hearts.value = 0;
    }
  }

  void increaseHearts(int amount) {
    _hearts.value += amount;
  }

  void resetHearts() {
    _hearts.value = 4;
  }

  void updateHearts(int newHearts) {
    _hearts.value = newHearts;
  }
}
