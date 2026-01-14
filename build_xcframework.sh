#!/bin/bash

# SauceLinkSDK XCFramework 빌드 스크립트
# 사용법: ./build_xcframework.sh

set -e

FRAMEWORK_NAME="SauceLinkSDK"
PROJECT="SauceLinkSDK.xcodeproj"
BUILD_DIR="./build"
OUTPUT_DIR="./output"
VERSION="1.0.0"

# 색상
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}SauceLinkSDK XCFramework Builder${NC}"
echo -e "${GREEN}========================================${NC}"

# 정리
echo -e "\n${YELLOW}[1/5] Cleaning...${NC}"
rm -rf "${BUILD_DIR}" "${OUTPUT_DIR}"
mkdir -p "${BUILD_DIR}" "${OUTPUT_DIR}"

# iOS Device 아카이브
echo -e "\n${YELLOW}[2/5] Archiving for iOS Device...${NC}"
xcodebuild archive \
    -project "${PROJECT}" \
    -scheme "${FRAMEWORK_NAME}" \
    -destination "generic/platform=iOS" \
    -archivePath "${BUILD_DIR}/ios-device" \
    SKIP_INSTALL=NO \
    BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
    | grep -E "^\*\*|error:" || true

# iOS Simulator 아카이브
echo -e "\n${YELLOW}[3/5] Archiving for iOS Simulator...${NC}"
xcodebuild archive \
    -project "${PROJECT}" \
    -scheme "${FRAMEWORK_NAME}" \
    -destination "generic/platform=iOS Simulator" \
    -archivePath "${BUILD_DIR}/ios-simulator" \
    SKIP_INSTALL=NO \
    BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
    | grep -E "^\*\*|error:" || true

# XCFramework 생성
echo -e "\n${YELLOW}[4/5] Creating XCFramework...${NC}"
xcodebuild -create-xcframework \
    -framework "${BUILD_DIR}/ios-device.xcarchive/Products/Library/Frameworks/${FRAMEWORK_NAME}.framework" \
    -framework "${BUILD_DIR}/ios-simulator.xcarchive/Products/Library/Frameworks/${FRAMEWORK_NAME}.framework" \
    -output "${OUTPUT_DIR}/${FRAMEWORK_NAME}.xcframework"

# Zip & Checksum
echo -e "\n${YELLOW}[5/5] Creating zip & checksum...${NC}"
cd "${OUTPUT_DIR}"
zip -r "${FRAMEWORK_NAME}-${VERSION}.zip" "${FRAMEWORK_NAME}.xcframework"
cd ..

CHECKSUM=$(swift package compute-checksum "${OUTPUT_DIR}/${FRAMEWORK_NAME}-${VERSION}.zip")

# 결과
echo -e "\n${GREEN}========================================${NC}"
echo -e "${GREEN}✅ 빌드 완료!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "📦 파일: ${OUTPUT_DIR}/${FRAMEWORK_NAME}-${VERSION}.zip"
echo "🔑 Checksum: ${CHECKSUM}"
echo ""
echo -e "${YELLOW}▶ S3 업로드:${NC}"
echo "aws s3 cp ${OUTPUT_DIR}/${FRAMEWORK_NAME}-${VERSION}.zip s3://sdk.saucelink.im/iOS/${FRAMEWORK_NAME}-${VERSION}.zip --acl public-read"
echo ""
echo -e "${YELLOW}▶ Package.swift:${NC}"
echo ".binaryTarget("
echo "    name: \"${FRAMEWORK_NAME}\","
echo "    url: \"https://sdk.saucelink.im/iOS/${FRAMEWORK_NAME}-${VERSION}.zip\","
echo "    checksum: \"${CHECKSUM}\""
echo ")"

# 정리
rm -rf "${BUILD_DIR}"
echo -e "\n${GREEN}Done!${NC}"
