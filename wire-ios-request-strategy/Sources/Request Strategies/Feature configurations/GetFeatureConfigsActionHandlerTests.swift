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
@testable import WireRequestStrategy

// MARK: - GetFeatureConfigsActionHandlerTests

final class GetFeatureConfigsActionHandlerTests: MessagingTestBase {
    // MARK: - Helpers

    func mockResponse(status: Int, label: String) -> ZMTransportResponse {
        let payload = ["label": label] as ZMTransportData
        return mockResponse(status: status, payload: payload)
    }

    func mockResponse(status: Int, payload: ZMTransportData? = nil) -> ZMTransportResponse {
        ZMTransportResponse(
            payload: payload,
            httpStatus: status,
            transportSessionError: nil,
            apiVersion: APIVersion.v0.rawValue
        )
    }

    // MARK: - Request generation

    func test_ItGeneratesARequest() throws {
        // Given
        let sut = GetFeatureConfigsActionHandler(context: syncMOC)
        let action = GetFeatureConfigsAction()

        // When
        let request = try XCTUnwrap(sut.request(for: action, apiVersion: .v0))

        // Then
        XCTAssertEqual(request.path, "/feature-configs")
        XCTAssertEqual(request.method, .get)
    }

    // MARK: - Response handling

    func test_ItHandlesResponse_200() {
        syncMOC.performAndWait {
            // Given
            let sut = GetFeatureConfigsActionHandler(context: self.syncMOC)
            var action = GetFeatureConfigsAction()

            // Expectation
            let gotResult = self.customExpectation(description: "gotResult")

            action.onResult { result in
                switch result {
                case .success:
                    break

                default:
                    XCTFail("Expected 'success'")
                }

                gotResult.fulfill()
            }

            let payloadString = JSONPayload.valuesHTTPStatus200

            // When
            sut.handleResponse(
                self.mockResponse(status: 200, payload: payloadString as ZMTransportData),
                action: action
            )
            XCTAssert(self.waitForCustomExpectations(withTimeout: 0.5))

            // Then
            let featureRepository = FeatureRepository(context: self.syncMOC)

            let appLock = featureRepository.fetchAppLock()
            XCTAssertEqual(appLock.status, .enabled)
            XCTAssertEqual(appLock.config.enforceAppLock, true)
            XCTAssertEqual(appLock.config.inactivityTimeoutSecs, 11)

            let classifiedDomains = featureRepository.fetchClassifiedDomains()
            XCTAssertEqual(classifiedDomains.status, .enabled)
            XCTAssertEqual(classifiedDomains.config.domains, ["foo"])

            let conferenceCalling = featureRepository.fetchConferenceCalling()
            XCTAssertEqual(conferenceCalling.status, .enabled)

            let conversationGuestLinks = featureRepository.fetchConversationGuestLinks()
            XCTAssertEqual(conversationGuestLinks.status, .enabled)

            let digitalSignature = featureRepository.fetchDigitalSignature()
            XCTAssertEqual(digitalSignature.status, .enabled)

            let fileSharing = featureRepository.fetchFileSharing()
            XCTAssertEqual(fileSharing.status, .enabled)

            let mls = featureRepository.fetchMLS()
            XCTAssertEqual(mls.status, .enabled)
            XCTAssertEqual(mls.config, .init(defaultProtocol: .mls))

            let selfDeletingMessage = featureRepository.fetchSelfDeletingMesssages()
            XCTAssertEqual(selfDeletingMessage.status, .enabled)
            XCTAssertEqual(selfDeletingMessage.config.enforcedTimeoutSeconds, 22)

            let e2ei = featureRepository.fetchE2EI()
            XCTAssertEqual(e2ei.status, .enabled)
            XCTAssertEqual(e2ei.config.acmeDiscoveryUrl, "https://example.com")
            XCTAssertEqual(e2ei.config.verificationExpiration, 70)
            XCTAssertEqual(e2ei.config.crlProxy, "https://example.com")
            XCTAssertEqual(e2ei.config.useProxyOnMobile, true)

            let mlsMigration = featureRepository.fetchMLSMigration()
            XCTAssertEqual(mlsMigration.status, .enabled)
            XCTAssertEqual(
                mlsMigration.config.startTime?.transportString(),
                "2024-02-19T11:59:27.542Z"
            )
            XCTAssertEqual(
                mlsMigration.config.finaliseRegardlessAfter?.transportString(),
                "2024-02-19T11:59:28.542Z"
            )
        }

        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
    }

    func test_ShouldTakeDefaultValuesWhenHandlingResponseWithNoFeatures_200() throws {
        syncMOC.performGroupedBlock {
            // Given
            let sut = GetFeatureConfigsActionHandler(context: self.syncMOC)
            var action = GetFeatureConfigsAction()

            // Expectation
            let gotResult = self.customExpectation(description: "gotResult")

            action.onResult { result in
                switch result {
                case .success:
                    break

                default:
                    XCTFail("Expected 'success'")
                }

                gotResult.fulfill()
            }

            let payloadString = JSONPayload.empty

            // When
            sut.handleResponse(
                self.mockResponse(status: 200, payload: payloadString as ZMTransportData),
                action: action
            )
            XCTAssert(self.waitForCustomExpectations(withTimeout: 0.5))

            // Then
            let featureRepository = FeatureRepository(context: self.syncMOC)

            let appLock = featureRepository.fetchAppLock()
            XCTAssertEqual(appLock.status, .enabled)
            XCTAssertEqual(appLock.config, .init())

            let classifiedDomains = featureRepository.fetchClassifiedDomains()
            XCTAssertEqual(classifiedDomains.status, .disabled)
            XCTAssertEqual(classifiedDomains.config, .init())

            let conferenceCalling = featureRepository.fetchConferenceCalling()
            XCTAssertEqual(conferenceCalling.status, .enabled)

            let conversationGuestLinks = featureRepository.fetchConversationGuestLinks()
            XCTAssertEqual(conversationGuestLinks.status, .enabled)

            let digitalSignature = featureRepository.fetchDigitalSignature()
            XCTAssertEqual(digitalSignature.status, .disabled)

            let fileSharing = featureRepository.fetchFileSharing()
            XCTAssertEqual(fileSharing.status, .enabled)

            let mls = featureRepository.fetchMLS()
            XCTAssertEqual(mls.status, .disabled)
            XCTAssertEqual(mls.config, .init())

            let selfDeletingMessage = featureRepository.fetchSelfDeletingMesssages()
            XCTAssertEqual(selfDeletingMessage.status, .enabled)
            XCTAssertEqual(selfDeletingMessage.config, .init())

            let e2ei = featureRepository.fetchE2EI()
            XCTAssertEqual(e2ei.status, .disabled)
            XCTAssertEqual(e2ei.config, .init())

            let mlsMigration = featureRepository.fetchMLSMigration()
            XCTAssertEqual(mlsMigration.status, .disabled)
            XCTAssertEqual(mlsMigration.config, .init())
        }

        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
    }

    func test_ItHandlesResponse_200_MalformedResponse() throws {
        // Given
        let sut = GetFeatureConfigsActionHandler(context: syncMOC)
        var action = GetFeatureConfigsAction()

        // Expectation
        let gotResult = customExpectation(description: "gotResult")

        action.onResult { result in
            switch result {
            case .failure(.malformedResponse):
                break

            default:
                XCTFail("Expected 'malformed response'")
            }

            gotResult.fulfill()
        }

        // When
        sut.handleResponse(mockResponse(status: 200, payload: nil), action: action)
        XCTAssert(waitForCustomExpectations(withTimeout: 0.5))
    }

    func test_ItHandlesResponse_403_InsuffientPermissions() throws {
        // Given
        let sut = GetFeatureConfigsActionHandler(context: syncMOC)
        var action = GetFeatureConfigsAction()

        // Expectation
        let gotResult = customExpectation(description: "gotResult")

        action.onResult { result in
            switch result {
            case .failure(.insufficientPermissions):
                break

            default:
                XCTFail("Expected 'insufficient permissions'")
            }

            gotResult.fulfill()
        }

        // When
        sut.handleResponse(mockResponse(status: 403, label: "operation-denied"), action: action)
        XCTAssert(waitForCustomExpectations(withTimeout: 0.5))
    }

    func test_ItHandlesResponse_403_UserIsNotTeamMember() throws {
        // Given
        let sut = GetFeatureConfigsActionHandler(context: syncMOC)
        var action = GetFeatureConfigsAction()

        // Expectation
        let gotResult = customExpectation(description: "gotResult")

        action.onResult { result in
            switch result {
            case .failure(.userIsNotTeamMember):
                break

            default:
                XCTFail("Expected 'user is not team member'")
            }

            gotResult.fulfill()
        }

        // When
        sut.handleResponse(mockResponse(status: 403, label: "no-team-member"), action: action)
        XCTAssert(waitForCustomExpectations(withTimeout: 0.5))
    }

    func test_ItHandlesResponse_404_TeamNotFound() throws {
        // Given
        let sut = GetFeatureConfigsActionHandler(context: syncMOC)
        var action = GetFeatureConfigsAction()

        // Expectation
        let gotResult = customExpectation(description: "gotResult")

        action.onResult { result in
            switch result {
            case .failure(.teamNotFound):
                break

            default:
                XCTFail("Expected 'team not found'")
            }

            gotResult.fulfill()
        }

        // When
        sut.handleResponse(mockResponse(status: 404, label: "no-team"), action: action)
        XCTAssert(waitForCustomExpectations(withTimeout: 0.5))
    }

    func test_ItHandlesResponse_UnknownResponse() throws {
        // Given
        let sut = GetFeatureConfigsActionHandler(context: syncMOC)
        var action = GetFeatureConfigsAction()

        // Expectation
        let gotResult = customExpectation(description: "gotResult")

        action.onResult { result in
            switch result {
            case let .failure(.unknown(status, label)):
                XCTAssertEqual(status, 999)
                XCTAssertEqual(label, "foo")

            default:
                XCTFail("Expected 'unknown status: 999, label: foo'")
            }

            gotResult.fulfill()
        }

        // When
        sut.handleResponse(mockResponse(status: 999, label: "foo"), action: action)
        XCTAssert(waitForCustomExpectations(withTimeout: 0.5))
    }

    func test_ItDecodesMLSFeatureConfig_V3() throws {
        // There was a bug where we couldn't decode the mls feature config for v3 because
        // 'supportedProtocols' was missing.
        syncMOC.performAndWait {
            // Given
            let sut = GetFeatureConfigsActionHandler(context: self.syncMOC)
            var action = GetFeatureConfigsAction()

            // Expectation
            let gotResult = self.customExpectation(description: "gotResult")

            action.onResult { result in
                switch result {
                case .success:
                    break

                default:
                    XCTFail("Expected 'success'")
                }

                gotResult.fulfill()
            }

            let payloadString = JSONPayload.mlsConfigV3

            // When
            sut.handleResponse(
                self.mockResponse(status: 200, payload: payloadString as ZMTransportData),
                action: action
            )
            XCTAssert(self.waitForCustomExpectations(withTimeout: 0.5))

            // Then
            let featureRepository = FeatureRepository(context: self.syncMOC)

            let mls = featureRepository.fetchMLS()
            XCTAssertEqual(mls.status, .enabled)
            XCTAssertEqual(mls.config.protocolToggleUsers, [UUID(uuidString: "881b1824-a6e1-4a60-8cc3-14feabf6dec0")!])
            XCTAssertEqual(mls.config.defaultProtocol, .proteus)
            XCTAssertEqual(mls.config.allowedCipherSuites, [.MLS_128_DHKEMX25519_AES128GCM_SHA256_Ed25519])
            XCTAssertEqual(mls.config.supportedProtocols, [.proteus])
        }

        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
    }
}

// MARK: - JSONPayload

private enum JSONPayload {
    static let empty = "{}"

    static let valuesHTTPStatus200 =
        """
        {
            "conversationGuestLinks": {
                "status": "enabled"
            },
            "mls": {
                "status": "enabled",
                "config": {
                    "supportedProtocols": [],
                    "defaultCipherSuite": 1,
                    "protocolToggleUsers": [],
                    "allowedCipherSuites": [
                        1
                    ],
                    "defaultProtocol": "mls"
                }
            },
            "appLock": {
                "config": {
                    "enforceAppLock": true,
                    "inactivityTimeoutSecs": 11
                },
                "status": "enabled"
            },
            "mlsMigration": {
                "status": "enabled",
                "config": {
                    "startTime": "2024-02-19T11:59:27.542Z",
                    "finaliseRegardlessAfter": "2024-02-19T11:59:28.542Z"
                }
            },
            "mlsE2EId": {
                "status": "enabled",
                "config": {
                    "acmeDiscoveryUrl": "https://example.com",
                    "verificationExpiration": 70,
                    "crlProxy": "https://example.com",
                    "useProxyOnMobile": true
                }
            },
            "conferenceCalling": {
                "status": "enabled"
            },
            "fileSharing": {
                "status": "enabled"
            },
            "digitalSignatures": {
                "status": "enabled"
            },
            "classifiedDomains": {
                "config": {
                    "domains": [
                        "foo"
                    ]
                },
                "status": "enabled"
            },
            "selfDeletingMessages": {
                "status": "enabled",
                "config": {
                    "enforcedTimeoutSeconds": 22
                }
            }
        }
        """

    static let mlsConfigV3 =
        """
        {
            "mls": {
                "status": "enabled",
                "config": {
                    "defaultCipherSuite": 1,
                    "protocolToggleUsers": ["881b1824-a6e1-4a60-8cc3-14feabf6dec0"],
                    "allowedCipherSuites": [1],
                    "defaultProtocol": "proteus"
                }
            }
        }
        """
}
