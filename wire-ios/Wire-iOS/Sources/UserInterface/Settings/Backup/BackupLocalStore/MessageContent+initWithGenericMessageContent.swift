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

import WireBackup
import WireProtos

extension MessageBackupModel.Content {

    init?(_ content: GenericMessage.OneOf_Content) {
        switch content {
        case let .text(text):
            self.init(text)
        case let .image(imageAsset):
            self.init(imageAsset)
        case let .asset(asset):
            self.init(asset)
        case let .location(location):
            self.init(location)
        case let .edited(messageEdit):
            self.init(messageEdit)
        case let .ephemeral(ephemeral):
            self.init(ephemeral)
        case .knock, .lastRead, .cleared, .external, .clientAction, .calling, .hidden, .deleted, .confirmation,
             .reaction, .availability, .composite, .buttonAction, .buttonActionConfirmation, .dataTransfer,
             .inCallEmoji,
             .inCallHandRaise:
            return nil
        }
    }

    private init?(_ ephemeral: Ephemeral) {
        switch ephemeral.content {
        case let .text(text):
            self.init(text)
        case let .image(imageAsset):
            self.init(imageAsset)
        case let .location(location):
            self.init(location)
        case .knock, .asset, .none:
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
        case .composite, .none:
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
            metadata: original.metaData.flatMap(MessageBackupModel.Content.AssetContent.Metadata.init)
        )
    }

    private init?(_ imageAsset: ImageAsset) {
        self = .asset(
            mimeType: imageAsset.hasMimeType ? imageAsset.mimeType : "application/octet-stream",
            size: UInt64(imageAsset.size),
            name: .none,
            otrKey: imageAsset.otrKey,
            sha256: imageAsset.sha256,
            assetID: "", // TODO: what value to set? is empty string ok?
            assetToken: .none,
            assetDomain: .none,
            encryption: .none,
            metadata: .image(
                width: imageAsset.width, // TODO: use .width or .originalWidth?
                height: imageAsset.height,
                tag: imageAsset.hasTag ? imageAsset.tag : ""
            )
        )
    }

}
