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
import WireLogging
import WireSyncEngine

extension ZMConversation: ShareDestination {

    var showsGuestIcon: Bool {
        guard let selfUser = ZMUser.selfUser() else {
            assertionFailure("ZMUser.selfUser() is nil")
            return false
        }
        return selfUser.hasTeam &&
            conversationType == .oneOnOne &&
            localParticipants.first { $0.isGuest(in: self) } != nil
    }
}

extension ShareDestination where Self: ConversationGroupAvatarViewConversation {

    var avatarView: UIView? {
        let avatarView = ConversationGroupAvatarView()
        avatarView.configure(
            context: ConversationGroupAvatarView.Context(
                conversation: self
            )
        )
        return avatarView
    }

    var qualifiedID: WireDataModel.QualifiedID? {
        nil
    }
}

extension [ZMConversation] {

    // Should be called inside ZMUserSession.shared().perform block
    func forEachNonEphemeral(_ block: (ZMConversation) -> Void) {
        forEach {
            guard let timeout = $0.activeMessageDestructionTimeoutValue,
                  let type = $0.activeMessageDestructionTimeoutType else {
                block($0)
                return
            }
            $0.setMessageDestructionTimeoutValue(.init(rawValue: 0), for: type)
            block($0)
            $0.setMessageDestructionTimeoutValue(timeout, for: type)
        }
    }
}

extension ZMMessage: Shareable {
    typealias I = ZMConversation

    func share(to: [some Any], userSession: UserSession) {
        forward(to: to as [AnyObject], userSession: userSession)
    }

    func forward(to: [AnyObject], userSession: UserSession) {

        let conversations = to as! [ZMConversation]

        if isText {
            let fetchLinkPreview = !Settings.disableLinkPreviews
            userSession.perform {
                conversations.forEachNonEphemeral {
                    do {
                        // We should not forward any mentions to other conversations
                        try $0.appendText(
                            content: self.textMessageData!.messageText!,
                            mentions: [],
                            fetchLinkPreview: fetchLinkPreview
                        )
                    } catch {
                        Logging.messageProcessing
                            .warn("Failed to append text message. Reason: \(error.localizedDescription)")
                    }
                }
            }
        } else if isImage, let imageMessageData, let data = imageMessageData.imageData {
            userSession.perform {
                conversations.forEachNonEphemeral {
                    do {
                        let image = SendableImage(
                            name: imageMessageData.name,
                            utType: nil,
                            data: data
                        )
                        try $0.appendImage(image, nonce: UUID())
                    } catch {
                        WireLogger.messageProcessing
                            .warn("Failed to append image message. Reason: \(error.localizedDescription)")
                    }
                }
            }
        } else if isVideo || isAudio || isFile {
            guard let url = fileMessageData!.temporaryURLToDecryptedFile() else { return }
            Task { [weak userSession] in
                let fileMetadata = await FileMetaDataGenerator.shared.metadataForFile(at: url)
                if let userSession = userSession as? ZMUserSession {
                    await userSession.managedObjectContext.perform {
                        conversations.forEachNonEphemeral {
                            do {
                                try $0.appendFile(with: fileMetadata)
                            } catch {
                                WireLogger.messageProcessing
                                    .warn("Failed to append file message. Reason: \(error.localizedDescription)")
                            }
                        }
                        userSession.saveOrRollbackChanges()
                    }
                }
            }
        } else if isLocation {
            let locationData = LocationData.locationData(
                withLatitude: locationMessageData!.latitude,
                longitude: locationMessageData!.longitude,
                name: locationMessageData!.name,
                zoomLevel: locationMessageData!.zoomLevel
            )
            userSession.perform {
                conversations.forEachNonEphemeral {
                    do {
                        try $0.appendLocation(with: locationData)
                    } catch {
                        WireLogger.messageProcessing
                            .warn("Failed to append location message. Reason: \(error.localizedDescription)")
                    }
                }
            }
        } else {
            fatal("Cannot forward message")
        }
    }

}

extension ZMConversationMessage {
    func previewView(userSession: UserSession) -> UIView? {
        let view = preparePreviewView(userSession: userSession, shouldDisplaySender: false)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = SemanticColors.View.backgroundUserCell
        return view
    }
}

// MARK: - popover appearance update

extension ConversationContentViewController {

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        guard traitCollection.horizontalSizeClass != previousTraitCollection?.horizontalSizeClass else { return }

        if let keyboardAvoidingViewController = presentedViewController as? KeyboardAvoidingViewController,
           let shareViewController = keyboardAvoidingViewController.viewController as? ShareViewController<
               ZMConversation,
               ZMMessage
           > {
            shareViewController.showPreview = traitCollection.horizontalSizeClass != .regular
        }
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        // TODO: [WPB-16431] this is to update the cells on iPad when sidebar
        // is hidden or shown. This is a quick fix for now. To improve later
        coordinator.animate(alongsideTransition: nil) { _ in
            self.dataSource.resetSectionControllers()
        }
    }

}

extension ConversationContentViewController: UIAdaptivePresentationControllerDelegate {

    func adaptivePresentationStyle(
        for controller: UIPresentationController,
        traitCollection: UITraitCollection
    ) -> UIModalPresentationStyle {
        traitCollection.horizontalSizeClass == .regular ? .popover : .overFullScreen
    }
}
