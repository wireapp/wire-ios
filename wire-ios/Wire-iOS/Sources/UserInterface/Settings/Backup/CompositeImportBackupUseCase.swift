//
// Wire
// Copyright (C) 2025 Wire Swiss GmbH
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
import WireBackup
import WireFoundation

struct CompositeImportBackupUseCase: ImportBackupUseCaseProtocol {

    let importBackupUseCase: ImportBackupUseCaseProtocol
    let legacyImportBackupUseCase: ImportBackupUseCaseProtocol

    func invoke(url: URL, password: String) -> AsyncThrowingStream<ImportBackupProgress, any Error> {
        let fileExtension = url.pathExtension.lowercased()
        switch WireBackup.BackupFileExtension(rawValue: fileExtension) {

        case .crossPlatform:
            return importBackupUseCase.invoke(url: url, password: password)

        case .fileExtensionWithUnderscore, .fileExtensionWithHyphen:
            return legacyImportBackupUseCase.invoke(url: url, password: password)

        case nil:
            return AsyncThrowingStream { continuation in
                continuation.finish(throwing: ImportBackupError.invalidFileExtension)
            }
        }
    }

}
