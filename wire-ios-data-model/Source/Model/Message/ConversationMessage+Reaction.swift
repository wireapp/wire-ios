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

extension ZMMessage {
    @discardableResult
    @objc
    public static func addReaction(
        _ reaction: String,
        to message: ZMConversationMessage
    ) -> ZMClientMessage? {
        guard reaction != "" else {
            return nil
        }

        var reactions = existingReactionsBySelfUser(for: message)
        reactions.insert(reaction)

        return setReactions(
            reactions: reactions,
            for: message
        )
    }

    @objc
    public static func removeReaction(
        _ reaction: String,
        from message: ZMConversationMessage
    ) {
        var reactions = existingReactionsBySelfUser(for: message)
        reactions.remove(reaction)

        setReactions(
            reactions: reactions,
            for: message
        )
    }

    private static func existingReactionsBySelfUser(for message: ZMConversationMessage) -> Set<String> {
        let existingReactions = message.usersReaction.compactMap { reaction, users in
            users.contains(where: \.isSelfUser) ? reaction : nil
        }

        return Set(existingReactions)
    }

    @discardableResult
    static func setReactions(
        reactions: Set<String>,
        for message: ZMConversationMessage
    ) -> ZMClientMessage? {
        guard
            let message = message as? ZMMessage,
            let context = message.managedObjectContext,
            let messageID = message.nonce,
            message.isSent,
            let conversation = message.conversation
        else {
            return nil
        }

        let genericMessage = GenericMessage(content: WireProtos.Reaction.createReaction(
            emojis: reactions,
            messageID: messageID
        ))

        do {
            let clientMessage = try conversation.appendClientMessage(
                with: genericMessage,
                expires: false,
                hidden: true
            )

            message.setReactions(
                reactions,
                forUser: .selfUser(in: context)
            )

            return clientMessage
        } catch {
            Logging.messageProcessing.warn("Failed to append reaction. Reason: \(error.localizedDescription)")
            return nil
        }
    }

    @objc
    public func setReactions(
        _ updatedReactions: Set<String>,
        forUser user: ZMUser,
        newReactionsCreationDate: Date? = nil
    ) {
        removeEmptyReactions()

        // Remove all existing reactions for this user.
        for reaction in reactions where reaction.users.contains(user) {
            reaction.mutableSetValue(forKey: ZMReactionUsersValueKey).remove(user)
        }

        // Add all new reactions for this user.
        for reaction in updatedReactions {
            let existingReaction = reactions.first(where: {
                $0.unicodeValue == reaction
            })

            if let existingReaction {
                existingReaction.mutableSetValue(forKey: ZMReactionUsersValueKey).add(user)
            } else if Reaction.validate(unicode: reaction) {
                let newReaction = Reaction.insertReaction(
                    reaction,
                    users: [user],
                    inMessage: self,
                    creationDate: newReactionsCreationDate
                )

                mutableSetValue(forKey: "reactions").add(newReaction)
                updateCategoryCache()
            }
        }
    }

    func removeEmptyReactions() {
        // Remove "empty" leftover reactions that have no user attached to treat them as fresh reactions in case of
        // adding them again
        guard let moc = managedObjectContext else {
            return
        }
        let reactionsCopy = reactions
        for reaction in reactionsCopy where reaction.users.isEmpty {
            mutableSetValue(forKey: "reactions").remove(reaction)
            moc.delete(reaction)
        }
    }

    @objc
    public func clearAllReactions() {
        let oldReactions = reactions
        reactions.removeAll()
        guard let moc = managedObjectContext else {
            return
        }
        oldReactions.forEach(moc.delete)
    }

    @objc
    public func clearConfirmations() {
        let oldConfirmations = confirmations
        mutableSetValue(forKey: ZMMessageConfirmationKey).removeAllObjects()
        guard let moc = managedObjectContext else {
            return
        }
        oldConfirmations.forEach(moc.delete)
    }
}
