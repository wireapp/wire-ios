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

import WireSyncEngine

extension ConversationContentViewController: CanvasViewControllerDelegate {

    func canvasViewController(
        _ canvasViewController: CanvasViewController,
        didExportImage image: UIImage
    ) {
        parent?.dismiss(animated: true) {
            if let imageData = image.pngData() {

                self.userSession.enqueue({
                    do {
                        let useCase = self.userSession.makeAppendImageMessageUseCase()
                        try useCase.invoke(withImageData: imageData, in: self.conversation)
                    } catch {
                        WireLogger.messageProcessing.warn("Failed to append image message from canvas. Reason: \(error.localizedDescription)")
                    }
                })
            }
        }
    }
}
