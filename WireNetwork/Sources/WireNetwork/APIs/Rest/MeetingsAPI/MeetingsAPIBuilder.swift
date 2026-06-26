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

/// A builder of `MeetingsAPI`.

public struct MeetingsAPIBuilder {

    let apiService: any APIServiceProtocol

    /// Create a new builder.
    ///
    /// - Parameter apiService: An api service.

    public init(apiService: any APIServiceProtocol) {
        self.apiService = apiService
    }

    /// Make a versioned `MeetingsAPI`.
    ///
    /// - Parameter version: An api version.
    /// - Returns: A versioned `MeetingsAPI`.

    public func makeAPI(for version: APIVersion) -> any MeetingsAPI {
        switch version {
        case .v0:
            MeetingsAPIV0(apiService: apiService)
        case .v1:
            MeetingsAPIV1(apiService: apiService)
        case .v2:
            MeetingsAPIV2(apiService: apiService)
        case .v3:
            MeetingsAPIV3(apiService: apiService)
        case .v4:
            MeetingsAPIV4(apiService: apiService)
        case .v5:
            MeetingsAPIV5(apiService: apiService)
        case .v6:
            MeetingsAPIV6(apiService: apiService)
        case .v7:
            MeetingsAPIV7(apiService: apiService)
        case .v8:
            MeetingsAPIV8(apiService: apiService)
        case .v9:
            MeetingsAPIV9(apiService: apiService)
        case .v10:
            MeetingsAPIV10(apiService: apiService)
        case .v11:
            MeetingsAPIV11(apiService: apiService)
        case .v12:
            MeetingsAPIV12(apiService: apiService)
        case .v13:
            MeetingsAPIV13(apiService: apiService)
        case .v14:
            MeetingsAPIV14(apiService: apiService)
        case .v15:
            MeetingsAPIV15(apiService: apiService)
        case .v16:
            MeetingsAPIV16(apiService: apiService)
        }
    }
}
