import Foundation
import Combine

enum AuthenticationError: Error, LocalizedError {
    case invalidEmailFormat
    case wrongCredentials
    case unknown(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidEmailFormat:
            return "El formato del correo electrónico no es válido."
        case .wrongCredentials:
            return "El correo o la contraseña son incorrectos."
        case .unknown(let error):
            return "Ha ocurrido un error desconocido: \(error.localizedDescription)"
        }
    }
}
