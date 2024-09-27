//
// Wire
// Copyright (C) 2024 Wire Swiss GmbH
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
import WireDataModel
import WireSystem

private let zmLog = ZMSLog(tag: "UI")

extension ContactsViewController {
    private var canInviteByEmail: Bool {
        ZMAddressBookContact.canInviteLocallyWithEmail()
    }

    private var canInviteByPhone: Bool {
        ZMAddressBookContact.canInviteLocallyWithPhoneNumber()
    }

    @objc
    func sendIndirectInvite(_ sender: UIButton) {
        let shareItemProvider = ShareItemProvider(placeholderItem: "")
        let activityController = UIActivityViewController(
            activityItems: [shareItemProvider],
            applicationActivities: nil
        )
        activityController.excludedActivityTypes = [UIActivity.ActivityType.airDrop]
        if let popoverPresentationController = activityController.popoverPresentationController {
            let margin = 2 * fmin(sender.frame.origin.x, sender.frame.origin.y)
            popoverPresentationController.sourceView = sender.superview
            popoverPresentationController.sourceRect = sender.frame.insetBy(dx: -margin, dy: -margin)
        }
        present(activityController, animated: true)
    }

    func openConversation(for user: UserType) {
        guard
            user.isConnected,
            let conversation = user.oneToOneConversation
        else { return }

        let showConversation: Completion = {
            ZClientViewController.shared?.select(conversation: conversation, focusOnView: true, animated: true)
        }

        if let navigationController {
            navigationController.popToRootViewController(animated: false, completion: showConversation)
        } else {
            showConversation()
        }
    }

    func invite(user: UserType) {
        do {
            guard let contact = (user as? ZMSearchUser)?.contact else { throw InvitationError.noContactInformation }
            try invite(contact: contact, from: view)
        } catch let InvitationError.canNotSend(client) {
            present(unableToSendController(client: client), animated: true)
        } catch {
            zmLog.error("Could not invite contact: \(error.localizedDescription)")
        }
    }

    private func invite(contact: ZMAddressBookContact, from view: UIView) throws {
        switch contact.contactDetails.count {
        case 1:
            try inviteWithSingleAddress(for: contact)

        case 2...:
            let actionSheet = try addressActionSheet(for: contact, in: view)
            present(actionSheet, animated: true)

        default:
            throw InvitationError.noContactInformation
        }
    }

    private func inviteWithSingleAddress(for contact: ZMAddressBookContact) throws {
        if let emailAddress = contact.emailAddresses.first {
            guard canInviteByEmail else { throw InvitationError.canNotSend(.email) }
            contact.inviteLocallyWithEmail(emailAddress)

        } else if let phoneNumber = contact.rawPhoneNumbers.first {
            guard canInviteByPhone else { throw InvitationError.canNotSend(.sms) }
            contact.inviteLocallyWithPhoneNumber(phoneNumber)

        } else {
            throw InvitationError.noContactInformation
        }
    }

    private func addressActionSheet(for contact: ZMAddressBookContact, in view: UIView) throws -> UIAlertController {
        guard canInviteByEmail || canInviteByPhone else { throw InvitationError.canNotSend(.any) }

        let chooseContactDetailController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

        let presentationController = chooseContactDetailController.popoverPresentationController
        presentationController?.sourceView = view
        presentationController?.sourceRect = view.bounds

        var actions = [UIAlertAction]()

        if canInviteByEmail {
            actions.append(contentsOf: contact.emailAddresses.map { address in
                UIAlertAction(title: address, style: .default) { _ in
                    contact.inviteLocallyWithEmail(address)
                    chooseContactDetailController.dismiss(animated: true)
                }
            })
        }

        if canInviteByPhone {
            actions.append(contentsOf: contact.rawPhoneNumbers.map { number in
                UIAlertAction(title: number, style: .default) { _ in
                    contact.inviteLocallyWithPhoneNumber(number)
                    chooseContactDetailController.dismiss(animated: true)
                }
            })
        }

        actions
            .append(UIAlertAction(
                title: L10n.Localizable.ContactsUi.InviteSheet.cancelButtonTitle,
                style: .cancel
            ) { _ in
                chooseContactDetailController.dismiss(animated: true)
            })

        actions.forEach(chooseContactDetailController.addAction)
        return chooseContactDetailController
    }

    private func unableToSendController(client: InvitationError.MessageType) -> UIAlertController {
        let unableToSendController = UIAlertController(title: nil, message: client.messageKey, preferredStyle: .alert)

        let okAction = UIAlertAction(title: L10n.Localizable.General.ok, style: .cancel) { _ in
            unableToSendController.dismiss(animated: true)
        }

        unableToSendController.addAction(okAction)
        return unableToSendController
    }

    private enum InvitationError: Error {
        case canNotSend(MessageType)
        case noContactInformation

        // MARK: Internal

        enum MessageType {
            case email, sms, any

            // MARK: Internal

            var messageKey: String {
                switch self {
                case .any, .email:
                    L10n.Localizable.Error.Invite.noEmailProvider
                case .sms:
                    L10n.Localizable.Error.Invite.noMessagingProvider
                }
            }
        }
    }
}
