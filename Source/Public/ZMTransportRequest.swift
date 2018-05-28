//
// Wire
// Copyright (C) 2018 Wire Swiss GmbH
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
import WireUtilities

extension String {
    static let UUIDMatcher: NSRegularExpression = {
        let regex = try! NSRegularExpression(pattern: "[a-f0-9]{8}-[a-f0-9]{4}-4[a-f0-9]{3}-[89aAbB][a-f0-9]{3}-[a-f0-9]{12}", options: .caseInsensitive)
        return regex
    }()
    
    public var removingUUIDs: String {
        let range = NSMakeRange(0, self.count)
        return type(of: self).UUIDMatcher.stringByReplacingMatches(in: self, options: [], range: range, withTemplate: "<uuid>")
    }
}

extension ZMTransportRequest: PrivateStringConvertible {
    public var privateDescription: String {
        return "\(type(of: self)) \(Unmanaged.passUnretained(self).toOpaque()): method=\(ZMTransportRequest.string(for: self.method)) \(self.path.removingUUIDs)"
    }
}
