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
import WireFoundation
import WireNetwork

public protocol IsBuildBlacklistedUseCase {

    func invoke() async -> Bool

}

public enum IsBuildBlacklistedUseCaseError: Error {

    case decodingFailed(message: String)

}

public struct IsBuildBlacklistedUseCaseImpl: IsBuildBlacklistedUseCase {

    private let currentBuildNumber: String
    private let api: any BlacklistAPI

    public init(
        currentBuildNumber: String,
        api: any BlacklistAPI
    ) {
        self.currentBuildNumber = DeveloperOverrides.buildNumber ?? currentBuildNumber
        self.api = api
    }

    public func invoke() async -> Bool {
        do {
            let blacklist = try await api.getBlacklist()

            guard
                let currentVersion = Int(currentBuildNumber),
                let minLegalVersion = Int(blacklist.minimumLegalBuildNumber)
            else {
                return false
            }

            return currentVersion < minLegalVersion || blacklist.illegalBuildNumbers.contains(String(currentVersion))
        } catch {
            // As per specs, if there is any failure obtaining the blacklist,
            // whether it is missing, can't be decoded, or otherwise, then
            // consider it empty (i.e all clients valid).
            return false
        }
    }

}
