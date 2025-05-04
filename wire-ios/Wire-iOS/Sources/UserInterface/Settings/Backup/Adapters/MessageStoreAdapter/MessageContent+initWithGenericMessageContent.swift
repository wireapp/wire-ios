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

extension MessageContent {

    init?(genericMessageContent content: GenericMessage.OneOf_Content) {
        switch content {
        case let .text(text):
            self.init(text)
        case let .image(imageAsset):
            self.init(imageAsset)
        case .knock, .lastRead:
            return nil
        case let .cleared(Cleared):
            return nil
        case let .external(External):
            return nil
        case let .clientAction(ClientAction):
            return nil
        case let .calling(Calling):
            return nil
        case let .asset(Asset): todo
            return nil
        case let .hidden(MessageHide):
            return nil
        case let .location(location):
            self.init(location)
        case let .deleted(MessageDelete):
            return nil
        case let .edited(messageEdit):
            self.init(messageEdit)
        case let .confirmation(Confirmation):
            return nil
        case let .reaction(Reaction):
            return nil
        case let .ephemeral(ephemeral):
            self.init(ephemeral)
        case let .availability(Availability):
            return nil
        case let .composite(Composite):
            return nil
        case let .buttonAction(ButtonAction):
            return nil
        case let .buttonActionConfirmation(ButtonActionConfirmation):
            return nil
        case let .dataTransfer(DataTransfer):
            return nil
        case let .inCallEmoji(InCallEmoji):
            return nil
        case let .inCallHandRaise(InCallHandRaise):
            return nil
        }
    }

    private init?(_ ephemeral: Ephemeral) {
        switch ephemeral.content {
        case .text(let text):
            self.init(text)
        case .image(let imageAsset):
            self.init(imageAsset)
        case .knock(let knock):
            return nil
        case .asset(let asset):
            return nil
        case .location(let location):
            self.init(location)
        case .none:
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
        case let .composite(composite):
            return nil
        case .none:
            return nil
        }
    }

    private init(_ imageAsset: ImageAsset) {
        self = .asset(
            mimeType: imageAsset.hasMimeType ? imageAsset.mimeType : "application/octet-stream",
            size: UInt64(imageAsset.size),
            name: .none,
            otrKey: imageAsset.otrKey,
            sha256: imageAsset.sha256,
            assetID: "????", // TODO: is this a blocker?
            assetToken: .none,
            assetDomain: .none,
            encryption: .none,
            metadata: .image(
                width: imageAsset.width, // TODO: when to use originalWidth?
                height: imageAsset.height,
                tag: imageAsset.hasTag ? imageAsset.tag : ""
            )
        )
    }

}
