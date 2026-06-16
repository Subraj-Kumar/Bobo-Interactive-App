import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:confetti/confetti.dart';
import 'dart:math';

void main() {
  runApp(const SproutApp());
}

class SproutApp extends StatelessWidget {
  const SproutApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bobo Color Safari',
      theme: ThemeData(
        primarySwatch: Colors.orange,
        scaffoldBackgroundColor: const Color(0xFFFFFDF5),
        fontFamily: 'ComicSans', // Or any soft, rounded font you prefer
      ),
      home: const ColorGameScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

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

  // Define the 5 rounds: Target Color, Target Name, and the options to display
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
      duration: const Duration(seconds: 2),
    );
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _startGame() {
    setState(() {
      _currentState = GameState.playing;
      _currentRoundIndex = 0;
      _feedbackMessage = "Find the color ${_rounds[0]['colorName']}!";
      _isWrongAnswer = false;
    });
  }

  void _handleColorTap(Color selectedColor, Color targetColor) async {
    if (selectedColor == targetColor) {
      // Success
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

      // Wait a moment for them to enjoy the success, then advance
      await Future.delayed(const Duration(seconds: 2));

      if (_currentRoundIndex < _rounds.length - 1) {
        setState(() {
          _currentRoundIndex++;
          _feedbackMessage =
              "Find the color ${_rounds[_currentRoundIndex]['colorName']}!";
        });
      } else {
        setState(() {
          _currentState = GameState.reward;
        });
      }
    } else {
      // Gentle Fail State
      setState(() {
        _isWrongAnswer = true;
        _feedbackMessage =
            "Oops! Let's try again. Find ${_rounds[_currentRoundIndex]['colorName']}!";
      });
    }
  }

  void _restartGame() {
    setState(() {
      _currentState = GameState.welcome;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        alignment: Alignment.center,
        children: [
          SafeArea(child: Center(child: _buildCurrentState())),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              emissionFrequency: 0.05,
              numberOfParticles: 30,
              gravity: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentState() {
    switch (_currentState) {
      case GameState.welcome:
        return _buildWelcomeScreen();
      case GameState.playing:
        return _buildPlayingScreen();
      case GameState.reward:
        return _buildRewardScreen();
    }
  }

  // 1. Welcome Screen
  Widget _buildWelcomeScreen() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const _BoboFace(),
        const SizedBox(height: 40),
        const Text(
          "Hello! I am Bobo.",
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Color(0xFF4A4A4A),
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          "Help me identify the colors!",
          style: TextStyle(fontSize: 22, color: Color(0xFF6B6B6B)),
        ),
        const SizedBox(height: 50),
        ElevatedButton(
          onPressed: _startGame,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFF39C7D),
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
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

  // 2 & 3. Gameplay and Gentle Fail State
  Widget _buildPlayingScreen() {
    final currentRound = _rounds[_currentRoundIndex];
    final String colorName = currentRound['colorName'];
    final Color targetColor = currentRound['targetColor'];

    // Shuffle options so the answer isn't in the same place
    List<Color> options = List.from(currentRound['options']);
    // Seed the shuffle based on round index so it doesn't reshuffle on setState rebuilds
    options.shuffle(Random(_currentRoundIndex));

    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        const SizedBox(height: 40),
        // Mini Bobo at the top to keep the mascot present
        Transform(
          transform: Matrix4.diagonal3Values(0.5, 0.5, 1.0),
          alignment: Alignment.center,
          child: _BoboFace(),
        ),

        Text(
          _feedbackMessage,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: _isWrongAnswer ? Colors.redAccent : const Color(0xFF4A4A4A),
          ),
        ),
        const SizedBox(height: 40),

        // Shape Grid
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
              ),
              itemCount: options.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () => _handleColorTap(options[index], targetColor),
                  child: Container(
                    decoration: BoxDecoration(
                      color: options[index],
                      // Mix up the shapes based on index to satisfy the "different shapes" requirement
                      shape: index % 2 == 0
                          ? BoxShape.circle
                          : BoxShape.rectangle,
                      borderRadius: index % 2 != 0
                          ? BorderRadius.circular(20)
                          : null,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  // 4. Reward Screen
  Widget _buildRewardScreen() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          "Yay! You did it!",
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
        ),
        const SizedBox(height: 20),
        const Icon(Icons.star_rounded, size: 120, color: Colors.amber),
        const SizedBox(height: 20),
        const Text(
          "You found all the colors!",
          style: TextStyle(fontSize: 24, color: Color(0xFF6B6B6B)),
        ),
        const SizedBox(height: 50),
        ElevatedButton(
          onPressed: _restartGame,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.amber,
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
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

/// A programmatic drawing of Bobo's face (reused from earlier)
class _BoboFace extends StatelessWidget {
  const _BoboFace({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 250,
      height: 250,
      child: Stack(
        alignment: Alignment.center,
        children: [
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
    );
  }
}
