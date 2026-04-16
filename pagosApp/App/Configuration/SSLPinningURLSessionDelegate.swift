import Foundation
import Security

final class SSLPinningURLSessionDelegate: NSObject, URLSessionDelegate {
    private let pinnedCertificateData: [Data]

    init(pinnedCertificateData: [Data]) {
        self.pinnedCertificateData = pinnedCertificateData
        super.init()
    }

    func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
              let serverTrust = challenge.protectionSpace.serverTrust else {
            completionHandler(.performDefaultHandling, nil)
            return
        }

        var error: CFError?
        guard SecTrustEvaluateWithError(serverTrust, &error) else {
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }

        guard let serverCertificate = SecTrustGetCertificateAtIndex(serverTrust, 0) else {
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }

        let serverCertificateData = SecCertificateCopyData(serverCertificate) as Data
        guard pinnedCertificateData.contains(serverCertificateData) else {
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }

        completionHandler(.useCredential, URLCredential(trust: serverTrust))
    }
}

