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

protocol AuthenticationService: AnyObject {
    var isAuthenticatedPublisher: AnyPublisher<Bool, Never> { get }
    var isAuthenticated: Bool { get }
    
    func signIn(email: String, password: String) async throws
    func signOut() async throws
    func getCurrentUser() async throws -> String?
    func signUp(email: String, password: String) async throws // Added signUp method
}