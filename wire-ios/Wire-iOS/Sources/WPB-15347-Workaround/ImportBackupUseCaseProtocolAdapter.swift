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
import WireDomainPkg
import WireLogging
import WireSettingsUI

// TODO: [WPB-15347] delete this workaround

// Instead of linking WireDomainPkg into WireUI targets several symlinks have been created.
// Therefore several types exist twice, once in their original target (WireDomainPkg) and once in WireUI.

typealias ImportBackupError = WireDomainPkg.ImportBackupError

struct ImportBackupUseCaseProtocolAdapter: WireSettingsUI.ImportBackupUseCaseProtocol {

    private let importBackupUseCase: any WireDomainPkg.ImportBackupUseCaseProtocol

    fileprivate init(_ importBackupUseCase: any WireDomainPkg.ImportBackupUseCaseProtocol) {
        self.importBackupUseCase = importBackupUseCase
    }

    func invoke(url: URL, password: String) -> AsyncThrowingStream<WireSettingsUI.ImportBackupProgress, any Error> {
        AsyncThrowingStream { continuation in
            Task<Void, Never> {
                do {

                    for try await update in importBackupUseCase.invoke(url: url, password: password) {
                        switch update {
                        case let .progress(fraction):
                            continuation.yield(.progress(fraction))
                        case .done:
                            continuation.yield(.done)
                        }
                    }
                    continuation.finish()

                } catch let error as ImportBackupError {
                    switch error {
                    case .noActiveAccountForImport:
                        continuation.finish(throwing: WireSettingsUI.ImportBackupError.noActiveAccountForImport)
                    case .passwordRequired:
                        continuation.finish(throwing: WireSettingsUI.ImportBackupError.passwordRequired)
                    case .incompatibleFileFormat:
                        continuation.finish(throwing: WireSettingsUI.ImportBackupError.incompatibleFileFormat)
                    case .invalidAccountID:
                        continuation.finish(throwing: WireSettingsUI.ImportBackupError.invalidAccountID)
                    case .compressionError:
                        continuation.finish(throwing: WireSettingsUI.ImportBackupError.compressionError)
                    case .invalidFileExtension:
                        continuation.finish(throwing: WireSettingsUI.ImportBackupError.invalidFileExtension)
                    case .keyCreationFailed:
                        continuation.finish(throwing: WireSettingsUI.ImportBackupError.keyCreationFailed)
                    case .decryptionError:
                        continuation.finish(throwing: WireSettingsUI.ImportBackupError.decryptionError)
                    case .faildToBackUpUserClient:
                        continuation.finish(throwing: WireSettingsUI.ImportBackupError.faildToBackUpUserClient)
                    case .failedToCreateStreamForDecryption:
                        continuation
                            .finish(throwing: WireSettingsUI.ImportBackupError.failedToCreateStreamForDecryption)
                    }

                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
}

func BackupImportExportBuilder(
    backupPasswordValidator: any BackupPasswordValidatorProtocol,
    createBackupUseCase: any CreateBackupUseCaseProtocol,
    importBackupUseCase: any WireDomainPkg.ImportBackupUseCaseProtocol,
    cleanUpBackupsUseCase: any CleanUpBackupsUseCaseProtocol
) -> WireSettingsUI.BackupImportExportBuilder {

    let importBackupUseCase = ImportBackupUseCaseProtocolAdapter(importBackupUseCase)

    return .init(
        backupPasswordValidator: backupPasswordValidator,
        createBackupUseCase: createBackupUseCase,
        importBackupUseCase: importBackupUseCase,
        cleanUpBackupsUseCase: cleanUpBackupsUseCase,
        exportBackupLogger: LoggerAdapter(logger: .backupExport),
        importBackupLogger: LoggerAdapter(logger: .backupImport)
    )

}

private struct LoggerAdapter: WireSettingsUILogger {

    var logger: WireLogger

    func debug(_ message: String) {
        logger.debug(message)
    }

    func info(_ message: String) {
        logger.info(message)
    }

    func notice(_ message: String) {
        logger.notice(message)
    }

    func warn(_ message: String) {
        logger.warn(message)
    }

    func error(_ message: String) {
        logger.error(message)
    }

    func critical(_ message: String) {
        logger.critical(message)
    }

}
