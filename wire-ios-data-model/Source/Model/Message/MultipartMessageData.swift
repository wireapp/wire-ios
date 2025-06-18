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

// TODO: [WPB-16311] This is currently just a stub and needs to be implemented properly.
public final class MultipartMessageData: NSObject {

    public struct Attachment {
        public let fileName: String
    }

    public let attachments: [Attachment]

    init(multipart: Multipart) {
        self.attachments = multipart.attachments.map { attachment in
            Attachment(
                fileName: URL(string: attachment.cellAsset.initialName)?.lastPathComponent ?? "Unknown file name"
            )
        }
    }

}
