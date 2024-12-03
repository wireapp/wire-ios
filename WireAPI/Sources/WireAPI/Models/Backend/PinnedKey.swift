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

public struct PinnedKey: Sendable {

    public struct Host: Sendable {

        public enum Rule: String, Sendable {

            case endsWith
            case equals

        }

        let rule: Rule
        let value: String

        public init(rule: Rule, value: String) {
            self.rule = rule
            self.value = value
        }

    }

    let key: Data
    let hosts: [Host]

    public init(key: Data, hosts: [Host]) {
        self.key = key
        self.hosts = hosts
    }

}
