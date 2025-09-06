import Foundation

enum LoginError: Error, LocalizedError {
    case invalidEmailFormat
    case wrongCredentials
    
    var errorDescription: String? {
        switch self {
        case .invalidEmailFormat:
            return "El formato del correo electrónico no es válido."
        case .wrongCredentials:
            return "El correo o la contraseña son incorrectos."
        }
    }
}