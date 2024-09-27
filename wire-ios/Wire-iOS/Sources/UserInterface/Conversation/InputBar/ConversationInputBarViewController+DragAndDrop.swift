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
import WireSyncEngine
import WireSystem

private let zmLog = ZMSLog(tag: "Drag and drop images")

// MARK: - ConversationInputBarViewController + UIDropInteractionDelegate

extension ConversationInputBarViewController: UIDropInteractionDelegate {
    func dropInteraction(_ interaction: UIDropInteraction, performDrop session: UIDropSession) {
        for dragItem in session.items {
            let itemProvider = dragItem.itemProvider
            if itemProvider.hasText() {
                itemProvider.loadObject(ofClass: NSString.self) { [self] object, _ in
                    guard let draggedText = object as? String else {
                        return
                    }
                    DispatchQueue.main.async {
                        self.inputBar.textView.text = draggedText
                    }
                }
            } else if itemProvider.canLoadObject(ofClass: UIImage.self) {
                itemProvider.loadObject(ofClass: UIImage.self, completionHandler: { object, error in

                    guard error == nil
                    else {
                        return zmLog.error("Failed to load dragged item: \(error!.localizedDescription)")
                    }
                    guard let draggedImage = object as? UIImage else {
                        return
                    }

                    DispatchQueue.main.async {
                        let context = ConfirmAssetViewController.Context(
                            asset: .image(mediaAsset: draggedImage),
                            onConfirm: { [unowned self] _ in
                                dismiss(animated: true) {
                                    if let draggedImageData = draggedImage
                                        .pngData() {
                                        self.sendController.sendMessage(
                                            withImageData: draggedImageData,
                                            userSession: self.userSession
                                        )
                                    }
                                }
                            },
                            onCancel: { [unowned self] in
                                dismiss(animated: true)
                            }
                        )

                        let confirmImageViewController = ConfirmAssetViewController(context: context)
                        confirmImageViewController.previewTitle = self.conversation.displayNameWithFallback
                        self.present(confirmImageViewController, animated: true) {}
                    }
                })
                // swiftlint:disable:next todo_requires_jira_link
                // TODO: it's a temporary solution to drag only one image, while we have no design for multiple images
                break
            }
        }
    }

    func dropInteraction(_ interaction: UIDropInteraction, sessionDidUpdate session: UIDropSession) -> UIDropProposal {
        dropProposal(mediaShareRestrictionManager: MediaShareRestrictionManager(
            sessionRestriction: ZMUserSession
                .shared()
        ))
    }

    func dropProposal(mediaShareRestrictionManager: MediaShareRestrictionManager) -> UIDropProposal {
        mediaShareRestrictionManager.canUseClipboard
            ? UIDropProposal(operation: .copy)
            : UIDropProposal(operation: .forbidden)
    }

    func dropInteraction(_ interaction: UIDropInteraction, canHandle session: UIDropSession) -> Bool {
        true
    }
}

extension NSItemProvider {
    fileprivate func hasText() -> Bool {
        // Image dragged from browser can be both NSString and UIImage
        canLoadObject(ofClass: NSString.self) && !canLoadObject(ofClass: UIImage.self)
    }
}
