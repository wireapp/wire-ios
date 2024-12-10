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
import WireLinkPreview

@objc(ZMTextMessage) @objcMembers
final class TextMessage: ZMMessage, TextMessageData {

    // swiftlint:disable:next static_over_final_class
    override class func entityName() -> String { "TextMessage" }

    @NSManaged public var text: String?

    override var textMessageData: (any TextMessageData)? { self }
    var messageText: String? { text }

    var mentions: [Mention] { [] }

    var linkPreview: LinkMetadata? { .none }
    var linkPreviewHasImage: Bool { false }
    var linkPreviewImageCacheKey: String? { nil }

    var hasQuote: Bool { false }
    var quoteMessage: (any ZMConversationMessage)? { nil }
    var isQuotingSelf: Bool { false }

    override func shortDebugDescription() -> String {
        super.shortDebugDescription() + (text.map { "'\($0)'" } ?? "<nil>")
    }

    // swiftlint:disable:next static_over_final_class
    override class func createOrUpdate(
        from updateEvent: ZMUpdateEvent,
        in moc: NSManagedObjectContext,
        prefetchResult: ZMFetchRequestBatchResult?
    ) -> Self? {
        nil
    }

    func fetchLinkPreviewImageData(
        queue: DispatchQueue,
        completionHandler: @escaping (_ imageData: Data?) -> Void
    ) {
        completionHandler(nil)
    }

    func requestLinkPreviewImageDownload() {
        // no op
    }

    func editText(_ text: String, mentions: [Mention], fetchLinkPreview: Bool) {
        // no op
    }

    override func removeClearingSender(_ clearingSender: Bool) {
        text = nil
        super.removeClearingSender(clearingSender)
    }
}
