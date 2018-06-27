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

// WebM can be considered the video MIME type if the appropriate video player is installed on the operating system.
fileprivate let unsupportedVideoTypes: Set<String> = ["video/webm"]

extension String {
    
    /// Returns whether the string represents a video mime type
    public func isVideoMimeType() -> Bool {
        return (self as NSString).zm_conforms(to: kUTTypeMovie)
    }
    
    /// Returns whether it is possible to play the file with the given mime type as the video
    public func isPlayableVideoMimeType() -> Bool {
        return isVideoMimeType() && !unsupportedVideoTypes.contains(self)
    }
    
    /// Returns whether the string represents an audio mime type
    public func isAudioMimeType() -> Bool {
        return (self as NSString).zm_conforms(to: kUTTypeAudio)
    }

    /// Returns whether the string represents an image mime type
    public func isImageMimeType() -> Bool {
        return (self as NSString).zm_conforms(to: kUTTypeImage)
    }

}
