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
            logger.info("📝 Signing up user with email: \(email)")

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
            return mapper.toDTO(session)

        } catch let error as AuthError {
            throw error
        } catch {
            logger.error("❌ Sign up error: \(error.localizedDescription)")
            throw mapper.mapError(error)
        }
    }

    func signIn(email: String, password: String) async throws -> SupabaseSessionDTO {
        do {
            logger.info("🔑 Signing in with email: \(email)")

            let session = try await client.auth.signIn(
                email: email,
                password: password
            )

            logger.info("✅ Signed in successfully")
            return mapper.toDTO(session)

        } catch {
            logger.error("❌ Sign in error: \(error.localizedDescription)")
            throw mapper.mapError(error)
        }
    }

    func signOut() async throws {
        do {
            logger.info("🚪 Signing out")
            try await client.auth.signOut()
            logger.info("✅ Signed out successfully")

        } catch {
            logger.error("❌ Sign out error: \(error.localizedDescription)")
            throw AuthError.networkError(error.localizedDescription)
        }
    }

    func getCurrentSession() async throws -> SupabaseSessionDTO? {
        do {
            logger.debug("🔍 Getting current session")
            let session = try await client.auth.session

            logger.debug("✅ Session retrieved")
            return mapper.toDTO(session)

        } catch {
            logger.debug("⚠️ No active session found")
            return nil
        }
    }

    func refreshSession(refreshToken: String) async throws -> SupabaseSessionDTO {
        do {
            logger.info("🔄 Refreshing session")

            let session = try await client.auth.refreshSession(refreshToken: refreshToken)

            logger.info("✅ Session refreshed successfully")
            return mapper.toDTO(session)

        } catch {
            logger.error("❌ Session refresh error: \(error.localizedDescription)")
            throw mapper.mapError(error)
        }
    }

    // MARK: - Password Management

    func sendPasswordResetEmail(email: String) async throws {
        do {
            logger.info("📧 Sending password reset email to: \(email)")

            try await client.auth.resetPasswordForEmail(email)

            logger.info("✅ Password reset email sent")

        } catch {
            logger.error("❌ Password reset email error: \(error.localizedDescription)")
            throw mapper.mapError(error)
        }
    }

    func resetPassword(token: String, newPassword: String) async throws {
        do {
            logger.info("🔐 Resetting password")

            // Supabase SDK doesn't have direct token-based reset
            // This would typically be handled through a deep link flow
            // For now, we'll use update password which requires active session
            try await client.auth.update(user: UserAttributes(password: newPassword))

            logger.info("✅ Password reset successfully")

        } catch {
            logger.error("❌ Password reset error: \(error.localizedDescription)")
            throw mapper.mapError(error)
        }
    }

    func updateEmail(newEmail: String) async throws {
        do {
            logger.info("📧 Updating email to: \(newEmail)")

            try await client.auth.update(user: UserAttributes(email: newEmail))

            logger.info("✅ Email updated successfully")

        } catch {
            logger.error("❌ Email update error: \(error.localizedDescription)")
            throw mapper.mapError(error)
        }
    }

    func updatePassword(newPassword: String) async throws {
        do {
            logger.info("🔐 Updating password")

            try await client.auth.update(user: UserAttributes(password: newPassword))

            logger.info("✅ Password updated successfully")

        } catch {
            logger.error("❌ Password update error: \(error.localizedDescription)")
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
