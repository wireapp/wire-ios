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
// along with this program. If not, see <http://www.gnu.org/licenses/>.


import Foundation


extension ZMSearchUser : ObjectInSnapshot {
    
    public var keysToChangeInfoMap : KeyToKeyTransformation { return KeyToKeyTransformation(mapping: [
        KeyPath.keyPathForString("imageMediumData"): .Default,
        KeyPath.keyPathForString("imageSmallProfileData"): .Default,
        KeyPath.keyPathForString("isConnected"): .Custom(KeyPath.keyPathForString("connectionStateChanged")),
        KeyPath.keyPathForString("user"): .Custom(KeyPath.keyPathForString("connectionStateChanged")),
        KeyPath.keyPathForString("isPendingApprovalByOtherUser"): .Custom(KeyPath.keyPathForString("connectionStateChanged"))
        ])
    }
    
    public func keyPathsForValuesAffectingValueForKey(key: String) -> Set<String> {
        return ZMSearchUser.keyPathsForValuesAffectingValueForKey(key) 
    }
}


