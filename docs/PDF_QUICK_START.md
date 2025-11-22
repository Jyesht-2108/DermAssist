# PDF Report Generation - Quick Start Guide

## For Users

### How to Generate a Report

1. **Capture and Analyze** a skin image using the camera
2. **View Results** on the Results Screen
3. **Tap "Generate PDF Report"** button (green button with PDF icon)
4. **Wait** for generation (typically 1-2 seconds)
5. **Success!** Dialog appears with file location
6. **Share** the report using the Share button, or find it later in:
   - **Android**: `Documents/DermAssist/` folder
   - **iOS**: Files app → DermAssist folder

### Report Contents

Your PDF report includes:
- ✅ Original captured image
- ✅ AI-generated attention heatmap
- ✅ 3D visualization snapshot
- ✅ Detected condition and risk level
- ✅ Confidence percentage
- ✅ Professional clinical guidance
- ✅ Medical disclaimer
- ✅ Timestamp and report ID

### File Format

- **Name**: `DermAssist_Report_YYYYMMDD_HHmmss.pdf`
- **Size**: ~200-500 KB
- **Compatible**: All PDF readers
- **Privacy**: 100% offline, stored locally only

## For Developers

### Quick Integration Test

```bash
# Run the test script
./scripts/test_pdf_generation.sh

# Or manually test
flutter pub get
flutter analyze lib/services/pdf_report_service.dart
flutter run
```

### Key Files

```
lib/services/pdf_report_service.dart    # PDF generation service
lib/ui/screens/results_screen.dart      # UI integration
docs/PDF_REPORT_FEATURE.md              # Full documentation
scripts/test_pdf_generation.sh          # Test script
```

### Usage in Code

```dart
import 'package:derm_assist/services/pdf_report_service.dart';

// Generate report
final pdfFile = await PdfReportService.generateReport(
  result: inferenceResult,
  originalImage: imageBytes,
  heatmapImage: heatmapBytes,
  snapshot3D: snapshot3DBytes,
);

print('PDF saved to: ${pdfFile.path}');
```

### Customization Points

Want to customize the report? Edit these methods in `pdf_report_service.dart`:

- `_buildHeader()` - Change branding/logo
- `_buildAnalysisSection()` - Modify results layout
- `_buildClinicalGuidance()` - Update medical guidance
- `_getGuidanceText()` - Add/edit condition-specific advice
- `_buildFooter()` - Customize disclaimer

### Testing Checklist

- [ ] Generate report from Results Screen
- [ ] Verify PDF opens correctly
- [ ] Check all images are embedded
- [ ] Confirm text is readable
- [ ] Test share functionality
- [ ] Verify file location
- [ ] Test on Android device
- [ ] Test on iOS device

## Troubleshooting

### "Failed to generate report"
- Check storage permissions
- Ensure image data is available
- Check device storage space

### "Cannot find PDF file"
- Android: Check `Documents/DermAssist/` in file manager
- iOS: Check Files app → On My iPhone/iPad → DermAssist

### Share not working
- Ensure share_plus package is installed
- Check app has necessary permissions
- Try opening PDF directly from file manager

## Performance

- **Generation Time**: 1-2 seconds
- **File Size**: 200-500 KB
- **Memory Usage**: Minimal (~10-20 MB during generation)
- **Battery Impact**: Negligible

## Privacy & Security

- ✅ 100% offline processing
- ✅ No data transmission
- ✅ Local storage only
- ✅ User controls sharing
- ✅ No cloud backup (unless user chooses)
- ✅ HIPAA-friendly architecture

## Support

For issues or questions:
1. Check `docs/PDF_REPORT_FEATURE.md` for detailed documentation
2. Run `./scripts/test_pdf_generation.sh` to verify setup
3. Check Flutter logs: `flutter logs`
4. Review permissions in AndroidManifest.xml / Info.plist
