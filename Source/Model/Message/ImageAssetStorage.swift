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

/// This protocol is used to encapsulate the information and data about an image asset
@objc
public protocol ImageAssetStorage: ZMImageOwner {
    
    /// Metadata of the medium representation of the image
    var previewGenericMessage: ZMGenericMessage? { get }
    
    /// Metadata of the preview representation of the image
    var mediumGenericMessage: ZMGenericMessage? { get }
    
    func updateMessage(imageData: Data, for: ZMImageFormat) -> AnyObject?
    
    func imageData(for: ZMImageFormat, encrypted: Bool) -> Data?
    
    //// returns whether image data should be reprocessed
    func shouldReprocess(for: ZMImageFormat) -> Bool
    
    func genericMessage(for: ZMImageFormat) -> ZMGenericMessage?
    
    var preprocessedSize: CGSize { get }
}
