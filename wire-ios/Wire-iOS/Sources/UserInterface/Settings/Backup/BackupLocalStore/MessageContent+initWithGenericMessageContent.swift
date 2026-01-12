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

import GenericMessageProtocol
import WireBackup

extension MessageBackupModel.Content {

    init?(_ content: GenericMessage.OneOf_Content) {
        switch content {
        case let .text(text):
            self.init(text)
        case let .asset(asset):
            self.init(asset)
        case let .location(location):
            self.init(location)
        case let .edited(messageEdit):
            self.init(messageEdit)
        case let .ephemeral(ephemeral):
            self.init(ephemeral)
        case let .multipart(multipart):
            self.init(multipart)
        case .knock, .lastRead, .cleared, .external, .clientAction, .calling, .hidden, .deleted, .confirmation,
             .reaction, .availability, .composite, .buttonAction, .buttonActionConfirmation, .dataTransfer, .image,
             .inCallEmoji, .inCallHandRaise:
            return nil
        }
    }

    private init?(_ ephemeral: Ephemeral) {
        switch ephemeral.content {
        case let .text(text):
            self.init(text)
        case let .location(location):
            self.init(location)
        case .knock, .asset, .image, .none:
            return nil
        }
    }

    private init(_ text: Text) {
        self = .text(text.content)
    }

    private init(_ location: Location) {
        self = .location(
            longitude: location.longitude,
            latitude: location.latitude,
            name: location.hasName ? location.name : nil,
            zoom: location.hasZoom ? location.zoom : nil
        )
    }

    private init?(_ messageEdit: MessageEdit) {
        switch messageEdit.content {
        case let .text(text):
            self.init(text)
        case .composite:
            fallthrough // composite messages are not supported in backups yet
        case .none:
            return nil
        }
    }

    private init?(_ asset: Asset) {
        guard
            let original = asset.hasOriginal ? asset.original : nil,
            let uploaded = asset.hasUploaded ? asset.uploaded : nil
        else { return nil }

        self = .asset(
            mimeType: original.hasMimeType ? original.mimeType : "application/octet-stream",
            size: original.size,
            name: original.hasName ? original.name : nil,
            otrKey: uploaded.otrKey,
            sha256: uploaded.sha256,
            assetID: uploaded.assetID,
            assetToken: uploaded.hasAssetToken ? uploaded.assetToken : nil,
            assetDomain: uploaded.hasAssetDomain ? uploaded.assetDomain : nil,
            encryption: uploaded.hasEncryption ? .init(uploaded.encryption) : nil,
            metadata: original.metaData.flatMap(MessageBackupModel.Content.AssetContent.Metadata.init) ??
                .generic(name: original.hasName ? original.name : nil)
        )
    }

    private init?(_ multipart: Multipart) {
        // TODO: [WPB-17971] Support multipart messages in backup
        nil
    }
}
