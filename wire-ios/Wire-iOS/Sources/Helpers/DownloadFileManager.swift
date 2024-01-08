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
import WireSystem

protocol DownloadFileActions {
    func download(value: String, fileName: String, type: String)
}

final class DownloadFileManager: NSObject, DownloadFileActions {
    private var pendingDownloadURLs = [URL]()
    private let logger: LoggerProtocol
    private let documentInteractionController: UIDocumentInteractionController

    public init(documentInteractionController: UIDocumentInteractionController, logger: LoggerProtocol) {
        self.documentInteractionController = documentInteractionController
        self.logger = logger
    }

    func download(value: String, fileName: String, type: String) {
        documentInteractionController.delegate = self
        let temporaryDirectoryURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        let fileURL = temporaryDirectoryURL.appendingPathComponent(fileName + "." + type)
        guard let data = value.data(using: .utf8) else {
            return
        }
        do {
            try data.write(to: fileURL)
            download(file: fileURL)
        } catch {
            logger.error(error.localizedDescription, attributes: nil)
        }
    }

    private func download(file fileURL: URL) {
        documentInteractionController.delegate = self
        pendingDownloadURLs.append(fileURL)
        documentInteractionController.url = fileURL
        documentInteractionController.name = fileURL.lastPathComponent
        documentInteractionController.presentPreview(animated: true)
    }

    private func deleteFilesInTemporyDirectory() throws {
        for fileURL in pendingDownloadURLs {
            try FileManager.default.removeItem(at: fileURL)
        }
        pendingDownloadURLs.removeAll()
    }

}

extension DownloadFileManager: UIDocumentInteractionControllerDelegate {

    func documentInteractionControllerViewControllerForPreview(_ controller: UIDocumentInteractionController) -> UIViewController {
        return UIApplication.shared.topmostViewController(onlyFullScreen: false)!
    }

    func documentInteractionControllerDidEndPreview(_ controller: UIDocumentInteractionController) {
        do {
            try deleteFilesInTemporyDirectory()
        } catch {
            logger.error(error.localizedDescription, attributes: nil)
        }
    }

}
