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

import Foundation
import WireSyncEngine
import ZIPFoundation

final class DocumentDelegate: NSObject, UIDocumentInteractionControllerDelegate {

    func documentInteractionControllerViewControllerForPreview(_ controller: UIDocumentInteractionController)
        -> UIViewController {
        UIApplication.shared.topmostViewController(onlyFullScreen: false)!
    }

}

final class SettingsShareDatabaseCellDescriptor: SettingsButtonCellDescriptor {

    let documentDelegate: DocumentDelegate

    init(userSession: UserSession) {
        let documentDelegate = DocumentDelegate()
        self.documentDelegate = documentDelegate

        super.init(title: "Share Database", isDestructive: false) { [weak userSession] _ in
            guard let userSession = userSession as? ZMUserSession else { return }
            let fileURL = userSession.managedObjectContext.zm_storeURL!
            let archiveURL = fileURL.appendingPathExtension("zip")

            try? FileManager.default.removeItem(at: archiveURL)
            try? FileManager.default.zipItem(
                at: fileURL,
                to: archiveURL,
                shouldKeepParent: false,
                compressionMethod: .deflate
            )

            let shareDatabaseDocumentController = UIDocumentInteractionController(url: archiveURL)
            shareDatabaseDocumentController.delegate = documentDelegate
            shareDatabaseDocumentController.presentPreview(animated: true)
        }

    }

}
