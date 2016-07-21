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


@objc public class ZiphyStillImageRep: NSObject {
    
    
    public let imageType:ZiphyImageType
    public let url:String
    public let width:Int
    public let height:Int
    
    public override var description: String {
        
        get{
            return "type: \(ZiphyClient.fromZiphyImageTypeToString(self.imageType)) , " +
                "url: \(self.url) , " +
                "width: \(self.width) , " +
            "height: \(self.height) , "
        }
    }
    
    public init(type:ZiphyImageType, url:String, width:Int, height:Int){
        
        self.imageType = type;
        self.url = url
        self.width = width
        self.height = height
        super.init()
    }
    
    convenience init(dictionary:[String:AnyObject]) {
        
        let typeAsInt = dictionary["type"] as? Int
        let url = dictionary["url"] as? String ?? ""
        let width = Int(dictionary["width"] as? String ?? "0") ?? 0
        let height = Int(dictionary["height"] as? String ?? "0") ?? 0
        
        let ziphyImageType = typeAsInt == nil ? ZiphyImageType.Unknown : ZiphyImageType(rawValue: typeAsInt!)
        
        self.init(type:ziphyImageType!, url:url, width:width, height:height)
    }
}
