import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:share_plus/share_plus.dart';
import '../../ml/inference_service.dart';
import '../../ml/model_labels.dart';
import '../../services/pdf_report_service.dart';
import '../components/glass_card.dart';
import '../components/skin_3d_viewer.dart';
import '../components/particle_background.dart';
import 'multi_region_screen.dart';

class ResultsScreen extends StatefulWidget {
  final InferenceResult result;
  final Uint8List? originalImage;

  const ResultsScreen({
    super.key,
    required this.result,
    this.originalImage,
  });

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  bool _showHeatmap = false;
  double _heatmapOpacity = 0.6;
  final ValueNotifier<Offset?> _selectedPointNotifier = ValueNotifier<Offset?>(null);
  final GlobalKey viewer3dKey = GlobalKey();
  bool _isGeneratingPdf = false;

  @override
  void dispose() {
    _selectedPointNotifier.dispose();
    super.dispose();
  }

  Future<void> _generatePdfReport() async {
    setState(() {
      _isGeneratingPdf = true;
    });

    try {
      // Capture 3D viewer snapshot if available
      Uint8List? snapshot3D;
      try {
        final boundary = viewer3dKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
        if (boundary != null) {
          final image = await boundary.toImage(pixelRatio: 2.0);
          final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
          snapshot3D = byteData?.buffer.asUint8List();
        }
      } catch (e) {
        // If 3D snapshot fails, continue without it
        debugPrint('Failed to capture 3D snapshot: $e');
      }

      // Capture heatmap image if available
      Uint8List? heatmapImage;
      if (widget.result.heatmap != null && widget.originalImage != null) {
        heatmapImage = widget.result.heatmap!.imageBytes;
      }

      // Generate the PDF
      final pdfFile = await PdfReportService.generateReport(
        result: widget.result,
        originalImage: widget.originalImage!,
        heatmapImage: heatmapImage,
        snapshot3D: snapshot3D,
      );

      setState(() {
        _isGeneratingPdf = false;
      });

      // Show success dialog with options
      if (mounted) {
        _showReportGeneratedDialog(pdfFile.path);
      }
    } catch (e) {
      setState(() {
        _isGeneratingPdf = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate report: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showReportGeneratedDialog(String filePath) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 28),
            const SizedBox(width: 12),
            const Text('Report Generated'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your professional PDF report has been generated successfully.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.folder, color: Colors.blue.shade700, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      filePath.split('/').last,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Location: Documents/DermAssist/',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(context);
              await Share.shareXFiles(
                [XFile(filePath)],
                subject: 'DermAssist Analysis Report',
              );
            },
            icon: const Icon(Icons.share),
            label: const Text('Share'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade700,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final riskColor = Color(ModelLabels.getRiskColor(widget.result.riskLevel));

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
        child: ParticleBackground(
          particleCount: 50,
          particleColor: Colors.white.withValues(alpha: 0.3),
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
                        'Analysis Results',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                )
                    .animate()
                    .fadeIn(duration: 400.ms)
                    .slideX(begin: -0.2, end: 0),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        // 3D Skin Visualization
                        GlassCard(
                          blur: 20,
                          opacity: 0.15,
                          padding: const EdgeInsets.all(30),
                          child: Column(
                            children: [
                              const Text(
                                '3D Skin Analysis',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 20),
                              RepaintBoundary(
                                key: viewer3dKey,
                                child: Skin3DViewer(
                                  confidence: widget.result.confidence,
                                  riskLevel: widget.result.riskLevel,
                                  riskColor: riskColor,
                                  heatmapGrid: widget.result.heatmap?.grid,
                                  predictedClass: widget.result.label,
                                  capturedImage: widget.originalImage,
                                  selectedPointNotifier: _selectedPointNotifier,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Drag to rotate • Tap hotspots for details',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white.withValues(alpha: 0.6),
                                ),
                              ),
                            ],
                          ),
                        )
                            .animate()
                            .fadeIn(duration: 600.ms, delay: 200.ms)
                            .scale(begin: const Offset(0.9, 0.9)),

                        const SizedBox(height: 24),

                        // Heatmap Overlay Section
                        if (widget.result.heatmap != null && widget.originalImage != null)
                          GlassCard(
                            blur: 20,
                            opacity: 0.15,
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Attention Heatmap',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                    Switch(
                                      value: _showHeatmap,
                                      onChanged: (value) {
                                        setState(() {
                                          _showHeatmap = value;
                                        });
                                      },
                                      activeTrackColor: Colors.greenAccent,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                // Image with heatmap overlay
                                GestureDetector(
                                  onTapDown: (details) {
                                    if (_showHeatmap && widget.result.heatmap != null) {
                                      final box = context.findRenderObject() as RenderBox?;
                                      if (box != null) {
                                        final localPosition = details.localPosition;
                                        // Normalize to 0-1 range
                                        final normalizedX = localPosition.dx / box.size.width;
                                        final normalizedY = localPosition.dy / box.size.height;
                                        _selectedPointNotifier.value = Offset(normalizedX, normalizedY);
                                      }
                                    }
                                  },
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: AspectRatio(
                                      aspectRatio: 1.0,
                                      child: Stack(
                                        fit: StackFit.expand,
                                        children: [
                                          // Original image
                                          Image.memory(
                                            widget.originalImage!,
                                            fit: BoxFit.cover,
                                          ),
                                          // Heatmap overlay
                                          if (_showHeatmap)
                                            Opacity(
                                              opacity: _heatmapOpacity,
                                              child: FutureBuilder<ui.Image>(
                                                future: _createHeatmapImage(),
                                                builder: (context, snapshot) {
                                                  if (snapshot.hasData) {
                                                    return CustomPaint(
                                                      painter: HeatmapPainter(snapshot.data!),
                                                    );
                                                  }
                                                  return const SizedBox();
                                                },
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                if (_showHeatmap) ...[
                                  const SizedBox(height: 16),
                                  // Opacity slider
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.opacity,
                                        color: Colors.white70,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Slider(
                                          value: _heatmapOpacity,
                                          min: 0.0,
                                          max: 1.0,
                                          activeColor: Colors.white,
                                          inactiveColor: Colors.white30,
                                          onChanged: (value) {
                                            setState(() {
                                              _heatmapOpacity = value;
                                            });
                                          },
                                        ),
                                      ),
                                      Text(
                                        '${(_heatmapOpacity * 100).toInt()}%',
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  // Color legend
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      _buildLegendItem(Colors.blue, 'Low'),
                                      const SizedBox(width: 8),
                                      _buildLegendItem(Colors.green, 'Medium'),
                                      const SizedBox(width: 8),
                                      _buildLegendItem(Colors.yellow, 'High'),
                                      const SizedBox(width: 8),
                                      _buildLegendItem(Colors.red, 'Critical'),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          )
                              .animate()
                              .fadeIn(duration: 600.ms, delay: 300.ms)
                              .slideY(begin: 0.2, end: 0),

                        if (widget.result.heatmap != null && widget.originalImage != null)
                          const SizedBox(height: 24),

                        // Condition Card
                        GlassCard(
                          blur: 20,
                          opacity: 0.15,
                          child: Column(
                            children: [
                              // Risk Badge
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      riskColor.withValues(alpha: 0.8),
                                      riskColor.withValues(alpha: 0.6),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(25),
                                  boxShadow: [
                                    BoxShadow(
                                      color: riskColor.withValues(alpha: 0.5),
                                      blurRadius: 20,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: Text(
                                  '${widget.result.riskLevel} Risk',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              )
                                  .animate(onPlay: (controller) => controller.repeat())
                                  .shimmer(
                                    duration: 2000.ms,
                                    color: Colors.white.withValues(alpha: 0.3),
                                  ),

                              const SizedBox(height: 24),

                              // Condition Name
                              Text(
                                widget.result.label,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  height: 1.2,
                                ),
                              ),

                              const SizedBox(height: 30),

                              // Confidence Meter
                              Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'Confidence Level',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.white70,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      Text(
                                        '${(widget.result.confidence * 100).toStringAsFixed(1)}%',
                                        style: const TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(15),
                                    child: Container(
                                      height: 16,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                      child: Stack(
                                        children: [
                                          FractionallySizedBox(
                                            widthFactor: widget.result.confidence,
                                            child: Container(
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  colors: [
                                                    riskColor,
                                                    riskColor.withValues(alpha: 0.7),
                                                  ],
                                                ),
                                                borderRadius: BorderRadius.circular(15),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: riskColor.withValues(alpha: 0.5),
                                                    blurRadius: 10,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          )
                                              .animate()
                                              .scaleX(
                                                duration: 1000.ms,
                                                begin: 0,
                                                end: 1,
                                                curve: Curves.easeOutCubic,
                                                delay: 400.ms,
                                              ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 30),

                              // Performance Metrics
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  _buildMetric(
                                    icon: Icons.speed_rounded,
                                    label: 'Processing',
                                    value: '${widget.result.inferenceTimeMs}ms',
                                    color: Colors.blue,
                                  ),
                                  _buildMetric(
                                    icon: Icons.security_rounded,
                                    label: 'Privacy',
                                    value: '100%',
                                    color: Colors.green,
                                  ),
                                  _buildMetric(
                                    icon: Icons.offline_bolt_rounded,
                                    label: 'Offline',
                                    value: 'Yes',
                                    color: Colors.purple,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        )
                            .animate()
                            .fadeIn(duration: 600.ms, delay: 400.ms)
                            .slideY(begin: 0.2, end: 0),

                        const SizedBox(height: 24),

                        // Disclaimer
                        GlassCard(
                          blur: 15,
                          opacity: 0.1,
                          color: Colors.orange,
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline_rounded,
                                color: Colors.orangeAccent,
                                size: 28,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  'This is an AI-assisted analysis. Please consult a dermatologist for professional diagnosis.',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.9),
                                    fontSize: 13,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                            .animate()
                            .fadeIn(duration: 600.ms, delay: 600.ms),

                        const SizedBox(height: 24),

                        // Generate Report Button
                        if (widget.originalImage != null)
                          Container(
                            width: double.infinity,
                            height: 60,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              gradient: LinearGradient(
                                colors: [
                                  Colors.green.shade600.withValues(alpha: 0.9),
                                  Colors.teal.shade600.withValues(alpha: 0.8),
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.green.withValues(alpha: 0.3),
                                  blurRadius: 20,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: _isGeneratingPdf ? null : _generatePdfReport,
                                borderRadius: BorderRadius.circular(20),
                                child: Center(
                                  child: _isGeneratingPdf
                                      ? Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            SizedBox(
                                              width: 24,
                                              height: 24,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2.5,
                                                valueColor: AlwaysStoppedAnimation<Color>(
                                                  Colors.white,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            const Text(
                                              'Generating Report...',
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ],
                                        )
                                      : Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.picture_as_pdf_rounded,
                                              color: Colors.white,
                                              size: 28,
                                            ),
                                            const SizedBox(width: 12),
                                            const Text(
                                              'Generate PDF Report',
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ],
                                        ),
                                ),
                              ),
                            ),
                          )
                              .animate()
                              .fadeIn(duration: 600.ms, delay: 700.ms)
                              .slideY(begin: 0.3, end: 0),

                        if (widget.originalImage != null)
                          const SizedBox(height: 16),

                        // Action Button
                        Container(
                          width: double.infinity,
                          height: 60,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            gradient: LinearGradient(
                              colors: [
                                Colors.white.withValues(alpha: 0.9),
                                Colors.blue.shade100.withValues(alpha: 0.8),
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.white.withValues(alpha: 0.3),
                                blurRadius: 20,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => Navigator.pop(context),
                              borderRadius: BorderRadius.circular(20),
                              child: Center(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.camera_alt_rounded,
                                      color: Colors.blue.shade700,
                                      size: 28,
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      'Scan Again',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        )
                            .animate()
                            .fadeIn(duration: 600.ms, delay: 800.ms)
                            .slideY(begin: 0.3, end: 0),

                        // Multi-Region button
                        if (widget.originalImage != null)
                          Container(
                            width: double.infinity,
                            height: 60,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              gradient: LinearGradient(
                                colors: [
                                  Colors.purple.withValues(alpha: 0.7),
                                  Colors.blue.withValues(alpha: 0.6),
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.purple.withValues(alpha: 0.3),
                                  blurRadius: 20,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => MultiRegionScreen(
                                        originalImage: widget.originalImage!,
                                        imageWidth: 224,
                                        imageHeight: 224,
                                      ),
                                    ),
                                  );
                                },
                                borderRadius: BorderRadius.circular(20),
                                child: Center(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.grid_on_rounded,
                                        color: Colors.white,
                                        size: 28,
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        'Multi-Region Analysis',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          )
                              .animate()
                              .fadeIn(duration: 600.ms, delay: 1000.ms)
                              .slideY(begin: 0.3, end: 0),

                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetric({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color.withValues(alpha: 0.9), size: 28),
        ),
        const SizedBox(height: 12),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Future<ui.Image> _createHeatmapImage() async {
    final heatmap = widget.result.heatmap!;
    final completer = Completer<ui.Image>();

    ui.decodeImageFromPixels(
      heatmap.imageBytes,
      heatmap.width,
      heatmap.height,
      ui.PixelFormat.rgba8888,
      (image) => completer.complete(image),
    );

    return completer.future;
  }
}

class HeatmapPainter extends CustomPainter {
  final ui.Image image;

  HeatmapPainter(this.image);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..filterQuality = FilterQuality.high;
    
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      Rect.fromLTWH(0, 0, size.width, size.height),
      paint,
    );
  }

  @override
  bool shouldRepaint(HeatmapPainter oldDelegate) => false;
}
