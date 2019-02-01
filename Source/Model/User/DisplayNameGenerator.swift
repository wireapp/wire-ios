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

private var zmLog = ZMSLog(tag: "DisplayNameGenerator")


@objcMembers public class DisplayNameGenerator : NSObject {
    private var idToPersonNameMap : [NSManagedObjectID: PersonName] = [:]
    weak private var managedObjectContext: NSManagedObjectContext?
    private let tagger =  NSLinguisticTagger(tagSchemes: convertToNSLinguisticTagSchemeArray([convertFromNSLinguisticTagScheme(NSLinguisticTagScheme.script)]), options: 0)
    
    init(managedObjectContext: NSManagedObjectContext) {
        self.managedObjectContext = managedObjectContext
        super.init()
    }
    
    // MARK : Accessors

    public func personName(for user: ZMUser) -> PersonName {
        if user.objectID.isTemporaryID {
            try! managedObjectContext!.obtainPermanentIDs(for: [user])
        }
        if let name = idToPersonNameMap[user.objectID], name.rawFullName == (user.name ?? "") {
            return name
        }
        let newName = PersonName.person(withName: user.name ?? "", schemeTagger: nil)
        idToPersonNameMap[user.objectID] = newName
        return newName
    }
    
    public func givenName(for user: ZMUser) -> String? {
        return personName(for: user).givenName
    }
    
    public func initials(for user: ZMUser) -> String? {
        return personName(for: user).initials
    }
    
    
    // MARK : DisplayNames on a conversation basis
    
    private var currentDisplayNameMap : ConversationDisplayNameMap?
    
    /// Can be used by the UI to return the displayNames for a conversation.
    /// Calculates a map for this conversation, as soon as another conversation's displayNames are requested, it discards the map
    @objc public func displayName(for user: ZMUser, in conversation: ZMConversation) -> String {

        if idToPersonNameMap[user.objectID]?.rawFullName == (user.name ?? ""),                  // the user name is still the same
           let map = currentDisplayNameMap, map.conversationObjectID == conversation.objectID,  // the current map is of the same conversation
           let name = map.map[user.objectID],                                                   // the current map contains the user
           !(name.isEmpty && !(user.name ?? "").isEmpty)                                        // the name contains a value or both the name and user's name are empty
        {
            return name
        }
        let newMap = displayNames(for: conversation)
        currentDisplayNameMap = ConversationDisplayNameMap(conversationObjectID: conversation.objectID, map: newMap)
        guard let name = newMap[user.objectID] else {
            zmLog.warn("User is not member of this conversation")
            return user.name ?? ""
        }
        return name
    }
    
    private func displayNames(for conversation: ZMConversation) -> [NSManagedObjectID : String] {
        let participants = conversation.sortedActiveParticipants
        let givenNames : [String] = participants.compactMap { user in
            let personName = self.personName(for: user)
            return personName.givenName
        }
        let countedGivenName = NSCountedSet(array: givenNames)
        var map = [NSManagedObjectID : String]()
        participants.forEach { user in
            let personName = self.personName(for: user)
            if countedGivenName.count(for: personName.givenName) == 1
                || conversation.conversationType == .oneOnOne
                || user.isSelfUser
            {
                map[user.objectID] = personName.givenName
            } else {
                map[user.objectID] = personName.fullName
            }
        }
        return map
    }    
}

struct ConversationDisplayNameMap {
    
    let conversationObjectID : NSManagedObjectID
    let map : [NSManagedObjectID : String]
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertToNSLinguisticTagSchemeArray(_ input: [String]) -> [NSLinguisticTagScheme] {
	return input.map { key in NSLinguisticTagScheme(key) }
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromNSLinguisticTagScheme(_ input: NSLinguisticTagScheme) -> String {
	return input.rawValue
}
