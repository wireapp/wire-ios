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


@objc public class ZiphyImageRep:ZiphyStillImageRep {
    
    public let size:Int
    public let frames:Int
    public let mp4:String
    public let mp4Size:Int
    public let webp:String
    public let webpSize:Int
    
    public override var description: String {
        
        get{
            return "<<" + super.description + "size: \(self.size) , " +
                "frames: \(self.frames) , " +
                "mp4: \(self.mp4) , " +
                "mp4Size: \(self.mp4Size) , " +
                "webp: \(self.webp) , " +
                "webpSize: \(self.webpSize)" + ">>"
        }
    }
    
    public init(type:ZiphyImageType,
        url:String,
        width:Int,
        height:Int,
        size:Int?,
        frames:Int?,
        mp4:String?,
        mp4Size:Int?,
        webp:String?,
        webpSize:Int?) {
            
            self.size = size ?? 0
            self.frames = frames ?? 0
            self.mp4 = mp4 ?? ""
            self.mp4Size = mp4Size ?? 0
            self.webp = webp ?? ""
            self.webpSize = webpSize ?? 0
            
            super.init(type:type, url: url, width: width, height: height)
    }
    
    convenience init(dictionary:[String:AnyObject]){
        
        let size = Int((dictionary["size"] as? String) ?? "0")
        let frames = Int((dictionary["frames"] as? String) ?? "0")
        let mp4 = dictionary["mp4"] as? String
        let mp4Size = Int((dictionary["mp4_size"] as? String) ?? "0")
        let webp = dictionary["webp"] as? String
        let webpSize = Int((dictionary["webp_size"] as? String) ?? "0")
        
        let typeAsInt = dictionary["type"] as? Int
        let url : String = dictionary["url"] as? String ?? ""
        let width : Int = Int((dictionary["width"] as? String) ?? "0") ?? 0
        let height : Int = Int((dictionary["height"] as? String) ?? "0") ?? 0
        
        let ziphyImageType = typeAsInt == nil ? ZiphyImageType.Unknown : ZiphyImageType(rawValue: typeAsInt!)
        
        self.init(type:ziphyImageType!,
            url:url, width:width,
            height:height,
            size:size,
            frames:frames,
            mp4:mp4,
            mp4Size:mp4Size,
            webp:webp,
            webpSize:webpSize)
    }
}
