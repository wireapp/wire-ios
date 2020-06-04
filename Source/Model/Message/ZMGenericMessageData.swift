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

@objc(ZMGenericMessageData)
@objcMembers public class ZMGenericMessageData: ZMManagedObject {
    
    public static let dataKey = "data"
    public static let messageKey = "message"
    public static let assetKey = "asset"

    @NSManaged public var data: Data
    @NSManaged public var message: ZMClientMessage?
    @NSManaged public var asset: ZMAssetClientMessage?
    
    override open class func entityName() -> String {
        return "GenericMessageData"
    }
    
    public override var modifiedKeys: Set<AnyHashable>? {
        get {
            return Set()
        } set {
            // do nothing
        }
    }
    
    public var underlyingMessage: GenericMessage? {
        do {
            let genericMessage = try GenericMessage(serializedData: data)
            return genericMessage
        } catch {
            return nil
        }
    }
}
