//
//  L10n.swift
//  pagosApp
//
//  Type-safe centralized access to localized strings.
//  Clean Architecture: Presentation layer uses L10n; domain stays free of UI text.
//

import Foundation

enum L10n {

    private static func tr(_ key: String, _ args: CVarArg...) -> String {
        let format = NSLocalizedString(key, tableName: "Localizable", bundle: .main, comment: "")
        return args.isEmpty ? format : String(format: format, arguments: args)
    }

    // MARK: - General
    enum General {
        static let ok = tr("general.ok")
        static let cancel = tr("general.cancel")
        static let save = tr("general.save")
        static let delete = tr("general.delete")
        static let edit = tr("general.edit")
        static let retry = tr("general.retry")
        static let error = tr("general.error")
        static let loading = tr("general.loading")
    }

    // MARK: - Auth
    enum Auth {
        enum Login {
            static let welcome = tr("auth.login.welcome")
            static let forgotPassword = tr("auth.login.forgotPassword")
            static let noAccount = tr("auth.login.noAccount")
            static func useBiometric(_ name: String) -> String { tr("auth.login.useBiometric", name) }
        }
        enum Register {
            static let title = tr("auth.register.title")
            static let back = tr("auth.register.back")
            static let passwordHintMin = tr("auth.register.passwordHintMin")
            static let passwordMatch = tr("auth.register.passwordMatch")
        }
        enum ForgotPassword {
            static let title = tr("auth.forgotPassword.title")
            static let description = tr("auth.forgotPassword.description")
            static let back = tr("auth.forgotPassword.back")
            static let emailSent = tr("auth.forgotPassword.emailSent")
        }
        enum ResetPassword {
            static let title = tr("auth.resetPassword.title")
            static let newPassword = tr("auth.resetPassword.newPassword")
            static let confirmPassword = tr("auth.resetPassword.confirmPassword")
            static let passwordsDontMatch = tr("auth.resetPassword.passwordsDontMatch")
            static let button = tr("auth.resetPassword.button")
            static let goToLogin = tr("auth.resetPassword.goToLogin")
            static let successMessage = tr("auth.resetPassword.successMessage")
        }
    }

    // MARK: - Payments
    enum Payments {
        enum List {
            static let title = tr("payments.list.title")
            static let filter = tr("payments.list.filter")
            static let syncing = tr("payments.list.syncing")
        }
        enum Add {
            static let title = tr("payments.add.title")
            static let cancel = tr("payments.add.cancel")
        }
        enum Edit {
            static let title = tr("payments.edit.title")
            static let discard = tr("payments.edit.discard")
            static let saving = tr("payments.edit.saving")
        }
        enum Amounts {
            static let section = tr("payments.amounts.section")
            static let soles = tr("payments.amounts.soles")
            static let dollars = tr("payments.amounts.dollars")
            static let dualCurrency = tr("payments.amounts.dualCurrency")
            static let hintOneAmount = tr("payments.amounts.hintOneAmount")
        }
        enum Details {
            static let section = tr("payments.details.section")
            static let paid = tr("payments.details.paid")
            static let namePlaceholder = tr("payments.details.namePlaceholder")
            static let category = tr("payments.details.category")
            static let dueDate = tr("payments.details.dueDate")
        }
        enum Validation {
            static let completeFields = tr("payments.validation.completeFields")
            static let amountGreaterZero = tr("payments.validation.amountGreaterZero")
            static let bothAmountsGreaterZero = tr("payments.validation.bothAmountsGreaterZero")
        }
        static func categoryDisplayName(_ category: PaymentCategory) -> String {
            let key: String
            switch category {
            case .servicios: key = "payment.category.servicios"
            case .tarjetaCredito: key = "payment.category.tarjetaCredito"
            case .vivienda: key = "payment.category.vivienda"
            case .prestamo: key = "payment.category.prestamo"
            case .seguro: key = "payment.category.seguro"
            case .educacion: key = "payment.category.educacion"
            case .impuestos: key = "payment.category.impuestos"
            case .suscripcion: key = "payment.category.suscripcion"
            case .otro: key = "payment.category.otro"
            }
            return tr(key)
        }
        static func filterDisplayName(_ filter: PaymentFilterUI) -> String {
            switch filter {
            case .currentMonth: return tr("payment.filter.currentMonth")
            case .futureMonths: return tr("payment.filter.futureMonths")
            }
        }
    }

    // MARK: - Payment Errors (for PaymentErrorMessageMapper)
    enum PaymentError {
        static let invalidName = tr("payment.error.invalidName")
        static let invalidAmount = tr("payment.error.invalidAmount")
        static let invalidDate = tr("payment.error.invalidDate")
        static func saveFailed(_ details: String) -> String { tr("payment.error.saveFailed", details) }
        static func deleteFailed(_ details: String) -> String { tr("payment.error.deleteFailed", details) }
        static func updateFailed(_ details: String) -> String { tr("payment.error.updateFailed", details) }
        static func notificationFailed(_ details: String) -> String { tr("payment.error.notificationFailed", details) }
        static func calendarSyncFailed(_ details: String) -> String { tr("payment.error.calendarSyncFailed", details) }
        static let notFound = tr("payment.error.notFound")
        static func unknown(_ details: String) -> String { tr("payment.error.unknown", details) }
    }

    // MARK: - Statistics
    enum Statistics {
        static let title = tr("statistics.title")
        static let noDataTitle = tr("statistics.noData.title")
        static let noDataDescription = tr("statistics.noData.description")
        static let periodPicker = tr("statistics.period.picker")
        static let periodMonth = tr("statistics.period.month")
        static let periodYear = tr("statistics.period.year")
        static let periodAll = tr("statistics.period.all")
        static let currencySoles = tr("statistics.currency.soles")
        static let currencyDollars = tr("statistics.currency.dollars")
        static func emptyNoPayments(_ currencyName: String) -> String { tr("statistics.empty.noPayments", currencyName) }
        static func emptyForFilter(_ filter: String) -> String { tr("statistics.empty.forFilter", filter) }
        static let chartByCategory = tr("statistics.chart.byCategory")
        static let chartLast6Months = tr("statistics.chart.last6Months")
        static let errorCategory = tr("statistics.error.category")
        static let errorMonthly = tr("statistics.error.monthly")
        static func periodDisplayName(_ filter: StatsFilter) -> String {
            switch filter {
            case .month: return periodMonth
            case .year: return periodYear
            case .all: return periodAll
            }
        }
    }

    // MARK: - History
    enum History {
        static let title = tr("history.title")
        static let navTitle = tr("history.navTitle")
        static let loading = tr("history.loading")
        static let emptyTitle = tr("history.empty.title")
        static let emptyDescription = tr("history.empty.description")
        static let filterCompleted = tr("history.filter.completed")
        static let filterOverdue = tr("history.filter.overdue")
        static let filterAll = tr("history.filter.all")
        static let errorLoad = tr("history.error.load")
        static func filterDisplayName(_ filter: PaymentHistoryFilter) -> String {
            switch filter {
            case .completed: return filterCompleted
            case .overdue: return filterOverdue
            case .all: return filterAll
            }
        }
    }

    // MARK: - Reminders
    enum Reminders {
        static let listTitle = tr("reminders.listTitle")
        static let emptyTitle = tr("reminders.emptyTitle")
        static let emptyDescription = tr("reminders.emptyDescription")
        enum Add {
            static let title = tr("reminders.add.title")
        }
        enum Edit {
            static let title = tr("reminders.edit.title")
            static let saving = tr("reminders.edit.saving")
        }
        static let typeLabel = tr("reminders.typeLabel")
        static let titleLabel = tr("reminders.titleLabel")
        static let descriptionLabel = tr("reminders.descriptionLabel")
        static let descriptionPlaceholder = tr("reminders.descriptionPlaceholder")
        static let dueDateLabel = tr("reminders.dueDateLabel")
        static func typeDisplayName(_ type: ReminderType) -> String {
            let key: String
            switch type {
            case .cardRenewal: key = "reminders.type.cardRenewal"
            case .membership: key = "reminders.type.membership"
            case .subscription: key = "reminders.type.subscription"
            case .pension: key = "reminders.type.pension"
            case .deposit: key = "reminders.type.deposit"
            case .documents: key = "reminders.type.documents"
            case .taxes: key = "reminders.type.taxes"
            case .other: key = "reminders.type.other"
            }
            return tr(key)
        }
        enum Error {
            static let invalidTitle = tr("reminders.error.invalidTitle")
            static let invalidDate = tr("reminders.error.invalidDate")
            static func saveFailed(_ detail: String) -> String { tr("reminders.error.saveFailed", detail) }
            static func deleteFailed(_ detail: String) -> String { tr("reminders.error.deleteFailed", detail) }
            static let notFound = tr("reminders.error.notFound")
            static func unknown(_ detail: String) -> String { tr("reminders.error.unknown", detail) }
        }
    }

    // MARK: - Calendar
    enum Calendar {
        static let title = tr("calendar.title")
        static let sync = tr("calendar.sync")
        static let noPaymentsTitle = tr("calendar.noPayments.title")
        static let noPaymentsDescription = tr("calendar.noPayments.description")
        static func paymentsFor(date: String) -> String { tr("calendar.paymentsFor", date) }
        static func itemsFor(date: String) -> String { tr("calendar.itemsFor", date) }
        static let noItemsTitle = tr("calendar.noItems.title")
        static let noItemsDescription = tr("calendar.noItems.description")
        static let sectionPayments = tr("calendar.section.payments")
        static let sectionReminders = tr("calendar.section.reminders")
        static let alertSyncSuccess = tr("calendar.alert.syncSuccess")
        static let alertNoPaymentsTitle = tr("calendar.alert.noPaymentsToSync")
        static let alertNoPaymentsMessage = tr("calendar.alert.noPaymentsToSyncMessage")
        static let alertAccessDenied = tr("calendar.alert.accessDenied")
        static let alertAccessDeniedMessage = tr("calendar.alert.accessDeniedMessage")
    }

    // MARK: - Settings
    enum Settings {
        static let title = tr("settings.title")
        static let syncErrorTitle = tr("settings.syncError.title")
        static let loggingOut = tr("settings.loggingOut")
        enum RepairDb {
            static let title = tr("settings.repairDb.title")
            static let button = tr("settings.repairDb.button")
            static let successTitle = tr("settings.repairDb.successTitle")
            static let successMessage = tr("settings.repairDb.successMessage")
            static let errorMessage = tr("settings.repairDb.errorMessage")
            static let confirmMessage = tr("settings.repairDb.confirmMessage")
        }
        enum Logout {
            static let title = tr("settings.logout.title")
            static let message = tr("settings.logout.message")
            static let button = tr("settings.logout.button")
        }
        enum DataSection {
            static let sectionTitle = tr("settings.data.sectionTitle")
            static let footer = tr("settings.data.footer")
            static let unlinkButton = tr("settings.data.unlinkButton")
        }
        enum Unlink {
            static let title = tr("settings.unlinkDevice.title")
            static let button = tr("settings.unlink.button")
            static func warning(pendingCount: Int) -> String {
                pendingCount > 0 ? tr("settings.unlink.warningWithPending", pendingCount) : tr("settings.unlink.warning")
            }
        }
        static let sectionProfile = tr("settings.section.profile")
        static let sectionApp = tr("settings.section.app")
        static let sectionAbout = tr("settings.section.about")
        static let sectionLegal = tr("settings.section.legal")
        static let sectionSync = tr("settings.section.sync")
        static let sectionSession = tr("settings.section.session")
        static let profileMyProfile = tr("settings.profile.myProfile")
        static let profileSignIn = tr("settings.profile.signIn")
        static let aboutVersion = tr("settings.about.version")
        static let aboutDevelopedBy = tr("settings.about.developedBy")
        static let aboutTeam = tr("settings.about.team")
        static let legalPrivacy = tr("settings.legal.privacy")
        static let legalTerms = tr("settings.legal.terms")
        static let legalLicenses = tr("settings.legal.licenses")
        static let syncPendingCount = tr("settings.sync.pendingCount")
        static let syncAllSynced = tr("settings.sync.allSynced")
        static let syncLastSync = tr("settings.sync.lastSync")
        static let syncSignInToSync = tr("settings.sync.signInToSync")
        static let syncRetry = tr("settings.sync.retry")
        static let syncRepairDb = tr("settings.sync.repairDb")
        static let syncNow = tr("settings.sync.syncNow")
        enum Biometric {
            static let title = tr("settings.biometric.title")
            static let fastAccess = tr("settings.biometric.fastAccess")
            static let description = tr("settings.biometric.description")
            static let benefits = tr("settings.biometric.benefits")
            static let benefit1 = tr("settings.biometric.benefit1")
            static let benefit2 = tr("settings.biometric.benefit2")
            static let benefit3 = tr("settings.biometric.benefit3")
            static let notAvailable = tr("settings.biometric.notAvailable")
            static let configuration = tr("settings.biometric.configuration")
            static let important = tr("settings.biometric.important")
            static let importantMessage = tr("settings.biometric.importantMessage")
            static let loginRequired = tr("settings.biometric.loginRequired")
        }
        static let logoutError = tr("settings.logoutError")
        static let unlinkError = tr("settings.unlinkError")
    }

    // MARK: - Profile
    enum Profile {
        static let myProfile = tr("profile.myProfile")
        static let save = tr("profile.save")
        static let edit = tr("profile.edit")
        static let preferredCurrency = tr("profile.preferredCurrency")
        static let sectionPersonal = tr("profile.section.personal")
        static let sectionLocation = tr("profile.section.location")
        static let sectionPreferences = tr("profile.section.preferences")
        static let fieldName = tr("profile.field.name")
        static let fieldCity = tr("profile.field.city")
        static let fieldCountry = tr("profile.field.country")
        static let noProfileTitle = tr("profile.noProfile.title")
        static let noProfileDescription = tr("profile.noProfile.description")
        static let updatedTitle = tr("profile.updated.title")
        static let updatedMessage = tr("profile.updated.message")
        static let loading = tr("profile.loading")
        static let errorTitle = tr("profile.error.title")
        static let errorLoadLocal = tr("profile.error.loadLocal")
        static func errorLoad(_ code: String) -> String { tr("profile.error.load", code) }
        static let errorNoProfile = tr("profile.error.noProfile")
        static func errorUpdate(_ code: String) -> String { tr("profile.error.update", code) }
    }

    // MARK: - Session
    enum Session {
        static let inactivityTitle = tr("session.inactivity.title")
        static let inactivityMessage = tr("session.inactivity.message")
    }

    // MARK: - Sync
    enum Sync {
        static let cannotSync = tr("sync.cannotSync")
        static let recoverySuggestion = tr("sync.recoverySuggestion")
    }

    // MARK: - Auth Errors (for Auth module mapper)
    enum AuthErrorKeys {
        static let invalidCredentials = tr("auth.error.invalidCredentials")
        static let emailExists = tr("auth.error.emailExists")
        static let weakPassword = tr("auth.error.weakPassword")
        static let invalidEmail = tr("auth.error.invalidEmail")
        static let userNotFound = tr("auth.error.userNotFound")
        static let sessionExpired = tr("auth.error.sessionExpired")
        static let network = tr("auth.error.network")
        static func unknown(_ message: String) -> String { tr("auth.error.unknown", message) }
    }

    // MARK: - Tab bar
    enum Tab {
        static let payments = tr("tab.payments")
        static let reminders = tr("tab.reminders")
        static let calendar = tr("tab.calendar")
        static let history = tr("tab.history")
        static let statistics = tr("tab.statistics")
        static let settings = tr("tab.settings")
    }

    // MARK: - Logs (consola; idioma según preferencia del dispositivo/app)
    enum Log {
        enum Generic {
            static func withDetail(_ detail: String) -> String { tr("log.generic.withDetail", detail) }
            static func withContext(_ context: String, _ detail: String) -> String { tr("log.generic.withContext", context, detail) }
        }
        enum Auth {
            static let signUp = tr("log.auth.signUp")
            static let signUpSuccess = tr("log.auth.signUpSuccess")
            static func signUpFailed(_ detail: String) -> String { tr("log.auth.signUpFailed", detail) }
            static let signIn = tr("log.auth.signIn")
            static let signInSuccess = tr("log.auth.signInSuccess")
            static func signInFailed(_ detail: String) -> String { tr("log.auth.signInFailed", detail) }
            static let signOut = tr("log.auth.signOut")
            static let signOutSuccess = tr("log.auth.signOutSuccess")
            static let gettingSession = tr("log.auth.gettingSession")
            static let sessionRetrieved = tr("log.auth.sessionRetrieved")
            static let noRemoteSession = tr("log.auth.noRemoteSession")
            static func sessionFailed(_ detail: String) -> String { tr("log.auth.sessionFailed", detail) }
            static let refreshingSession = tr("log.auth.refreshingSession")
            static let sessionRefreshed = tr("log.auth.sessionRefreshed")
            static func sessionRefreshFailed(_ detail: String) -> String { tr("log.auth.sessionRefreshFailed", detail) }
            static let passwordResetEmail = tr("log.auth.passwordResetEmail")
            static let passwordResetEmailSent = tr("log.auth.passwordResetEmailSent")
            static func passwordResetEmailFailed(_ detail: String) -> String { tr("log.auth.passwordResetEmailFailed", detail) }
            static let resettingPassword = tr("log.auth.resettingPassword")
            static let passwordResetSuccess = tr("log.auth.passwordResetSuccess")
            static func passwordResetFailed(_ detail: String) -> String { tr("log.auth.passwordResetFailed", detail) }
            static let updatingEmail = tr("log.auth.updatingEmail")
            static let emailUpdated = tr("log.auth.emailUpdated")
            static func emailUpdateFailed(_ detail: String) -> String { tr("log.auth.emailUpdateFailed", detail) }
            static let updatingPassword = tr("log.auth.updatingPassword")
            static let passwordUpdated = tr("log.auth.passwordUpdated")
            static func passwordUpdateFailed(_ detail: String) -> String { tr("log.auth.passwordUpdateFailed", detail) }
            static let deletingAccount = tr("log.auth.deletingAccount")
            static let accountDeleted = tr("log.auth.accountDeleted")
            static func accountDeletionFailed(_ detail: String) -> String { tr("log.auth.accountDeletionFailed", detail) }
            static let biometricClearing = tr("log.auth.biometricClearing")
            static let biometricCleared = tr("log.auth.biometricCleared")
            static let biometricClearFailed = tr("log.auth.biometricClearFailed")
            static let tokensSaving = tr("log.auth.tokensSaving")
            static let tokensSaved = tr("log.auth.tokensSaved")
            static func tokensSaveFailed(_ detail: String) -> String { tr("log.auth.tokensSaveFailed", detail) }
            static let tokensRetrieving = tr("log.auth.tokensRetrieving")
            static let noTokens = tr("log.auth.noTokens")
            static let tokensRetrieved = tr("log.auth.tokensRetrieved")
            static let tokensClearing = tr("log.auth.tokensClearing")
            static let tokensCleared = tr("log.auth.tokensCleared")
            static func hasStoredTokens(_ value: String) -> String { tr("log.auth.hasStoredTokens", value) }
            static let allTokensCleared = tr("log.auth.allTokensCleared")
        }
        enum Profile {
            static func fetching(_ userId: String) -> String { tr("log.profile.fetching", userId) }
            static func notFound(_ userId: String) -> String { tr("log.profile.notFound", userId) }
            static let fetchedMapped = tr("log.profile.fetchedMapped")
            static func fetchFailed(_ detail: String) -> String { tr("log.profile.fetchFailed", detail) }
            static func updating(_ userId: String) -> String { tr("log.profile.updating", userId) }
            static let updated = tr("log.profile.updated")
            static func updateFailed(_ detail: String) -> String { tr("log.profile.updateFailed", detail) }
            static let fetchingLocal = tr("log.profile.fetchingLocal")
            static let savingLocal = tr("log.profile.savingLocal")
            static let postedNotification = tr("log.profile.postedNotification")
            static let deletingLocal = tr("log.profile.deletingLocal")
            static let localFound = tr("log.profile.localFound")
            static let noLocalFound = tr("log.profile.noLocalFound")
            static func fetchLocalFailed(_ detail: String) -> String { tr("log.profile.fetchLocalFailed", detail) }
            static let savedToStorage = tr("log.profile.savedToStorage")
            static func saveLocalFailed(_ detail: String) -> String { tr("log.profile.saveLocalFailed", detail) }
            static let localDeleted = tr("log.profile.localDeleted")
            static func deleteLocalFailed(_ detail: String) -> String { tr("log.profile.deleteLocalFailed", detail) }
            static let initRepo = tr("log.profile.initRepo")
        }
        enum Payments {
            static func fetchingAll(_ userId: String) -> String { tr("log.payments.fetchingAll", userId) }
            static func fetchedCount(_ count: String) -> String { tr("log.payments.fetchedCount", count) }
            static func upserting(_ name: String) -> String { tr("log.payments.upserting", name) }
            static let upserted = tr("log.payments.upserted")
            static let noPaymentsToUpsert = tr("log.payments.noPaymentsToUpsert")
            static func upsertingCount(_ count: Int) -> String { tr("log.payments.upsertingCount", count) }
            static func upsertedCount(_ count: Int) -> String { tr("log.payments.upsertedCount", count) }
            static func deleting(_ id: String) -> String { tr("log.payments.deleting", id) }
            static let deleted = tr("log.payments.deleted")
            static let noPaymentsToDelete = tr("log.payments.noPaymentsToDelete")
            static func deletingCount(_ count: Int) -> String { tr("log.payments.deletingCount", count) }
            static func deletedCount(_ count: Int) -> String { tr("log.payments.deletedCount", count) }
            static let fetchingLocal = tr("log.payments.fetchingLocal")
            static let clearingAll = tr("log.payments.clearingAll")
            static func failedToGet(_ detail: String) -> String { tr("log.payments.failedToGet", detail) }
            static let syncStart = tr("log.payments.syncStart")
            static let syncSuccess = tr("log.payments.syncSuccess")
            static func syncFailed(_ detail: String) -> String { tr("log.payments.syncFailed", detail) }
            static let noAuthUser = tr("log.payments.noAuthUser")
            static func uploadingCount(_ count: Int) -> String { tr("log.payments.uploadingCount", count) }
            static func uploadedSynced(_ count: Int) -> String { tr("log.payments.uploadedSynced", count) }
            static func downloading(_ userId: String) -> String { tr("log.payments.downloading", userId) }
            static func downloadedCount(_ count: Int) -> String { tr("log.payments.downloadedCount", count) }
            static func syncingDeletion(_ paymentId: String) -> String { tr("log.payments.syncingDeletion", paymentId) }
            static let deletionSynced = tr("log.payments.deletionSynced")
        }
        enum Statistics {
            static let gettingAll = tr("log.statistics.gettingAll")
            static func gettingFiltered(_ filter: String, _ currency: String) -> String { tr("log.statistics.gettingFiltered", filter, currency) }
            static func filteredCount(_ filtered: Int, _ total: Int) -> String { tr("log.statistics.filteredCount", filtered, total) }
            static func gettingForMonths(_ count: Int, _ currency: String) -> String { tr("log.statistics.gettingForMonths", count, currency) }
            static let failedStartMonth = tr("log.statistics.failedStartMonth")
            static let failedEndPrevMonth = tr("log.statistics.failedEndPrevMonth")
            static let failedStartPeriod = tr("log.statistics.failedStartPeriod")
            static func filteredForMonths(_ filtered: Int, _ count: Int, _ total: Int) -> String { tr("log.statistics.filteredForMonths", filtered, count, total) }
            static let initRepo = tr("log.statistics.initRepo")
        }
        enum Calendar {
            static let gettingForDate = tr("log.calendar.gettingForDate")
            static func filteredForDate(_ filtered: Int, _ total: Int) -> String { tr("log.calendar.filteredForDate", filtered, total) }
            static let gettingForMonth = tr("log.calendar.gettingForMonth")
            static func filteredForMonth(_ filtered: Int, _ total: Int) -> String { tr("log.calendar.filteredForMonth", filtered, total) }
            static let gettingAll = tr("log.calendar.gettingAll")
            static let initRepo = tr("log.calendar.initRepo")
        }
        enum Settings {
            static let syncComplete = tr("log.settings.syncComplete")
            static func syncFailed(_ detail: String) -> String { tr("log.settings.syncFailed", detail) }
            static let clearingDb = tr("log.settings.clearingDb")
            static let dbCleared = tr("log.settings.dbCleared")
            static let dbClearFailed = tr("log.settings.dbClearFailed")
            static let loggingOut = tr("log.settings.loggingOut")
            static func logoutFailed(_ detail: String) -> String { tr("log.settings.logoutFailed", detail) }
            static let unlinking = tr("log.settings.unlinking")
            static func unlinkFailed(_ detail: String) -> String { tr("log.settings.unlinkFailed", detail) }
        }
        enum Notifications {
            static func authFailed(_ detail: String) -> String { tr("log.notifications.authFailed", detail) }
            static func authGranted(_ granted: String) -> String { tr("log.notifications.authGranted", granted) }
            static func paymentAlreadyPaid(_ name: String) -> String { tr("log.notifications.paymentAlreadyPaid", name) }
            static func cancelling(_ name: String) -> String { tr("log.notifications.cancelling", name) }
            static func notAuthorized(_ name: String) -> String { tr("log.notifications.notAuthorized", name) }
            static func scheduled9AM(_ name: String) -> String { tr("log.notifications.scheduled9AM", name) }
            static func schedule9AMFailed(_ name: String, _ detail: String) -> String { tr("log.notifications.schedule9AMFailed", name, detail) }
            static func skipping9AM(_ name: String) -> String { tr("log.notifications.skipping9AM", name) }
            static func scheduled2PM(_ name: String) -> String { tr("log.notifications.scheduled2PM", name) }
            static func schedule2PMFailed(_ name: String, _ detail: String) -> String { tr("log.notifications.schedule2PMFailed", name, detail) }
            static func skipping2PM(_ name: String) -> String { tr("log.notifications.skipping2PM", name) }
            static func skippingDays(_ name: String, _ days: Int) -> String { tr("log.notifications.skippingDays", name, days) }
            static func scheduledDays(_ name: String, _ days: Int) -> String { tr("log.notifications.scheduledDays", name, days) }
            static func scheduleFailed(_ name: String, _ days: Int, _ detail: String) -> String { tr("log.notifications.scheduleFailed", name, days, detail) }
            static func noneScheduled(_ name: String) -> String { tr("log.notifications.noneScheduled", name) }
            static func scheduledCount(_ count: Int, _ name: String) -> String { tr("log.notifications.scheduledCount", count, name) }
            static func cancelled(_ paymentId: String) -> String { tr("log.notifications.cancelled", paymentId) }
        }
        enum Db {
            static func modelContainerFailed(_ detail: String) -> String { tr("log.db.modelContainerFailed", detail) }
            static let recoveryAttempt = tr("log.db.recoveryAttempt")
            static let corruptedRemoved = tr("log.db.corruptedRemoved")
            static let recreated = tr("log.db.recreated")
            static func recoveryFailed(_ detail: String) -> String { tr("log.db.recoveryFailed", detail) }
        }
        enum Supabase {
            static let initialized = tr("log.supabase.initialized")
            static func configFailed(_ detail: String) -> String { tr("log.supabase.configFailed", detail) }
            static let usingDemo = tr("log.supabase.usingDemo")
        }
    }
}
