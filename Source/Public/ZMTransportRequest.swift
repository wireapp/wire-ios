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
    fileprivate static let UUIDMatcher: NSRegularExpression = {
        let regex = try! NSRegularExpression(pattern: "[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}", options: .caseInsensitive)
        return regex
    }()
    
    fileprivate static let clientIDMatcher: NSRegularExpression = {
        let regex = try! NSRegularExpression(pattern: "[a-f0-9]{13,16}", options: .caseInsensitive)
        return regex
    }()
    
    fileprivate static let matchers = [UUIDMatcher, clientIDMatcher]

    var removingSensitiveInfo: String {
        let result = NSMutableString(string: self)
        let range = NSMakeRange(0, self.count)

        String.matchers
        .flatMap {
            $0.matches(in: self, options: [], range: range)
        }
        .reversed()
        .forEach {
            let matchedString = result.substring(with: $0.range)
            result.replaceCharacters(in: $0.range, with: matchedString.readableHash)
        }

        return result as String
    }
}

extension ZMTransportRequest: SafeForLoggingStringConvertible {
    @objc public var safeForLoggingDescription: String {
        let identifier = "\(Unmanaged.passUnretained(self).toOpaque())".readableHash
        return "<\(identifier)> \(ZMTransportRequest.string(for: self.method)) \(self.path.removingSensitiveInfo)"
    }
}
