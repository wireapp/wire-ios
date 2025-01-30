//
// Wire
// Copyright (C) 2025 Wire Swiss GmbH
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see http://www.gnu.org/licenses/.
//

import SwiftUI
import WireCommonComponents
import WireDataModel
import WireDesign
import WireSettingsUI
import WireSyncEngine

extension ZMUser {
    var hasValidEmail: Bool {
        guard let email = emailAddress,
              !email.isEmpty else {
            return false
        }
        return true
    }
}

extension SettingsCellDescriptorFactory {

    @MainActor
    func accountGroup(
        isPublicDomain: Bool,
        userSession: UserSession,
        useTypeIntrinsicSizeTableView: Bool
    ) -> any SettingsCellDescriptorType {
        var sections: [SettingsSectionDescriptorType] = [
            infoSection(userSession: userSession, useTypeIntrinsicSizeTableView: useTypeIntrinsicSizeTableView)
        ]

        if userRightInterfaceType.selfUserIsPermitted(to: .editAccentColor),
           userRightInterfaceType.selfUserIsPermitted(to: .editProfilePicture) {
            sections.append(appearanceSection())
        }

        sections.append(privacySection())

        if Bundle.developerModeEnabled, !SecurityFlags.forceEncryptionAtRest.isEnabled {
            sections.append(encryptionAtRestSection())
        }

        #if !DATA_COLLECTION_DISABLED
            sections.append(personalInformationSection(isPublicDomain: isPublicDomain))
        #endif

        if SecurityFlags.backup.isEnabled {
            sections.append(conversationsSection())
        }

        if let user = ZMUser.selfUser(), !user.usesCompanyLogin {
            sections.append(actionsSection())
        }

        sections.append(signOutSection())

        return SettingsGroupCellDescriptor(
            items: sections,
            title: L10n.Localizable.Self.Settings.accountSection,
            icon: .personalProfile,
            accessibilityBackButtonText: L10n.Accessibility.AccountSettings.BackButton.description,
            settingsTopLevelMenuItem: .account,
            settingsCoordinator: settingsCoordinator
        )
    }

    // MARK: - Sections

    func infoSection(
        userSession: UserSession,
        useTypeIntrinsicSizeTableView: Bool
    ) -> SettingsSectionDescriptorType {
        let federationEnabled = BackendInfo.isFederationEnabled
        var cellDescriptors: [SettingsCellDescriptorType] = []
        cellDescriptors = [
            nameElement(enabled: userRightInterfaceType.selfUserIsPermitted(to: .editName)),
            handleElement(
                enabled: userRightInterfaceType.selfUserIsPermitted(to: .editHandle),
                federationEnabled: federationEnabled,
                useTypeIntrinsicSizeTableView: useTypeIntrinsicSizeTableView
            )
        ]

        if let user = SelfUser.provider?.providedSelfUser {
            if !user.usesCompanyLogin {
                cellDescriptors.append(
                    emailElement(
                        enabled: userRightInterfaceType.selfUserIsPermitted(to: .editEmail),
                        userSession: userSession,
                        useTypeIntrinsicSizeTableView: useTypeIntrinsicSizeTableView
                    )
                )
            }

            if user.hasTeam {
                cellDescriptors.append(teamElement())
            }
        }

        if federationEnabled {
            cellDescriptors.append(domainElement())
        }

        if URL.selfUserProfileLink != nil {
            cellDescriptors.append(profileLinkElement())
            cellDescriptors.append(profileLinkButton())
        }

        return SettingsSectionDescriptor(
            cellDescriptors: cellDescriptors,
            header: L10n.Localizable.Self.Settings.AccountDetailsGroup.Info.title,
            footer: nil
        )
    }

    private func appearanceSection() -> SettingsSectionDescriptorType {
        SettingsSectionDescriptor(
            cellDescriptors: [pictureElement(), colorElement()],
            header: L10n.Localizable.Self.Settings.AccountAppearanceGroup.title
        )
    }

    // swiftlint:disable:next todo_requires_jira_link
    // TODO: John remove warning and consult design about this setting.

    func encryptionAtRestSection() -> SettingsSectionDescriptorType {
        SettingsSectionDescriptor(
            cellDescriptors: [encryptMessagesAtRestElement()],
            header: "Encryption at Rest",
            footer: "WARNING: this feature is experimental and may lead to data loss. Use at your own risk."
        )
    }

    func privacySection() -> SettingsSectionDescriptorType {
        SettingsSectionDescriptor(
            cellDescriptors: [readReceiptsEnabledElement()],
            header: L10n.Localizable.Self.Settings.PrivacySectionGroup.title,
            footer: L10n.Localizable.Self.Settings.PrivacySectionGroup.subtitle
        )
    }

    func personalInformationSection(isPublicDomain: Bool) -> SettingsSectionDescriptorType {
        SettingsSectionDescriptor(
            cellDescriptors: [dateUsagePermissionsElement(isPublicDomain: isPublicDomain)],
            header: L10n.Localizable.Self.Settings.AccountPersonalInformationGroup.title
        )
    }

    @MainActor
    func conversationsSection() -> SettingsSectionDescriptorType {
        SettingsSectionDescriptor(
            cellDescriptors: [backUpElement()],
            header: L10n.Localizable.Self.Settings.Conversations.title
        )
    }

    func actionsSection() -> SettingsSectionDescriptorType {
        var cellDescriptors = [resetPasswordElement()]
        if let selfUser = settingsPropertyFactory.selfUser, !selfUser.isTeamMember {
            cellDescriptors.append(deleteAccountButtonElement())
        }

        return SettingsSectionDescriptor(
            cellDescriptors: cellDescriptors,
            header: L10n.Localizable.Self.Settings.AccountDetails.Actions.title,
            footer: .none
        )
    }

    func signOutSection() -> SettingsSectionDescriptorType {
        SettingsSectionDescriptor(cellDescriptors: [signOutElement()], header: .none, footer: .none)
    }

    // MARK: - Elements

    private func textValueCellDescriptor(
        propertyName: SettingsPropertyName,
        enabled: Bool = true
    ) -> SettingsPropertyTextValueCellDescriptor {
        var settingsProperty = settingsPropertyFactory.property(propertyName)
        settingsProperty.enabled = enabled

        return SettingsPropertyTextValueCellDescriptor(settingsProperty: settingsProperty)
    }

    func nameElement(enabled: Bool = true) -> SettingsPropertyTextValueCellDescriptor {
        textValueCellDescriptor(propertyName: .profileName, enabled: enabled)
    }

    func emailElement(
        enabled: Bool = true,
        userSession: UserSession,
        useTypeIntrinsicSizeTableView: Bool
    ) -> SettingsCellDescriptorType {
        if enabled {
            SettingsExternalScreenCellDescriptor(
                title: L10n.Localizable.Self.Settings.AccountSection.Email.title,
                isDestructive: false,
                presentationStyle: .navigation,
                presentationAction: { () -> (UIViewController?) in
                    guard let selfUser = ZMUser.selfUser() else {
                        assertionFailure("ZMUser.selfUser() is nil")
                        return .none
                    }
                    return ChangeEmailViewController(
                        user: selfUser,
                        userSession: userSession,
                        useTypeIntrinsicSizeTableView: useTypeIntrinsicSizeTableView,
                        settingsCoordinator: settingsCoordinator
                    )
                },
                previewGenerator: { _ in
                    if let email = ZMUser.selfUser()?.emailAddress, !email.isEmpty {
                        SettingsCellPreview.text(email)
                    } else {
                        SettingsCellPreview.text(L10n.Localizable.Self.addEmailPassword)
                    }
                },
                accessoryViewMode: .alwaysHide
            )
        } else {
            textValueCellDescriptor(propertyName: .email, enabled: enabled)
        }
    }

    func handleElement(
        enabled: Bool = true,
        federationEnabled: Bool,
        useTypeIntrinsicSizeTableView: Bool
    ) -> SettingsCellDescriptorType {
        typealias AccountSection = L10n.Localizable.Self.Settings.AccountSection
        if enabled {
            let presentation = {
                ChangeHandleViewController(
                    useTypeIntrinsicSizeTableView: useTypeIntrinsicSizeTableView,
                    settingsCoordinator: settingsCoordinator
                )
            }

            if let selfUser = ZMUser.selfUser(), selfUser.handle != nil {

                let preview: PreviewGeneratorType = { _ in
                    guard let handleDisplayString = selfUser.handleDisplayString(withDomain: federationEnabled) else {
                        return .none
                    }
                    return .text(handleDisplayString)
                }

                let copiableText = selfUser.handleDisplayString(withDomain: federationEnabled)

                return SettingsExternalScreenCellDescriptor(
                    title: AccountSection.Handle.title,
                    isDestructive: false,
                    presentationStyle: .navigation,
                    presentationAction: presentation,
                    previewGenerator: preview,
                    accessoryViewMode: .alwaysHide,
                    copiableText: copiableText
                )
            }

            return SettingsExternalScreenCellDescriptor(
                title: AccountSection.AddHandle.title,
                presentationAction: presentation
            )
        } else {
            return textValueCellDescriptor(propertyName: .handle, enabled: enabled)
        }
    }

    func teamElement() -> any SettingsCellDescriptorType {
        textValueCellDescriptor(propertyName: .team, enabled: false)
    }

    func domainElement() -> any SettingsCellDescriptorType {
        textValueCellDescriptor(propertyName: .domain, enabled: false)
    }

    func profileLinkElement() -> any SettingsCellDescriptorType {
        SettingsProfileLinkCellDescriptor()
    }

    func profileLinkButton() -> any SettingsCellDescriptorType {
        SettingsCopyButtonCellDescriptor()
    }

    private func pictureElement() -> any SettingsCellDescriptorType {
        let profileImagePicker = ProfileImagePickerManager()
        let previewGenerator: PreviewGeneratorType = { _ in
            guard let image = ZMUser.selfUser()?.imageSmallProfileData.flatMap(UIImage.init) else { return .none }
            return .image(image)
        }

        let presentationAction: (_ sender: UIView) -> UIViewController? = { sender in
            profileImagePicker.selectProfileImage(
                popoverConfiguration: .sourceView(sourceView: sender, sourceRect: .null)
            )
        }
        return SettingsAppearanceCellDescriptor(
            text: L10n.Localizable.Self.Settings.AccountPictureGroup.picture.capitalized,
            previewGenerator: previewGenerator,
            presentationStyle: .alert,
            presentationAction: presentationAction,
            settingsCoordinator: settingsCoordinator
        )
    }

    private func colorElement() -> any SettingsCellDescriptorType {
        SettingsAppearanceCellDescriptor(
            text: L10n.Localizable.Self.Settings.AccountPictureGroup.color.capitalized,
            previewGenerator: colorElementPreviewGenerator,
            presentationStyle: .navigation,
            presentationAction: colorElementPresentationAction,
            settingsCoordinator: settingsCoordinator
        )
    }

    private func colorElementPreviewGenerator(cellDescriptorType: any SettingsCellDescriptorType)
        -> SettingsCellPreview {
        guard let selfUser = ZMUser.selfUser() else {
            assertionFailure("ZMUser.selfUser() is nil")
            return .none
        }
        return SettingsCellPreview.color((selfUser.accentColor ?? .default).uiColor)
    }

    private func colorElementPresentationAction(sender: UIView) -> UIViewController {
        guard
            let selfUser = ZMUser.selfUser(),
            let userSession = ZMUserSession.shared()
        else {
            assertionFailure("misses prerequisites to present color elements!")
            return UIViewController()
        }

        return AccentColorPickerController(
            selfUser: selfUser,
            userSession: userSession
        )
    }

    func readReceiptsEnabledElement() -> any SettingsCellDescriptorType {

        SettingsPropertyToggleCellDescriptor(
            settingsProperty:
            settingsPropertyFactory.property(.readReceiptsEnabled),
            inverse: false,
            identifier: "ReadReceiptsSwitch"
        )
    }

    func encryptMessagesAtRestElement() -> any SettingsCellDescriptorType {
        SettingsPropertyToggleCellDescriptor(settingsProperty: settingsPropertyFactory.property(.encryptMessagesAtRest))
    }

    private var backupImportExportBuilder: BackupImportExportBuilder {

        // force-unwrapping should be fine, since we should have a session manager and an active user session here
        let sessionManager = SessionManager.shared!
        let importBackupUseCase = sessionManager.importBackupUseCase!

        return BackupImportExportBuilder(
            backupPasswordValidator: BackupPasswordValidator(),
            exportBackupUseCase: CreateBackupUseCase(sessionManager: sessionManager),
            importBackupUseCase: .adapter(importBackupUseCase),
            cleanUpBackupsUseCaseProtocol: CleanUpBackupsUseCase(sessionManager: sessionManager)
        )
    }

    @MainActor
    func backUpElement() -> any SettingsCellDescriptorType {
        SettingsExternalScreenCellDescriptor(
            title: L10n.Localizable.Self.Settings.HistoryBackup.title,
            isDestructive: false,
            presentationStyle: .navigation,
            presentationAction: {
                guard let selfUser = ZMUser.selfUser() else {
                    assertionFailure("ZMUser.selfUser() is nil")
                    return .none
                }
                if selfUser.hasValidEmail || selfUser.usesCompanyLogin {
                    let backupRestoreController = backupImportExportBuilder.build()
//                    let viewModel = BackupRestoreViewModel( // TODO: delete, use `backupRestoreBuilder`
//                        backupSource: BackupSource(),
//                        restoreSource: RestoreSource(),
//                        backupResultHandler: BackupResultHandler(
//                            onSuccess: presentShareSheet,
//                            onFailure: presentExportBackupErrorAlert
//                        ),
//                        restoreBackupResultHandler: RestoreBackupResultHandler(
//                            onSuccess: presentOnSuccessAlert,
//                            onConfirmation: presentConfirmationAlert,
//                            onFailure: presentRestoreBackupErrorAlert
//                        )
//                    )
//                    let backupRestoreController = BackupRestoreViewController(
//                        viewModel: viewModel,
//                        backupPasswordValidator: BackupPasswordValidator()
//                    )
                    backupRestoreController.setupNavigationBarTitle(L10n.Localizable.Self.Settings.HistoryBackup.title)
                    return backupRestoreController
                } else {
                    let alert = UIAlertController(
                        title: L10n.Localizable.Self.Settings.HistoryBackup.SetEmail.title,
                        message: L10n.Localizable.Self.Settings.HistoryBackup.SetEmail.message,
                        preferredStyle: .alert
                    )
                    let actionCancel = UIAlertAction(title: L10n.Localizable.General.ok, style: .cancel, handler: nil)
                    alert.addAction(actionCancel)

                    guard let controller = UIApplication.shared.topmostViewController(onlyFullScreen: false)
                    else { return nil }

                    controller.present(alert, animated: true)
                    return nil
                }
            }
        )
    }

    func dateUsagePermissionsElement(isPublicDomain: Bool) -> any SettingsCellDescriptorType {
        dataUsagePermissionsGroup(isPublicDomain: isPublicDomain)
    }

    func resetPasswordElement() -> any SettingsCellDescriptorType {
        let resetPasswordTitle = L10n.Localizable.Self.Settings.PasswordResetMenu.title
        return SettingsExternalScreenCellDescriptor(
            title: resetPasswordTitle,
            isDestructive: false,
            presentationStyle: .modal,
            presentationAction: {
                URL.wr_passwordReset.open()
                return nil
            },
            previewGenerator: .none
        )
    }

    func deleteAccountButtonElement() -> any SettingsCellDescriptorType {
        let presentationAction: () -> UIViewController = {
            let alert = UIAlertController(
                title: L10n.Localizable.Self.Settings.AccountDetails.DeleteAccount.Alert.title,
                message: L10n.Localizable.Self.Settings.AccountDetails.DeleteAccount.Alert.message,
                preferredStyle: .alert
            )
            let actionCancel = UIAlertAction(title: L10n.Localizable.General.cancel, style: .cancel, handler: nil)
            alert.addAction(actionCancel)
            let actionDelete = UIAlertAction(title: L10n.Localizable.General.ok, style: .destructive) { _ in
                ZMUserSession.shared()?.enqueue {
                    ZMUserSession.shared()?.initiateUserDeletion()
                }
            }
            alert.addAction(actionDelete)
            return alert
        }

        return SettingsExternalScreenCellDescriptor(
            title: L10n.Localizable.Self.Settings.AccountDetails.DeleteAccount.title,
            isDestructive: true,
            presentationStyle: .modal,
            presentationAction: presentationAction
        )
    }

    func signOutElement() -> any SettingsCellDescriptorType {
        SettingsSignOutCellDescriptor()
    }

}

// MARK: - Backup action handler

// TODO: remove, present alert and file picker with BackupRestoreViewController
extension SettingsCellDescriptorFactory {

    private func presentErrorAlert(errorMessage: String) {
        guard let controller = UIApplication.shared.topmostViewController(onlyFullScreen: false) else {
            return
        }

        let alert = UIAlertController(
            title: L10n.Localizable.General.failure,
            message: errorMessage,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(
            title: L10n.Localizable.General.ok,
            style: .cancel
        ))

        controller.present(alert, animated: true)
    }

    private func presentExportBackupErrorAlert() {
        presentErrorAlert(errorMessage: L10n.Localizable.ExportBackup.Failed.message)
    }

    private func presentRestoreBackupErrorAlert() {
        presentErrorAlert(errorMessage: L10n.Localizable.RestoreBackup.Failed.message)
    }

    private func presentShareSheet(with url: URL, completion: @escaping Completion) {
        guard let controller = UIApplication.shared.topmostViewController(onlyFullScreen: false) else {
            return
        }

        let activityController = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        activityController.completionWithItemsHandler = { _, _, _, _ in
            completion()
        }
        controller.present(activityController, animated: true)
    }

    private func presentConfirmationAlert(completion: @escaping Completion) {
        guard let controller = UIApplication.shared.topmostViewController(onlyFullScreen: false) else {
            return
        }

        let alert = UIAlertController(
            title: L10n.Localizable.RestoreBackup.Confirmation.title,
            message: L10n.Localizable.RestoreBackup.Confirmation.description,
            preferredStyle: .alert
        )

        alert.addAction(
            UIAlertAction(
                title: L10n.Localizable.RestoreBackup.Confirmation.cancelButton,
                style: .cancel
            )
        )
        alert.addAction(
            UIAlertAction(
                title: L10n.Localizable.RestoreBackup.Confirmation.overrideButton, // TODO: overwrite?
                style: .default,
                handler: { _ in completion() }
            )
        )

        controller.present(alert, animated: true)
    }

    private func presentOnSuccessAlert() {
        guard let controller = UIApplication.shared.topmostViewController(onlyFullScreen: false) else {
            return
        }

        let alert = UIAlertController(
            title: L10n.Localizable.RestoreBackup.SuccessAlert.title,
            message: L10n.Localizable.RestoreBackup.SuccessAlert.description,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(
            title: L10n.Localizable.General.ok,
            style: .cancel
        ))

        controller.present(alert, animated: true)
    }

}
