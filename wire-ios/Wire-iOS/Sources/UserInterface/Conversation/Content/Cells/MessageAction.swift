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
    case
        digitallySign
    case copy
    case reply
    case openDetails
    case edit
    case delete
    case save
    case cancel
    case download
    case resend
    case showInConversation
    case sketchDraw
    case sketchEmoji
    case // Not included in ConversationMessageActionController.allMessageActions, for image viewer/open quote
        present
    case openQuote
    case resetSession
    case react(Emoji.ID)
    case visitLink

    // MARK: Internal

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
        .react("❤️"),
    ]

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
        case .openQuote,
             .present,
             .react,
             .resetSession:
            return nil
        }
    }

    var icon: StyleKitIcon? {
        switch self {
        case .copy:
            .copy
        case .reply:
            .reply
        case .openDetails:
            .about
        case .edit:
            .pencil
        case .delete:
            .trash
        case .save:
            .save
        case .cancel:
            .cross
        case .download:
            .downArrow
        case .resend:
            .redo
        case .showInConversation:
            .eye
        case .sketchDraw:
            .brush
        case .sketchEmoji:
            .emoji
        case .visitLink:
            .externalLink
        case .digitallySign,
             .openQuote,
             .present,
             .react,
             .resetSession:
            nil
        }
    }

    var selector: Selector? {
        switch self {
        case .copy:
            #selector(ConversationMessageActionController.copyMessage)
        case .digitallySign:
            #selector(ConversationMessageActionController.digitallySignMessage)
        case .reply:
            #selector(ConversationMessageActionController.quoteMessage)
        case .openDetails:
            #selector(ConversationMessageActionController.openMessageDetails)
        case .edit:
            #selector(ConversationMessageActionController.editMessage)
        case .delete:
            #selector(ConversationMessageActionController.deleteMessage)
        case .save:
            #selector(ConversationMessageActionController.saveMessage)
        case .cancel:
            #selector(ConversationMessageActionController.cancelDownloadingMessage)
        case .download:
            #selector(ConversationMessageActionController.downloadMessage)
        case .resend:
            #selector(ConversationMessageActionController.resendMessage)
        case .showInConversation:
            #selector(ConversationMessageActionController.revealMessage)
        case .react:
            #selector(ConversationMessageActionController.addReaction(reaction:))
        case .visitLink:
            #selector(ConversationMessageActionController.visitLink)
        case .openQuote,
             .present,
             .resetSession,
             .sketchDraw,
             .sketchEmoji:
            // no message related actions are not handled in ConversationMessageActionController
            nil
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

    func systemIcon() -> UIImage? {
        imageSystemName().flatMap(UIImage.init(systemName:))
    }

    // MARK: Private

    private func imageSystemName() -> String? {
        switch self {
        case .copy:
            "doc.on.doc"
        case .reply:
            "arrow.uturn.left"
        case .openDetails:
            "info.circle"
        case .edit:
            "pencil"
        case .delete:
            "trash"
        case .save:
            "arrow.down.to.line"
        case .cancel:
            "xmark"
        case .download:
            "chevron.down"
        case .resend:
            "arrow.clockwise"
        case .showInConversation:
            "eye.fill"
        case .sketchDraw:
            "scribble"
        case .sketchEmoji:
            "smiley.fill"
        case .digitallySign,
             .openQuote,
             .present,
             .react,
             .resetSession,
             .visitLink:
            nil
        }
    }
}
