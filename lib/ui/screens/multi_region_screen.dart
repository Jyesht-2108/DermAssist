import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../ml/inference_service.dart';
import '../../ml/model_labels.dart';
import '../components/glass_card.dart';

class MultiRegionScreen extends StatefulWidget {
  final Uint8List originalImage;
  final int imageWidth;
  final int imageHeight;

  const MultiRegionScreen({
    super.key,
    required this.originalImage,
    required this.imageWidth,
    required this.imageHeight,
  });

  @override
  State<MultiRegionScreen> createState() => _MultiRegionScreenState();
}

class _MultiRegionScreenState extends State<MultiRegionScreen> {
  final List<RegionData> _regions = [];
  bool _isProcessing = false;
  int _regionCounter = 1;

  Future<void> _addRegion(Offset position) async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    final regionId = 'region_${DateTime.now().millisecondsSinceEpoch}';
    final regionName = 'Region $_regionCounter';
    _regionCounter++;

    // Process region off main thread
    final regionData = await InferenceService().processRegion(
      imageBytes: widget.originalImage,
      regionId: regionId,
      regionName: regionName,
      center: position,
      radius: 50,
      imageWidth: widget.imageWidth,
      imageHeight: widget.imageHeight,
    );

    if (regionData != null && mounted) {
      setState(() {
        _regions.add(regionData);
        _isProcessing = false;
      });
    } else {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  void _deleteRegion(String regionId) {
    setState(() {
      _regions.removeWhere((r) => r.id == regionId);
    });
  }

  void _renameRegion(String regionId, String newName) {
    setState(() {
      final region = _regions.firstWhere((r) => r.id == regionId);
      region.name = newName;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF667eea),
              const Color(0xFF764ba2),
              Colors.blue.shade900,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Text(
                      'Multi-Region Analysis',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${_regions.length} regions',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // Image with region markers
                      GlassCard(
                        blur: 20,
                        opacity: 0.15,
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            const Text(
                              'Tap to mark regions',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 16),
                            GestureDetector(
                              onTapDown: (details) {
                                _addRegion(details.localPosition);
                              },
                              child: Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.memory(
                                      widget.originalImage,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                  // Region markers
                                  ..._regions.map((region) {
                                    final color = Color(ModelLabels.getRiskColor(
                                      region.result.riskLevel,
                                    ));
                                    return Positioned(
                                      left: region.center.dx - region.radius,
                                      top: region.center.dy - region.radius,
                                      child: Container(
                                        width: region.radius * 2,
                                        height: region.radius * 2,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: color,
                                            width: 3,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: color.withValues(alpha: 0.5),
                                              blurRadius: 10,
                                              spreadRadius: 2,
                                            ),
                                          ],
                                        ),
                                        child: Center(
                                          child: Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: BoxDecoration(
                                              color: color,
                                              shape: BoxShape.circle,
                                            ),
                                            child: Text(
                                              region.name.split(' ').last,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    )
                                        .animate()
                                        .scale(
                                          duration: 300.ms,
                                          begin: const Offset(0, 0),
                                          curve: Curves.elasticOut,
                                        )
                                        .fadeIn(duration: 200.ms);
                                  }),
                                  // Processing indicator
                                  if (_isProcessing)
                                    Positioned.fill(
                                      child: Container(
                                        color: Colors.black.withValues(alpha: 0.5),
                                        child: const Center(
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Region results
                      if (_regions.isNotEmpty)
                        ..._regions.map((region) {
                          final color = Color(ModelLabels.getRiskColor(
                            region.result.riskLevel,
                          ));
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: GlassCard(
                              blur: 20,
                              opacity: 0.15,
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 12,
                                        height: 12,
                                        decoration: BoxDecoration(
                                          color: color,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          region.name,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.edit,
                                          color: Colors.white70,
                                          size: 20,
                                        ),
                                        onPressed: () => _showRenameDialog(region),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete,
                                          color: Colors.red,
                                          size: 20,
                                        ),
                                        onPressed: () => _deleteRegion(region.id),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    region.result.label,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildMetric(
                                          'Confidence',
                                          '${(region.result.confidence * 100).toStringAsFixed(1)}%',
                                        ),
                                      ),
                                      Expanded(
                                        child: _buildMetric(
                                          'Risk',
                                          region.result.riskLevel,
                                        ),
                                      ),
                                      Expanded(
                                        child: _buildMetric(
                                          'Time',
                                          '${region.result.inferenceTimeMs}ms',
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            )
                                .animate()
                                .fadeIn(duration: 400.ms)
                                .slideY(begin: 0.2, end: 0),
                          );
                        }),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetric(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  void _showRenameDialog(RegionData region) {
    final controller = TextEditingController(text: region.name);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Region'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Region Name',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              _renameRegion(region.id, controller.text);
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
