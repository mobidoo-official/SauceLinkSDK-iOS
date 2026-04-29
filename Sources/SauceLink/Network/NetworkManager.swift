import Foundation

/// 네트워크 에러 타입
enum NetworkError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(statusCode: Int, code: String?, message: String?)
    case decodingError
    case networkError(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response"
        case .httpError(let statusCode, let code, let message):
            return "HTTP \(statusCode): \(code ?? "") - \(message ?? "")"
        case .decodingError:
            return "Decoding error"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}

/// 토큰 인증 요청 바디
private struct TokenValidationRequest: Encodable {
    let sauceLinkSdkToken: String
    let partnerUniqueId: String
}

/// 토큰 인증 응답
private struct TokenValidationResponse: Decodable {
    let code: String
    let data: TokenValidationData?

    struct TokenValidationData: Decodable {
        let sauceLinkCookieRetentionHours: Int?
    }
}

/// 에러 응답
private struct ErrorResponse: Decodable {
    let message: String?
    let status: Int?
    let errors: [String]?
    let code: String?
}

/// 네트워크 매니저
/// 토큰 인증 및 트래킹 데이터 전송 담당
final class NetworkManager {
    
    // MARK: - Private Properties
    
    private let session: URLSession
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    
    // MARK: - Initialization
    
    init(session: URLSession = .shared) {
        self.session = session
        
        self.encoder = JSONEncoder()
        self.encoder.outputFormatting = .sortedKeys
        
        self.decoder = JSONDecoder()
        self.decoder.keyDecodingStrategy = .convertFromSnakeCase
    }
    
    // MARK: - Token Validation
    
    /// 토큰 인증 API 호출
    /// - Parameters:
    ///   - token: SDK 토큰 (sla_xxx 형식)
    ///   - partnerUniqueId: 파트너 고유 ID
    ///   - environment: 환경 설정
    ///   - completion: 완료 콜백
    func validateToken(
        token: String,
        partnerUniqueId: String,
        environment: Environment,
        completion: @escaping (Result<TimeInterval, NetworkError>) -> Void
    ) {
        let endpoint = APIEndpoints.tokenValidation(token: token, partnerUniqueId: partnerUniqueId)
        
        guard let url = endpoint.url(for: environment) else {
            Logger.error("Invalid token validation URL")
            completion(.failure(.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 30

        // POST body
        let requestBody = TokenValidationRequest(sauceLinkSdkToken: token, partnerUniqueId: partnerUniqueId)
        do {
            request.httpBody = try encoder.encode(requestBody)
        } catch {
            Logger.error("Failed to encode token validation request body")
            completion(.failure(.decodingError))
            return
        }

        Logger.info("🌐 토큰 인증 요청")
        Logger.info("   URL: \(url.absoluteString)")
        Logger.info("   Partner ID: \(partnerUniqueId)")
        Logger.info("   Token: \(token)")
        
        let task = session.dataTask(with: request) { [weak self] data, response, error in
            // 네트워크 에러 처리
            if let error = error {
                Logger.error("Token validation network error: \(error.localizedDescription)")
                completion(.failure(.networkError(error)))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                Logger.error("Invalid response type")
                completion(.failure(.invalidResponse))
                return
            }
            
            // HTTP 상태 코드 확인
            Logger.info("📥 토큰 인증 응답: HTTP \(httpResponse.statusCode)")
            
            switch httpResponse.statusCode {
            case 200:
                // 성공
                var retentionInterval: TimeInterval = 7 * 24 * 60 * 60
                if let data = data {
                    if let responseString = String(data: data, encoding: .utf8) {
                        Logger.info("   응답 내용: \(responseString)")
                    }
                    if let response = try? self?.decoder.decode(TokenValidationResponse.self, from: data) {
                        if let hours = response.data?.sauceLinkCookieRetentionHours, hours > 0 {
                            retentionInterval = TimeInterval(hours) * 3600
                            Logger.info("   sauceLinkCookieRetentionHours: \(hours) → retentionInterval: \(Int(retentionInterval))s")
                        } else {
                            Logger.warning("   sauceLinkCookieRetentionHours 필드 없음 → 기본값 7일 적용")
                        }
                    }
                }
                Logger.info("✅ 토큰 인증 성공 (retentionInterval: \(retentionInterval)s)")
                completion(.success(retentionInterval))
                
            case 401:
                Logger.error("❌ 토큰 인증 실패 (401)")
                self?.handleErrorResponse(data: data, statusCode: 401, completion: completion)

            case 403:
                // 소스링크 서비스 미사용 파트너 (SLS003)
                Logger.error("❌ 소스링크 서비스 미사용 파트너 (403)")
                self?.handleErrorResponse(data: data, statusCode: 403, completion: completion)

            default:
                Logger.error("❌ 토큰 인증 실패 (\(httpResponse.statusCode))")
                self?.handleErrorResponse(data: data, statusCode: httpResponse.statusCode, completion: completion)
            }
        }
        
        task.resume()
    }
    
    // MARK: - Tracking Data
    
    /// 트래킹 데이터 서버 전송
    /// - Parameters:
    ///   - data: 트래킹 데이터
    ///   - environment: 환경 설정
    ///   - completion: 완료 콜백
    func sendTrackingData(
        _ trackingData: TrackingData,
        environment: Environment,
        completion: @escaping (Result<Void, NetworkError>) -> Void
    ) {
        let endpoint = APIEndpoints.tracking
        
        guard let url = endpoint.url(for: environment) else {
            Logger.error("Invalid tracking URL")
            completion(.failure(.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 30
        
        // JSON 인코딩
        do {
            let jsonData = try encoder.encode(trackingData)
            request.httpBody = jsonData
            
            #if DEBUG
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                Logger.debug("Tracking data: \(jsonString)")
            }
            #endif
        } catch {
            Logger.error("Failed to encode tracking data: \(error.localizedDescription)")
            completion(.failure(.decodingError))
            return
        }
        
        Logger.info("Sending tracking data to: \(url.absoluteString)")
        
        let task = session.dataTask(with: request) { data, response, error in
            // 네트워크 에러 처리
            if let error = error {
                Logger.error("Tracking network error: \(error.localizedDescription)")
                completion(.failure(.networkError(error)))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                Logger.error("Invalid response type")
                completion(.failure(.invalidResponse))
                return
            }
            
            // HTTP 상태 코드 확인
            if (200...299).contains(httpResponse.statusCode) {
                Logger.info("Tracking data sent successfully")
                completion(.success(()))
            } else {
                Logger.error("Tracking failed with status: \(httpResponse.statusCode)")
                completion(.failure(.httpError(statusCode: httpResponse.statusCode, code: nil, message: nil)))
            }
        }
        
        task.resume()
    }
    
    // MARK: - Private Methods
    
    private func handleErrorResponse(
        data: Data?,
        statusCode: Int,
        completion: @escaping (Result<TimeInterval, NetworkError>) -> Void
    ) {
        var errorCode: String?
        var errorMessage: String?
        
        if let data = data {
            do {
                let errorResponse = try decoder.decode(ErrorResponse.self, from: data)
                errorCode = errorResponse.code
                errorMessage = errorResponse.message
            } catch {
                Logger.warning("Failed to decode error response")
            }
        }
        
        Logger.error("HTTP Error \(statusCode): \(errorCode ?? "") - \(errorMessage ?? "")")
        completion(.failure(.httpError(statusCode: statusCode, code: errorCode, message: errorMessage)))
    }
}

