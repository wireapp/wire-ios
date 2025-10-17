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

import Foundation
import GenericMessageProtocol

// TODO: [WPB-16311] This is currently just a stub and needs to be implemented properly.
public final class MultipartMessageData: NSObject {

    public struct Attachment {
        public let nodeID: UUID
        public let contentType: String?
        public let initialName: String?
        public let initialSize: Int?
    }

    public let attachments: [Attachment]

    init(multipart: Multipart) {
        self.attachments = multipart.attachments.compactMap { attachment in
            let asset = attachment.cellAsset

            guard let nodeID = UUID(uuidString: asset.uuid) else { return nil }

            return Attachment(
                nodeID: nodeID,
                contentType: asset.hasContentType ? asset.contentType : nil,
                initialName: asset.hasInitialName ? URL(string: asset.initialName)?.lastPathComponent : nil,
                initialSize: asset.hasInitialSize ? Int(attachment.cellAsset.initialSize) : nil
            )
        }
    }

}
