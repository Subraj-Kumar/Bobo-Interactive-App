import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:confetti/confetti.dart';

class CameraHuntScreen extends StatefulWidget {
  final List<CameraDescription> cameras;

  const CameraHuntScreen({Key? key, required this.cameras}) : super(key: key);

  @override
  State<CameraHuntScreen> createState() => _CameraHuntScreenState();
}

class _CameraHuntScreenState extends State<CameraHuntScreen> {
  late CameraController _cameraController;
  late ImageLabeler _imageLabeler;
  late ConfettiController _confettiController;
  final AudioPlayer _audioPlayer = AudioPlayer();

  bool _isInitializing = true;
  bool _isProcessing = false;
  String _feedbackMessage = "Find a Cup or Mug!";
  int _score = 0;

  // New state variables for visual enhancements
  Color _screenBorderColor = Colors.transparent;

  final List<String> _targetKeywords = ['cup', 'mug', 'bottle', 'drinkware'];

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 2),
    );

    // Initializing ML Kit with a slightly stricter confidence for better accuracy
    final options = ImageLabelerOptions(confidenceThreshold: 0.65);
    _imageLabeler = ImageLabeler(options: options);

    _initCamera();
  }

  Future<void> _initCamera() async {
    if (widget.cameras.isEmpty) {
      setState(() {
        _isInitializing = false;
        _feedbackMessage = "No camera found";
      });
      return;
    }

    final rearCamera = widget.cameras.firstWhere(
      (cam) => cam.lensDirection == CameraLensDirection.back,
      orElse: () => widget.cameras.first,
    );

    _cameraController = CameraController(
      rearCamera,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    try {
      await _cameraController.initialize();
      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
      }
    } catch (e) {
      debugPrint("Camera initialization error: $e");
    }
  }

  @override
  void dispose() {
    _cameraController.dispose();
    _imageLabeler.close();
    _confettiController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _captureAndAnalyze() async {
    if (_isProcessing || !_cameraController.value.isInitialized) return;

    setState(() {
      _isProcessing = true;
      _feedbackMessage = "Looking...";
      _screenBorderColor = Colors.transparent; // Reset border
    });
    HapticFeedback.lightImpact();

    try {
      final XFile imageFile = await _cameraController.takePicture();
      final inputImage = InputImage.fromFilePath(imageFile.path);
      final List<ImageLabel> labels = await _imageLabeler.processImage(
        inputImage,
      );

      bool foundTarget = false;
      String matchedLabel = "";

      // Check labels against our keywords
      for (ImageLabel label in labels) {
        final text = label.label.toLowerCase();
        debugPrint("Detected: $text with confidence ${label.confidence}");

        if (_targetKeywords.any((keyword) => text.contains(keyword))) {
          foundTarget = true;
          // Capitalize the first letter for the UI
          matchedLabel = text[0].toUpperCase() + text.substring(1);
          break;
        }
      }

      if (foundTarget) {
        // --- SUCCESS STATE ---
        HapticFeedback.vibrate();
        _confettiController.play();

        try {
          // Ensure your asset is at assets/audio/giggle.mp3 in pubspec.yaml
          await _audioPlayer.play(AssetSource('audio/giggle.mp3'));
        } catch (e) {
          debugPrint("Audio file not found: $e");
        }

        setState(() {
          _score++;
          _feedbackMessage = "Yay! You found a $matchedLabel!";
          _screenBorderColor = Colors.greenAccent.withOpacity(
            0.5,
          ); // Green flash
        });

        // Reset UI after 3 seconds
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            setState(() {
              _feedbackMessage = "Find another Cup or Mug!";
              _screenBorderColor = Colors.transparent;
            });
          }
        });
      } else {
        // --- FAIL STATE ---
        HapticFeedback.heavyImpact();
        setState(() {
          _feedbackMessage = "Oops, not quite! Try again.";
          _screenBorderColor = Colors.redAccent.withOpacity(0.5); // Red flash
        });

        // Clear the red border after a short delay
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            setState(() {
              _screenBorderColor = Colors.transparent;
              if (_feedbackMessage.contains("Oops")) {
                _feedbackMessage = "Find a Cup or Mug!";
              }
            });
          }
        });
      }
    } catch (e) {
      debugPrint("Error processing image: $e");
      setState(() {
        _feedbackMessage = "Something went wrong. Try again!";
        _screenBorderColor = Colors.transparent;
      });
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFFF39C7D)),
        ),
      );
    }

    final size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.white),
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        alignment: Alignment.center,
        children: [
          // 1. Camera Feed with Animated Border Flash
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: size.width,
            height: size.height,
            decoration: BoxDecoration(
              border: Border.all(
                color: _screenBorderColor,
                width: _screenBorderColor == Colors.transparent ? 0 : 12,
              ),
            ),
            child: widget.cameras.isEmpty
                ? const Center(child: Text("No camera available"))
                : CameraPreview(_cameraController),
          ),

          // 2. Confetti Layer (Top Center)
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              emissionFrequency: 0.05,
              numberOfParticles:
                  50, // Slightly more particles for better visual reward
              gravity: 0.2,
            ),
          ),

          // 3. UI Overlay
          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Top Feedback Box
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          _feedbackMessage,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            // Change text color dynamically based on success/fail
                            color:
                                _screenBorderColor ==
                                    Colors.redAccent.withOpacity(0.5)
                                ? Colors.redAccent
                                : const Color(0xFF4A4A4A),
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            color: Colors.amber,
                            size: 32,
                          ),
                          Text(
                            " $_score",
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Bottom Capture Button
                Padding(
                  padding: const EdgeInsets.only(bottom: 40),
                  child: GestureDetector(
                    onTap: _captureAndAnalyze,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: _isProcessing ? 80 : 90,
                      height: _isProcessing ? 80 : 90,
                      decoration: BoxDecoration(
                        color: _isProcessing
                            ? Colors.grey.shade400
                            : const Color(0xFFF39C7D),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 6),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: _isProcessing
                          ? const Center(
                              child: CircularProgressIndicator(
                                color: Colors.white,
                              ),
                            )
                          : const Icon(
                              Icons.camera_alt_rounded,
                              color: Colors.white,
                              size: 40,
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
