//
// Wire
// Copyright (C) 2022 Wire Swiss GmbH
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
import XCTest

final class AssetDownloadRequestFactoryTests: XCTestCase {

    override func tearDown() {
        BackendInfo.domain = nil
        super.tearDown()
    }

    // MARK: - API V0

    func test_GenerateGetAssetRequest() throws {
        // Given
        let sut = AssetDownloadRequestFactory()

        // When
        let request = try XCTUnwrap(sut.requestToGetAsset(
            withKey: "key",
            token: nil,
            domain: nil,
            apiVersion: .v0
        ))

        // Then
        XCTAssertEqual(request.path, "/assets/v3/key")
        XCTAssertEqual(request.method, .methodGET)
        XCTAssertEqual(request.apiVersion, 0)
    }

    // MARK: - API V1

    func test_GeneratesGetAssetRequestWithDomain() throws {
        // Given
        let sut = AssetDownloadRequestFactory()

        // When
        let request = try XCTUnwrap(sut.requestToGetAsset(
            withKey: "key",
            token: nil,
            domain: "domain",
            apiVersion: .v1
        ))

        // Then
        XCTAssertEqual(request.path, "/v1/assets/v4/domain/key")
        XCTAssertEqual(request.method, .methodGET)
        XCTAssertEqual(request.apiVersion, 1)
    }

    func test_GeneratesGetAssetRequestWithLocalDomainIfDomainIsNil() throws {
        // Given
        let sut = AssetDownloadRequestFactory()
        BackendInfo.domain = "localDomain"

        // When
        let request = try XCTUnwrap(sut.requestToGetAsset(
            withKey: "key",
            token: nil,
            domain: nil,
            apiVersion: .v1
        ))

        // Then
        XCTAssertEqual(request.path, "/v1/assets/v4/localDomain/key")
        XCTAssertEqual(request.method, .methodGET)
        XCTAssertEqual(request.apiVersion, 1)
    }

    func test_GeneratesGetAssetRequestWithLocalDomainIfDomainIsEmpty() throws {
        // Given
        let sut = AssetDownloadRequestFactory()
        BackendInfo.domain = "localDomain"

        // When
        let request = try XCTUnwrap(sut.requestToGetAsset(
            withKey: "key",
            token: nil,
            domain: "",
            apiVersion: .v1
        ))

        // Then
        XCTAssertEqual(request.path, "/v1/assets/v4/localDomain/key")
        XCTAssertEqual(request.method, .methodGET)
        XCTAssertEqual(request.apiVersion, 1)
    }

    func test_DoesNotGenerateGetAssetRequestIfNoDomainExists() throws {
        // Given
        let sut = AssetDownloadRequestFactory()
        BackendInfo.domain = nil

        // When
        let request = sut.requestToGetAsset(
            withKey: "key",
            token: nil,
            domain: nil,
            apiVersion: .v1
        )

        // Then
        XCTAssertNil(request)
    }

    // MARK: - API V2

    func test_GeneratesGetAssetRequestWithDomainForV2() throws {
        // Given
        let sut = AssetDownloadRequestFactory()

        // When
        let request = try XCTUnwrap(sut.requestToGetAsset(
            withKey: "key",
            token: nil,
            domain: "domain",
            apiVersion: .v2
        ))

        // Then
        XCTAssertEqual(request.path, "/v2/assets/domain/key")
        XCTAssertEqual(request.method, .methodGET)
        XCTAssertEqual(request.apiVersion, 2)
    }

    func test_GeneratesGetAssetRequestWithLocalDomainIfDomainIsNilForV2() throws {
        // Given
        let sut = AssetDownloadRequestFactory()
        BackendInfo.domain = "localDomain"

        // When
        let request = try XCTUnwrap(sut.requestToGetAsset(
            withKey: "key",
            token: nil,
            domain: nil,
            apiVersion: .v2
        ))

        // Then
        XCTAssertEqual(request.path, "/v2/assets/localDomain/key")
        XCTAssertEqual(request.method, .methodGET)
        XCTAssertEqual(request.apiVersion, 2)
    }

    func test_GeneratesGetAssetRequestWithLocalDomainIfDomainIsEmptyForV2() throws {
        // Given
        let sut = AssetDownloadRequestFactory()
        BackendInfo.domain = "localDomain"

        // When
        let request = try XCTUnwrap(sut.requestToGetAsset(
            withKey: "key",
            token: nil,
            domain: "",
            apiVersion: .v2
        ))

        // Then
        XCTAssertEqual(request.path, "/v2/assets/localDomain/key")
        XCTAssertEqual(request.method, .methodGET)
        XCTAssertEqual(request.apiVersion, 2)
    }

    func test_DoesNotGenerateGetAssetRequestIfNoDomainExistsForV2() throws {
        // Given
        let sut = AssetDownloadRequestFactory()
        BackendInfo.domain = nil

        // When
        let request = sut.requestToGetAsset(
            withKey: "key",
            token: nil,
            domain: nil,
            apiVersion: .v2
        )

        // Then
        XCTAssertNil(request)
    }

}
