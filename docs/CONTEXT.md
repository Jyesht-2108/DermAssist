# DermAssist: Edge Health Monitor – Vibecoding Agent Context

Use this document as the **master context file** for building the DermAssist mobile app. It is designed to eliminate hallucinations, preserve architectural coherence, and maintain a consistent reference for all development tasks.

---

# 📌 Project Overview

**DermAssist** is a privacy‑focused dermatological screening mobile application that uses **Edge AI** to perform instant, offline, on‑device skin anomaly detection.

The app:

* Performs CNN inference **directly on the device** using TensorFlow Lite.
* Never uploads images to a server, ensuring **full privacy**.
* Provides results in **<1 second**.
* Features an incredibly polished **3D‑enhanced UI/UX**.

---

# 🚀 Core Objectives

1. Build a **Flutter** app that is fully responsive, stable, and efficient.
2. Integrate a pre‑trained, optimized CNN model through **tflite_flutter**.
3. Maintain a **zero‑hallucination development flow** for both UI/UX and backend.
4. Deliver a **stunning 3D interface** that blows hackathon judges away.
5. Guarantee **frontend + backend integration correctness** throughout development.
6. Keep the entire app free of bugs, unnecessary complexity, or inconsistencies.

---

# 🧱 Tech Stack

## **Frontend (Flutter)**

* Flutter 3.x
* Dart
* Packages:

  * `camera`
  * `tflite_flutter`
  * `image`
  * `provider` or `riverpod`
  * `three_dart` **OR** Three.js via WebView
  * `flutter_animate`
  * `lottie`
  * `glassmorphism` (optional)

## **Backend (On-device / Local)**

* TensorFlow Lite model
* CNN model optimized and quantized (INT8 or FP16)
* On-device preprocessing pipeline

## **No cloud backend** (privacy-by-design)

---

# 🔄 Application Workflow (End-to-End)

## **1. App Launch**

* Splash screen with animated 3D rotating molecule/skin cell.
* Smooth transition to home screen.

## **2. Home Screen**

* Minimal, elegant UI.
* Primary Call-to-Action: **Scan Skin**.

## **3. Camera Scan**

* Live camera feed.
* Automatic detection of skin region.
* Capture button + auto-capture when stable.

## **4. Preprocessing**

* Resize to model input (e.g., 224×224).
* Normalize pixels.
* Feed into TFLite model.

## **5. On-device Inference**

* CNN outputs condition class + confidence.
* Latency target: < 1 second.

## **6. Result Screen**

* 3D visualization of affected area.
* Risk indicators.
* Heatmap overlay (local explainability).
* Local-only storage if user enables Skin Diary.

## **7. Optional Features**

* Progress tracking.
* Offline suggestions.
* Educational 3D animations.

---

# 🎨 UI / UX Vision

## **Overall Aesthetic**

A premium medical feel:

* Clean whites, neutrals, soft gradients.
* Subtle shadows.
* Elegant modern typography.
* Micro-animations that feel organic.

The UI should feel like:

* Apple Health × Tesla UI × high-end medical software.

---

# 🔥 3D Interface Design (Judges’ Mind-Blow Section)

## **1. 3D Skin Surface Visualizer**

A real-time 3D model that:

* Shows a mesh of the scanned area.
* Projects heatmap-style inference highlights.
* Rotates interactively.

## **2. 3D Scan Animation**

On capturing the image:

* The photo becomes a floating 3D card.
* Then morphs into a mini 3D skin model.

## **3. Explainability Heatmap**

* Grad-CAM rendered as overlay.
* Smooth zoom/pan on 3D object.

## **4. Flutter Implementation Options**

* **three_dart** (pure Flutter)
* **three.js inside WebView** (more powerful)

The UI must feel *premium*, *smooth*, and *designed for awards*.

---

# 🧩 Frontend Architecture

## **State Management**

`riverpod` or `provider`

## **Core Screens**

1. Splash / Intro
2. Home
3. Camera Scan
4. Analysis Preview
5. Results + 3D Viewer
6. Settings

## **Folder Structure**

```
lib/
  ui/
    screens/
    components/
    3d/
  core/
    utils/
    constants/
  ml/
    model/
    inference.dart
  services/
    camera_service.dart
    preprocessing.dart
  state/
    app_state.dart
```

---

# 🧠 ML Architecture

## **Model Characteristics**

* Format: `.tflite`
* Input: 224×224 RGB
* Output: probability vector
* Optimizations:

  * INT8 quantization
  * Fused ops for speed

## **Inference Steps**

1. Convert image → tensor
2. Run prediction
3. Return class + confidence

## **Performance Target**

* Latency: < 700ms on mid-range device
* Memory: < 50MB

---

# 🔌 Frontend + Backend Integration Rules

These rules ensure **zero hallucination** and **bug-free architecture**:

1. Model inference must only be called through a single function:
   `InferenceService.run(imageBytes)`

2. Preprocessing must match training pipeline exactly.

3. UI must never block the main thread; use async operations.

4. 3D viewer receives heatmap + mesh from backend as structured data.

5. No API calls. Everything is local.

6. Error handling must be explicit and silent:

   * No crash logs on UI.
   * Graceful fallbacks.

7. All ML outputs must be validated before UI rendering.

---

# 🧪 Bug Prevention & Quality Standards

## **Strict Requirements**

* No silent nulls.
* No unsafe casts.
* No unbounded lists/maps.
* No unawaited futures.
* No blocking calls in UI threads.

## **Testing Checklist**

* Camera test
* Model load test
* Inference speed test
* Landscape/portrait UI handling
* 3D viewer rendering performance

---

# 📦 Deliverables (Minimum Viable for Hackathon)

1. Fully working Flutter app
2. On-device inference
3. 3D visualization module
4. Demo-ready UI/UX
5. Flawless navigation
6. Offline-only functionality

---

# 🏆 Final Notes for the Agent

* Maintain strict alignment with this document.
* Never invent APIs, functions, or files not defined here.
* Always integrate ML, UI, and 3D features following the given architecture.
* Prioritize smooth performance and visual polish.
* Keep all data processing strictly on-device.
* The goal is a clean, efficient, beautiful, and fully working application.
