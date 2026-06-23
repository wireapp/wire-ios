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

import XCTest

@testable import WireNetwork
@testable import WireNetworkSupport

final class MeetingsAPITests: XCTestCase {

    private var apiSnapshotHelper: APIServiceSnapshotHelper<any MeetingsAPI>!

    // MARK: - Setup

    override func setUp() {
        super.setUp()
        apiSnapshotHelper = APIServiceSnapshotHelper { apiService, apiVersion in
            let builder = MeetingsAPIBuilder(apiService: apiService)
            return builder.makeAPI(for: apiVersion)
        }
    }

    override func tearDown() {
        apiSnapshotHelper = nil
        super.tearDown()
    }

    // MARK: -

    enum Scaffolding {
        static let meetingID = QualifiedID(
            id: UUID(uuidString: "9c2e5e1a-1234-5678-abcd-0123456789ab")!,
            domain: "example.com"
        )
    }

}

private extension APIVersion {
    func buildAPI(apiService: any APIServiceProtocol) -> any MeetingsAPI {
        let builder = MeetingsAPIBuilder(apiService: apiService)
        return builder.makeAPI(for: self)
    }
}
