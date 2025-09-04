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
import WireNetwork

public protocol IsBuildBlacklistedUseCase {

    func invoke() async throws -> Bool

}

public enum IsBuildBlacklistedUseCaseError: Error {

    case decodingFailed(message: String)

}

public struct IsBuildBlacklistedUseCaseImpl: IsBuildBlacklistedUseCase {

    let currentBuildNumber: String
    let api: any BlacklistAPI

    public init(
        currentBuildNumber: String,
        api: any BlacklistAPI
    ) {
        self.currentBuildNumber = currentBuildNumber
        self.api = api
    }

    public func invoke() async throws -> Bool {
        let blacklist = try await api.getBlacklist()

        guard let currrentVersion = Int(currentBuildNumber) else {
            throw IsBuildBlacklistedUseCaseError.decodingFailed(
                message: "current build number '\(currentBuildNumber)' must be an integer"
            )
        }

        guard let minLegalVersion = Int(blacklist.minimumLegalBuildNumber) else {
            throw IsBuildBlacklistedUseCaseError.decodingFailed(
                message: "blacklist version '\(blacklist.minimumLegalBuildNumber)' must be an integer"
            )
        }

        return currrentVersion < minLegalVersion || blacklist.illegalBuildNumbers.contains(currentBuildNumber)
    }

}
