//
//  UserProfileViewModel.swift
//  pagosApp
//
//  ViewModel for UserProfile using Clean Architecture
//  Uses Use Cases instead of direct repository access
//

import Foundation

@MainActor
@Observable
final class UserProfileViewModel: BaseViewModel {
    // MARK: - UI State
    var profile: UserProfileUI?
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
        super.init(category: "UserProfileViewModel")
    }

    // MARK: - Data Operations

    /// Load user profile from local storage (offline-first, fast - no loading indicator)
    func loadLocalProfile() async {
        clearError()
        let result = await getLocalProfileUseCase.execute()

        switch result {
        case .success(let loadedProfile):
            profile = loadedProfile.map { mapper.toUI($0) }

        case .failure(let error):
            logError(error)
            setError(L10n.Profile.errorLoadLocal)
        }
    }

    /// Fetch user profile from remote and save to local
    /// Called during login
    func fetchAndSaveProfile(userId: UUID) async -> Bool {
        isLoading = true
        clearError()

        let result = await fetchUserProfileUseCase.execute(userId: userId)

        switch result {
        case .success(let fetchedProfile):
            profile = mapper.toUI(fetchedProfile)
            isLoading = false
            return true

        case .failure(let error):
            logError(error)
            setError(L10n.Profile.errorLoad(error.errorCode))
            isLoading = false
            return false
        }
    }

    /// Update user profile
    func updateProfile(with editableProfile: EditableProfileUI) async -> Bool {
        guard let currentProfile = profile else {
            setError(L10n.Profile.errorNoProfile)
            return false
        }

        isSaving = true
        clearError()

        // Apply changes to create updated UI entity
        let updatedProfileUI = editableProfile.applyTo(currentProfile)

        // Convert UI -> Domain and execute
        let result = await updateUserProfileUseCase.execute(mapper.toDomain(updatedProfileUI))

        switch result {
        case .success(let savedProfile):
            profile = mapper.toUI(savedProfile)
            isSaving = false
            return true

        case .failure(let error):
            logError(error)
            setError(L10n.Profile.errorUpdate(error.errorCode))
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

        case .failure(let error):
            logError(error)
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

