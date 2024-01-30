//
// Wire
// Copyright (C) 2023 Wire Swiss GmbH
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

extension Swift.Result where Success == Void {
    public static func success() -> Self {
        .success(())
    }
}

public typealias Result<T> = ZMResult<T>

public enum ZMResult<T> {
    case success(T)
    case failure(Error)
}

public extension ZMResult {
    var value: T? {
        guard case let .success(value) = self else { return nil }
        return value
    }

    var error: Error? {
        guard case let .failure(error) = self else { return nil }
        return error
    }
}
