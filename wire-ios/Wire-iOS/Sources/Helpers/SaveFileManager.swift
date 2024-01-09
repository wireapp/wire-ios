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

protocol SaveFileActions {
    func save(value: String, fileName: String, type: String)
}

final class SaveFileManager: NSObject, SaveFileActions {
    private var pendingSaveURLs = [URL]()

    private let logger: LoggerProtocol
    private let systemSaveFilePresenter: SystemSaveFilePresenting

    public init(systemFileSavePresenter: SystemSaveFilePresenting, logger: LoggerProtocol) {
        self.systemSaveFilePresenter = systemFileSavePresenter
        self.logger = logger
    }

    func save(value: String, fileName: String, type: String) {
        let temporaryDirectoryURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        let fileURL = temporaryDirectoryURL.appendingPathComponent(fileName + "." + type)
        guard let data = value.data(using: .utf8) else {
            return
        }
        do {
            try data.write(to: fileURL)
            systemSaveFilePresenter.presentSystemPromptToSave(file: fileURL, completed: finishedSaving)
            pendingSaveURLs.append(fileURL)
        } catch {
            logger.error(error.localizedDescription, attributes: nil)
        }
    }

    private func deleteFilesInTemporyDirectory() throws {
        for fileURL in pendingSaveURLs {
            try FileManager.default.removeItem(at: fileURL)
        }
        pendingSaveURLs.removeAll()
    }

    private func finishedSaving() {
        do {
            try deleteFilesInTemporyDirectory()
        } catch {
            logger.error(error.localizedDescription, attributes: nil)
        }
    }
}
