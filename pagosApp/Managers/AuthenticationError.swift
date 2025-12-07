import Foundation

enum AuthenticationError: Error, LocalizedError, UserFacingError {
    case invalidEmailFormat
    case wrongCredentials
    case networkError
    case sessionExpired
    case unknown(Error)

    // MARK: - LocalizedError

    var errorDescription: String? {
        switch self {
        case .invalidEmailFormat:
            return "El formato del correo electrónico no es válido."
        case .wrongCredentials:
            return "El correo o la contraseña son incorrectos."
        case .networkError:
            return "No se pudo conectar con el servidor. Verifica tu conexión a internet."
        case .sessionExpired:
            return "Tu sesión ha expirado. Por favor, inicia sesión nuevamente."
        case .unknown(let error):
            return "Ha ocurrido un error inesperado: \(error.localizedDescription)"
        }
    }

    // MARK: - UserFacingError

    var title: String {
        switch self {
        case .invalidEmailFormat:
            return "Email Inválido"
        case .wrongCredentials:
            return "Credenciales Incorrectas"
        case .networkError:
            return "Error de Conexión"
        case .sessionExpired:
            return "Sesión Expirada"
        case .unknown:
            return "Error Inesperado"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .invalidEmailFormat:
            return "Asegúrate de ingresar un correo válido (ejemplo@dominio.com)"
        case .wrongCredentials:
            return "Verifica que tu correo y contraseña sean correctos e intenta nuevamente."
        case .networkError:
            return "Verifica tu conexión a internet y vuelve a intentarlo."
        case .sessionExpired:
            return "Ingresa tus credenciales para continuar."
        case .unknown:
            return "Si el problema persiste, contacta a soporte técnico."
        }
    }

    var severity: ErrorSeverity {
        switch self {
        case .invalidEmailFormat:
            return .warning
        case .wrongCredentials:
            return .error
        case .networkError:
            return .error
        case .sessionExpired:
            return .warning
        case .unknown:
            return .error
        }
    }
}
