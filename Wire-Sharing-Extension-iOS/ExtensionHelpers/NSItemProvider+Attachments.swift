// 
// Wire
// Copyright (C) 2016 Wire Swiss GmbH
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
import MobileCoreServices



extension NSItemProvider {
    
    func loadText(completion:(String) -> Void) {
        self.loadItemForTypeIdentifier(kUTTypePlainText) { (object: NSSecureCoding?, error: NSError!) -> Void in
            if let text = object as? String {
                dispatch_async(dispatch_get_main_queue()) {
                    completion(text)
                }
            }
        }
    }
    
    func loadURL(completion:(NSURL) -> Void) {
        self.loadItemForTypeIdentifier(kUTTypeURL) { (object: NSSecureCoding?, error: NSError!) -> Void in
            if let url = object as? NSURL {
                dispatch_async(dispatch_get_main_queue()) {
                    completion(url)
                }
            }
        }
    }
    
    func loadImage(completion:(object: NSSecureCoding) -> Void) {
        self.loadItemForTypeIdentifier(kUTTypeImage) { (object: NSSecureCoding?, error: NSError!) -> Void in
            if let imageObject = object {
                dispatch_async(dispatch_get_main_queue()) {
                    completion(object: imageObject)
                }
            }
        }
    }

    private func loadItemForTypeIdentifier(typeIdentifier: CFString, completion:(object: NSSecureCoding?, error: NSError!) -> Void) {
        self.loadItemForTypeIdentifier(typeIdentifier as String, options: [:], completionHandler: completion)
    }
    
}
