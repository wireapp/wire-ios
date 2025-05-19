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

import Down
import Foundation

public extension NSAttributedString {

    @objc
    static func markdown(from text: String, style: DownStyle) -> NSMutableAttributedString {
        let down = Down(markdownString: text)
        let result: NSMutableAttributedString = if let attrStr = try? down.toAttributedString(using: style) {
            .init(attributedString: attrStr)
        } else {
            NSMutableAttributedString(string: text)
        }

        if result.string.last == "\n" {
            result.deleteCharacters(in: NSRange(location: result.length - 1, length: 1))
        }

        guard !result.string.isEmpty else {
            return .init(string: text)
        }

        return result
    }
}
