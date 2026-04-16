//
//  SupabaseAuthDataSource.swift
//  pagosApp
//
//  Supabase implementation of remote authentication data source
//  Clean Architecture - Data Layer
//

import Foundation
import Supabase
import OSLog

private let logger = Logger(subsystem: "com.rapser.pagosApp", category: "SupabaseAuthDataSource")

/// Supabase implementation of AuthRemoteDataSource
@MainActor
final class SupabaseAuthDataSource: AuthRemoteDataSource {
    private let client: SupabaseClient
    private let mapper: SupabaseAuthDTOMapper

    init(client: SupabaseClient, mapper: SupabaseAuthDTOMapper = SupabaseAuthDTOMapper()) {
        self.client = client
        self.mapper = mapper
    }

    // MARK: - Authentication

    func signUp(email: String, password: String, metadata: [String: String]?) async throws -> SupabaseSessionDTO {
        do {
            logger.info("📝 Signing up user")
            NetworkDebugLogger.logRequest(
                "signUp",
                resource: "auth",
                details: ["email": NetworkDebugLogger.redactEmail(email)]
            )

            // Convert metadata to [String: AnyJSON] for Supabase
            let supabaseMetadata: [String: AnyJSON] = metadata?.reduce(into: [:]) { result, pair in
                result[pair.key] = AnyJSON.string(pair.value)
            } ?? [:]

            let response = try await client.auth.signUp(
                email: email,
                password: password,
                data: supabaseMetadata
            )

            guard let session = response.session else {
                logger.error("❌ No session received after sign up")
                throw AuthError.unknown("Failed to create session")
            }

            logger.info("✅ User signed up successfully")
            NetworkDebugLogger.logResponse("signUp", resource: "auth")
            return mapper.toDTO(session)

        } catch let error as AuthError {
            throw error
        } catch {
            logger.error("❌ Sign up error: \(error.localizedDescription)")
            NetworkDebugLogger.logFailure("signUp", resource: "auth", error: error)
            throw mapper.mapError(error)
        }
    }

    func signIn(email: String, password: String) async throws -> SupabaseSessionDTO {
        do {
            logger.info("🔑 Signing in")
            NetworkDebugLogger.logRequest(
                "signIn",
                resource: "auth",
                details: ["email": NetworkDebugLogger.redactEmail(email)]
            )

            let session = try await client.auth.signIn(
                email: email,
                password: password
            )

            logger.info("✅ Signed in successfully")
            NetworkDebugLogger.logResponse("signIn", resource: "auth")
            return mapper.toDTO(session)

        } catch {
            logger.error("❌ Sign in error: \(error.localizedDescription)")
            NetworkDebugLogger.logFailure("signIn", resource: "auth", error: error)
            throw mapper.mapError(error)
        }
    }

    func signOut() async throws {
        do {
            logger.info("🚪 Signing out")
            NetworkDebugLogger.logRequest("signOut", resource: "auth")
            try await client.auth.signOut()
            logger.info("✅ Signed out successfully")
            NetworkDebugLogger.logResponse("signOut", resource: "auth")

        } catch {
            logger.error("❌ Sign out error: \(error.localizedDescription)")
            NetworkDebugLogger.logFailure("signOut", resource: "auth", error: error)
            throw AuthError.networkError(error.localizedDescription)
        }
    }

    func getCurrentSession() async throws -> SupabaseSessionDTO? {
        do {
            logger.debug("🔍 Getting current session")
            NetworkDebugLogger.logRequest("getCurrentSession", resource: "auth")
            let session = try await client.auth.session

            logger.debug("✅ Session retrieved")
            NetworkDebugLogger.logResponse("getCurrentSession", resource: "auth")
            return mapper.toDTO(session)

        } catch {
            logger.debug("⚠️ No active session found")
            return nil
        }
    }

    func refreshSession(refreshToken: String) async throws -> SupabaseSessionDTO {
        do {
            logger.info("🔄 Refreshing session")
            NetworkDebugLogger.logRequest("refreshSession", resource: "auth")

            let session = try await client.auth.refreshSession(refreshToken: refreshToken)

            logger.info("✅ Session refreshed successfully")
            NetworkDebugLogger.logResponse("refreshSession", resource: "auth")
            return mapper.toDTO(session)

        } catch {
            logger.error("❌ Session refresh error: \(error.localizedDescription)")
            NetworkDebugLogger.logFailure("refreshSession", resource: "auth", error: error)
            throw mapper.mapError(error)
        }
    }

    // MARK: - Password Management

    func sendPasswordResetEmail(email: String) async throws {
        do {
            logger.info("📧 Sending password reset email")
            NetworkDebugLogger.logRequest(
                "sendPasswordResetEmail",
                resource: "auth",
                details: ["email": NetworkDebugLogger.redactEmail(email)]
            )

            try await client.auth.resetPasswordForEmail(email)

            logger.info("✅ Password reset email sent")
            NetworkDebugLogger.logResponse("sendPasswordResetEmail", resource: "auth")

        } catch {
            logger.error("❌ Password reset email error: \(error.localizedDescription)")
            NetworkDebugLogger.logFailure("sendPasswordResetEmail", resource: "auth", error: error)
            throw mapper.mapError(error)
        }
    }

    func resetPassword(token: String, newPassword: String) async throws {
        do {
            logger.info("🔐 Resetting password")
            NetworkDebugLogger.logRequest("resetPassword", resource: "auth")

            // Supabase SDK doesn't have direct token-based reset
            // This would typically be handled through a deep link flow
            // For now, we'll use update password which requires active session
            try await client.auth.update(user: UserAttributes(password: newPassword))

            logger.info("✅ Password reset successfully")
            NetworkDebugLogger.logResponse("resetPassword", resource: "auth")

        } catch {
            logger.error("❌ Password reset error: \(error.localizedDescription)")
            NetworkDebugLogger.logFailure("resetPassword", resource: "auth", error: error)
            throw mapper.mapError(error)
        }
    }

    func updateEmail(newEmail: String) async throws {
        do {
            logger.info("📧 Updating email")
            NetworkDebugLogger.logRequest(
                "updateEmail",
                resource: "auth",
                details: ["email": NetworkDebugLogger.redactEmail(newEmail)]
            )

            try await client.auth.update(user: UserAttributes(email: newEmail))

            logger.info("✅ Email updated successfully")
            NetworkDebugLogger.logResponse("updateEmail", resource: "auth")

        } catch {
            logger.error("❌ Email update error: \(error.localizedDescription)")
            NetworkDebugLogger.logFailure("updateEmail", resource: "auth", error: error)
            throw mapper.mapError(error)
        }
    }

    func updatePassword(newPassword: String) async throws {
        do {
            logger.info("🔐 Updating password")
            NetworkDebugLogger.logRequest("updatePassword", resource: "auth")

            try await client.auth.update(user: UserAttributes(password: newPassword))

            logger.info("✅ Password updated successfully")
            NetworkDebugLogger.logResponse("updatePassword", resource: "auth")

        } catch {
            logger.error("❌ Password update error: \(error.localizedDescription)")
            NetworkDebugLogger.logFailure("updatePassword", resource: "auth", error: error)
            throw mapper.mapError(error)
        }
    }

    // MARK: - Account Management

    func deleteAccount() async throws {
        do {
            logger.info("🗑️ Deleting account")

            // Supabase doesn't have built-in delete user from client side
            // This typically requires a server-side function or admin API call
            // For now, we'll throw an error indicating this needs to be implemented
            throw AuthError.unknown("Account deletion not implemented - requires server-side function")

        } catch {
            logger.error("❌ Account deletion error: \(error.localizedDescription)")
            throw error as? AuthError ?? AuthError.unknown(error.localizedDescription)
        }
    }
}
