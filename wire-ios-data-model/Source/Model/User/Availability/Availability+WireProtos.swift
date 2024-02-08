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

import WireProtos

extension Availability {

    public init(proto: WireProtos.Availability) {
        switch proto.type {
        case .none:
            self = .none
        case .available:
            self = .available
        case .away:
            self = .away
        case .busy:
            self = .busy
        }
    }
}

extension WireProtos.Availability {

    public init(_ availability: Availability) {
        self = WireProtos.Availability.with { populator in
            switch availability {
            case .none:
                populator.type = .none
            case .available:
                populator.type = .available
            case .away:
                populator.type = .away
            case .busy:
                populator.type = .busy
            }
        }
    }
}
