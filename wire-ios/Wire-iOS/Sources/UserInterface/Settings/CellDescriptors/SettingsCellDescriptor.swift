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

import UIKit
import WireCommonComponents
import WireDesign
import WireSettingsUI

// * Top-level structure overview:
// * Settings group (screen) @c SettingsGroupCellDescriptorType contains
// * |--Settings section (table view section) @c SettingsSectionDescriptorType
// * |   |--Cell @c SettingsCellDescriptorType
// * |   |--Subgroup @c SettingsGroupCellDescriptorType
// * |   |  \..
// * |   \..
// * \...
// *

// MARK: - Protocols

/// @abstract Top-level protocol for model object of settings. Describes the way cell should be created or how the value
/// should be updated from the cell.
protocol SettingsCellDescriptorType: AnyObject {

    static var cellType: SettingsTableCellProtocol.Type { get }
    typealias PresentationStyle = SettingsCellDescriptorPresentationStyle
    typealias AccessoryView = SettingsCellDescriptorAccessoryView

    var visible: Bool { get }
    var title: String { get }
    var identifier: String? { get }
    var group: (any SettingsGroupCellDescriptorType)? { get }
    var copiableText: String? { get }

    /// If non-nil the item is a top-level item of the main settings menu.
    /// For presenting the content the main coordinator is called.
    var settingsTopLevelMenuItem: SettingsTopLevelMenuItem? { get }

    func select(_ value: SettingsPropertyValue, sender: UIView)
    func featureCell(_: SettingsCellType)
}

extension SettingsCellDescriptorType {
    var copiableText: String? {
        nil
    }

    var settingsTopLevelMenuItem: SettingsTopLevelMenuItem? {
        .none
    }
}

func == (left: SettingsCellDescriptorType, right: SettingsCellDescriptorType) -> Bool {
    if let leftID = left.identifier,
       let rightID = right.identifier {
        leftID == rightID
    } else {
        left == right
    }
}

typealias PreviewGeneratorType = (SettingsCellDescriptorType) -> SettingsCellPreview

protocol SettingsGroupCellDescriptorType: SettingsCellDescriptorType {
    var viewController: UIViewController? { get set }
}

protocol SettingsSectionDescriptorType: AnyObject {
    var cellDescriptors: [SettingsCellDescriptorType] { get }
    var visibleCellDescriptors: [SettingsCellDescriptorType] { get }
    var header: String? { get }
    var footer: String? { get }
    var visible: Bool { get }
}

extension SettingsSectionDescriptorType {
    func allCellDescriptors() -> [SettingsCellDescriptorType] {
        cellDescriptors
    }
}

enum InternalScreenStyle {
    case plain
    case grouped
}

protocol SettingsInternalGroupCellDescriptorType: SettingsGroupCellDescriptorType {
    var items: [SettingsSectionDescriptorType] { get }
    var visibleItems: [SettingsSectionDescriptorType] { get }
    var style: InternalScreenStyle { get }
    var accessibilityBackButtonText: String { get }
}

extension SettingsInternalGroupCellDescriptorType {

    func allCellDescriptors() -> [SettingsCellDescriptorType] {
        items.flatMap { section in
            section.allCellDescriptors()
        }
    }
}

protocol SettingsPropertyCellDescriptorType: SettingsCellDescriptorType {
    var settingsProperty: SettingsProperty { get }
}

protocol SettingsControllerGeneratorType {
    func generateViewController() -> UIViewController?
}

// MARK: - Classes

class SettingsSectionDescriptor: SettingsSectionDescriptorType {
    let cellDescriptors: [SettingsCellDescriptorType]
    var visibleCellDescriptors: [SettingsCellDescriptorType] {
        cellDescriptors.filter(\.visible)
    }

    var visible: Bool {
        visibilityAction?(self) ?? true
    }

    let visibilityAction: ((SettingsSectionDescriptorType) -> (Bool))?

    var header: String? {
        headerGenerator()
    }

    var footer: String? {
        footerGenerator()
    }

    let headerGenerator: () -> String?
    let footerGenerator: () -> String?

    convenience init(
        cellDescriptors: [SettingsCellDescriptorType],
        header: String? = .none,
        footer: String? = .none,
        visibilityAction: ((SettingsSectionDescriptorType) -> (Bool))? = .none
    ) {
        self.init(
            cellDescriptors: cellDescriptors,
            headerGenerator: { header },
            footerGenerator: { footer },
            visibilityAction: visibilityAction
        )
    }

    init(
        cellDescriptors: [SettingsCellDescriptorType],
        headerGenerator: @escaping () -> String?,
        footerGenerator: @escaping () -> String?,
        visibilityAction: ((SettingsSectionDescriptorType) -> (Bool))? = .none
    ) {
        self.cellDescriptors = cellDescriptors
        self.headerGenerator = headerGenerator
        self.footerGenerator = footerGenerator
        self.visibilityAction = visibilityAction
    }
}

final class SettingsGroupCellDescriptor: SettingsInternalGroupCellDescriptorType, SettingsControllerGeneratorType {

    static let cellType: SettingsTableCellProtocol.Type = SettingsTableCell.self

    typealias Cell = SettingsTableCell

    var visible: Bool = true
    let title: String
    let accessibilityBackButtonText: String
    let style: InternalScreenStyle
    let items: [SettingsSectionDescriptorType]
    let identifier: String?
    let icon: StyleKitIcon?

    let previewGenerator: PreviewGeneratorType?

    weak var group: (any SettingsGroupCellDescriptorType)?

    var visibleItems: [SettingsSectionDescriptorType] {
        items.filter(\.visible)
    }

    let settingsTopLevelMenuItem: SettingsTopLevelMenuItem?
    let settingsCoordinator: AnySettingsCoordinator

    weak var viewController: UIViewController?

    init(
        items: [SettingsSectionDescriptorType],
        title: String,
        style: InternalScreenStyle = .grouped,
        identifier: String? = .none,
        previewGenerator: PreviewGeneratorType? = .none,
        icon: StyleKitIcon? = nil,
        accessibilityBackButtonText: String,
        settingsTopLevelMenuItem: SettingsTopLevelMenuItem?,
        settingsCoordinator: AnySettingsCoordinator
    ) {
        self.items = items
        self.title = title
        self.style = style
        self.identifier = identifier
        self.previewGenerator = previewGenerator
        self.icon = icon
        self.accessibilityBackButtonText = accessibilityBackButtonText
        self.settingsTopLevelMenuItem = settingsTopLevelMenuItem
        self.settingsCoordinator = settingsCoordinator
    }

    func featureCell(_ cell: SettingsCellType) {
        cell.titleText = title
        if let previewGenerator {
            let preview = previewGenerator(self)
            cell.preview = preview
        }
        cell.icon = icon
        if let cell = cell as? SettingsTableCell {
            cell.showDisclosureIndicatorAccessoryView()
            cell.accessibilityIdentifier = settingsTopLevelMenuItem?.accessibilityID
            cell.accessibilityTraits = .button
        }
    }

    func select(_ value: SettingsPropertyValue, sender: UIView) {
        if let navigationController = viewController?.navigationController,
           let controllerToPush = generateViewController() {
            controllerToPush.hidesBottomBarWhenPushed = true
            navigationController.pushViewController(controllerToPush, animated: true)
        }
    }

    func generateViewController() -> UIViewController? {
        SettingsTableViewController(group: self, settingsCoordinator: settingsCoordinator)
    }
}

// MARK: - Helpers

extension SettingsPropertyName {

    var settingsPropertyLabelText: String {
        typealias Settings = L10n.Localizable.Self.Settings
        typealias Notifications = Settings.Notifications
        typealias Account = Settings.AccountSection
        typealias SoundMenu = Settings.SoundMenu
        typealias LinkOptions = Settings.LinkOptions

        switch self {
        case .chatHeadsDisabled:
            return Notifications.ChatAlerts.toggle
        case .notificationContentVisible:
            return Notifications.PushNotification.toogle
        case .disableMarkdown:
            return "Disable Markdown support"
        case .darkMode:
            return Settings.AccountPictureGroup.theme
        // Profile
        case .profileName:
            return Account.Name.title
        case .handle:
            return Account.Handle.title
        case .email:
            return Account.Email.title
        case .team:
            return Account.Team.title
        case .domain:
            return Account.Domain.title
        // AVS
        case .soundAlerts:
            return SoundMenu.title
        case .messageSoundName:
            return SoundMenu.Message.title
        case .callSoundName:
            return SoundMenu.Ringtone.title
        case .pingSoundName:
            return SoundMenu.Ping.title
        case .accentColor:
            return Settings.AccountPictureGroup.color
        case .conversationBackground:
            return Settings.AccountPictureGroup.Background.title
        case .disableSendButton:
            return Settings.PopularDemand.SendButton.title
        case .disableCallKit:
            return Settings.Callkit.caption
        case .muteIncomingCallsWhileInACall:
            return Settings.MuteOtherCall.caption
        case .mapsOpeningOption:
            return LinkOptions.Maps.title
        case .browserOpeningOption:
            return LinkOptions.Browser.title
        case .enableBatchCollections:
            return "Use AssetCollectionBatched"
        case .lockApp:
            return Settings.PrivacySecurity.lockApp
        case .callingConstantBitRate:
            return Settings.Vbr.title
        case .disableLinkPreviews:
            return Settings.PrivacySecurity.DisableLinkPreviews.title
        case .collapseOwnMessages:
            return Settings.PrivacySecurity.CollapseOwnMessages.title
        // personal information - Analytics
        case .disableAnalyticsSharing:
            return Settings.PrivacyAnalytics.title
        case .readReceiptsEnabled:
            return Settings.EnableReadReceipts.title
        case .encryptMessagesAtRest:
            return Settings.EncryptMessagesAtRest.title
        }
    }
}
