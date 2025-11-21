import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../services/camera_service.dart';
import '../../ml/inference_service.dart';
import '../../state/app_state.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  final CameraService _cameraService = CameraService();
  bool _isInitializing = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    // Request camera permission
    final status = await Permission.camera.request();
    
    if (!status.isGranted) {
      setState(() {
        _isInitializing = false;
        _errorMessage = 'Camera permission denied';
      });
      return;
    }

    // Initialize camera
    final success = await _cameraService.initialize();
    setState(() {
      _isInitializing = false;
      if (!success) {
        _errorMessage = 'Failed to initialize camera';
      }
    });
  }

  Future<void> _captureAndAnalyze() async {
    final appState = context.read<AppState>();
    
    if (!appState.isModelLoaded) {
      _showError('Model not loaded');
      return;
    }

    try {
      appState.setProcessing(true);

      // Capture image
      final imageBytes = await _cameraService.captureImage();
      if (imageBytes == null) {
        appState.setProcessing(false);
        _showError('Failed to capture image');
        return;
      }

      // Show capture feedback
      if (mounted) {
        _showInfo('Processing image...');
      }

      // Run inference
      final result = await InferenceService().run(imageBytes);
      appState.setResult(result);

      if (result != null && mounted) {
        // Show results
        _showSuccess(
          'Analysis complete!\n'
          'Confidence: ${(result.confidence * 100).toStringAsFixed(1)}%\n'
          'Time: ${result.inferenceTimeMs}ms'
        );
      } else {
        _showError('Analysis failed - please try again');
      }
    } catch (e) {
      appState.setProcessing(false);
      _showError('Error: ${e.toString()}');
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showInfo(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.blue,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  void dispose() {
    _cameraService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) {
          await _cameraService.dispose();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
        child: _isInitializing
            ? const Center(
                child: CircularProgressIndicator(color: Colors.white),
              )
            : _errorMessage != null
                ? Center(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.white),
                    ),
                  )
                : _buildCameraView(),
        ),
      ),
    );
  }

  Widget _buildCameraView() {
    final controller = _cameraService.controller;
    if (controller == null || !controller.value.isInitialized) {
      return const Center(
        child: Text(
          'Camera not available',
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    return Stack(
      children: [
        // Camera preview
        Center(
          child: AspectRatio(
            aspectRatio: controller.value.aspectRatio,
            child: CameraPreview(controller),
          ),
        ),

        // Top bar
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.7),
                  Colors.transparent,
                ],
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () async {
                    await _cameraService.dispose();
                    if (mounted) Navigator.pop(context);
                  },
                ),
                const Spacer(),
                const Text(
                  'Scan Skin',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                const SizedBox(width: 48),
              ],
            ),
          ),
        ),

        // Scan guide overlay
        Center(
          child: Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.5),
                width: 2,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Center(
              child: Text(
                'Position skin area\nwithin frame',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ),

        // Capture button
        Positioned(
          bottom: 40,
          left: 0,
          right: 0,
          child: Center(
            child: Consumer<AppState>(
              builder: (context, appState, child) {
                return GestureDetector(
                  onTap: appState.isProcessing ? null : _captureAndAnalyze,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: appState.isProcessing 
                          ? Colors.grey.shade300 
                          : Colors.white,
                      border: Border.all(
                        color: Colors.white,
                        width: 4,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: appState.isProcessing
                        ? const Padding(
                            padding: EdgeInsets.all(20),
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.blue,
                              ),
                            ),
                          )
                        : const Icon(
                            Icons.camera_alt,
                            size: 40,
                            color: Colors.blue,
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
}
