import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:confetti/confetti.dart';

class CameraHuntScreen extends StatefulWidget {
  final List<CameraDescription> cameras;

  // Constructor requires the cameras list
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

  final List<String> _targetKeywords = ['cup', 'mug', 'bottle', 'drinkware'];

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 2),
    );

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
    });
    HapticFeedback.lightImpact();

    try {
      final XFile imageFile = await _cameraController.takePicture();
      final inputImage = InputImage.fromFilePath(imageFile.path);
      final List<ImageLabel> labels = await _imageLabeler.processImage(
        inputImage,
      );

      bool foundTarget = false;
      for (ImageLabel label in labels) {
        final text = label.label.toLowerCase();
        debugPrint("Detected: $text with confidence ${label.confidence}");

        if (_targetKeywords.any((keyword) => text.contains(keyword))) {
          foundTarget = true;
          break;
        }
      }

      if (foundTarget) {
        HapticFeedback.vibrate();
        _confettiController.play();
        try {
          await _audioPlayer.play(AssetSource('audio/giggle.mp3'));
        } catch (e) {
          debugPrint("Audio file not found: $e");
        }

        setState(() {
          _score++;
          _feedbackMessage = "Yay! You found it!";
        });

        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            setState(() {
              _feedbackMessage = "Find another Cup or Mug!";
            });
          }
        });
      } else {
        HapticFeedback.heavyImpact();
        setState(() {
          _feedbackMessage = "Oops, not quite! Try again.";
        });
      }
    } catch (e) {
      debugPrint("Error processing image: $e");
      setState(() {
        _feedbackMessage = "Something went wrong. Try again!";
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
        leading: const BackButton(
          color: Colors.white,
        ), // White to show up over the camera feed
      ),
      extendBodyBehindAppBar:
          true, // Let the camera feed take up the whole screen
      body: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: size.width,
            height: size.height,
            child: widget.cameras.isEmpty
                ? const Center(child: Text("No camera available"))
                : CameraPreview(_cameraController),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              emissionFrequency: 0.05,
              numberOfParticles: 40,
              gravity: 0.2,
            ),
          ),
          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          _feedbackMessage,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF4A4A4A),
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
                Padding(
                  padding: const EdgeInsets.only(bottom: 40),
                  child: GestureDetector(
                    onTap: _captureAndAnalyze,
                    child: Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        color: _isProcessing
                            ? Colors.grey
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
