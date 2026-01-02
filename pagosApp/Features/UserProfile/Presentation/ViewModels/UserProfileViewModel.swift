//
//  UserProfileViewModel.swift
//  pagosApp
//
//  ViewModel for UserProfile using Clean Architecture
//  Uses Use Cases instead of direct repository access
//

import Foundation
import Observation
import OSLog

@MainActor
@Observable
final class UserProfileViewModel {
    // MARK: - Domain State
    var profile: UserProfileEntity?
    var isLoading = false
    var errorMessage: String?
    var isSaving = false

    // MARK: - UI State
    var isEditing = false
    var showSuccessAlert = false
    var showDatePicker = false
    var editableProfile: EditableProfile?

    // MARK: - Dependencies (Use Cases)
    private let fetchUserProfileUseCase: FetchUserProfileUseCase
    private let getLocalProfileUseCase: GetLocalProfileUseCase
    private let updateUserProfileUseCase: UpdateUserProfileUseCase
    private let deleteLocalProfileUseCase: DeleteLocalProfileUseCase
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "pagosApp", category: "UserProfileViewModel")

    init(
        fetchUserProfileUseCase: FetchUserProfileUseCase,
        getLocalProfileUseCase: GetLocalProfileUseCase,
        updateUserProfileUseCase: UpdateUserProfileUseCase,
        deleteLocalProfileUseCase: DeleteLocalProfileUseCase
    ) {
        self.fetchUserProfileUseCase = fetchUserProfileUseCase
        self.getLocalProfileUseCase = getLocalProfileUseCase
        self.updateUserProfileUseCase = updateUserProfileUseCase
        self.deleteLocalProfileUseCase = deleteLocalProfileUseCase
    }

    // MARK: - Data Operations

    /// Load user profile from local storage (offline-first, fast - no loading indicator)
    func loadLocalProfile() async {
        errorMessage = nil

        let result = await getLocalProfileUseCase.execute()

        switch result {
        case .success(let loadedProfile):
            profile = loadedProfile
            if loadedProfile != nil {
                logger.info("✅ Profile loaded from local storage")
            } else {
                logger.info("⚠️ No local profile found")
            }

        case .failure(let error):
            logger.error("❌ Error loading local profile: \(error.errorCode)")
            errorMessage = "Error al cargar el perfil local"
        }
    }

    /// Fetch user profile from remote and save to local
    /// Called during login
    func fetchAndSaveProfile(userId: UUID) async -> Bool {
        isLoading = true
        errorMessage = nil

        let result = await fetchUserProfileUseCase.execute(userId: userId)

        switch result {
        case .success(let fetchedProfile):
            profile = fetchedProfile
            logger.info("✅ Profile fetched and saved successfully")
            isLoading = false
            return true

        case .failure(let error):
            logger.error("❌ Error fetching profile: \(error.errorCode)")
            errorMessage = "Error al cargar el perfil: \(error.errorCode)"
            isLoading = false
            return false
        }
    }

    /// Update user profile
    func updateProfile(with editableProfile: EditableProfile) async -> Bool {
        guard let currentProfile = profile else {
            errorMessage = "No hay perfil cargado"
            return false
        }

        isSaving = true
        errorMessage = nil

        // Apply changes to create updated entity
        let updatedProfile = editableProfile.applyTo(currentProfile)

        let result = await updateUserProfileUseCase.execute(updatedProfile)

        switch result {
        case .success(let savedProfile):
            profile = savedProfile
            logger.info("✅ Profile updated successfully")
            isSaving = false
            return true

        case .failure(let error):
            logger.error("❌ Error updating profile: \(error.errorCode)")
            errorMessage = "Error al actualizar el perfil: \(error.errorCode)"
            isSaving = false
            return false
        }
    }

    /// Clear local profile (called on logout)
    func clearLocalProfile() async {
        let result = await deleteLocalProfileUseCase.execute()

        switch result {
        case .success:
            profile = nil
            logger.info("✅ Local profile cleared")

        case .failure(let error):
            logger.error("❌ Error clearing local profile: \(error.errorCode)")
        }
    }

    // MARK: - UI Actions

    /// Start editing mode
    func startEditing() {
        guard let profile = profile else { return }
        editableProfile = EditableProfile(from: profile)
        isEditing = true
    }

    /// Cancel editing and reset state
    func cancelEditing() {
        showDatePicker = false
        editableProfile = nil
        isEditing = false
    }

    /// Save profile changes
    func saveProfile() async {
        guard let edited = editableProfile else { return }

        let success = await updateProfile(with: edited)
        if success {
            showSuccessAlert = true
            showDatePicker = false
            editableProfile = nil
        }
    }

    // MARK: - Computed Properties

    /// Form validation
    var isFormValid: Bool {
        editableProfile?.fullName.isEmpty == false
    }
}

