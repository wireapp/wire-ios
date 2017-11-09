//
// Wire
// Copyright (C) 2017 Wire Swiss GmbH
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


private enum TeamTransportKey: String {
    case name, creator, icon, iconKey = "icon_key"
}


extension Team {

    public func update(with payload: [String: Any]) {
        if let teamName = payload[TeamTransportKey.name.rawValue] as? String {
            name = teamName
        }

        if let creatorId = (payload[TeamTransportKey.creator.rawValue] as? String).flatMap(UUID.init) {
            creator = ZMUser.fetchAndMerge(with: creatorId, createIfNeeded: true, in: managedObjectContext!)
            creator?.needsToBeUpdatedFromBackend = true
        }

        if let icon = payload[TeamTransportKey.icon.rawValue] as? String {
            pictureAssetId = icon
        }

        if let iconKey = payload[TeamTransportKey.iconKey.rawValue] as? String {
            pictureAssetKey = iconKey
        }
    }

}
