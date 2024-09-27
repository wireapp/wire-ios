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

@testable import Wire

final class MockCollection: NSObject, ZMCollection {
    // MARK: Lifecycle

    init(messages: [CategoryMatch: [ZMConversationMessage]]) {
        self.messages = messages
    }

    convenience init(fileMessages: [ZMConversationMessage]) {
        self.init(messages: [
            MockCollection.onlyFilesCategory: fileMessages,
        ])
    }

    convenience init(linkMessages: [ZMConversationMessage]) {
        self.init(messages: [
            MockCollection.onlyLinksCategory: linkMessages,
        ])
    }

    // MARK: Internal

    static let onlyImagesCategory = CategoryMatch(including: .image, excluding: .none)
    static let onlyVideosCategory = CategoryMatch(including: .video, excluding: .none)
    static let onlyFilesCategory = CategoryMatch(including: .file, excluding: .video)
    static let onlyLinksCategory = CategoryMatch(including: .linkPreview, excluding: .none)

    static var empty: MockCollection {
        MockCollection(messages: [:])
    }

    let messages: [CategoryMatch: [ZMConversationMessage]]

    let fetchingDone = true

    func tearDown() {}

    func assets(for category: WireDataModel.CategoryMatch) -> [ZMConversationMessage] {
        messages[category] ?? []
    }
}
