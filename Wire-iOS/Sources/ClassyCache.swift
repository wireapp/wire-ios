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


import Classy
import Foundation
import CocoaLumberjackSwift

extension Dictionary where
    Key : AnyObject,
    Value: AnyObject
{
    func wr_keyValues() -> [[String: AnyObject]] {
        return self.keys.map({ ["key":   $0,
                                "value": self[$0]!] as [String: AnyObject] })
    }
    
    func wr_sortedKeyValues() -> [[String: AnyObject]] {
        let sortByKey = NSSortDescriptor(key: "key", ascending:true)
        return (self.wr_keyValues() as NSArray).sortedArrayUsingDescriptors([sortByKey]) as! [[String: AnyObject]]
    }
}

@objc class ClassyCache: NSObject, CASCacheProtocol {
    
    override init() {
        super.init()
        let currentAppBuild = self.dynamicType.currentAppBuild
        let lastAppBuild = self.dynamicType.lastAppBuild
        
        if currentAppBuild != lastAppBuild {
            do {
                try NSFileManager.defaultManager().removeItemAtPath(self.dynamicType.casDirectory as String)
            }
            catch let error as NSError {
                DDLogError("Cannot clear CAS cache: \(error)")
            }
            self.dynamicType.lastAppBuild = currentAppBuild
        }
        
        if !NSFileManager.defaultManager().fileExistsAtPath(self.dynamicType.casDirectory as String) {
            do {
                try NSFileManager.defaultManager().createDirectoryAtPath(self.dynamicType.casDirectory as String, withIntermediateDirectories: true, attributes: .None)
            }
            catch let error as NSError {
                DDLogError("Cannot create CAS cache: \(error)")
            }
        }
    }
    
    static let currentAppBuild: String = {
        guard let version = NSBundle.mainBundle().infoDictionary?["CFBundleVersion"] as? String else {
            return "999998"
        }
        
        return version
    }()
    
    static var lastAppBuild: String {
        get {
            guard let lastBuild = NSUserDefaults.standardUserDefaults().objectForKey(self.lastAppBuildKey) as? String else {
                return ""
            }
        
            return lastBuild
        }
        
        set {
            NSUserDefaults.standardUserDefaults().setObject(newValue, forKey: self.lastAppBuildKey)
        }
    }
    
    static let lastAppBuildKey = "ZMLastUsedBuild"
    
    static let casDirectory: NSString = {
        let cachePath = NSSearchPathForDirectoriesInDomains(.CachesDirectory, .UserDomainMask, true)[0] as NSString
        return cachePath.stringByAppendingPathComponent("cas")
    }()
    
    func bcasPath(casPath: String, variables: [NSObject : AnyObject]!) -> String? {
        guard let fileData = NSMutableData(contentsOfFile: casPath),
            let variablesJSON = try? NSJSONSerialization.dataWithJSONObject(variables.wr_sortedKeyValues(), options: .PrettyPrinted)
            else {
                return .None
        }
        
        fileData.appendData(variablesJSON)
        let casHash = fileData.wr_MD5Hash()
        
        let casName = ((casPath as NSString).lastPathComponent as NSString).stringByDeletingPathExtension
        let bcasPath = self.dynamicType.casDirectory.stringByAppendingPathComponent("\(casName)-\(casHash).bcas")
        
        return bcasPath
    }
    
    // MARK: - CASCacheProtocol
    
    func cacheStyleNodes(styleNodes: [AnyObject]!, fromPath path: String!, variables: [NSObject : AnyObject]!) {
        guard let bcasPath = self.bcasPath(path, variables: variables),
            let styleNodes = styleNodes else {
            return
        }
        
        delay(5) {
            let data = NSKeyedArchiver.archivedDataWithRootObject(styleNodes)
            let bcasFolderPath = (bcasPath as NSString).stringByDeletingLastPathComponent
            
            guard ((try? NSFileManager.defaultManager().createDirectoryAtPath(bcasFolderPath, withIntermediateDirectories: true, attributes: .None)) != nil) else {
                DDLogError("Cannot create directory for bcas: " + bcasPath)
                return
            }
            
            guard ((try? data.writeToFile(bcasPath, options: .AtomicWrite)) != nil) else {
                DDLogError("bcas cannot be saved to: " + bcasPath)
                return
            }
            
            DDLogInfo("Saved bcas to: \(bcasPath) (\(data.length))")
        }
    }
    
    func cachedStyleNodesFromCASPath(path: String!, withVariables variables: [NSObject : AnyObject]!) -> [AnyObject]! {
        guard let bcasPath = self.bcasPath(path, variables: variables) else {
            return .None
        }
        
        guard let attributes = try? NSFileManager.defaultManager().attributesOfItemAtPath(bcasPath),
            let fileSize = attributes[NSFileSize] as? Int
            where fileSize != 0 else {
                DDLogInfo("bcas file not found")
                return .None
        }
        
        DDLogInfo("Loading bcas file")
        
        
        if let array = NSKeyedUnarchiver.unarchiveObjectWithFile(bcasPath) as? [AnyObject] {
            return array
        }
        else {
            DDLogError("bcas cannot be decoded")
            // We need to cleanup the archive since we cannot decode it
            _ = try? NSFileManager.defaultManager().removeItemAtPath(bcasPath)
            return .None
        }
        
    }}
