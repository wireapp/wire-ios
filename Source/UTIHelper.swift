//
// Wire
// Copyright (C) 2021 Wire Swiss GmbH
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
import UniformTypeIdentifiers
import CoreServices

#if targetEnvironment(simulator)
//HACK: subsitution of .preferredMIMEType(returns nil when arch is x86_64) on arm64 simulator

@available(iOSApplicationExtension 14.0, *)
extension UniformTypeIdentifiers.UTType {
    var mimeType: String? {
        switch self {
        case .jpeg:
            return "image/jpeg"
        case .png:
            return "image/png"
        case .gif:
            return "image/gif"
        case .svg:
            return "image/svg+xml"
        case .json:
            return "application/json"
        default:
            return nil
        }
        
    }
}

#endif

@objc
public final class UTIHelper: NSObject {
    
    @objc
    public class func conformsToImageType(uti: String) -> Bool {
        if #available(iOS 14, *) {
            guard let utType = UniformTypeIdentifiers.UTType(uti) else {
                return false
            }
            #if targetEnvironment(simulator)
            //HACK: arm64 simulator return false for utType.conforms(to: .image), but add additional subtype check works
            return utType.conforms(to: .image) ||
                utType.conforms(to: .png) ||
                utType.conforms(to: .jpeg) ||
                utType.conforms(to: .gif) ||
                utType.conforms(to: .svg)
            #else
            return utType.conforms(to: .image)
            #endif
        } else {
            return UTTypeConformsTo(uti as CFString, kUTTypeImage)
        }
    }
    
    @objc
    public class func conformsToVectorType(uti: String) -> Bool {
        if #available(iOS 14, *) {
            guard let utType = UniformTypeIdentifiers.UTType(uti) else {
                return false
            }
            
            return utType.conforms(to: UniformTypeIdentifiers.UTType.svg)
        } else {
            return UTTypeConformsTo(uti as CFString, kUTTypeScalableVectorGraphics)
        }
    }
    
    @objc
    public class func conformsToJsonType(uti: String) -> Bool {
        if #available(iOS 14, *) {
            guard let utType = UniformTypeIdentifiers.UTType(uti) else {
                return false
            }
            
            return utType.conforms(to: UniformTypeIdentifiers.UTType.json)
        } else {
            return UTTypeConformsTo(uti as CFString, kUTTypeJSON)
        }
    }
    
    @objc
    public class func convertToUti(mime: String) -> String? {
        if #available(iOS 14, *) {
            var utType: UniformTypeIdentifiers.UTType?
            utType = UniformTypeIdentifiers.UTType(mimeType: mime)
            
            #if targetEnvironment(simulator)
            /// HACK: hard code MIME when preferredMIMEType is nil for M1 simulator, we should file a ticket to apple for this issue
            if utType == nil {
                
                let imageTypes: [UniformTypeIdentifiers.UTType] = [.jpeg, .gif, .png, .json, .svg]
                for type in imageTypes {
                    if mime == type.mimeType {
                        utType = type
                        break
                    }
                }
            }
            #endif
            
            return utType?.identifier
        } else {
            return UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType,
                                                         mime as CFString,
                                                         kUTTypeContent)?.takeRetainedValue() as String?
        }
    }
    
    @objc
    public class func convertToMime(uti: String) -> String? {
        
        let mimeType: String
        if #available(iOS 14, *) {
            guard let utType = UniformTypeIdentifiers.UTType(uti) else {
                return nil
            }
            
            if let preferredMIMEType = utType.preferredMIMEType {
                mimeType = preferredMIMEType
            } else {
                #if targetEnvironment(simulator)
                /// HACK: hard code MIME when preferredMIMEType is nil for M1 simulator, we should file a ticket to apple for this issue
                guard let type = utType.mimeType else {
                    return nil
                }
                
                mimeType = type
                #else
                return nil
                #endif
            }
            
        } else {
            let unmanagedMime = UTTypeCopyPreferredTagWithClass(uti as CFString, kUTTagClassMIMEType)
            
            guard let retainedValue = unmanagedMime?.takeRetainedValue() else {
                return nil
            }
            
            mimeType = retainedValue as String
        }
        
        return mimeType
    }
    
}
