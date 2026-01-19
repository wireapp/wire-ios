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

public extension AttributedString {
    static func formattedMarkdown(
        key: String.LocalizationValue,
        bundle: Bundle? = nil,
        _ arguments: any CVarArg...
    ) -> AttributedString {
        let string: String = .formated(key: key, bundle: bundle, arguments)
        return .markdown(from: string)
    }

    static func localizedMarkdown(key: String.LocalizationValue, bundle: Bundle? = nil) -> AttributedString {
        let string: String = .localized(key: key, bundle: bundle)
        return .markdown(from: string)
    }

    static func markdown(from string: String) -> AttributedString {
        (try? AttributedString(markdown: string)) ?? AttributedString(string)
    }
}
