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

import Foundation
import UIKit

protocol SystemSaveFilePresenting {
    func presentSystemPromptToSave(file fileURL: URL, completed: @escaping () -> Void)
}

final class SystemSavePresenter: NSObject, SystemSaveFilePresenting {
    private var finishedPresenting: (() -> Void)?
    private let documentInteractionController: UIDocumentInteractionController

    init(documentInteractionController: UIDocumentInteractionController = UIDocumentInteractionController()) {
        self.documentInteractionController = documentInteractionController
        super.init()
    }

    func presentSystemPromptToSave(file fileURL: URL, completed: @escaping () -> Void) {
        documentInteractionController.delegate = self
        self.finishedPresenting = completed
        documentInteractionController.url = fileURL
        documentInteractionController.name = fileURL.lastPathComponent
        documentInteractionController.presentPreview(animated: true)
    }
}

extension SystemSavePresenter: UIDocumentInteractionControllerDelegate {

    func documentInteractionControllerViewControllerForPreview(_ controller: UIDocumentInteractionController, finished: @escaping () -> Void) -> UIViewController {
        self.finishedPresenting = finished
        return UIApplication.shared.topmostViewController(onlyFullScreen: false)!
    }

    func documentInteractionControllerDidEndPreview(_ controller: UIDocumentInteractionController) {
        finishedPresenting?()
    }

}
