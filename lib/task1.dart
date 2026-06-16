import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:confetti/confetti.dart';
import 'dart:math';

enum GameState { welcome, playing, reward }

class ColorGameScreen extends StatefulWidget {
  const ColorGameScreen({Key? key}) : super(key: key);

  @override
  State<ColorGameScreen> createState() => _ColorGameScreenState();
}

class _ColorGameScreenState extends State<ColorGameScreen> {
  GameState _currentState = GameState.welcome;
  int _currentRoundIndex = 0;
  String _feedbackMessage = "";
  bool _isWrongAnswer = false;

  late ConfettiController _confettiController;
  final AudioPlayer _audioPlayer = AudioPlayer();

  final List<Map<String, dynamic>> _rounds = [
    {
      'colorName': 'RED',
      'targetColor': Colors.red,
      'options': [Colors.red, Colors.blue, Colors.green, Colors.yellow],
    },
    {
      'colorName': 'BLUE',
      'targetColor': Colors.blue,
      'options': [Colors.green, Colors.pink, Colors.blue, Colors.orange],
    },
    {
      'colorName': 'GREEN',
      'targetColor': Colors.green,
      'options': [Colors.purple, Colors.green, Colors.red, Colors.yellow],
    },
    {
      'colorName': 'YELLOW',
      'targetColor': Colors.yellow,
      'options': [Colors.blue, Colors.yellow, Colors.pink, Colors.green],
    },
    {
      'colorName': 'PINK',
      'targetColor': Colors.pink,
      'options': [Colors.pink, Colors.orange, Colors.blue, Colors.red],
    },
  ];

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(milliseconds: 1500),
    );
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _startGame() {
    HapticFeedback.mediumImpact();
    setState(() {
      _currentState = GameState.playing;
      _currentRoundIndex = 0;
      _feedbackMessage = "Find the color ${_rounds[0]['colorName']}!";
      _isWrongAnswer = false;
    });
  }

  void _handleColorTap(Color selectedColor, Color targetColor) async {
    if (selectedColor == targetColor) {
      HapticFeedback.lightImpact();
      setState(() {
        _isWrongAnswer = false;
        _feedbackMessage = "Great job!";
      });
      _confettiController.play();

      try {
        await _audioPlayer.play(AssetSource('audio/giggle.mp3'));
      } catch (e) {
        debugPrint("Audio missing: $e");
      }

      await Future.delayed(const Duration(seconds: 2));

      if (!mounted) return;
      if (_currentRoundIndex < _rounds.length - 1) {
        setState(() {
          _currentRoundIndex++;
          _feedbackMessage =
              "Find the color ${_rounds[_currentRoundIndex]['colorName']}!";
        });
      } else {
        HapticFeedback.vibrate();
        setState(() {
          _currentState = GameState.reward;
        });
      }
    } else {
      HapticFeedback.heavyImpact();
      setState(() {
        _isWrongAnswer = true;
        _feedbackMessage =
            "Oops! Let's try again. Find ${_rounds[_currentRoundIndex]['colorName']}!";
      });
    }
  }

  void _restartGame() {
    HapticFeedback.mediumImpact();
    setState(() {
      _currentState = GameState.welcome;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Color(0xFF4A4A4A)),
      ),
      body: Stack(
        alignment: Alignment.center,
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Center(child: _buildCurrentState(context)),
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              emissionFrequency: 0.05,
              numberOfParticles: 40,
              gravity: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentState(BuildContext context) {
    switch (_currentState) {
      case GameState.welcome:
        return _buildWelcomeScreen(context);
      case GameState.playing:
        return _buildPlayingScreen(context);
      case GameState.reward:
        return _buildRewardScreen(context);
    }
  }

  Widget _buildWelcomeScreen(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: min(size.width * 0.4, 250),
          child: const FittedBox(child: BoboFace()),
        ),
        SizedBox(height: size.height * 0.05),
        Text(
          "Hello! I am Bobo.",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: size.width * 0.08 > 32 ? 32 : size.width * 0.08,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF4A4A4A),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          "Help me identify the colors!",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: size.width * 0.05 > 22 ? 22 : size.width * 0.05,
            color: const Color(0xFF6B6B6B),
          ),
        ),
        SizedBox(height: size.height * 0.08),
        ElevatedButton(
          onPressed: _startGame,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFF39C7D),
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            elevation: 5,
          ),
          child: const Text(
            "Start Safari",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlayingScreen(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final currentRound = _rounds[_currentRoundIndex];
    final Color targetColor = currentRound['targetColor'];

    // Seed the randomizer based on the round so it doesn't shuffle on every setState rebuild
    List<Color> options = List.from(currentRound['options']);
    options.shuffle(Random(_currentRoundIndex));

    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        SizedBox(height: size.height * 0.02),

        // Visual Progress Tracker (Stars)
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (index) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: AnimatedScale(
                scale: index == _currentRoundIndex ? 1.2 : 1.0,
                duration: const Duration(milliseconds: 300),
                child: Icon(
                  Icons.star_rounded,
                  color: index < _currentRoundIndex
                      ? Colors.amber
                      : Colors.grey.shade300,
                  size: 36,
                ),
              ),
            );
          }),
        ),

        SizedBox(height: size.height * 0.03),
        SizedBox(
          width: min(size.width * 0.2, 100),
          child: const FittedBox(child: BoboFace()),
        ),
        SizedBox(height: size.height * 0.02),

        // Feedback Message
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Text(
            _feedbackMessage,
            key: ValueKey<String>(_feedbackMessage),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: size.width * 0.07 > 28 ? 28 : size.width * 0.07,
              fontWeight: FontWeight.bold,
              color: _isWrongAnswer
                  ? Colors.redAccent
                  : const Color(0xFF4A4A4A),
            ),
          ),
        ),
        SizedBox(height: size.height * 0.04),

        // Shape Grid with Tactile Feedback
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              double childAspectRatio =
                  (constraints.maxWidth / 2) / (constraints.maxHeight / 2.5);
              return GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 20,
                  mainAxisSpacing: 20,
                  childAspectRatio: childAspectRatio.clamp(0.8, 1.5),
                ),
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final isCircle = index % 2 == 0;
                  final borderRadius = isCircle
                      ? BorderRadius.circular(1000)
                      : BorderRadius.circular(20);

                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _handleColorTap(options[index], targetColor),
                      borderRadius: borderRadius,
                      splashColor: Colors.white.withOpacity(0.3),
                      highlightColor: Colors.white.withOpacity(0.1),
                      child: Ink(
                        decoration: BoxDecoration(
                          color: options[index],
                          shape: isCircle
                              ? BoxShape.circle
                              : BoxShape.rectangle,
                          borderRadius: isCircle ? null : borderRadius,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRewardScreen(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Yay! You did it!",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: size.width * 0.09 > 36 ? 36 : size.width * 0.09,
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
        ),
        const SizedBox(height: 20),
        Icon(
          Icons.star_rounded,
          size: min(size.width * 0.3, 120),
          color: Colors.amber,
        ),
        const SizedBox(height: 20),
        Text(
          "You found all the colors!",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: size.width * 0.06 > 24 ? 24 : size.width * 0.06,
            color: const Color(0xFF6B6B6B),
          ),
        ),
        SizedBox(height: size.height * 0.08),
        ElevatedButton(
          onPressed: _restartGame,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.amber,
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            elevation: 5,
          ),
          child: const Text(
            "Play Again",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}

/// A stateful Bobo face that gently floats up and down to feel "alive"
class BoboFace extends StatefulWidget {
  const BoboFace({Key? key}) : super(key: key);

  @override
  State<BoboFace> createState() => _BoboFaceState();
}

class _BoboFaceState extends State<BoboFace>
    with SingleTickerProviderStateMixin {
  late AnimationController _breathingController;

  @override
  void initState() {
    super.initState();
    // Creates a smooth, continuous up-and-down floating effect
    _breathingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _breathingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _breathingController,
      builder: (context, child) {
        return Transform.translate(
          // Moves Bobo smoothly by 8 pixels up and down
          offset: Offset(0, -8 * _breathingController.value),
          child: child,
        );
      },
      child: SizedBox(
        width: 250,
        height: 250,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Left Ear
            Positioned(
              left: 10,
              top: 40,
              child: Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  color: Color(0xFFF39C7D),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            // Right Ear
            Positioned(
              right: 10,
              top: 40,
              child: Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  color: Color(0xFFF39C7D),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            // Main Head
            Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                color: const Color(0xFFF39C7D),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
            ),
            // Left Eye
            Positioned(
              left: 90,
              top: 100,
              child: Container(
                width: 15,
                height: 15,
                decoration: const BoxDecoration(
                  color: Color(0xFF333333),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            // Right Eye
            Positioned(
              right: 90,
              top: 100,
              child: Container(
                width: 15,
                height: 15,
                decoration: const BoxDecoration(
                  color: Color(0xFF333333),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            // Trunk
            Positioned(
              top: 120,
              child: Container(
                width: 20,
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFFE08969),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
