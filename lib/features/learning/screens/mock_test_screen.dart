import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class MockTestScreen extends StatefulWidget {
  const MockTestScreen({super.key});

  @override
  State<MockTestScreen> createState() => _MockTestScreenState();
}

class _MockTestScreenState extends State<MockTestScreen> {
  int _currentQuestion = 0;
  int? _selectedAnswer;
  bool _answered = false;
  int _score = 0;
  bool _testCompleted = false;

  final List<_Question> _questions = [
    _Question(
      question: 'What does a red traffic light mean?',
      options: ['Go slowly', 'Stop completely', 'Speed up', 'Yield to right'],
      correctIndex: 1,
      explanation: 'A red traffic light means you must stop completely before the stop line.',
    ),
    _Question(
      question: 'What is the speed limit in a residential area in Nepal?',
      options: ['40 km/h', '50 km/h', '30 km/h', '60 km/h'],
      correctIndex: 2,
      explanation: 'The speed limit in residential areas is 30 km/h.',
    ),
    _Question(
      question: 'When should you use hazard lights?',
      options: [
        'When parking illegally',
        'When your vehicle is broken down or in an emergency',
        'When driving in fog',
        'When turning right',
      ],
      correctIndex: 1,
      explanation: 'Hazard lights should be used when your vehicle breaks down or is in an emergency situation.',
    ),
    _Question(
      question: 'What does a yellow dashed center line mean?',
      options: [
        'No passing allowed',
        'Passing allowed with caution',
        'Stop zone ahead',
        'School zone',
      ],
      correctIndex: 1,
      explanation: 'A yellow dashed line means passing is allowed when it is safe to do so.',
    ),
    _Question(
      question: 'Which document is NOT required while driving in Nepal?',
      options: [
        'Driving license',
        'Vehicle bluebook',
        'Insurance certificate',
        'PAN card',
      ],
      correctIndex: 3,
      explanation: 'PAN card is not a mandatory document while driving. You need license, bluebook, and insurance.',
    ),
  ];

  void _selectAnswer(int index) {
    if (_answered) return;
    setState(() {
      _selectedAnswer = index;
      _answered = true;
      if (index == _questions[_currentQuestion].correctIndex) {
        _score++;
      }
    });
  }

  void _nextQuestion() {
    if (_currentQuestion < _questions.length - 1) {
      setState(() {
        _currentQuestion++;
        _selectedAnswer = null;
        _answered = false;
      });
    } else {
      setState(() => _testCompleted = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_testCompleted) {
      return _ResultScreen(
        score: _score,
        total: _questions.length,
        onRetry: () => setState(() {
          _currentQuestion = 0;
          _selectedAnswer = null;
          _answered = false;
          _score = 0;
          _testCompleted = false;
        }),
      );
    }

    final question = _questions[_currentQuestion];
    final progress = (_currentQuestion + 1) / _questions.length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: Text('Question ${_currentQuestion + 1}/${_questions.length}',
            style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Progress bar
          Container(
            height: 6,
            color: AppColors.primary.withOpacity(0.2),
            child: FractionallySizedBox(
              widthFactor: progress,
              alignment: Alignment.centerLeft,
              child: Container(color: AppColors.primary),
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Score
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.star_rounded,
                                color: AppColors.accent, size: 16),
                            const SizedBox(width: 4),
                            Text('Score: $_score',
                                style: const TextStyle(
                                    color: AppColors.success,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13)),
                          ],
                        ),
                      ),
                      Text('${(_currentQuestion + 1)} of ${_questions.length}',
                          style: const TextStyle(
                              color: AppColors.textMedium, fontSize: 13)),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Question
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1565C0), Color(0xFF0D47A1)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Question',
                            style: TextStyle(
                                color: Colors.white60, fontSize: 12)),
                        const SizedBox(height: 8),
                        Text(question.question,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                height: 1.4)),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Options
                  ...question.options.asMap().entries.map((entry) {
                    final index = entry.key;
                    final option = entry.value;
                    final isSelected = _selectedAnswer == index;
                    final isCorrect = index == question.correctIndex;
                    final showResult = _answered;

                    Color bgColor = Colors.white;
                    Color borderColor = AppColors.divider;
                    Color textColor = AppColors.textDark;
                    IconData? trailingIcon;

                    if (showResult) {
                      if (isCorrect) {
                        bgColor = AppColors.success.withOpacity(0.1);
                        borderColor = AppColors.success;
                        textColor = AppColors.success;
                        trailingIcon = Icons.check_circle_rounded;
                      } else if (isSelected && !isCorrect) {
                        bgColor = AppColors.danger.withOpacity(0.1);
                        borderColor = AppColors.danger;
                        textColor = AppColors.danger;
                        trailingIcon = Icons.cancel_rounded;
                      }
                    } else if (isSelected) {
                      bgColor = AppColors.primary.withOpacity(0.1);
                      borderColor = AppColors.primary;
                      textColor = AppColors.primary;
                    }

                    return GestureDetector(
                      onTap: () => _selectAnswer(index),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: bgColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: borderColor, width: 1.5),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 4)
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: borderColor.withOpacity(0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  ['A', 'B', 'C', 'D'][index],
                                  style: TextStyle(
                                      color: textColor,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(option,
                                  style: TextStyle(
                                      color: textColor,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14)),
                            ),
                            if (trailingIcon != null)
                              Icon(trailingIcon, color: textColor, size: 20),
                          ],
                        ),
                      ),
                    );
                  }),

                  // Explanation
                  if (_answered) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.info.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: AppColors.info.withOpacity(0.3)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.info_outline_rounded,
                              color: AppColors.info, size: 18),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(question.explanation,
                                style: const TextStyle(
                                    color: AppColors.textMedium,
                                    fontSize: 13,
                                    height: 1.4)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Next Button
          if (_answered)
            Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton(
                onPressed: _nextQuestion,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(
                  _currentQuestion < _questions.length - 1
                      ? 'Next Question'
                      : 'See Results',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ResultScreen extends StatelessWidget {
  final int score;
  final int total;
  final VoidCallback onRetry;

  const _ResultScreen({
    required this.score,
    required this.total,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final pct = (score / total * 100).round();
    final passed = pct >= 60;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: (passed ? AppColors.success : AppColors.danger)
                      .withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  passed
                      ? Icons.emoji_events_rounded
                      : Icons.sentiment_dissatisfied_rounded,
                  size: 60,
                  color: passed ? AppColors.success : AppColors.danger,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                passed ? 'Congratulations! 🎉' : 'Better luck next time',
                style: const TextStyle(
                    fontSize: 22, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                'You scored $score out of $total ($pct%)',
                style: const TextStyle(
                    color: AppColors.textMedium, fontSize: 15),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(200, 52),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(200, 52),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Back to Learning'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Question {
  final String question;
  final List<String> options;
  final int correctIndex;
  final String explanation;

  const _Question({
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.explanation,
  });
}
