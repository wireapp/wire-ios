// Generated using Sourcery 2.1.7 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT

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

// swiftlint:disable superfluous_disable_command
// swiftlint:disable vertical_whitespace
// swiftlint:disable line_length
// swiftlint:disable variable_name

import Foundation
#if os(iOS) || os(tvOS) || os(watchOS)
import UIKit
#elseif os(OSX)
import AppKit
#endif

import CoreLocation
import WireDataModel
import WireSyncEngine

@testable import Wire
@testable import WireCommonComponents





















class MockBackupSource: BackupSource {

    // MARK: - Life cycle



    // MARK: - backupActiveAccount

    var backupActiveAccountPasswordCompletion_Invocations: [(password: String, completion: (Result<URL, Error>) -> Void)] = []
    var backupActiveAccountPasswordCompletion_MockMethod: ((String, @escaping (Result<URL, Error>) -> Void) -> Void)?

    func backupActiveAccount(password: String, completion: @escaping (Result<URL, Error>) -> Void) {
        backupActiveAccountPasswordCompletion_Invocations.append((password: password, completion: completion))

        guard let mock = backupActiveAccountPasswordCompletion_MockMethod else {
            fatalError("no mock for `backupActiveAccountPasswordCompletion`")
        }

        mock(password, completion)
    }

    // MARK: - clearPreviousBackups

    var clearPreviousBackups_Invocations: [Void] = []
    var clearPreviousBackups_MockMethod: (() -> Void)?

    func clearPreviousBackups() {
        clearPreviousBackups_Invocations.append(())

        guard let mock = clearPreviousBackups_MockMethod else {
            fatalError("no mock for `clearPreviousBackups`")
        }

        mock()
    }

}

class MockConversationUserClientDetailsActions: ConversationUserClientDetailsActions {

    // MARK: - Life cycle



    // MARK: - showMyDevice

    var showMyDevice_Invocations: [Void] = []
    var showMyDevice_MockMethod: (() -> Void)?

    func showMyDevice() {
        showMyDevice_Invocations.append(())

        guard let mock = showMyDevice_MockMethod else {
            fatalError("no mock for `showMyDevice`")
        }

        mock()
    }

    // MARK: - howToDoThat

    var howToDoThat_Invocations: [Void] = []
    var howToDoThat_MockMethod: (() -> Void)?

    func howToDoThat() {
        howToDoThat_Invocations.append(())

        guard let mock = howToDoThat_MockMethod else {
            fatalError("no mock for `howToDoThat`")
        }

        mock()
    }

}

class MockDeviceDetailsViewActions: DeviceDetailsViewActions {

    // MARK: - Life cycle


    // MARK: - isSelfClient

    var isSelfClient: Bool {
        get { return underlyingIsSelfClient }
        set(value) { underlyingIsSelfClient = value }
    }

    var underlyingIsSelfClient: Bool!

    // MARK: - isProcessing

    var isProcessing: ((Bool) -> Void)?


    // MARK: - enrollClient

    var enrollClient_Invocations: [Void] = []
    var enrollClient_MockError: Error?
    var enrollClient_MockMethod: (() async throws -> String)?
    var enrollClient_MockValue: String?

    func enrollClient() async throws -> String {
        enrollClient_Invocations.append(())

        if let error = enrollClient_MockError {
            throw error
        }

        if let mock = enrollClient_MockMethod {
            return try await mock()
        } else if let mock = enrollClient_MockValue {
            return mock
        } else {
            fatalError("no mock for `enrollClient`")
        }
    }

    // MARK: - removeDevice

    var removeDevice_Invocations: [Void] = []
    var removeDevice_MockMethod: (() async -> Bool)?
    var removeDevice_MockValue: Bool?

    func removeDevice() async -> Bool {
        removeDevice_Invocations.append(())

        if let mock = removeDevice_MockMethod {
            return await mock()
        } else if let mock = removeDevice_MockValue {
            return mock
        } else {
            fatalError("no mock for `removeDevice`")
        }
    }

    // MARK: - resetSession

    var resetSession_Invocations: [Void] = []
    var resetSession_MockMethod: (() -> Void)?

    func resetSession() {
        resetSession_Invocations.append(())

        guard let mock = resetSession_MockMethod else {
            fatalError("no mock for `resetSession`")
        }

        mock()
    }

    // MARK: - updateVerified

    var updateVerified_Invocations: [Bool] = []
    var updateVerified_MockMethod: ((Bool) async -> Bool)?
    var updateVerified_MockValue: Bool?

    func updateVerified(_ value: Bool) async -> Bool {
        updateVerified_Invocations.append(value)

        if let mock = updateVerified_MockMethod {
            return await mock(value)
        } else if let mock = updateVerified_MockValue {
            return mock
        } else {
            fatalError("no mock for `updateVerified`")
        }
    }

    // MARK: - copyToClipboard

    var copyToClipboard_Invocations: [String] = []
    var copyToClipboard_MockMethod: ((String) -> Void)?

    func copyToClipboard(_ value: String) {
        copyToClipboard_Invocations.append(value)

        guard let mock = copyToClipboard_MockMethod else {
            fatalError("no mock for `copyToClipboard`")
        }

        mock(value)
    }

    // MARK: - downloadE2EIdentityCertificate

    var downloadE2EIdentityCertificateCertificate_Invocations: [E2eIdentityCertificate] = []
    var downloadE2EIdentityCertificateCertificate_MockMethod: ((E2eIdentityCertificate) -> Void)?

    func downloadE2EIdentityCertificate(certificate: E2eIdentityCertificate) {
        downloadE2EIdentityCertificateCertificate_Invocations.append(certificate)

        guard let mock = downloadE2EIdentityCertificateCertificate_MockMethod else {
            fatalError("no mock for `downloadE2EIdentityCertificateCertificate`")
        }

        mock(certificate)
    }

    // MARK: - getProteusFingerPrint

    var getProteusFingerPrint_Invocations: [Void] = []
    var getProteusFingerPrint_MockMethod: (() async -> String)?
    var getProteusFingerPrint_MockValue: String?

    func getProteusFingerPrint() async -> String {
        getProteusFingerPrint_Invocations.append(())

        if let mock = getProteusFingerPrint_MockMethod {
            return await mock()
        } else if let mock = getProteusFingerPrint_MockValue {
            return mock
        } else {
            fatalError("no mock for `getProteusFingerPrint`")
        }
    }

}

public class MockFileMetaDataGenerating: FileMetaDataGenerating {

    // MARK: - Life cycle

    public init() {}


    // MARK: - metadataForFileAtURL

    public var metadataForFileAtURLUTINameCompletion_Invocations: [(url: URL, uti: String, name: String, completion: (ZMFileMetadata) -> Void)] = []
    public var metadataForFileAtURLUTINameCompletion_MockMethod: ((URL, String, String, @escaping (ZMFileMetadata) -> Void) -> Void)?

    public func metadataForFileAtURL(_ url: URL, UTI uti: String, name: String, completion: @escaping (ZMFileMetadata) -> Void) {
        metadataForFileAtURLUTINameCompletion_Invocations.append((url: url, uti: uti, name: name, completion: completion))

        guard let mock = metadataForFileAtURLUTINameCompletion_MockMethod else {
            fatalError("no mock for `metadataForFileAtURLUTINameCompletion`")
        }

        mock(url, uti, name, completion)
    }

}

class MockLogFilesProviding: LogFilesProviding {

    // MARK: - Life cycle



    // MARK: - generateLogFilesData

    var generateLogFilesData_Invocations: [Void] = []
    var generateLogFilesData_MockError: Error?
    var generateLogFilesData_MockMethod: (() throws -> Data)?
    var generateLogFilesData_MockValue: Data?

    func generateLogFilesData() throws -> Data {
        generateLogFilesData_Invocations.append(())

        if let error = generateLogFilesData_MockError {
            throw error
        }

        if let mock = generateLogFilesData_MockMethod {
            return try mock()
        } else if let mock = generateLogFilesData_MockValue {
            return mock
        } else {
            fatalError("no mock for `generateLogFilesData`")
        }
    }

    // MARK: - generateLogFilesZip

    var generateLogFilesZip_Invocations: [Void] = []
    var generateLogFilesZip_MockError: Error?
    var generateLogFilesZip_MockMethod: (() throws -> URL)?
    var generateLogFilesZip_MockValue: URL?

    func generateLogFilesZip() throws -> URL {
        generateLogFilesZip_Invocations.append(())

        if let error = generateLogFilesZip_MockError {
            throw error
        }

        if let mock = generateLogFilesZip_MockMethod {
            return try mock()
        } else if let mock = generateLogFilesZip_MockValue {
            return mock
        } else {
            fatalError("no mock for `generateLogFilesZip`")
        }
    }

    // MARK: - clearLogsDirectory

    var clearLogsDirectory_Invocations: [Void] = []
    var clearLogsDirectory_MockError: Error?
    var clearLogsDirectory_MockMethod: (() throws -> Void)?

    func clearLogsDirectory() throws {
        clearLogsDirectory_Invocations.append(())

        if let error = clearLogsDirectory_MockError {
            throw error
        }

        guard let mock = clearLogsDirectory_MockMethod else {
            fatalError("no mock for `clearLogsDirectory`")
        }

        try mock()
    }

}

class MockSettingsDebugReportRouterProtocol: SettingsDebugReportRouterProtocol {

    // MARK: - Life cycle



    // MARK: - presentMailComposer

    var presentMailComposer_Invocations: [Void] = []
    var presentMailComposer_MockMethod: (() -> Void)?

    @MainActor
    func presentMailComposer() {
        presentMailComposer_Invocations.append(())

        guard let mock = presentMailComposer_MockMethod else {
            fatalError("no mock for `presentMailComposer`")
        }

        mock()
    }

    // MARK: - presentFallbackAlert

    var presentFallbackAlert_Invocations: [Void] = []
    var presentFallbackAlert_MockMethod: (() -> Void)?

    func presentFallbackAlert() {
        presentFallbackAlert_Invocations.append(())

        guard let mock = presentFallbackAlert_MockMethod else {
            fatalError("no mock for `presentFallbackAlert`")
        }

        mock()
    }

    // MARK: - presentShareViewController

    var presentShareViewControllerDestinationsDebugReport_Invocations: [(destinations: [ZMConversation], debugReport: ShareableDebugReport)] = []
    var presentShareViewControllerDestinationsDebugReport_MockMethod: (([ZMConversation], ShareableDebugReport) -> Void)?

    func presentShareViewController(destinations: [ZMConversation], debugReport: ShareableDebugReport) {
        presentShareViewControllerDestinationsDebugReport_Invocations.append((destinations: destinations, debugReport: debugReport))

        guard let mock = presentShareViewControllerDestinationsDebugReport_MockMethod else {
            fatalError("no mock for `presentShareViewControllerDestinationsDebugReport`")
        }

        mock(destinations, debugReport)
    }

}

class MockSettingsDebugReportViewModelProtocol: SettingsDebugReportViewModelProtocol {

    // MARK: - Life cycle



    // MARK: - sendReport

    var sendReport_Invocations: [Void] = []
    var sendReport_MockMethod: (() -> Void)?

    func sendReport() {
        sendReport_Invocations.append(())

        guard let mock = sendReport_MockMethod else {
            fatalError("no mock for `sendReport`")
        }

        mock()
    }

    // MARK: - shareReport

    var shareReport_Invocations: [Void] = []
    var shareReport_MockMethod: (() -> Void)?

    func shareReport() {
        shareReport_Invocations.append(())

        guard let mock = shareReport_MockMethod else {
            fatalError("no mock for `shareReport`")
        }

        mock()
    }

}

// swiftlint:enable variable_name
// swiftlint:enable line_length
// swiftlint:enable vertical_whitespace
// swiftlint:enable superfluous_disable_command
