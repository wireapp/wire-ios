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

@objc public class Ziph : NSObject {
    
    public let ziphId:String!
    public let ziphyImages:[String:ZiphyImageRep]!
    
    public override var description: String {
        
        get{
            return "ziphId: \(self.ziphId)\n" +
            "ziphyImages:\n\(self.ziphyImages)\n"
        }
    }
    
    public init(ziphId:String, ziphyImages:[String:ZiphyImageRep]){
    
        self.ziphId = ziphId;
        self.ziphyImages = ziphyImages;
    }
    
    init?(dictionary:[String:AnyObject]){
        
        let ziphId = dictionary["id"] as? String ?? "";
        
        if let images:[String:AnyObject] = dictionary["images"] as? [String: AnyObject] {
            
            var ziphyImagesDict:[String:ZiphyImageRep] = Dictionary<String, ZiphyImageRep>()
            
            for (key, value) in images {
                
                let ziphyImageType = ZiphyClient.fromStringToZiphyImageType(key)
                var dictionaryValue = value as? [String:AnyObject]
                dictionaryValue?["type"] = ziphyImageType.rawValue

                if let dictionaryValue = dictionaryValue {
                    ziphyImagesDict[key] = ZiphyImageRep(dictionary:dictionaryValue)
                }
                else {
                    
                    self.ziphId = nil
                    self.ziphyImages = nil
                    super.init()
                    return nil
                }
            }

            self.ziphId = ziphId
            self.ziphyImages = ziphyImagesDict
            
            super.init()

        }
        else {
            self.ziphyImages = nil
            self.ziphId = nil
            super.init()
            
            return nil
        }
    }
    
    public func imageWithType(type:ZiphyImageType)->ZiphyImageRep? {
    
        return self.ziphyImages[ZiphyClient.fromZiphyImageTypeToString(type)]
    }
}