//
// Wire
// Copyright (C) 2018 Wire Swiss GmbH
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

fileprivate extension NSRange {
    var range: Range<Int> {
        return lowerBound..<upperBound
    }
}

@objc
extension ZMClientMessage: ZMTextMessageData {
    
    @NSManaged public var quote: ZMMessage?
    
    public var isQuotingSelf: Bool{
        return quote?.sender?.isSelfUser ?? false
    }
    
    public var hasQuote: Bool {
        return genericMessage?.textData?.hasQuote() ?? false
    }
    
    public var messageText: String? {
        return genericMessage?.textData?.content.removingExtremeCombiningCharacters
    }
    
    public var mentions: [Mention] {
        guard let protoBuffers = genericMessage?.textData?.mentions,
              let messageText = messageText,
              let managedObjectContext = managedObjectContext else { return [] }
        
        let mentions = Array(protoBuffers.compactMap({ Mention($0, context: managedObjectContext) }).prefix(500))
        var mentionRanges = IndexSet()
        let messageRange = NSRange(messageText.startIndex ..< messageText.endIndex, in: messageText)

        return mentions.filter({ mention  in
            let range = mention.range.range
            
            guard !mentionRanges.intersects(integersIn: range), range.upperBound <= messageRange.upperBound else { return false }
            
            mentionRanges.insert(integersIn: range)
            
            return true
        })
    }
        
    public func editText(_ text: String, mentions: [Mention], fetchLinkPreview: Bool) {
        guard let nonce = nonce, isEditableMessage else { return }
        
        // Quotes are ignored in edits but keep it to mark that the message has quote for us locally
        let editedText = ZMText.text(with: text, mentions: mentions, linkPreviews: [], replyingTo: self.quote as? ZMOTRMessage)
        let editNonce = UUID()
        add(ZMGenericMessage.message(content: ZMMessageEdit.edit(with: editedText, replacingMessageId: nonce), nonce: editNonce).data())
        updateNormalizedText()
        
        self.nonce = editNonce
        self.updatedTimestamp = Date()
        self.reactions.removeAll()
        self.linkPreviewState = fetchLinkPreview ? .waitingToBeProcessed : .done
        self.linkAttachments = nil
        self.delivered = false
    }
        
}

