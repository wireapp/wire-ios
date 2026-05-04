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

public import Foundation

public struct CommitBundle: Sendable, Equatable {

    public var welcome: Data?

    public var commit: Data

    public var groupInfo: Data

    public init(welcome: Data?, commit: Data, groupInfo: Data) {
        self.welcome = welcome
        self.commit = commit
        self.groupInfo = groupInfo
    }

    func transportData() -> Data {
        var data = Data()
        data.append(commit)

        if let welcome {
            data.append(welcome)
        }

        data.append(groupInfo)

        return data
    }
}
