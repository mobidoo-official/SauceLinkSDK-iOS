import Foundation
import UIKit

/// 디바이스 정보 유틸리티
/// user_agent 생성 등 디바이스 관련 정보 제공
enum DeviceInfo {
    
    /// User Agent 문자열
    /// 형식: iOS/{OS버전} ({디바이스모델}) {앱이름}/{앱버전}
    /// 예: iOS/17.1.1 (iPhone 15 Pro) MyApp/1.0.0
    static var userAgent: String {
        let osVersion = UIDevice.current.systemVersion
        let deviceModel = deviceModelName
        let appName = bundleName
        let appVersion = bundleVersion
        
        return "iOS/\(osVersion) (\(deviceModel)) \(appName)/\(appVersion)"
    }
    
    /// 디바이스 모델명
    /// 예: iPhone 15 Pro, iPad Pro (12.9-inch)
    static var deviceModelName: String {
        var systemInfo = utsname()
        uname(&systemInfo)
        
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        
        return mapToDeviceName(identifier: identifier)
    }
    
    /// 앱 번들 이름
    static var bundleName: String {
        return Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String
            ?? Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
            ?? "Unknown"
    }
    
    /// 앱 버전
    static var bundleVersion: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
        return "\(version).\(build)"
    }
    
    /// OS 버전
    static var osVersion: String {
        return UIDevice.current.systemVersion
    }
    
    /// 디바이스 식별자를 사람이 읽을 수 있는 이름으로 변환
    private static func mapToDeviceName(identifier: String) -> String {
        switch identifier {
        // iPhone
        case "iPhone14,4": return "iPhone 13 mini"
        case "iPhone14,5": return "iPhone 13"
        case "iPhone14,2": return "iPhone 13 Pro"
        case "iPhone14,3": return "iPhone 13 Pro Max"
        case "iPhone14,6": return "iPhone SE (3rd generation)"
        case "iPhone14,7": return "iPhone 14"
        case "iPhone14,8": return "iPhone 14 Plus"
        case "iPhone15,2": return "iPhone 14 Pro"
        case "iPhone15,3": return "iPhone 14 Pro Max"
        case "iPhone15,4": return "iPhone 15"
        case "iPhone15,5": return "iPhone 15 Plus"
        case "iPhone16,1": return "iPhone 15 Pro"
        case "iPhone16,2": return "iPhone 15 Pro Max"
        case "iPhone17,1": return "iPhone 16 Pro"
        case "iPhone17,2": return "iPhone 16 Pro Max"
        case "iPhone17,3": return "iPhone 16"
        case "iPhone17,4": return "iPhone 16 Plus"
            
        // iPad
        case "iPad13,1", "iPad13,2": return "iPad Air (4th generation)"
        case "iPad13,4", "iPad13,5", "iPad13,6", "iPad13,7": return "iPad Pro (11-inch) (3rd generation)"
        case "iPad13,8", "iPad13,9", "iPad13,10", "iPad13,11": return "iPad Pro (12.9-inch) (5th generation)"
        case "iPad13,16", "iPad13,17": return "iPad Air (5th generation)"
        case "iPad14,1", "iPad14,2": return "iPad mini (6th generation)"
        case "iPad14,3", "iPad14,4": return "iPad Pro (11-inch) (4th generation)"
        case "iPad14,5", "iPad14,6": return "iPad Pro (12.9-inch) (6th generation)"
            
        // Simulator
        case "i386", "x86_64", "arm64":
            return "Simulator"
            
        default:
            return identifier
        }
    }
}

