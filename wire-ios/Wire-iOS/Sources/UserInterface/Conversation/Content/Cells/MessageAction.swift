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

import UIKit
import WireCommonComponents
import WireDataModel
import WireDesign

enum MessageAction: CaseIterable, Equatable {

    static var allCases: [MessageAction] = [
        .visitLink,
        .digitallySign,
        .copy,
        .reply,
        .openDetails,
        .edit,
        .save,
        .cancel,
        .download,
        .resend,
        .showInConversation,
        .sketchDraw,
        .sketchEmoji,
        .present,
        .openQuote,
        .resetSession,
        .delete,
        .react("❤️")
    ]

    case
    digitallySign,
    copy,
    reply,
    openDetails,
    edit,
    delete,
    save,
    cancel,
    download,
    resend,
    showInConversation,
    sketchDraw,
    sketchEmoji,
    // Not included in ConversationMessageActionController.allMessageActions, for image viewer/open quote
    present,
    openQuote,
    resetSession,
    react(Emoji.ID),
    visitLink

    var title: String? {
        typealias MessageActionLocale = L10n.Localizable.Content.Message
        switch self {
        case .copy:
            return MessageActionLocale.copy
        case .digitallySign:
            return MessageActionLocale.sign
        case .reply:
            return MessageActionLocale.reply
        case .openDetails:
            return MessageActionLocale.details
        case .edit:
            return L10n.Localizable.Message.Menu.Edit.title
        case .delete:
            return MessageActionLocale.delete
        case .save:
            return MessageActionLocale.save
        case .cancel:
            return L10n.Localizable.General.cancel
        case .download:
            return MessageActionLocale.download
        case .resend:
            return MessageActionLocale.resend
        case .showInConversation:
            return MessageActionLocale.goToConversation
        case .sketchDraw:
            return L10n.Localizable.Image.addSketch
        case .sketchEmoji:
            return L10n.Localizable.Image.addEmoji
        case .visitLink:
            return MessageActionLocale.OpenLinkAlert.title
        case .present,
                .openQuote,
                .resetSession,
                .react:
            return nil
        }
    }

    var icon: StyleKitIcon? {
        switch self {
        case .copy:
            return .copy
        case .reply:
            return .reply
        case .openDetails:
            return .about
        case .edit:
            return .pencil
        case .delete:
            return .trash
        case .save:
            return .save
        case .cancel:
            return .cross
        case .download:
            return .downArrow
        case .resend:
            return .redo
        case .showInConversation:
            return .eye
        case .sketchDraw:
            return .brush
        case .sketchEmoji:
            return .emoji
        case .visitLink:
            return .externalLink
        case .present,
                .openQuote,
                .digitallySign,
                .resetSession,
                .react:
            return nil
        }
    }

    func systemIcon() -> UIImage? {
        return imageSystemName().flatMap(UIImage.init(systemName:))
    }

    private func imageSystemName() -> String? {
        let imageName: String?
        switch self {
        case .copy:
            imageName = "doc.on.doc"
        case .reply:
            imageName = "arrow.uturn.left"
        case .openDetails:
            imageName = "info.circle"
        case .edit:
            imageName = "pencil"
        case .delete:
            imageName = "trash"
        case .save:
            imageName = "arrow.down.to.line"
        case .cancel:
            imageName = "xmark"
        case .download:
            imageName = "chevron.down"
        case .resend:
            imageName = "arrow.clockwise"
        case .showInConversation:
            imageName = "eye.fill"
        case .sketchDraw:
            imageName = "scribble"
        case .sketchEmoji:
            imageName = "smiley.fill"
        case .present,
                .openQuote,
                .digitallySign,
                .resetSession,
                .react,
                .visitLink:
            imageName = nil
        }

        return imageName
    }

    var selector: Selector? {
        switch self {
        case .copy:
            return #selector(ConversationMessageActionController.copyMessage)
        case .digitallySign:
            return #selector(ConversationMessageActionController.digitallySignMessage)
        case .reply:
            return #selector(ConversationMessageActionController.quoteMessage)
        case .openDetails:
            return #selector(ConversationMessageActionController.openMessageDetails)
        case .edit:
            return #selector(ConversationMessageActionController.editMessage)
        case .delete:
            return #selector(ConversationMessageActionController.deleteMessage)
        case .save:
            return #selector(ConversationMessageActionController.saveMessage)
        case .cancel:
            return #selector(ConversationMessageActionController.cancelDownloadingMessage)
        case .download:
            return #selector(ConversationMessageActionController.downloadMessage)
        case .resend:
            return #selector(ConversationMessageActionController.resendMessage)
        case .showInConversation:
            return #selector(ConversationMessageActionController.revealMessage)
        case .react:
            return #selector(ConversationMessageActionController.addReaction(reaction:) )
        case .visitLink:
            return #selector(ConversationMessageActionController.visitLink)
        case .present,
                .sketchDraw,
                .sketchEmoji,
                .openQuote,
                .resetSession:
            // no message related actions are not handled in ConversationMessageActionController
            return nil
        }
    }

    var accessibilityLabel: String? {
        typealias MessageAction = L10n.Accessibility.MessageAction

        switch self {
        case .copy:
            return MessageAction.CopyButton.description
        case .save:
            return MessageAction.SaveButton.description
        case .sketchDraw:
            return MessageAction.SketchButton.description
        case .sketchEmoji:
            return MessageAction.EmojiButton.description
        case .showInConversation:
            return MessageAction.RevealButton.description
        case .delete:
            return MessageAction.DeleteButton.description
        default:
            return nil
        }
    }
}
