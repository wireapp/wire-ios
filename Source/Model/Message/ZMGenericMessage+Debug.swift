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

fileprivate let redactedValue = "<redacted>"

fileprivate extension ZMText {
    
    func sanitize() -> ZMText {
        let builder = toBuilder()!
        _ = builder.setContent(redactedValue)
        
        if let linkPreviews = builder.linkPreview() as? [ZMLinkPreview] {
            builder.setLinkPreviewArray(linkPreviews.map({ $0.sanitize() }))
        }
        
        return builder.build()
    }
    
}

fileprivate extension ZMLinkPreview {
    
    func sanitize() -> ZMLinkPreview {
        let builder = toBuilder()!
        builder.setUrl(redactedValue)
        builder.setPermanentUrl(redactedValue)
        builder.setTitle(redactedValue)
        builder.setSummary(redactedValue)
        builder.clearTweet()
        
        if builder.hasArticle() {
            builder.setArticle(builder.article().sanitize())
        }
        
        return builder.build()
    }
    
}

fileprivate extension ZMArticle {
    
    func sanitize() -> ZMArticle {
        let builder = toBuilder()!
        builder.setTitle(redactedValue)
        builder.setPermanentUrl(redactedValue)
        builder.setSummary(redactedValue)
        return builder.build()
    }
    
}

extension ZMGenericMessage {
    
    open override var debugDescription: String {
        
        guard let builder = self.toBuilder() else { return "" }
        
        if builder.hasText() {
            builder.setText(builder.text().sanitize())
        }
        
        if builder.hasEdited(), let editedBuilder = builder.edited().toBuilder(), editedBuilder.hasText() {
            builder.setEdited(editedBuilder.setText(editedBuilder.text().sanitize()))
        }
        
        let message = builder.build()!
        
        let description = NSMutableString()
        message.writeDescription(to: description, withIndent: "")
        return description as String
    }
}
