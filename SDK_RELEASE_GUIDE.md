# SauceLinkSDK 배포 가이드

SDK 코드 변경 후 SPM/CocoaPods 배포 작업 가이드

---

## 1. XCFramework 빌드

```bash
cd /Users/keaton/Documents/Mobidoo/saucelink-tracking-ios-sdk
./build_xcframework.sh
```

빌드 완료 시 출력 확인:
```
📦 파일: ./output/SauceLinkSDK-1.0.0.zip
🔑 Checksum: [새로운 체크섬 값]

▶ Package.swift:
.binaryTarget(
    name: "SauceLinkSDK",
    url: "https://sdk.saucelink.im/iOS/SauceLinkSDK-1.0.0.zip",
    checksum: "[새로운 체크섬 값]"
)
```

---

## 2. S3 업로드

```bash
aws s3 cp ./output/SauceLinkSDK-1.0.0.zip s3://sdk.saucelink.im/iOS/SauceLinkSDK-1.0.0.zip --acl public-read
```

### 버전 업데이트 시
```bash
aws s3 cp ./output/SauceLinkSDK-1.0.1.zip s3://sdk.saucelink.im/iOS/SauceLinkSDK-1.0.1.zip --acl public-read
```

### CDN 캐시 무효화 (필요시)
CloudFront 캐시 때문에 이전 파일이 제공될 수 있음. 필요시 캐시 무효화 실행:

```bash
aws cloudfront create-invalidation --distribution-id [DISTRIBUTION_ID] --paths "/iOS/*"
```

> Distribution ID는 AWS CloudFront 콘솔에서 확인

---

## 3. Package.swift 수정 (SPM)

`Package.swift` 파일에서 checksum 업데이트:

```swift
.binaryTarget(
    name: "SauceLinkSDK",
    url: "https://sdk.saucelink.im/iOS/SauceLinkSDK-1.0.0.zip",
    checksum: "[새로운 체크섬 값]"  // ← 여기 수정
)
```

### 버전 업데이트 시
```swift
.binaryTarget(
    name: "SauceLinkSDK",
    url: "https://sdk.saucelink.im/iOS/SauceLinkSDK-1.0.1.zip",  // ← URL도 수정
    checksum: "[새로운 체크섬 값]"
)
```

---

## 4. SauceLinkSDK.podspec 수정 (CocoaPods)

### 버전 업데이트 시에만 수정 필요

```ruby
s.version = '1.0.1'  # ← 버전 수정
s.source  = { :http => 'https://sdk.saucelink.im/iOS/SauceLinkSDK-1.0.1.zip' }  # ← URL 수정
```

> 같은 버전으로 덮어씌울 경우 podspec 수정 불필요 (단, 사용자는 pod cache clean 필요할 수 있음)

---

## 5. GitHub 푸시

```bash
git add Package.swift SauceLinkSDK.podspec
git commit -m "Release v1.0.1"
git push origin main
```

### 태그 추가 (권장)
```bash
git tag 1.0.1
git push origin 1.0.1
```

---

## 6. CocoaPods Trunk 배포

### 최초 등록 시
```bash
pod trunk register your@email.com 'Your Name' --description='macbook'
```

### Trunk에 배포
```bash
pod trunk push SauceLinkSDK.podspec --allow-warnings
```

### 배포 확인
```bash
pod trunk info SauceLinkSDK
```

> 배포 후 반영까지 몇 분 소요될 수 있음

---

## 7. 배포 확인

### SPM 확인
```bash
# S3 파일 체크섬 확인
curl -sL "https://sdk.saucelink.im/iOS/SauceLinkSDK-1.0.0.zip" -o /tmp/test.zip
swift package compute-checksum /tmp/test.zip
```

### CocoaPods 확인
```bash
pod spec lint SauceLinkSDK.podspec --allow-warnings
```

---

## 요약 체크리스트

| 단계 | 작업 | 필수 |
|------|------|------|
| 1 | `./build_xcframework.sh` 실행 | ✅ |
| 2 | S3 업로드 | ✅ |
| 3 | `Package.swift` checksum 수정 | ✅ |
| 4 | `SauceLinkSDK.podspec` 수정 | 버전 변경시만 |
| 5 | GitHub 푸시 | ✅ |
| 6 | `pod trunk push` 실행 | 버전 변경시만 |
| 7 | (선택) Git 태그 추가 | 권장 |

---

## 사용자 설치 방법

### SPM
```
https://github.com/mobidoo-official/SauceLinkSDK-iOS.git
```

### CocoaPods

```ruby
# Podfile
pod 'SauceLinkSDK'
```

```bash
pod install
```

> 최신 버전이 안 보일 경우:
> ```bash
> pod repo update
> pod cache clean 'SauceLinkSDK' --all
> pod install
> ```

### 직접 다운로드
```
https://sdk.saucelink.im/iOS/SauceLinkSDK-1.0.0.zip
```
