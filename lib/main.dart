import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

// Import our task files
import 'task1.dart';
import 'task2.dart';

// Global variable to store cameras so we only initialize them once
List<CameraDescription> availableDeviceCameras = [];

Future<void> main() async {
  // Ensure bindings are initialized before accessing native APIs (like cameras)
  WidgetsFlutterBinding.ensureInitialized();

  try {
    availableDeviceCameras = await availableCameras();
  } catch (e) {
    debugPrint("Error initializing cameras: $e");
  }

  runApp(const SproutEvaluationApp());
}

class SproutEvaluationApp extends StatelessWidget {
  const SproutEvaluationApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sprout Intern Evaluation',
      theme: ThemeData(
        primarySwatch: Colors.orange,
        scaffoldBackgroundColor: const Color(0xFFFFFDF5),
        fontFamily: 'ComicSans', // Ensure this is in pubspec.yaml if custom
      ),
      home: const MainMenuScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.rocket_launch_rounded,
                  size: 80,
                  color: Color(0xFFF39C7D),
                ),
                const SizedBox(height: 20),
                const Text(
                  "Sprout Evaluation",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4A4A4A),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  "Select a task to review",
                  style: TextStyle(fontSize: 18, color: Color(0xFF6B6B6B)),
                ),
                SizedBox(height: size.height * 0.1),

                // Button for Task 1 (Interactive Screen)
                _buildMenuButton(
                  context,
                  title: "Task 2: Interactive Screen",
                  subtitle: "Bobo's Color Safari",
                  icon: Icons.touch_app_rounded,
                  color: Colors.orange,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ColorGameScreen(),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 20),

                // Button for Task 2 (Camera Integration)
                _buildMenuButton(
                  context,
                  title: "Task 4: Device Integration",
                  subtitle: "House Explorer (ML Kit)",
                  icon: Icons.camera_alt_rounded,
                  color: Colors.blueAccent,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            CameraHuntScreen(cameras: availableDeviceCameras),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuButton(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
          border: Border.all(color: color.withOpacity(0.3), width: 2),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 32, color: color),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4A4A4A),
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF6B6B6B),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
