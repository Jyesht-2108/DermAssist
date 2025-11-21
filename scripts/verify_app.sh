#!/bin/bash

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║                                                              ║"
echo "║         DermAssist - App Verification Script                ║"
echo "║                                                              ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

ERRORS=0

# Function to check status
check_status() {
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓${NC} $1"
    else
        echo -e "${RED}✗${NC} $1"
        ERRORS=$((ERRORS + 1))
    fi
}

echo "═══════════════════════════════════════════════════════════════"
echo "1. Checking Flutter Installation"
echo "═══════════════════════════════════════════════════════════════"
flutter --version > /dev/null 2>&1
check_status "Flutter is installed"

echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "2. Checking Project Files"
echo "═══════════════════════════════════════════════════════════════"

# Check critical files
[ -f "pubspec.yaml" ]
check_status "pubspec.yaml exists"

[ -f "lib/main.dart" ]
check_status "lib/main.dart exists"

[ -f "assets/models/skin_model.tflite" ]
check_status "Model file exists (skin_model.tflite)"

[ -f "assets/models/labels.txt" ]
check_status "Labels file exists"

# Check model size
MODEL_SIZE=$(stat -f%z "assets/models/skin_model.tflite" 2>/dev/null || stat -c%s "assets/models/skin_model.tflite" 2>/dev/null)
if [ "$MODEL_SIZE" -gt 3000000 ]; then
    echo -e "${GREEN}✓${NC} Model size is correct ($(($MODEL_SIZE / 1024 / 1024)) MB)"
else
    echo -e "${RED}✗${NC} Model size is too small"
    ERRORS=$((ERRORS + 1))
fi

echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "3. Checking Dependencies"
echo "═══════════════════════════════════════════════════════════════"
flutter pub get > /dev/null 2>&1
check_status "Dependencies installed"

echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "4. Running Code Analysis"
echo "═══════════════════════════════════════════════════════════════"
flutter analyze --no-fatal-infos > /dev/null 2>&1
check_status "Code analysis passed (0 issues)"

echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "5. Running Tests"
echo "═══════════════════════════════════════════════════════════════"
flutter test test/inference_test.dart test/integration_test.dart > /dev/null 2>&1
check_status "All tests passed"

echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "6. Checking Build Configuration"
echo "═══════════════════════════════════════════════════════════════"

# Check Android permissions
grep -q "android.permission.CAMERA" android/app/src/main/AndroidManifest.xml
check_status "Camera permission configured (Android)"

# Check iOS permissions
grep -q "NSCameraUsageDescription" ios/Runner/Info.plist
check_status "Camera permission configured (iOS)"

# Check TFLite configuration
grep -q "noCompress" android/app/build.gradle.kts
check_status "TFLite configuration present"

echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "7. Verifying Core Files"
echo "═══════════════════════════════════════════════════════════════"

CORE_FILES=(
    "lib/ml/inference_service.dart"
    "lib/ml/model_labels.dart"
    "lib/services/camera_service.dart"
    "lib/services/preprocessing_service.dart"
    "lib/state/app_state.dart"
    "lib/core/utils/image_utils.dart"
    "lib/core/constants/app_constants.dart"
    "lib/ui/screens/splash_screen.dart"
    "lib/ui/screens/home_screen.dart"
    "lib/ui/screens/camera_screen.dart"
    "lib/ui/screens/results_screen.dart"
)

for file in "${CORE_FILES[@]}"; do
    [ -f "$file" ]
    check_status "$(basename $file)"
done

echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "8. Build Test"
echo "═══════════════════════════════════════════════════════════════"
echo -e "${YELLOW}Building debug APK...${NC}"
flutter build apk --debug --target-platform android-arm64 > /dev/null 2>&1
check_status "Debug APK builds successfully"

echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "VERIFICATION SUMMARY"
echo "═══════════════════════════════════════════════════════════════"

if [ $ERRORS -eq 0 ]; then
    echo -e "${GREEN}"
    echo "✓ ALL CHECKS PASSED!"
    echo ""
    echo "The app is ready to run:"
    echo "  $ flutter run"
    echo -e "${NC}"
    exit 0
else
    echo -e "${RED}"
    echo "✗ $ERRORS CHECK(S) FAILED"
    echo ""
    echo "Please fix the issues above before running the app."
    echo -e "${NC}"
    exit 1
fi
