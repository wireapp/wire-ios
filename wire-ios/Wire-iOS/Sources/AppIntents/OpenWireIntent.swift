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

import AppIntents

@available(iOS 16, *)
struct OpenWireIntent: OpenIntent {

    static let title = LocalizedStringResource(stringLiteral: "title")

    @Parameter(title: "Trail", description: "The trail to get information on.")
    var target: Accountt
}

@available(iOS 16.0, *)
enum Accountt: String, AppEnum {

    static let typeDisplayRepresentation = TypeDisplayRepresentation(stringLiteral: "x")

    static var caseDisplayRepresentations: [Accountt: DisplayRepresentation] = [
        .a: DisplayRepresentation(title: "a",
                                       subtitle: "aaa",
                                       image: nil),
        .b: DisplayRepresentation(title: "b",
                                       subtitle: "bbb",
                                       image: nil),
    ]

    case a, b
}
