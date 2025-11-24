// Navigation
function navigateToSection(sectionId) {
    // Hide all sections
    document.querySelectorAll('.section').forEach(section => {
        section.classList.remove('active');
    });
    
    // Show selected section
    document.getElementById(sectionId).classList.add('active');
    
    // Update nav links
    document.querySelectorAll('.nav-link').forEach(link => {
        link.classList.remove('active');
        if (link.dataset.section === sectionId) {
            link.classList.add('active');
        }
    });
    
    // Initialize section if needed
    if (sectionId === 'vocabulary') {
        initVocabulary();
    } else if (sectionId === 'grammar') {
        initGrammar();
    } else if (sectionId === 'reading') {
        initReading();
    } else if (sectionId === 'progress') {
        updateProgress();
    }
}

// Add click listeners to nav links
document.addEventListener('DOMContentLoaded', function() {
    document.querySelectorAll('.nav-link').forEach(link => {
        link.addEventListener('click', function(e) {
            e.preventDefault();
            navigateToSection(this.dataset.section);
        });
    });
    
    // Load progress from localStorage
    loadProgress();
    initVocabulary();
});

// Vocabulary Data
const vocabularyData = {
    beginner: [
        { word: "Happy", type: "adjective", definition: "Feeling or showing pleasure or contentment", example: "She was happy to see her friends." },
        { word: "Beautiful", type: "adjective", definition: "Pleasing the senses or mind aesthetically", example: "The sunset was beautiful." },
        { word: "Quick", type: "adjective", definition: "Moving fast or doing something in a short time", example: "He gave a quick answer to the question." },
        { word: "Friend", type: "noun", definition: "A person whom one knows and with whom one has a bond of mutual affection", example: "She is my best friend." },
        { word: "Learn", type: "verb", definition: "Gain knowledge or skill by studying, practicing, or being taught", example: "I want to learn English." },
        { word: "Book", type: "noun", definition: "A written or printed work consisting of pages glued or sewn together", example: "I am reading a good book." },
        { word: "Walk", type: "verb", definition: "Move at a regular pace by lifting and setting down each foot in turn", example: "Let's walk in the park." },
        { word: "House", type: "noun", definition: "A building for human habitation", example: "They live in a big house." },
        { word: "Water", type: "noun", definition: "A colorless, transparent, odorless liquid", example: "Drink plenty of water every day." },
        { word: "Food", type: "noun", definition: "Any nutritious substance that people or animals eat or drink", example: "We need food to survive." }
    ],
    intermediate: [
        { word: "Abundance", type: "noun", definition: "A very large quantity of something", example: "There was an abundance of food at the party." },
        { word: "Achieve", type: "verb", definition: "Successfully reach a desired objective or result", example: "She worked hard to achieve her goals." },
        { word: "Analyze", type: "verb", definition: "Examine in detail the structure or elements of something", example: "Scientists analyze data carefully." },
        { word: "Consistent", type: "adjective", definition: "Acting or done in the same way over time", example: "He is consistent in his work." },
        { word: "Demonstrate", type: "verb", definition: "Clearly show the existence or truth of something", example: "The teacher will demonstrate the experiment." },
        { word: "Efficient", type: "adjective", definition: "Achieving maximum productivity with minimum wasted effort", example: "This is an efficient way to work." },
        { word: "Enhance", type: "verb", definition: "Improve the quality, value, or extent of something", example: "Exercise can enhance your health." },
        { word: "Establish", type: "verb", definition: "Set up on a firm or permanent basis", example: "They established a new company." },
        { word: "Fundamental", type: "adjective", definition: "Forming a necessary base or core", example: "Reading is a fundamental skill." },
        { word: "Innovative", type: "adjective", definition: "Featuring new methods; advanced and original", example: "The company has an innovative approach." }
    ],
    advanced: [
        { word: "Ambiguous", type: "adjective", definition: "Open to more than one interpretation; not having one obvious meaning", example: "The politician's statement was deliberately ambiguous." },
        { word: "Articulate", type: "verb", definition: "Express an idea or feeling fluently and coherently", example: "She was able to articulate her thoughts clearly." },
        { word: "Meticulous", type: "adjective", definition: "Showing great attention to detail; very careful and precise", example: "He kept meticulous records of all transactions." },
        { word: "Paradox", type: "noun", definition: "A seemingly absurd or contradictory statement that when investigated may prove to be true", example: "The paradox of choice suggests that more options can lead to less satisfaction." },
        { word: "Pragmatic", type: "adjective", definition: "Dealing with things sensibly and realistically based on practical considerations", example: "We need a pragmatic approach to solve this problem." },
        { word: "Resilient", type: "adjective", definition: "Able to withstand or recover quickly from difficult conditions", example: "Children are often more resilient than adults think." },
        { word: "Juxtapose", type: "verb", definition: "Place or deal with close together for contrasting effect", example: "The exhibition juxtaposes traditional and modern art." },
        { word: "Eloquent", type: "adjective", definition: "Fluent or persuasive in speaking or writing", example: "She gave an eloquent speech at the conference." },
        { word: "Ephemeral", type: "adjective", definition: "Lasting for a very short time", example: "Fashion trends are often ephemeral." },
        { word: "Ubiquitous", type: "adjective", definition: "Present, appearing, or found everywhere", example: "Smartphones have become ubiquitous in modern society." }
    ]
};

// Vocabulary State
let currentDifficulty = 'beginner';
let currentCardIndex = 0;
let vocabularyProgress = [];

function initVocabulary() {
    currentCardIndex = 0;
    displayCard();
}

function displayCard() {
    const words = vocabularyData[currentDifficulty];
    const card = words[currentCardIndex];
    
    document.getElementById('word').textContent = card.word;
    document.getElementById('wordType').textContent = `(${card.type})`;
    document.getElementById('definition').textContent = card.definition;
    document.getElementById('example').textContent = `Example: "${card.example}"`;
    document.getElementById('cardCounter').textContent = `${currentCardIndex + 1} / ${words.length}`;
    
    // Remove flipped class
    document.getElementById('flashcard').classList.remove('flipped');
}

function flipCard() {
    document.getElementById('flashcard').classList.toggle('flipped');
}

function nextCard() {
    const words = vocabularyData[currentDifficulty];
    if (currentCardIndex < words.length - 1) {
        currentCardIndex++;
        displayCard();
        updateVocabularyProgress();
    }
}

function previousCard() {
    if (currentCardIndex > 0) {
        currentCardIndex--;
        displayCard();
    }
}

function changeDifficulty() {
    currentDifficulty = document.getElementById('difficultySelect').value;
    currentCardIndex = 0;
    displayCard();
}

function updateVocabularyProgress() {
    const key = `${currentDifficulty}_${currentCardIndex}`;
    if (!vocabularyProgress.includes(key)) {
        vocabularyProgress.push(key);
        saveProgress();
    }
}

// Grammar Data
const grammarQuestions = {
    tenses: [
        {
            question: "She ___ to the store yesterday.",
            options: ["go", "goes", "went", "going"],
            correct: 2
        },
        {
            question: "I ___ studying English for three years.",
            options: ["am", "was", "have been", "will be"],
            correct: 2
        },
        {
            question: "They ___ dinner when I arrived.",
            options: ["eat", "are eating", "were eating", "have eaten"],
            correct: 2
        },
        {
            question: "By next month, I ___ here for a year.",
            options: ["work", "will work", "worked", "will have worked"],
            correct: 3
        },
        {
            question: "He ___ his homework every day.",
            options: ["do", "does", "did", "doing"],
            correct: 1
        }
    ],
    articles: [
        {
            question: "She is ___ honest person.",
            options: ["a", "an", "the", "no article"],
            correct: 1
        },
        {
            question: "I saw ___ movie last night. ___ movie was excellent.",
            options: ["a / The", "the / A", "an / The", "a / A"],
            correct: 0
        },
        {
            question: "___ Moon orbits around ___ Earth.",
            options: ["A / the", "The / the", "The / an", "A / an"],
            correct: 1
        },
        {
            question: "I need ___ advice about this problem.",
            options: ["a", "an", "the", "no article"],
            correct: 3
        },
        {
            question: "She plays ___ piano beautifully.",
            options: ["a", "an", "the", "no article"],
            correct: 2
        }
    ],
    prepositions: [
        {
            question: "I arrived ___ the station at 5 PM.",
            options: ["in", "at", "on", "to"],
            correct: 1
        },
        {
            question: "The book is ___ the table.",
            options: ["in", "at", "on", "by"],
            correct: 2
        },
        {
            question: "We will meet ___ Monday.",
            options: ["in", "at", "on", "by"],
            correct: 2
        },
        {
            question: "She is interested ___ learning languages.",
            options: ["in", "at", "on", "for"],
            correct: 0
        },
        {
            question: "The cat jumped ___ the fence.",
            options: ["in", "over", "at", "by"],
            correct: 1
        }
    ],
    conditionals: [
        {
            question: "If it rains tomorrow, we ___ stay home.",
            options: ["will", "would", "had", "have"],
            correct: 0
        },
        {
            question: "If I ___ you, I would study harder.",
            options: ["am", "was", "were", "be"],
            correct: 2
        },
        {
            question: "If she had studied, she ___ passed the exam.",
            options: ["will have", "would have", "had", "has"],
            correct: 1
        },
        {
            question: "Unless you hurry, you ___ miss the bus.",
            options: ["will", "would", "had", "have"],
            correct: 0
        },
        {
            question: "If I ___ a million dollars, I would travel the world.",
            options: ["have", "had", "will have", "would have"],
            correct: 1
        }
    ]
};

// Grammar State
let currentTopic = 'tenses';
let currentQuestionIndex = 0;
let selectedAnswer = null;
let grammarScore = 0;
let grammarProgress = [];

function initGrammar() {
    currentQuestionIndex = 0;
    grammarScore = 0;
    selectedAnswer = null;
    displayQuestion();
    updateScoreDisplay();
}

function displayQuestion() {
    const questions = grammarQuestions[currentTopic];
    const question = questions[currentQuestionIndex];
    
    document.getElementById('question').textContent = question.question;
    
    const optionsContainer = document.getElementById('options');
    optionsContainer.innerHTML = '';
    
    question.options.forEach((option, index) => {
        const optionDiv = document.createElement('div');
        optionDiv.className = 'option';
        optionDiv.textContent = option;
        optionDiv.onclick = () => selectOption(index);
        optionsContainer.appendChild(optionDiv);
    });
    
    document.getElementById('feedback').innerHTML = '';
    document.getElementById('feedback').className = 'feedback';
    selectedAnswer = null;
}

function selectOption(index) {
    selectedAnswer = index;
    document.querySelectorAll('.option').forEach((opt, i) => {
        opt.classList.remove('selected');
        if (i === index) {
            opt.classList.add('selected');
        }
    });
}

function checkAnswer() {
    if (selectedAnswer === null) {
        alert('Please select an answer');
        return;
    }
    
    const questions = grammarQuestions[currentTopic];
    const question = questions[currentQuestionIndex];
    const feedback = document.getElementById('feedback');
    
    if (selectedAnswer === question.correct) {
        grammarScore++;
        feedback.textContent = '✓ Correct!';
        feedback.className = 'feedback correct';
        document.querySelectorAll('.option')[selectedAnswer].classList.add('correct');
        updateGrammarProgress();
    } else {
        feedback.textContent = `✗ Incorrect. The correct answer is: ${question.options[question.correct]}`;
        feedback.className = 'feedback incorrect';
        document.querySelectorAll('.option')[selectedAnswer].classList.add('incorrect');
        document.querySelectorAll('.option')[question.correct].classList.add('correct');
    }
    
    updateScoreDisplay();
}

function nextQuestion() {
    const questions = grammarQuestions[currentTopic];
    if (currentQuestionIndex < questions.length - 1) {
        currentQuestionIndex++;
        displayQuestion();
    } else {
        alert(`Quiz complete! Your score: ${grammarScore}/${questions.length}`);
        initGrammar();
    }
}

function selectTopic(topic) {
    currentTopic = topic;
    document.querySelectorAll('.topic-button').forEach(btn => {
        btn.classList.remove('active');
    });
    event.target.classList.add('active');
    initGrammar();
}

function updateScoreDisplay() {
    const questions = grammarQuestions[currentTopic];
    document.getElementById('score').textContent = grammarScore;
    document.getElementById('totalQuestions').textContent = questions.length;
}

function updateGrammarProgress() {
    const key = `${currentTopic}_${currentQuestionIndex}`;
    if (!grammarProgress.includes(key)) {
        grammarProgress.push(key);
        saveProgress();
    }
}

// Reading Data
const readingPassages = [
    {
        title: "The Benefits of Learning Languages",
        text: `Learning a new language is one of the most rewarding experiences a person can have. It opens doors to new cultures, helps you connect with people from different backgrounds, and can even improve your cognitive abilities.

Studies have shown that bilingual people have better memory, problem-solving skills, and multitasking abilities compared to monolingual individuals. Learning a language also delays the onset of age-related cognitive decline.

Beyond the cognitive benefits, knowing multiple languages can significantly improve your career prospects. In our globalized world, companies value employees who can communicate with international clients and partners. Many jobs now require or prefer candidates with language skills.

Perhaps most importantly, learning a language allows you to experience the world in new ways. You can travel with confidence, enjoy foreign films and literature in their original form, and make friends across cultural boundaries. Each language offers a unique perspective on the world, enriching your understanding of human experience.`,
        questions: [
            {
                question: "According to the passage, what is one cognitive benefit of being bilingual?",
                options: [
                    "Better physical health",
                    "Improved memory",
                    "Enhanced artistic ability",
                    "Greater height"
                ],
                correct: 1
            },
            {
                question: "Why do companies value employees with language skills?",
                options: [
                    "They work faster",
                    "They need less training",
                    "They can communicate with international clients",
                    "They are more creative"
                ],
                correct: 2
            },
            {
                question: "What does the passage say about language and travel?",
                options: [
                    "It makes travel cheaper",
                    "It allows you to travel with confidence",
                    "It is not related to travel",
                    "It makes travel unnecessary"
                ],
                correct: 1
            }
        ]
    }
];

// Reading State
let currentPassageIndex = 0;
let readingProgress = [];

function initReading() {
    currentPassageIndex = 0;
    displayPassage();
}

function displayPassage() {
    const passage = readingPassages[currentPassageIndex];
    
    document.getElementById('passageTitle').textContent = passage.title;
    document.getElementById('passageText').textContent = passage.text;
    
    const questionsContainer = document.getElementById('readingQuestions');
    questionsContainer.innerHTML = '';
    
    passage.questions.forEach((q, qIndex) => {
        const questionDiv = document.createElement('div');
        questionDiv.className = 'reading-question';
        
        const questionText = document.createElement('p');
        questionText.textContent = `${qIndex + 1}. ${q.question}`;
        questionDiv.appendChild(questionText);
        
        q.options.forEach((option, oIndex) => {
            const label = document.createElement('label');
            const input = document.createElement('input');
            input.type = 'radio';
            input.name = `question${qIndex}`;
            input.value = oIndex;
            label.appendChild(input);
            label.appendChild(document.createTextNode(' ' + option));
            questionDiv.appendChild(label);
        });
        
        questionsContainer.appendChild(questionDiv);
    });
    
    document.getElementById('readingFeedback').innerHTML = '';
}

function checkReadingAnswers() {
    const passage = readingPassages[currentPassageIndex];
    let correct = 0;
    
    passage.questions.forEach((q, qIndex) => {
        const selected = document.querySelector(`input[name="question${qIndex}"]:checked`);
        if (selected && parseInt(selected.value) === q.correct) {
            correct++;
        }
    });
    
    const feedback = document.getElementById('readingFeedback');
    feedback.textContent = `You got ${correct} out of ${passage.questions.length} correct!`;
    feedback.className = correct === passage.questions.length ? 'feedback correct' : 'feedback incorrect';
    
    if (correct === passage.questions.length) {
        updateReadingProgress();
    }
}

function updateReadingProgress() {
    const key = `passage_${currentPassageIndex}`;
    if (!readingProgress.includes(key)) {
        readingProgress.push(key);
        saveProgress();
    }
}

// Progress Management
function updateProgress() {
    // Update vocabulary stats
    document.getElementById('vocabProgress').textContent = vocabularyProgress.length;
    const vocabPercentage = (vocabularyProgress.length / 30) * 100; // Total 30 words
    document.getElementById('vocabBar').style.width = `${vocabPercentage}%`;
    
    // Update grammar stats
    document.getElementById('grammarProgress').textContent = grammarProgress.length;
    const grammarPercentage = (grammarProgress.length / 20) * 100; // Total 20 questions
    document.getElementById('grammarBar').style.width = `${grammarPercentage}%`;
    
    // Update reading stats
    document.getElementById('readingProgress').textContent = readingProgress.length;
    const readingPercentage = (readingProgress.length / readingPassages.length) * 100;
    document.getElementById('readingBar').style.width = `${readingPercentage}%`;
    
    // Calculate overall progress
    const overall = Math.round((vocabPercentage + grammarPercentage + readingPercentage) / 3);
    document.getElementById('overallProgress').textContent = `${overall}%`;
}

function saveProgress() {
    localStorage.setItem('vocabularyProgress', JSON.stringify(vocabularyProgress));
    localStorage.setItem('grammarProgress', JSON.stringify(grammarProgress));
    localStorage.setItem('readingProgress', JSON.stringify(readingProgress));
}

function loadProgress() {
    const vocabData = localStorage.getItem('vocabularyProgress');
    const grammarData = localStorage.getItem('grammarProgress');
    const readingData = localStorage.getItem('readingProgress');
    
    if (vocabData) vocabularyProgress = JSON.parse(vocabData);
    if (grammarData) grammarProgress = JSON.parse(grammarData);
    if (readingData) readingProgress = JSON.parse(readingData);
}

function resetProgress() {
    if (confirm('Are you sure you want to reset all progress? This cannot be undone.')) {
        vocabularyProgress = [];
        grammarProgress = [];
        readingProgress = [];
        saveProgress();
        updateProgress();
        alert('Progress has been reset!');
    }
}
