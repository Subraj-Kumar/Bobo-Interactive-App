# Sprout Mobile App Developer Evaluation

**Submitted by:** Subraj Kumar  
**Target Audience:** Children ages 3–8  
**Core Philosophy:** Delightful interactions, zero-latency feedback, and privacy-by-design.

This repository contains the functional implementations for **Task 2 (Mini Interactive Screen)** and **Task 4 (Live Device Integration)** of the Sprout evaluation.

_Note: The written deliverables for Task 1 (Engagement Loop Design) and Task 3 (Drop-off Diagnosis) are provided in the accompanying documentation._

---

## 🌟 Product & Engineering Highlights

When building these activities, I focused on translating simple learning concepts into robust, toddler-friendly product experiences:

- **Privacy-First Architecture:** The image recognition in Task 4 uses **Google ML Kit** to process frames entirely on-device. No images of a child's environment ever leave the device or touch a cloud server.
- **Zero-Latency Feedback:** By keeping ML processing local and utilizing Flutter's native `ScaleTransition` and `AnimatedContainer`, animations and feedback are instant (60fps), preventing toddler drop-off due to loading states.
- **Tactile & Visual Engagement:** The app utilizes dynamic haptic feedback (`services/HapticFeedback`)—light impacts for success, heavy impacts for errors—combined with animated border flashes and confetti to create a highly rewarding cause-and-effect loop.
- **Accessible UI:** Built with large touch targets, programmatic scaling via `FittedBox` for varied screen sizes, and minimal text dependency (relying on icons, colors, and audio).

---

## 📱 The Features

### Task 2: Bobo's Color Safari (Interactive Screen)

A guided, 5-round micro-game where children help "Bobo" identify colors.

- **State Management:** Smooth transitions between Welcome, Gameplay, and Reward states.
- **Forgiving UX:** Incorrect taps do not result in a "Game Over." They trigger a gentle haptic buzz and an encouraging prompt to try again.
- **Programmatic Mascot:** Bobo is rendered entirely using Flutter's core layout widgets (no external image assets required), ensuring pixel-perfect scaling on any device.

### Task 4: House Explorer (Device Integration)

A real-time camera scavenger hunt asking the child to find everyday objects.

- **Machine Learning:** Integrates `google_mlkit_image_labeling` with a custom confidence threshold (0.65) for fast, accurate local detection.
- **Dynamic Visual Cues:** The camera feed border flashes green for success and red for misses, giving children immediate visual validation before the audio and confetti fire.
- **Graceful Fails:** Handles missing camera hardware and denied permissions without crashing.

---

## 🛠 Tech Stack & Packages

- **Framework:** Flutter (Dart)
- **Machine Learning:** `google_mlkit_image_labeling`
- **Hardware Integration:** `camera`
- **Audio & Animation:** `audioplayers`, `confetti`

---

## 🚀 How to Run & Test

**Important Note for Reviewers:** Because Task 4 relies heavily on physical camera hardware, and both tasks utilize device vibration motors for haptic feedback, **this application must be run on a physical Android device** (API 21+) rather than a web browser or emulator.

1. **Clone the repository:**
   ```bash
   git clone <your-repo-link-here>
   cd bobo_interactive
   ```
