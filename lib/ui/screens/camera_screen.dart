import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../services/camera_service.dart';
import '../../ml/inference_service.dart';
import '../../state/app_state.dart';
import 'results_screen.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  final CameraService _cameraService = CameraService();
  bool _isInitializing = true;
  String? _errorMessage;
  
  // Real-time inference state
  bool _isRealTimeMode = false;
  bool _isProcessingFrame = false;
  int _frameCount = 0;
  String? _realtimeLabel;
  double? _realtimeConfidence;
  int? _realtimeInferenceTime;
  String _realtimeRiskLevel = 'Low';
  bool _hasShownError = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }
  
  void _toggleRealTimeMode() {
    setState(() {
      _isRealTimeMode = !_isRealTimeMode;
      if (!_isRealTimeMode) {
        // Clear real-time data when disabled
        _realtimeLabel = null;
        _realtimeConfidence = null;
        _realtimeInferenceTime = null;
        _realtimeRiskLevel = 'Low';
      }
    });
  }
  
  Future<void> _processFrameForRealtime() async {
    if (!_isRealTimeMode || _isProcessingFrame) return;
    
    final appState = context.read<AppState>();
    if (!appState.isModelLoaded) return;
    
    _frameCount++;
    
    // Process every 5th frame to maintain 60 FPS
    if (_frameCount % 5 != 0) return;
    
    _isProcessingFrame = true;
    
    try {
      // Capture current frame (off main thread)
      final imageBytes = await _cameraService.captureImage();
      if (imageBytes == null) {
        _isProcessingFrame = false;
        return;
      }
      
      // Run inference off main thread
      final result = await InferenceService().run(imageBytes);
      
      if (result != null && mounted) {
        setState(() {
          _realtimeLabel = result.label;
          _realtimeConfidence = result.confidence;
          _realtimeInferenceTime = result.inferenceTimeMs;
          _realtimeRiskLevel = result.riskLevel;
        });
      }
    } catch (e) {
      // Silent failure - show toast only once
      if (!_hasShownError && mounted) {
        _hasShownError = true;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Real-time inference paused'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } finally {
      _isProcessingFrame = false;
    }
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
      
      if (result == null) {
        appState.setProcessing(false);
        _showError('Analysis failed - please try again');
        return;
      }

      // Generate heatmap off main thread
      if (mounted) {
        _showInfo('Generating heatmap...');
      }
      
      final heatmap = await InferenceService().generateHeatmap(
        imageBytes,
        result.classIndex,
      );

      // Create result with heatmap
      final resultWithHeatmap = InferenceResult(
        classIndex: result.classIndex,
        confidence: result.confidence,
        probabilities: result.probabilities,
        inferenceTimeMs: result.inferenceTimeMs,
        label: result.label,
        riskLevel: result.riskLevel,
        heatmap: heatmap,
      );

      appState.setResult(resultWithHeatmap);

      if (mounted) {
        // Navigate to results screen
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ResultsScreen(
              result: resultWithHeatmap,
              originalImage: imageBytes,
            ),
          ),
        );
        // Reset processing state after returning
        appState.setProcessing(false);
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
    _isRealTimeMode = false;
    _cameraService.dispose();
    super.dispose();
  }
  
  Color _getRiskColor() {
    switch (_realtimeRiskLevel) {
      case 'High':
        return Colors.red;
      case 'Medium':
        return Colors.orange;
      default:
        return Colors.green;
    }
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
    
    // Trigger real-time processing
    if (_isRealTimeMode) {
      Future.microtask(() => _processFrameForRealtime());
    }

    return Stack(
      children: [
        // Camera preview with colored border for real-time mode
        Center(
          child: AspectRatio(
            aspectRatio: controller.value.aspectRatio,
            child: Container(
              decoration: _isRealTimeMode && _realtimeConfidence != null
                  ? BoxDecoration(
                      border: Border.all(
                        color: _getRiskColor(),
                        width: 4,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _getRiskColor().withValues(alpha: 0.5),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    )
                  : null,
              child: CameraPreview(controller),
            ),
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
            child: Column(
              children: [
                Row(
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
                    // Real-time mode toggle
                    IconButton(
                      icon: Icon(
                        _isRealTimeMode ? Icons.visibility : Icons.visibility_off,
                        color: _isRealTimeMode ? Colors.greenAccent : Colors.white,
                      ),
                      onPressed: _toggleRealTimeMode,
                      tooltip: 'Real-Time Scan',
                    ),
                  ],
                ),
                // Real-time info display
                if (_isRealTimeMode && _realtimeLabel != null)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _getRiskColor().withValues(alpha: 0.5),
                        width: 2,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: _getRiskColor(),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _realtimeLabel!,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Confidence: ${(_realtimeConfidence! * 100).toStringAsFixed(1)}%',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              '${_realtimeInferenceTime}ms',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
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
