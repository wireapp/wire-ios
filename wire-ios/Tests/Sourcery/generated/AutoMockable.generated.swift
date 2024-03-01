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

import WireDataModel

@testable import Wire





















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

// swiftlint:enable variable_name
// swiftlint:enable line_length
// swiftlint:enable vertical_whitespace
// swiftlint:enable superfluous_disable_command
