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

import WireSystemSupport
import WireTesting
import WireUtilitiesSupport
import XCTest
@testable import Wire

// MARK: - ShouldPresentNotificationPermissionHintUseCaseTests

final class ShouldPresentNotificationPermissionHintUseCaseTests: XCTestCase {
    // MARK: Internal

    override func setUp() {
        mockDateProvider = .init()
        mockDateProvider.now = .now
        userDefaults = .temporary()
        userNotificationCenterMock = .init()
        sut = .init(
            currentDateProvider: mockDateProvider,
            userDefaults: userDefaults,
            userNotificationCenter: userNotificationCenterMock
        )
    }

    override func tearDown() {
        sut = nil
    }

    func testReturningTrueForDeniedAndNoDate() async throws {
        // Given
        let notificationSettings = try UNNotificationSettings.with(authorizationStatus: .denied)
        userNotificationCenterMock.notificationSettings_MockValue = notificationSettings

        // When
        let shouldPresentHint = await sut.invoke()

        // Then
        XCTAssertTrue(shouldPresentHint)
    }

    func testReturningTrueForDeniedAndDistantPastDate() async throws {
        // Given
        let notificationSettings = try UNNotificationSettings.with(authorizationStatus: .denied)
        userNotificationCenterMock.notificationSettings_MockValue = notificationSettings
        userDefaults.setValue(Date.distantPast, for: .lastTimeNotificationPermissionHintWasShown)

        // When
        let shouldPresentHint = await sut.invoke()

        // Then
        XCTAssertTrue(shouldPresentHint)
    }

    func testReturningFalseForDeniedAndRecentPastDate() async throws {
        // Given
        let notificationSettings = try UNNotificationSettings.with(authorizationStatus: .denied)
        userNotificationCenterMock.notificationSettings_MockValue = notificationSettings
        userDefaults.setValue(
            mockDateProvider.now.addingTimeInterval(-3600),
            for: .lastTimeNotificationPermissionHintWasShown
        )

        // When
        let shouldPresentHint = await sut.invoke()

        // Then
        XCTAssertFalse(shouldPresentHint)
    }

    func testReturningFalseForAuthorized() async throws {
        // Given
        let notificationSettings = try UNNotificationSettings.with(authorizationStatus: .authorized)
        userNotificationCenterMock.notificationSettings_MockValue = notificationSettings

        // When
        let shouldPresentHint = await sut.invoke()

        // Then
        XCTAssertFalse(shouldPresentHint)
    }

    func testReturningFalseForNotDetermined() async throws {
        // Given
        let notificationSettings = try UNNotificationSettings.with(authorizationStatus: .notDetermined)
        userNotificationCenterMock.notificationSettings_MockValue = notificationSettings

        // When
        let shouldPresentHint = await sut.invoke()

        // Then
        XCTAssertFalse(shouldPresentHint)
    }

    func testDecoding() throws {
        XCTAssertEqual(
            try UNNotificationSettings.with(authorizationStatus: .authorized).authorizationStatus,
            .authorized
        )
        XCTAssertEqual(try UNNotificationSettings.with(authorizationStatus: .denied).authorizationStatus, .denied)
        XCTAssertEqual(
            try UNNotificationSettings.with(authorizationStatus: .notDetermined).authorizationStatus,
            .notDetermined
        )
    }

    // MARK: Private

    private var mockDateProvider: MockCurrentDateProviding!
    private var userDefaults: UserDefaults!
    private var userNotificationCenterMock: MockUserNotificationCenterAbstraction!
    private var sut: ShouldPresentNotificationPermissionHintUseCase<MockCurrentDateProviding>!
}

// MARK: -

/// base64 encoded data which can be restored to an instance of `UNNotificationSettings`.
///
/// created:
/// ```
/// let data = try NSKeyedArchiver
///     .archivedData(
///         withRootObject: notificationSettings,
///         requiringSecureCoding: true
///     )
///     .base64EncodedString()
/// ```
extension UNNotificationSettings {
    fileprivate static func with(authorizationStatus: UNAuthorizationStatus) throws -> Self {
        let encoded =
            switch authorizationStatus {
            case .authorized:
                "YnBsaXN0MDDUAQIDBAUGBwpYJHZlcnNpb25ZJGFyY2hpdmVyVCR0b3BYJG9iamVjdHMSAAGGoF8Q" +
                    "D05TS2V5ZWRBcmNoaXZlctEICVRyb290gAGjCwwjVSRudWxs3xARDQ4PEBESExQVFhcYGRobHB0e" +
                    "Hx8fHx4eHh4eICEfIiEhH18QFWRpcmVjdE1lc3NhZ2VzU2V0dGluZ1xiYWRnZVNldHRpbmdfEBNh" +
                    "dXRob3JpemF0aW9uU3RhdHVzXHNvdW5kU2V0dGluZ18QGW5vdGlmaWNhdGlvbkNlbnRlclNldHRp" +
                    "bmdfEBRjcml0aWNhbEFsZXJ0U2V0dGluZ18QE3Nob3dQcmV2aWV3c1NldHRpbmdeY2FyUGxheVNl" +
                    "dHRpbmdfEA9ncm91cGluZ1NldHRpbmdfEBR0aW1lU2Vuc2l0aXZlU2V0dGluZ18QH3Byb3ZpZGVz" +
                    "QXBwTm90aWZpY2F0aW9uU2V0dGluZ3NfEBhzY2hlZHVsZWREZWxpdmVyeVNldHRpbmdfEBFsb2Nr" +
                    "U2NyZWVuU2V0dGluZ1YkY2xhc3NaYWxlcnRTdHlsZV8QE2Fubm91bmNlbWVudFNldHRpbmdcYWxl" +
                    "cnRTZXR0aW5nEAAQAggQAYAC0iQlJidaJGNsYXNzbmFtZVgkY2xhc3Nlc18QFlVOTm90aWZpY2F0" +
                    "aW9uU2V0dGluZ3OiKClfEBZVTk5vdGlmaWNhdGlvblNldHRpbmdzWE5TT2JqZWN0AAgAEQAaACQA" +
                    "KQAyADcASQBMAFEAUwBXAF0AggCaAKcAvQDKAOYA/QETASIBNAFLAW0BiAGcAaMBrgHEAdEB0wHV" +
                    "AdYB2AHaAd8B6gHzAgwCDwIoAAAAAAAAAgEAAAAAAAAAKgAAAAAAAAAAAAAAAAAAAjE="

            case .denied:
                "YnBsaXN0MDDUAQIDBAUGBwpYJHZlcnNpb25ZJGFyY2hpdmVyVCR0b3BYJG9iamVjdHMSAAGGoF8Q" +
                    "D05TS2V5ZWRBcmNoaXZlctEICVRyb290gAGjCwwiVSRudWxs3xARDQ4PEBESExQVFhcYGRobHB0e" +
                    "Hx8fHx4eHh4eIB8fIR4fH18QFWRpcmVjdE1lc3NhZ2VzU2V0dGluZ1xiYWRnZVNldHRpbmdfEBNh" +
                    "dXRob3JpemF0aW9uU3RhdHVzXHNvdW5kU2V0dGluZ18QGW5vdGlmaWNhdGlvbkNlbnRlclNldHRp" +
                    "bmdfEBRjcml0aWNhbEFsZXJ0U2V0dGluZ18QE3Nob3dQcmV2aWV3c1NldHRpbmdeY2FyUGxheVNl" +
                    "dHRpbmdfEA9ncm91cGluZ1NldHRpbmdfEBR0aW1lU2Vuc2l0aXZlU2V0dGluZ18QH3Byb3ZpZGVz" +
                    "QXBwTm90aWZpY2F0aW9uU2V0dGluZ3NfEBhzY2hlZHVsZWREZWxpdmVyeVNldHRpbmdfEBFsb2Nr" +
                    "U2NyZWVuU2V0dGluZ1YkY2xhc3NaYWxlcnRTdHlsZV8QE2Fubm91bmNlbWVudFNldHRpbmdcYWxl" +
                    "cnRTZXR0aW5nEAAQAQiAAtIjJCUmWiRjbGFzc25hbWVYJGNsYXNzZXNfEBZVTk5vdGlmaWNhdGlv" +
                    "blNldHRpbmdzoicoXxAWVU5Ob3RpZmljYXRpb25TZXR0aW5nc1hOU09iamVjdAAIABEAGgAkACkA" +
                    "MgA3AEkATABRAFMAVwBdAIIAmgCnAL0AygDmAP0BEwEiATQBSwFtAYgBnAGjAa4BxAHRAdMB1QHW" +
                    "AdgB3QHoAfECCgINAiYAAAAAAAACAQAAAAAAAAApAAAAAAAAAAAAAAAAAAACLw=="

            case .notDetermined:
                "YnBsaXN0MDDUAQIDBAUGBwpYJHZlcnNpb25ZJGFyY2hpdmVyVCR0b3BYJG9iamVjdHMSAAGGoF8Q" +
                    "D05TS2V5ZWRBcmNoaXZlctEICVRyb290gAGjCwwhVSRudWxs3xARDQ4PEBESExQVFhcYGRobHB0e" +
                    "Hh4eHh4eHh4eHx4eIB4eHl8QFWRpcmVjdE1lc3NhZ2VzU2V0dGluZ1xiYWRnZVNldHRpbmdfEBNh" +
                    "dXRob3JpemF0aW9uU3RhdHVzXHNvdW5kU2V0dGluZ18QGW5vdGlmaWNhdGlvbkNlbnRlclNldHRp" +
                    "bmdfEBRjcml0aWNhbEFsZXJ0U2V0dGluZ18QE3Nob3dQcmV2aWV3c1NldHRpbmdeY2FyUGxheVNl" +
                    "dHRpbmdfEA9ncm91cGluZ1NldHRpbmdfEBR0aW1lU2Vuc2l0aXZlU2V0dGluZ18QH3Byb3ZpZGVz" +
                    "QXBwTm90aWZpY2F0aW9uU2V0dGluZ3NfEBhzY2hlZHVsZWREZWxpdmVyeVNldHRpbmdfEBFsb2Nr" +
                    "U2NyZWVuU2V0dGluZ1YkY2xhc3NaYWxlcnRTdHlsZV8QE2Fubm91bmNlbWVudFNldHRpbmdcYWxl" +
                    "cnRTZXR0aW5nEAAIgALSIiMkJVokY2xhc3NuYW1lWCRjbGFzc2VzXxAWVU5Ob3RpZmljYXRpb25T" +
                    "ZXR0aW5nc6ImJ18QFlVOTm90aWZpY2F0aW9uU2V0dGluZ3NYTlNPYmplY3QACAARABoAJAApADIA" +
                    "NwBJAEwAUQBTAFcAXQCCAJoApwC9AMoA5gD9ARMBIgE0AUsBbQGIAZwBowGuAcQB0QHTAdQB1gHb" +
                    "AeYB7wIIAgsCJAAAAAAAAAIBAAAAAAAAACgAAAAAAAAAAAAAAAAAAAIt"

            default:
                fatalError("not implemented")
            }

        return try decoded(encoded)
    }

    private static func decoded(_ base64Encoded: String) throws -> Self {
        let data = try XCTUnwrap(Data(base64Encoded: base64Encoded))
        let decoded = try NSKeyedUnarchiver.unarchivedObject(ofClass: Self.self, from: data)
        return try XCTUnwrap(decoded)
    }
}
