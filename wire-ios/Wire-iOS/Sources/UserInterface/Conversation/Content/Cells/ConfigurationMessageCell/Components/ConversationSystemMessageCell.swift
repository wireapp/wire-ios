//
// Wire
// Copyright (C) 2018 Wire Swiss GmbH
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

import Down
import UIKit
import WireCommonComponents
import WireDataModel
import WireSyncEngine
import WireUtilities

// MARK: Properties

private typealias IconColors = SemanticColors.Icon
private typealias LabelColors = SemanticColors.Label

// MARK: - ConversationSystemMessageCell

class ConversationSystemMessageCell: ConversationIconBasedCell, ConversationMessageCell {

    struct Configuration: Equatable {
        let icon: UIImage?
        let attributedText: NSAttributedString?
        let showLine: Bool
    }

    // MARK: - Configuration

    func configure(with object: Configuration, animated: Bool) {
        lineView.isHidden = !object.showLine
        imageView.image = object.icon
        attributedText = object.attributedText
    }

}

// MARK: - Factory

final class ConversationSystemMessageCellDescription {

    static func cells(for message: ZMConversationMessage,
                      isCollapsed: Bool = true,
                      buttonAction: Completion? = nil) -> [AnyConversationMessageCellDescription] {
        guard let systemMessageData = message.systemMessageData,
              let sender = message.senderUser,
              let conversation = message.conversationLike
        else {
            preconditionFailure("Invalid system message")
        }

        switch systemMessageData.systemMessageType {
        case .connectionRequest, .connectionUpdate, .usingNewDevice, .reactivatedDevice:
            break // Deprecated

        case .conversationNameChanged:
            guard let newName = systemMessageData.text else {
                fallthrough
            }

            let renamedCell = ConversationRenamedSystemMessageCellDescription(message: message, data: systemMessageData, sender: sender, newName: newName)
            return [AnyConversationMessageCellDescription(renamedCell)]

        case .missedCall:
            let missedCallCell = ConversationCallSystemMessageCellDescription(message: message, data: systemMessageData, missed: true)
            return [AnyConversationMessageCellDescription(missedCallCell)]

        case .performedCall:
            let callCell = ConversationCallSystemMessageCellDescription(message: message, data: systemMessageData, missed: false)
            return [AnyConversationMessageCellDescription(callCell)]

        case .messageDeletedForEveryone:
            let senderCell = ConversationSenderMessageCellDescription(sender: sender, message: message, timestamp: nil)
            return [AnyConversationMessageCellDescription(senderCell)]

        case .messageTimerUpdate:
            guard let timer = systemMessageData.messageTimer else {
                fallthrough
            }

            let timerCell = ConversationMessageTimerCellDescription(message: message, data: systemMessageData, timer: timer, sender: sender)
            return [AnyConversationMessageCellDescription(timerCell)]

        case .conversationIsSecure:
            let shieldCell = ConversationVerifiedSystemMessageSectionDescription()
            return [AnyConversationMessageCellDescription(shieldCell)]

        case .sessionReset:
            let sessionResetCell = ConversationSessionResetSystemMessageCellDescription(message: message, data: systemMessageData, sender: sender)
            return [AnyConversationMessageCellDescription(sessionResetCell)]

        case .decryptionFailed, .decryptionFailedResolved, .decryptionFailed_RemoteIdentityChanged:
            let decryptionCell = ConversationCannotDecryptSystemMessageCellDescription(message: message, data: systemMessageData, sender: sender)
            return [AnyConversationMessageCellDescription(decryptionCell)]

        case .newClient:
            let newClientCell = ConversationNewDeviceSystemMessageCellDescription(message: message, systemMessageData: systemMessageData, conversation: conversation as! ZMConversation)
            return [AnyConversationMessageCellDescription(newClientCell)]

        case .ignoredClient:
            guard let user = systemMessageData.userTypes.first as? UserType else { fallthrough }
            let ignoredClientCell = ConversationIgnoredDeviceSystemMessageCellDescription(message: message, data: systemMessageData, user: user)
            return [AnyConversationMessageCellDescription(ignoredClientCell)]

        case .potentialGap:
            let missingMessagesCell = ConversationMissingMessagesSystemMessageCellDescription(message: message, data: systemMessageData)
            return [AnyConversationMessageCellDescription(missingMessagesCell)]

        case .participantsAdded, .participantsRemoved, .teamMemberLeave:
            let participantsChangedCell = ConversationParticipantsChangedSystemMessageCellDescription(message: message, data: systemMessageData)
            return [AnyConversationMessageCellDescription(participantsChangedCell)]

        case .readReceiptsEnabled,
                .readReceiptsDisabled,
                .readReceiptsOn:
            let cell = ConversationReadReceiptSettingChangedCellDescription(sender: sender,
                                                                            systemMessageType: systemMessageData.systemMessageType)
            return [AnyConversationMessageCellDescription(cell)]

        case .legalHoldEnabled, .legalHoldDisabled:
            let cell = ConversationLegalHoldCellDescription(systemMessageType: systemMessageData.systemMessageType, conversation: conversation as! ZMConversation)
            return [AnyConversationMessageCellDescription(cell)]

        case .newConversation:
            var cells: [AnyConversationMessageCellDescription] = []
            let startedConversationCell = ConversationStartedSystemMessageCellDescription(message: message, data: systemMessageData)
            cells.append(AnyConversationMessageCellDescription(startedConversationCell))

            // Only display invite user cell for team members
            if let user = SelfUser.provider?.providedSelfUser,
               user.isTeamMember,
               conversation.selfCanAddUsers,
               conversation.isOpenGroup {
                cells.append(AnyConversationMessageCellDescription(GuestsAllowedCellDescription()))
            }
            if conversation.isOpenGroup {
                let encryptionInfoCell = ConversationEncryptionInfoDescription()
                cells.append(AnyConversationMessageCellDescription(encryptionInfoCell))
            }

            return cells

        case .failedToAddParticipants:
            if let users = Array(systemMessageData.userTypes) as? [UserType], let buttonAction = buttonAction {
                let cellDescription = ConversationFailedToAddParticipantsCellDescription(failedUsers: users,
                                                                                         isCollapsed: isCollapsed,
                                                                                         buttonAction: buttonAction)
                return [AnyConversationMessageCellDescription(cellDescription)]
            }

        case .domainsStoppedFederating:
            let domainsStoppedFederatingCell = DomainsStoppedFederatingCellDescription(systemMessageData: systemMessageData)
            return [AnyConversationMessageCellDescription(domainsStoppedFederatingCell)]

        case .mlsMigrationFinalized, .mlsMigrationJoinAfterwards, .mlsMigrationOngoingCall, .mlsMigrationStarted, .mlsMigrationUpdateVersion, .mlsMigrationPotentialGap:
            let description = MLSMigrationCellDescription(messageType: systemMessageData.systemMessageType)
            return [AnyConversationMessageCellDescription(description)]

        case .invalid:
            let unknownMessage = UnknownMessageCellDescription()
            return [AnyConversationMessageCellDescription(unknownMessage)]
        }

        return []
    }
}

private extension ConversationLike {
    var isOpenGroup: Bool {
        return conversationType == .group && allowGuests
    }

    var selfCanAddUsers: Bool {
        guard let user = SelfUser.provider?.providedSelfUser else {
            assertionFailure("expected available 'user'!")
            return false
        }
        return user.canAddUser(to: self)
    }
}

// MARK: - Descriptions

final class ConversationStartedSystemMessageCellDescription: NSObject, ConversationMessageCellDescription {

    typealias View = ConversationStartedSystemMessageCell
    let configuration: View.Configuration

    var message: ZMConversationMessage?
    weak var delegate: ConversationMessageCellDelegate?
    weak var actionController: ConversationMessageActionController?

    var showEphemeralTimer: Bool = false
    var topMargin: Float = 0

    let isFullWidth: Bool = true
    let supportsActions: Bool = false
    let containsHighlightableContent: Bool = false

    let accessibilityIdentifier: String? = nil
    var conversationObserverToken: Any?

    init(message: ZMConversationMessage, data: ZMSystemMessageData) {
        let color = LabelColors.textDefault
        let iconColor = IconColors.backgroundDefault
        let model = ParticipantsCellViewModel(font: .mediumFont, largeFont: .largeSemiboldFont, textColor: color, iconColor: iconColor, message: message)

        actionController = nil
        configuration =  View.Configuration(title: model.attributedHeading(),
                                            message: model.attributedTitle() ?? NSAttributedString(string: ""),
                                            selectedUsers: model.selectedUsers,
                                            icon: model.image())
        super.init()

        accessibilityLabel = configuration.message.string
    }

}

class ConversationIgnoredDeviceSystemMessageCellDescription: ConversationMessageCellDescription {

    typealias View = ConversationNewDeviceSystemMessageCell
    let configuration: View.Configuration

    var message: ZMConversationMessage?
    weak var delegate: ConversationMessageCellDelegate?
    weak var actionController: ConversationMessageActionController?

    var showEphemeralTimer: Bool = false
    var topMargin: Float = 0

    let isFullWidth: Bool = true
    let supportsActions: Bool = false
    let containsHighlightableContent: Bool = false

    let accessibilityIdentifier: String? = nil
    let accessibilityLabel: String?

    init(message: ZMConversationMessage, data: ZMSystemMessageData, user: UserType) {
        let title = ConversationIgnoredDeviceSystemMessageCellDescription.makeAttributedString(systemMessage: data, user: user)

        configuration = View.Configuration(attributedText: title, icon: WireStyleKit.imageOfShieldnotverified, linkTarget: .user(user))
        accessibilityLabel = configuration.attributedText?.string
        actionController = nil
    }

    private static func makeAttributedString(systemMessage: ZMSystemMessageData, user: UserType) -> NSAttributedString {
        let string: String
        let link = View.userClientURL.absoluteString

        if user.isSelfUser == true {
            string = L10n.Localizable.Content.System.unverifiedSelfDevices(link)
        } else {
            string = L10n.Localizable.Content.System.unverifiedOtherDevices(user.name ?? "", link)
        }

        return .markdown(from: string, style: .systemMessage)
    }

}

class ConversationCannotDecryptSystemMessageCellDescription: ConversationMessageCellDescription {
    typealias View = ConversationCannotDecryptSystemMessageCell
    let configuration: View.Configuration

    static fileprivate let resetSessionURL: URL = URL(string: "action://reset-session")!

    var message: ZMConversationMessage?
    weak var delegate: ConversationMessageCellDelegate?
    weak var actionController: ConversationMessageActionController?

    var showEphemeralTimer: Bool = false
    var topMargin: Float = 0

    let isFullWidth: Bool = true
    let supportsActions: Bool = false
    let containsHighlightableContent: Bool = false

    let accessibilityIdentifier: String? = nil
    let accessibilityLabel: String?

    init(message: ZMConversationMessage, data: ZMSystemMessageData, sender: UserType) {
        let icon: UIImage
        if data.systemMessageType == .decryptionFailedResolved {
            icon = StyleKitIcon.checkmark.makeImage(size: 16, color: IconColors.foregroundCheckMarkInSystemMessage)
        } else {
            icon = StyleKitIcon.exclamationMark.makeImage(size: 16, color: IconColors.foregroundExclamationMarkInSystemMessage)
        }

        let title = ConversationCannotDecryptSystemMessageCellDescription
            .makeAttributedString(
                systemMessage: data,
                sender: sender
            )

        configuration = View.Configuration(icon: icon,
                                           attributedText: title,
                                           showLine: false)
        accessibilityLabel = title.string
        actionController = nil
    }

    func isConfigurationEqual(with other: Any) -> Bool {
        guard let otherDescription = other as? ConversationCannotDecryptSystemMessageCellDescription else {
            return false
        }

        return configuration.attributedText == otherDescription.configuration.attributedText
    }

    // MARK: - Localization

    private static let BaseLocalizationString = "content.system.cannot_decrypt"
    private static let IdentityString = ".identity"

    private static func makeAttributedString(systemMessage: ZMSystemMessageData, sender: UserType) -> NSAttributedString {

        let messageString = self.messageString(systemMessage.systemMessageType, sender: sender)
        let resetSessionString = self.resetSessionString()
        let errorDetailsString = self.errorDetailsString(
            errorCode: systemMessage.decryptionErrorCode?.intValue ?? 0,
            clientIdentifier: (systemMessage.senderClientID ?? "N/A"))

        var components: [NSAttributedString]

        switch systemMessage.systemMessageType {
        case .decryptionFailed:
            components = [
                messageString
            ]

            if systemMessage.isDecryptionErrorRecoverable {
                components.append(resetSessionString)
            }
        case .decryptionFailedResolved:
            components = [
                messageString,
                errorDetailsString
            ]
        case .decryptionFailed_RemoteIdentityChanged:
            components = [
                messageString
            ]
        default:
            fatal("Incorrect cell configuration")
        }

        return components.joined(separator: NSAttributedString(string: "\n"))
    }

    private static func localizationKey(_ systemMessageType: ZMSystemMessageType) -> String {
        let localizationKey: String
        switch systemMessageType {
        case .decryptionFailed:
            localizationKey = BaseLocalizationString
        case .decryptionFailedResolved:
            localizationKey = BaseLocalizationString + "_resolved"
        case .decryptionFailed_RemoteIdentityChanged:
            localizationKey = BaseLocalizationString + "_identity_changed"
        default:
            fatal("Incorrect cell configuration")
        }

        return localizationKey
    }

    private static func messageString(_ systemMessageType: ZMSystemMessageType, sender: UserType) -> NSAttributedString {

        let name = sender.name ?? ""
        var localizationKey = self.localizationKey(systemMessageType)

        if sender.isSelfUser {
            localizationKey += ".self"
        } else {
            localizationKey += ".other"
        }

        return NSMutableAttributedString.markdown(from: localizationKey.localized(args: name), style: .systemMessage)
    }

    private static func resetSessionString() -> NSAttributedString {
        let string = L10n.Localizable.Content.System.CannotDecrypt.resetSession

        return NSAttributedString(string: string.localizedUppercase,
                                  attributes: [.link: resetSessionURL,
                                               .foregroundColor: UIColor.accent(),
                                               .font: UIFont.mediumSemiboldFont])
    }

    private static func errorDetailsString(errorCode: Int, clientIdentifier: String) -> NSAttributedString {
        let string = L10n.Localizable.Content.System.CannotDecrypt.errorDetails(errorCode, clientIdentifier)

        return NSAttributedString(string: string.localizedUppercase,
                                  attributes: [.foregroundColor: LabelColors.textDefault,
                                               .font: UIFont.mediumFont])
    }

}

class ConversationEncryptionInfoDescription: ConversationMessageCellDescription {
    typealias View = ConversationWarningSystemMessageCell
    let configuration: View.Configuration

    var message: ZMConversationMessage?
    weak var delegate: ConversationMessageCellDelegate?
    weak var actionController: ConversationMessageActionController?

    var showEphemeralTimer: Bool = false
    var topMargin: Float = 26.0

    let isFullWidth: Bool = true
    let supportsActions: Bool = false
    let containsHighlightableContent: Bool = false

    let accessibilityIdentifier: String? = nil
    let accessibilityLabel: String?

    init() {
        typealias connectionView = L10n.Localizable.Conversation.ConnectionView

        configuration = View.Configuration(topText: connectionView.encryptionInfo,
                                           bottomText: connectionView.sensitiveInformationWarning)
        accessibilityLabel = "\(connectionView.encryptionInfo), \(connectionView.sensitiveInformationWarning)"
        actionController = nil
    }
}

final class ConversationFailedToAddParticipantsCellDescription: ConversationMessageCellDescription {

    typealias SystemContent = L10n.Localizable.Content.System
    typealias View = FailedUsersSystemMessageCell

    let configuration: View.Configuration

    var message: ZMConversationMessage?
    weak var delegate: ConversationMessageCellDelegate?
    weak var actionController: ConversationMessageActionController?

    var showEphemeralTimer: Bool = false
    var topMargin: Float = 26.0

    let isFullWidth: Bool = true
    let supportsActions: Bool = false
    let containsHighlightableContent: Bool = false

    let accessibilityIdentifier: String? = nil
    let accessibilityLabel: String? = nil

    init(failedUsers: [UserType], isCollapsed: Bool, buttonAction: @escaping Completion) {
        configuration = View.Configuration(
            title: ConversationFailedToAddParticipantsCellDescription.configureTitle(for: failedUsers),
            content: ConversationFailedToAddParticipantsCellDescription.configureContent(for: failedUsers),
            isCollapsed: isCollapsed,
            icon: Asset.Images.attention.image,
            buttonAction: buttonAction)
    }

    private static func configureTitle(for failedUsers: [UserType]) -> NSAttributedString? {
        guard failedUsers.count > 1 else {
            return nil
        }

        let title = SystemContent.FailedtoaddParticipants.count(failedUsers.count)
        return .markdown(from: title, style: .errorLabelStyle)
    }

    private static func configureContent(for failedUsers: [UserType]) -> NSAttributedString {
        let keyString = "content.system.failedtoadd_participants.could_not_be_added"

        let userNames = failedUsers.compactMap { $0.name }
        let userNamesJoined = userNames.joined(separator: ", ")
        let text = keyString.localized(args: userNames.count, userNamesJoined)

        let attributedText = NSAttributedString.errorSystemMessage(withText: text, andHighlighted: userNamesJoined)
        let learnMore = NSAttributedString.unreachableBackendLearnMoreLink

        return [attributedText, learnMore].joined(separator: " ".attributedString)
    }

}

final class DomainsStoppedFederatingCellDescription: ConversationMessageCellDescription {

    typealias View = ConversationSystemMessageCell
    typealias System = L10n.Localizable.Content.System
    let configuration: View.Configuration

    var showEphemeralTimer: Bool = false
    var topMargin: Float = 0

    let isFullWidth: Bool = true
    let supportsActions: Bool = false
    let containsHighlightableContent: Bool = false

    let accessibilityIdentifier: String? = nil
    let accessibilityLabel: String?

    var message: WireDataModel.ZMConversationMessage?
    var delegate: ConversationMessageCellDelegate?
    var actionController: ConversationMessageActionController?

    init(systemMessageData: ZMSystemMessageData) {
        let icon = Asset.Images.attention.image.withTintColor(SemanticColors.Icon.backgroundDefault)
        let content = DomainsStoppedFederatingCellDescription.makeAttributedString(for: systemMessageData)
        configuration = View.Configuration(icon: icon, attributedText: content, showLine: false)

        accessibilityLabel = content?.string
    }

    private static func makeAttributedString(for systemMessageData: ZMSystemMessageData) -> NSAttributedString? {
        typealias BackendsStopFederating = L10n.Localizable.Content.System.BackendsStopFederating

        guard let domains = systemMessageData.domains,
              domains.count == 2 else {
            return nil
        }

        var text: String
        if domains.hasSelfDomain, let user = SelfUser.provider?.providedSelfUser {
            let withoutSelfDomain = domains.filter { $0 != user.domain }
            text = BackendsStopFederating.selfBackend(withoutSelfDomain.first ?? "", URL.wr_FederationLearnMore.absoluteString)
        } else {
            text = BackendsStopFederating.otherBackends(domains.first ?? "", domains.last ?? "", URL.wr_FederationLearnMore.absoluteString)
        }

        let attributedString = NSAttributedString.markdown(from: text, style: .systemMessage)

        return attributedString
    }

}

private extension Array where Element == String {

    var hasSelfDomain: Bool {
        return self.contains(SelfUser.provider?.providedSelfUser.domain ?? "")
    }

}
