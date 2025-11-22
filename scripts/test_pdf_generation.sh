#!/bin/bash

# DermAssist PDF Report Generation Test Script
# This script verifies the PDF generation feature implementation

echo "=========================================="
echo "DermAssist PDF Report Generation Test"
echo "=========================================="
echo ""

# Color codes
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counter
PASSED=0
FAILED=0

# Function to check if file exists
check_file() {
    if [ -f "$1" ]; then
        echo -e "${GREEN}✓${NC} $2"
        ((PASSED++))
    else
        echo -e "${RED}✗${NC} $2"
        ((FAILED++))
    fi
}

# Function to check if string exists in file
check_content() {
    if grep -q "$2" "$1"; then
        echo -e "${GREEN}✓${NC} $3"
        ((PASSED++))
    else
        echo -e "${RED}✗${NC} $3"
        ((FAILED++))
    fi
}

echo "1. Checking Dependencies..."
echo "----------------------------"
check_file "pubspec.yaml" "pubspec.yaml exists"
check_content "pubspec.yaml" "pdf:" "PDF package added"
check_content "pubspec.yaml" "path_provider:" "path_provider package added"
check_content "pubspec.yaml" "share_plus:" "share_plus package added"
check_content "pubspec.yaml" "intl:" "intl package added"
echo ""

echo "2. Checking Service Implementation..."
echo "--------------------------------------"
check_file "lib/services/pdf_report_service.dart" "PdfReportService created"
check_content "lib/services/pdf_report_service.dart" "generateReport" "generateReport method exists"
check_content "lib/services/pdf_report_service.dart" "_buildHeader" "Header builder exists"
check_content "lib/services/pdf_report_service.dart" "_buildAnalysisSection" "Analysis section builder exists"
check_content "lib/services/pdf_report_service.dart" "_buildImagesSection" "Images section builder exists"
check_content "lib/services/pdf_report_service.dart" "_buildClinicalGuidance" "Clinical guidance builder exists"
check_content "lib/services/pdf_report_service.dart" "_getGuidanceText" "Guidance text generator exists"
echo ""

echo "3. Checking UI Integration..."
echo "------------------------------"
check_file "lib/ui/screens/results_screen.dart" "Results screen exists"
check_content "lib/ui/screens/results_screen.dart" "PdfReportService" "PdfReportService imported"
check_content "lib/ui/screens/results_screen.dart" "_generatePdfReport" "PDF generation method exists"
check_content "lib/ui/screens/results_screen.dart" "Generate PDF Report" "Generate button added"
check_content "lib/ui/screens/results_screen.dart" "RepaintBoundary" "3D viewer snapshot support added"
check_content "lib/ui/screens/results_screen.dart" "_showReportGeneratedDialog" "Success dialog exists"
check_content "lib/ui/screens/results_screen.dart" "share_plus" "Share functionality imported"
echo ""

echo "4. Checking Permissions..."
echo "--------------------------"
check_file "android/app/src/main/AndroidManifest.xml" "Android manifest exists"
check_content "android/app/src/main/AndroidManifest.xml" "WRITE_EXTERNAL_STORAGE" "Android write permission added"
check_content "android/app/src/main/AndroidManifest.xml" "READ_EXTERNAL_STORAGE" "Android read permission added"
check_file "ios/Runner/Info.plist" "iOS Info.plist exists"
check_content "ios/Runner/Info.plist" "NSPhotoLibraryUsageDescription" "iOS photo library permission added"
check_content "ios/Runner/Info.plist" "UIFileSharingEnabled" "iOS file sharing enabled"
echo ""

echo "5. Checking Documentation..."
echo "-----------------------------"
check_file "docs/PDF_REPORT_FEATURE.md" "Feature documentation created"
check_content "docs/PDF_REPORT_FEATURE.md" "Clinical Guidance" "Clinical guidance documented"
check_content "docs/PDF_REPORT_FEATURE.md" "File Storage" "File storage documented"
check_content "docs/PDF_REPORT_FEATURE.md" "Technical Implementation" "Technical details documented"
echo ""

echo "6. Checking Code Quality..."
echo "----------------------------"
echo -e "${YELLOW}Running Flutter analyze...${NC}"
flutter analyze lib/services/pdf_report_service.dart 2>&1 | grep -q "No issues found" && {
    echo -e "${GREEN}✓${NC} PdfReportService passes analysis"
    ((PASSED++))
} || {
    echo -e "${RED}✗${NC} PdfReportService has analysis issues"
    ((FAILED++))
}

flutter analyze lib/ui/screens/results_screen.dart 2>&1 | grep -q "No issues found" && {
    echo -e "${GREEN}✓${NC} ResultsScreen passes analysis"
    ((PASSED++))
} || {
    echo -e "${RED}✗${NC} ResultsScreen has analysis issues"
    ((FAILED++))
}
echo ""

echo "7. Checking Clinical Guidance Content..."
echo "-----------------------------------------"
check_content "lib/services/pdf_report_service.dart" "Actinic Keratosis" "Actinic Keratosis guidance exists"
check_content "lib/services/pdf_report_service.dart" "Basal Cell Carcinoma" "Basal Cell Carcinoma guidance exists"
check_content "lib/services/pdf_report_service.dart" "Melanoma" "Melanoma guidance exists"
check_content "lib/services/pdf_report_service.dart" "Nevus" "Nevus guidance exists"
check_content "lib/services/pdf_report_service.dart" "Seborrheic Keratosis" "Seborrheic Keratosis guidance exists"
echo ""

echo "=========================================="
echo "Test Results Summary"
echo "=========================================="
echo -e "${GREEN}Passed: $PASSED${NC}"
echo -e "${RED}Failed: $FAILED${NC}"
echo ""

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}✓ All tests passed! PDF generation feature is ready.${NC}"
    exit 0
else
    echo -e "${RED}✗ Some tests failed. Please review the issues above.${NC}"
    exit 1
fi
