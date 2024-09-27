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

// MARK: - ChangeUsernameError

public enum ChangeUsernameError: Error {
    case taken
    case unknown
}

// MARK: - ChangeUsernameUseCaseProtocol

/// Change the user name of the self user

public protocol ChangeUsernameUseCaseProtocol {
    func invoke(username: String) async throws
}

// MARK: - ChangeUsernameUseCase

class ChangeUsernameUseCase: NSObject, ChangeUsernameUseCaseProtocol {
    // MARK: Lifecycle

    init(userProfile: UserProfile) {
        self.userProfile = userProfile
    }

    // MARK: Internal

    let userProfile: UserProfile
    var continuation: CheckedContinuation<Void, Error>?
    var token: Any?

    func invoke(username: String) async throws {
        _ = try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            userProfile.requestSettingHandle(handle: username)
            token = userProfile.add(observer: self)
        }
    }
}

// MARK: UserProfileUpdateObserver

extension ChangeUsernameUseCase: UserProfileUpdateObserver {
    func didSetHandle() {
        continuation?.resume()
        continuation = nil
        token = nil
    }

    func didFailToSetHandle() {
        continuation?.resume(throwing: ChangeUsernameError.unknown)
        continuation = nil
        token = nil
    }

    func didFailToSetHandleBecauseExisting() {
        continuation?.resume(throwing: ChangeUsernameError.taken)
        continuation = nil
        token = nil
    }
}
