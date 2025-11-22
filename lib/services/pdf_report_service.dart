import 'dart:io';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import '../ml/inference_service.dart';

class PdfReportService {
  /// Generate a professional clinic-style PDF report
  static Future<File> generateReport({
    required InferenceResult result,
    required Uint8List originalImage,
    Uint8List? heatmapImage,
    Uint8List? snapshot3D,
  }) async {
    final pdf = pw.Document();
    final timestamp = DateTime.now();
    final dateFormat = DateFormat('MMMM dd, yyyy');
    final timeFormat = DateFormat('hh:mm a');

    // Add pages to the PDF
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => [
          // Header
          _buildHeader(timestamp, dateFormat, timeFormat),
          pw.SizedBox(height: 30),

          // Patient Information Section
          _buildPatientSection(timestamp),
          pw.SizedBox(height: 25),

          // Analysis Results Section
          _buildAnalysisSection(result),
          pw.SizedBox(height: 25),

          // Images Section
          _buildImagesSection(originalImage, heatmapImage, snapshot3D),
          pw.SizedBox(height: 25),

          // Clinical Guidance Section
          _buildClinicalGuidance(result),
          pw.SizedBox(height: 25),

          // Technical Details
          _buildTechnicalDetails(result),
          pw.SizedBox(height: 30),

          // Footer & Disclaimer
          _buildFooter(),
        ],
      ),
    );

    // Save the PDF
    final output = await _getOutputDirectory();
    final fileName = 'DermAssist_Report_${DateFormat('yyyyMMdd_HHmmss').format(timestamp)}.pdf';
    final file = File('${output.path}/$fileName');
    await file.writeAsBytes(await pdf.save());

    return file;
  }

  static pw.Widget _buildHeader(DateTime timestamp, DateFormat dateFormat, DateFormat timeFormat) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'DermAssist',
                  style: pw.TextStyle(
                    fontSize: 32,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue800,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'AI-Powered Skin Analysis Report',
                  style: pw.TextStyle(
                    fontSize: 14,
                    color: PdfColors.grey700,
                  ),
                ),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(
                  dateFormat.format(timestamp),
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(
                  timeFormat.format(timestamp),
                  style: const pw.TextStyle(
                    fontSize: 11,
                    color: PdfColors.grey700,
                  ),
                ),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 15),
        pw.Divider(thickness: 2, color: PdfColors.blue800),
      ],
    );
  }

  static pw.Widget _buildPatientSection(DateTime timestamp) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'SCAN INFORMATION',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue800,
              letterSpacing: 1.2,
            ),
          ),
          pw.SizedBox(height: 12),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              _buildInfoItem('Report ID', 'DA-${timestamp.millisecondsSinceEpoch}'),
              _buildInfoItem('Analysis Type', 'Single Region Scan'),
              _buildInfoItem('Device', 'Mobile (Offline)'),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildInfoItem(String label, String value) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: 9,
            color: PdfColors.grey600,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 3),
        pw.Text(
          value,
          style: const pw.TextStyle(
            fontSize: 11,
            color: PdfColors.black,
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildAnalysisSection(InferenceResult result) {
    final riskColor = _getRiskPdfColor(result.riskLevel);
    
    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: riskColor, width: 2),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'DETECTED CONDITION',
                      style: pw.TextStyle(
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.grey700,
                        letterSpacing: 1.0,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      result.label,
                      style: pw.TextStyle(
                        fontSize: 22,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.black,
                      ),
                    ),
                  ],
                ),
              ),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: pw.BoxDecoration(
                  color: riskColor,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(20)),
                ),
                child: pw.Text(
                  '${result.riskLevel.toUpperCase()} RISK',
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                  ),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 20),
          pw.Divider(color: PdfColors.grey300),
          pw.SizedBox(height: 15),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
            children: [
              _buildMetricBox(
                'Confidence',
                '${(result.confidence * 100).toStringAsFixed(1)}%',
                PdfColors.blue700,
              ),
              _buildMetricBox(
                'Processing Time',
                '${result.inferenceTimeMs}ms',
                PdfColors.green700,
              ),
              _buildMetricBox(
                'Privacy',
                '100% Offline',
                PdfColors.purple700,
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildMetricBox(String label, String value, PdfColor color) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: color.shade(0.1),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: color,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 9,
              color: PdfColors.grey700,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildImagesSection(
    Uint8List originalImage,
    Uint8List? heatmapImage,
    Uint8List? snapshot3D,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'VISUAL ANALYSIS',
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.blue800,
            letterSpacing: 1.2,
          ),
        ),
        pw.SizedBox(height: 15),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Original Image
            pw.Expanded(
              child: pw.Column(
                children: [
                  pw.Container(
                    height: 180,
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.grey400),
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                    ),
                    child: pw.ClipRRect(
                      horizontalRadius: 8,
                      verticalRadius: 8,
                      child: pw.Image(
                        pw.MemoryImage(originalImage),
                        fit: pw.BoxFit.cover,
                      ),
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    'Original Capture',
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.grey700,
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(width: 15),
            // Heatmap Image
            if (heatmapImage != null)
              pw.Expanded(
                child: pw.Column(
                  children: [
                    pw.Container(
                      height: 180,
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: PdfColors.grey400),
                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                      ),
                      child: pw.ClipRRect(
                        horizontalRadius: 8,
                        verticalRadius: 8,
                        child: pw.Image(
                          pw.MemoryImage(heatmapImage),
                          fit: pw.BoxFit.cover,
                        ),
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      'Attention Heatmap',
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.grey700,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        if (snapshot3D != null) ...[
          pw.SizedBox(height: 15),
          pw.Center(
            child: pw.Column(
              children: [
                pw.Container(
                  width: 200,
                  height: 200,
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey400),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                  ),
                  child: pw.ClipRRect(
                    horizontalRadius: 8,
                    verticalRadius: 8,
                    child: pw.Image(
                      pw.MemoryImage(snapshot3D),
                      fit: pw.BoxFit.contain,
                    ),
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  '3D Visualization Snapshot',
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.grey700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  static pw.Widget _buildClinicalGuidance(InferenceResult result) {
    final guidance = _getGuidanceText(result.label, result.riskLevel);
    
    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue50,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
        border: pw.Border.all(color: PdfColors.blue200),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  color: PdfColors.blue700,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                ),
                child: pw.Icon(
                  pw.IconData(0xe88e), // medical icon
                  color: PdfColors.white,
                  size: 20,
                ),
              ),
              pw.SizedBox(width: 12),
              pw.Text(
                'CLINICAL GUIDANCE',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue800,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 15),
          pw.Text(
            guidance,
            style: const pw.TextStyle(
              fontSize: 11,
              height: 1.6,
              color: PdfColors.black,
            ),
            textAlign: pw.TextAlign.justify,
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildTechnicalDetails(InferenceResult result) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey50,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'TECHNICAL DETAILS',
            style: pw.TextStyle(
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey800,
              letterSpacing: 1.0,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              _buildTechDetail('Model', 'TensorFlow Lite'),
              _buildTechDetail('Input Size', '224x224 RGB'),
              _buildTechDetail('Inference', 'On-Device'),
              _buildTechDetail('Precision', 'Float32'),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildTechDetail(String label, String value) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: 8,
            color: PdfColors.grey600,
          ),
        ),
        pw.SizedBox(height: 2),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 9,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.black,
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildFooter() {
    return pw.Column(
      children: [
        pw.Divider(thickness: 1, color: PdfColors.grey400),
        pw.SizedBox(height: 15),
        pw.Container(
          padding: const pw.EdgeInsets.all(15),
          decoration: pw.BoxDecoration(
            color: PdfColors.orange50,
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
            border: pw.Border.all(color: PdfColors.orange300),
          ),
          child: pw.Row(
            children: [
              pw.Icon(
                pw.IconData(0xe88f), // warning icon
                color: PdfColors.orange700,
                size: 24,
              ),
              pw.SizedBox(width: 12),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'IMPORTANT DISCLAIMER',
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.orange900,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'This report is generated by an AI-assisted analysis tool and is NOT a medical diagnosis. '
                      'It should be used for informational purposes only. Please consult a qualified dermatologist '
                      'or healthcare professional for proper diagnosis and treatment recommendations.',
                      style: const pw.TextStyle(
                        fontSize: 9,
                        height: 1.4,
                        color: PdfColors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 15),
        pw.Text(
          'Generated by DermAssist • AI-Powered Skin Analysis • 100% Offline & Private',
          style: pw.TextStyle(
            fontSize: 8,
            color: PdfColors.grey600,
          ),
          textAlign: pw.TextAlign.center,
        ),
      ],
    );
  }

  static PdfColor _getRiskPdfColor(String riskLevel) {
    switch (riskLevel.toLowerCase()) {
      case 'high':
        return PdfColors.red700;
      case 'medium':
        return PdfColors.orange700;
      case 'low':
        return PdfColors.green700;
      default:
        return PdfColors.blue700;
    }
  }

  static String _getGuidanceText(String condition, String riskLevel) {
    // Provide condition-specific guidance
    final baseGuidance = {
      'Actinic Keratosis': 'Actinic keratosis is a precancerous skin condition caused by sun damage. '
          'It is important to have this evaluated by a dermatologist. Treatment options include cryotherapy, '
          'topical medications, or photodynamic therapy. Regular monitoring is essential.',
      
      'Basal Cell Carcinoma': 'Basal cell carcinoma is the most common form of skin cancer. '
          'While it rarely spreads, early treatment is important. Please schedule an appointment with a '
          'dermatologist promptly. Treatment typically involves surgical removal or other targeted therapies.',
      
      'Melanoma': 'Melanoma is a serious form of skin cancer that requires immediate medical attention. '
          'Please consult a dermatologist as soon as possible for proper evaluation and biopsy. '
          'Early detection and treatment are critical for the best outcomes.',
      
      'Nevus': 'A nevus (mole) is typically benign, but monitoring for changes is important. '
          'Follow the ABCDE rule: Asymmetry, Border irregularity, Color variation, Diameter >6mm, and Evolution. '
          'Schedule regular skin checks with a dermatologist, especially if you have many moles.',
      
      'Seborrheic Keratosis': 'Seborrheic keratosis is a benign skin growth that does not require treatment '
          'unless it becomes irritated or for cosmetic reasons. However, it\'s important to have it examined '
          'by a dermatologist to confirm the diagnosis and rule out other conditions.',
    };

    final guidance = baseGuidance[condition] ?? 
        'This condition has been detected by our AI analysis. Please consult with a qualified dermatologist '
        'for proper evaluation, diagnosis, and treatment recommendations. Regular skin examinations are '
        'important for maintaining skin health.';

    final riskAddendum = riskLevel.toLowerCase() == 'high'
        ? '\n\nIMPORTANT: This analysis indicates a higher risk level. We strongly recommend scheduling '
          'an appointment with a dermatologist as soon as possible for professional evaluation.'
        : riskLevel.toLowerCase() == 'medium'
        ? '\n\nRECOMMENDATION: Schedule an appointment with a dermatologist within the next few weeks '
          'for professional evaluation and guidance.'
        : '\n\nRECOMMENDATION: While this appears to be lower risk, regular monitoring and periodic '
          'dermatologist check-ups are still advisable.';

    return guidance + riskAddendum;
  }

  static Future<Directory> _getOutputDirectory() async {
    if (Platform.isAndroid) {
      // Use external storage for Android
      final directory = await getExternalStorageDirectory();
      final basePath = directory!.path.split('Android')[0];
      final documentsPath = '${basePath}Documents/DermAssist';
      final dir = Directory(documentsPath);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      return dir;
    } else if (Platform.isIOS) {
      // Use documents directory for iOS
      final directory = await getApplicationDocumentsDirectory();
      final dirPath = '${directory.path}/DermAssist';
      final dir = Directory(dirPath);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      return dir;
    } else {
      // Fallback to documents directory
      return await getApplicationDocumentsDirectory();
    }
  }
}
