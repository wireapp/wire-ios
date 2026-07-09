// Generated using Sourcery 2.2.4 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT
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

// swiftlint:disable superfluous_disable_command
// swiftlint:disable vertical_whitespace
// swiftlint:disable line_length
// swiftlint:disable variable_name

import CoreLocation
import WireDataModel
import WireLogging
import WireSyncEngine
import WireAccountImageUI
import WireMessagingDomain

@testable import Wire
@testable import WireCommonComponents

typealias UserType = WireDataModel.UserType

class MockGetUserByIdUseCaseProtocol: GetUserByIDUseCaseProtocol {

    // MARK: - getUserByID

    var getUserByIdIdContext_Invocations: [(id: Any, context: NSManagedObjectContext)] = []
    var getUserByIdIdContext_MockValue: (any UserType)?

    func getUserByID(id: Any, context: NSManagedObjectContext) -> (any UserType)? {
        getUserByIdIdContext_Invocations.append((id: id, context: context))

        if let mock = getUserByIdIdContext_MockValue {
            return mock
        } else {
            fatalError("no mock for `getUserByIdIdContext`")
        }
    }

}

class MockLogFilesProviding: LogFilesProviding {

    // MARK: - Life cycle

    // MARK: - logFileURLs

    var logFileURLs: [URL] = []

    // MARK: - info

    var infoSelfUserID_Invocations: [UUID?] = []
    var infoSelfUserID_MockMethod: ((UUID?) -> String)?
    var infoSelfUserID_MockValue: String?

    func info(selfUserID: UUID?) -> String {
        infoSelfUserID_Invocations.append(selfUserID)

        if let mock = infoSelfUserID_MockMethod {
            return mock(selfUserID)
        } else if let mock = infoSelfUserID_MockValue {
            return mock
        } else {
            fatalError("no mock for `infoSelfUserID`")
        }
    }

    // MARK: - clearLogsDirectory

    var clearLogsDirectoryFileManager_Invocations: [FileManager] = []
    var clearLogsDirectoryFileManager_MockError: Error?
    var clearLogsDirectoryFileManager_MockMethod: ((FileManager) throws -> Void)?

    func clearLogsDirectory(fileManager: FileManager) throws {
        clearLogsDirectoryFileManager_Invocations.append(fileManager)

        if let error = clearLogsDirectoryFileManager_MockError {
            throw error
        }

        guard let mock = clearLogsDirectoryFileManager_MockMethod else {
            return
        }

        try mock(fileManager)
    }

    // MARK: - removeLogFiles

    var removeLogFilesFileManager_Invocations: [FileManager] = []
    var removeLogFilesFileManager_MockError: Error?
    var removeLogFilesFileManager_MockMethod: ((FileManager) throws -> Void)?

    func removeLogFiles(fileManager: FileManager) throws {
        removeLogFilesFileManager_Invocations.append(fileManager)

        if let error = removeLogFilesFileManager_MockError {
            throw error
        }

        guard let mock = removeLogFilesFileManager_MockMethod else {
            return
        }

        try mock(fileManager)
    }

    // MARK: - removeLegacyLogArchives

    var removeLegacyLogArchives_Invocations: [Void] = []
    var removeLegacyLogArchives_MockError: Error?
    var removeLegacyLogArchives_MockMethod: (() throws -> Void)?

    func removeLegacyLogArchives() throws {
        removeLegacyLogArchives_Invocations.append(())

        if let error = removeLegacyLogArchives_MockError {
            throw error
        }

        guard let mock = removeLegacyLogArchives_MockMethod else {
            return
        }

        try mock()
    }

}

// swiftlint:enable variable_name
// swiftlint:enable line_length
// swiftlint:enable vertical_whitespace
// swiftlint:enable superfluous_disable_command
