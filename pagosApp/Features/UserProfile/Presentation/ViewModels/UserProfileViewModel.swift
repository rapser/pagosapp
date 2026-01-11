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
    // MARK: - UI State
    var profile: UserProfileUI?
    var isLoading = false
    var errorMessage: String?
    var isSaving = false

    // MARK: - Editing State
    var isEditing = false
    var showSuccessAlert = false
    var showDatePicker = false
    var editableProfile: EditableProfileUI?

    // MARK: - Dependencies (Use Cases)
    private let fetchUserProfileUseCase: FetchUserProfileUseCase
    private let getLocalProfileUseCase: GetLocalProfileUseCase
    private let updateUserProfileUseCase: UpdateUserProfileUseCase
    private let deleteLocalProfileUseCase: DeleteLocalProfileUseCase
    private let mapper: UserProfileUIMapping
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "pagosApp", category: "UserProfileViewModel")

    init(
        fetchUserProfileUseCase: FetchUserProfileUseCase,
        getLocalProfileUseCase: GetLocalProfileUseCase,
        updateUserProfileUseCase: UpdateUserProfileUseCase,
        deleteLocalProfileUseCase: DeleteLocalProfileUseCase,
        mapper: UserProfileUIMapping
    ) {
        self.fetchUserProfileUseCase = fetchUserProfileUseCase
        self.getLocalProfileUseCase = getLocalProfileUseCase
        self.updateUserProfileUseCase = updateUserProfileUseCase
        self.deleteLocalProfileUseCase = deleteLocalProfileUseCase
        self.mapper = mapper
    }

    // MARK: - Data Operations

    /// Load user profile from local storage (offline-first, fast - no loading indicator)
    func loadLocalProfile() async {
        errorMessage = nil

        logger.info("🔍 [ViewModel] Starting loadLocalProfile")
        let result = await getLocalProfileUseCase.execute()

        switch result {
        case .success(let loadedProfile):
            logger.info("🔍 [ViewModel] Got result - profile is \(loadedProfile == nil ? "nil" : "not nil")")
            // Convert Domain -> UI
            profile = loadedProfile.map { mapper.toUI($0) }
            logger.info("🔍 [ViewModel] Assigned to self.profile - self.profile is now \(self.profile == nil ? "nil" : "not nil")")

            if let loadedProfile = loadedProfile {
                logger.info("✅ Profile loaded from local storage - Name: \(loadedProfile.fullName), Email: \(loadedProfile.email)")
            } else {
                logger.warning("⚠️ No local profile found in SwiftData")
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
            // Convert Domain -> UI
            profile = mapper.toUI(fetchedProfile)
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
    func updateProfile(with editableProfile: EditableProfileUI) async -> Bool {
        guard let currentProfile = profile else {
            errorMessage = "No hay perfil cargado"
            return false
        }

        isSaving = true
        errorMessage = nil

        // Apply changes to create updated UI entity
        let updatedProfileUI = editableProfile.applyTo(currentProfile)

        // Convert UI -> Domain and execute
        let result = await updateUserProfileUseCase.execute(mapper.toDomain(updatedProfileUI))

        switch result {
        case .success(let savedProfile):
            // Convert Domain -> UI
            profile = mapper.toUI(savedProfile)
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
        editableProfile = EditableProfileUI(from: profile)
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

