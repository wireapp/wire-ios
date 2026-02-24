//
// Wire
// Copyright (C) 2026 Wire Swiss GmbH
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
import WireBackup
import WireCommonComponents
import WireDataModel
import WireDesign
import WireDomain
import WireFoundation
import WireLogging
import WireNetwork
import WireSettingsUI
import WireSyncEngine
import WireUtilitiesPackage

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
        isAnalyticsTrackingAvailable: Bool,
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
            sections.append(personalInformationSection(isAnalyticsTrackingAvailable: isAnalyticsTrackingAvailable))
        #endif

        sections.append(conversationsSection())

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
            settingsCoordinator: settingsCoordinator,
            userSession: userSession
        )
    }

    // MARK: - Sections

    func infoSection(
        userSession: UserSession,
        useTypeIntrinsicSizeTableView: Bool
    ) -> SettingsSectionDescriptorType {
        var cellDescriptors: [SettingsCellDescriptorType] = []
        cellDescriptors = [
            nameElement(enabled: userRightInterfaceType.selfUserIsPermitted(to: .editName)),
            handleElement(
                enabled: userRightInterfaceType.selfUserIsPermitted(to: .editHandle),
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

        if userSession.resolvedBackendMetadata.isFederationEnabled {
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
            cellDescriptors: [
                pictureElement(),
                colorElement(),
                conversationBackgroundEnabledElement()
            ],
            header: L10n.Localizable.Self.Settings.AccountAppearanceGroup.title,
            footer: L10n.Localizable.Self.Settings.AccountAppearanceGroup.footer
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

    func personalInformationSection(isAnalyticsTrackingAvailable: Bool) -> SettingsSectionDescriptorType {
        SettingsSectionDescriptor(
            cellDescriptors: [dateUsagePermissionsElement(isAnalyticsTrackingAvailable: isAnalyticsTrackingAvailable)],
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
                accessoryView: .none
            )
        } else {
            textValueCellDescriptor(propertyName: .email, enabled: enabled)
        }
    }

    func handleElement(
        enabled: Bool = true,
        useTypeIntrinsicSizeTableView: Bool
    ) -> SettingsCellDescriptorType {
        typealias AccountSection = L10n.Localizable.Self.Settings.AccountSection
        if enabled {
            let presentation = { [userSession] in
                ChangeHandleViewController(
                    useTypeIntrinsicSizeTableView: useTypeIntrinsicSizeTableView,
                    settingsCoordinator: settingsCoordinator,
                    isFederationEnabled: isFederationEnabled,
                    userSession: userSession
                )
            }

            if let selfUser = ZMUser.selfUser(), selfUser.handle != nil {

                let preview: PreviewGeneratorType = { _ in
                    guard let handleDisplayString = selfUser.handleDisplayString(withDomain: isFederationEnabled) else {
                        return .none
                    }
                    return .text(handleDisplayString)
                }

                let copiableText = selfUser.handleDisplayString(withDomain: isFederationEnabled)

                return SettingsExternalScreenCellDescriptor(
                    title: AccountSection.Handle.title,
                    isDestructive: false,
                    presentationStyle: .navigation,
                    presentationAction: presentation,
                    previewGenerator: preview,
                    accessoryView: .none,
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
        let profileImagePicker = ProfileImagePickerManager(userSession: userSession)
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

    func conversationBackgroundEnabledElement() -> any SettingsCellDescriptorType {

        SettingsPropertyToggleCellDescriptor(
            settingsProperty:
            settingsPropertyFactory.property(.conversationBackground),
            inverse: false,
            identifier: "ConversationBackgroundSwitch"
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
        guard let selfUser = ZMUser.selfUser() else {
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
        let selfUser = ZMUser.selfUser()!
        let selfUserID = selfUser.qualifiedID!
        let backupLocalStore = BackupLocalStore(
            contextProvider: sessionManager.activeUserSession!.contextProvider
        )
        let userSession = sessionManager.activeUserSession!
        let importBackupUseCaseFactory = ImportBackupUseCaseFactory { url in
            ImportBackupUseCase(
                url: url,
                selfUserID: .init(selfUserID),
                backupLocalStore: backupLocalStore,
                fileUnarchiver: ZIPFoundationFileUnarchiver(),
                syncTrigger: {
                    Task {
                        await userSession.triggerResourcesSync()
                    }
                },
                logger: WireLogger.backupImport
            )
        } legacyImportBackupUseCase: { url in
            sessionManager.importLegacyBackupUseCase(url: url)!
        }
        let createBackupUseCase: CreateBackupUseCaseProtocol = if DeveloperFlag.createLegacyBackups.isOn {
            CreateLegacyBackupUseCase(sessionManager: sessionManager)
        } else {
            CreateBackupUseCase(
                selfUserID: .init(selfUserID),
                backupLocalStore: backupLocalStore,
                fileArchiver: ZIPFoundationFileArchiver(),
                logger: WireLogger.backupExport
            )
        }

        return BackupImportExportBuilder(
            backupPasswordValidator: BackupPasswordValidator(),
            createBackupUseCase: createBackupUseCase,
            importBackupUseCaseFactory: importBackupUseCaseFactory,
            cleanUpBackupsUseCase: CleanUpBackupsUseCase(sessionManager: sessionManager),
            exportBackupLogger: WireLogger.backupExport,
            importBackupLogger: WireLogger.backupImport,
            wireAccentColor: selfUser.accentColor ?? .default,
            isContextMenuAllowed: SecurityFlags.clipboard.isEnabled
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

    func dateUsagePermissionsElement(isAnalyticsTrackingAvailable: Bool) -> any SettingsCellDescriptorType {
        dataUsagePermissionsGroup(isAnalyticsTrackingAvailable: isAnalyticsTrackingAvailable)
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
        let presentationAction: () -> UIViewController = { [userSession] in
            let alert = UIAlertController(
                title: L10n.Localizable.Self.Settings.AccountDetails.DeleteAccount.Alert.title,
                message: L10n.Localizable.Self.Settings.AccountDetails.DeleteAccount.Alert.message,
                preferredStyle: .alert
            )
            let actionCancel = UIAlertAction(title: L10n.Localizable.General.cancel, style: .cancel, handler: nil)
            alert.addAction(actionCancel)
            let actionDelete = UIAlertAction(title: L10n.Localizable.General.ok, style: .destructive) { _ in
                guard let session = userSession as? ZMUserSession else { return }
                session.enqueue {
                    session.initiateUserDeletion()
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

// MARK: -

private extension ConversationProtobufMessageProcessor {

    init(
        context: NSManagedObjectContext,
        localDomain: String?,
        isFederationEnabled: Bool
    ) {
        let messageLocalStore = MessageLocalStore(context: context)
        self.init(
            messageLocalStore: messageLocalStore,
            conversationLocalStore: ConversationLocalStore(
                context: context,
                mlsService: context.performAndWait { context.mlsService },
                messageLocalStore: messageLocalStore,
                localDomain: localDomain,
                isFederationEnabled: isFederationEnabled
            ),
            userLocalStore: UserLocalStore(
                context: context,
                messageLocalStore: messageLocalStore
            )
        )
    }

}
