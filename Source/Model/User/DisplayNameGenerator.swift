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


public class DisplayNameGenerator : NSObject {
    private var idToPersonNameMap : [NSManagedObjectID: PersonName] = [:]

    var allUsers : Set<ZMUser>?
    unowned var managedObjectContext: NSManagedObjectContext
    
    public func personName(for user: ZMUser) -> PersonName? {
        fetchAllUsersIfNeeded()
        return idToPersonNameMap[user.objectID]
    }
    
    public func displayName(for user: ZMUser) -> String? {
        fetchAllUsersIfNeeded()
        return idToPersonNameMap[user.objectID]?.displayName
    }
    
    public func initials(for user: ZMUser) -> String? {
        fetchAllUsersIfNeeded()
        return idToPersonNameMap[user.objectID]?.initials
    }
    
    init(managedObjectContext: NSManagedObjectContext, allUsers: Set<ZMUser>?) {
        self.managedObjectContext = managedObjectContext
        super.init()
        self.allUsers = allUsers
        mapUsersToNames(returnChanges: false)
    }
    
    /// Creates a copy the existing generator and returns the objectIDs of users whose displayName or fullName changed
    public func createCopy(with allUsers: Set<ZMUser>) -> (newGenerator: DisplayNameGenerator, updatedUserIDs: Set<NSManagedObjectID>) {
        let generator = DisplayNameGenerator(managedObjectContext: managedObjectContext, allUsers: Set())
        generator.allUsers = allUsers
        let updatedUsers = generator.mapUsersToNames(oldIDToPersonNameMap: idToPersonNameMap, returnChanges: true)
        return (generator, updatedUsers)
    }
    
    // Use the old map to avoid the expensive calculation of personNames
    // Return users that have a new fullName or were inserted
    static func mapIDsToPersonName(oldMap: [NSManagedObjectID : PersonName], users: Set<ZMUser>) -> (newMap: [NSManagedObjectID : PersonName], updatedUsers: Set<NSManagedObjectID>){
        var newIdToPersonNameMap : [NSManagedObjectID : PersonName] = [:]
        var updatedUsers = Set<NSManagedObjectID>()
        users.forEach{
            let fullName = $0.name ?? ""
            if let oldPersonName = oldMap[$0.objectID], oldPersonName.fullName == fullName  {
                newIdToPersonNameMap[$0.objectID] = oldPersonName
            } else {
                newIdToPersonNameMap[$0.objectID] = PersonName.person(withName: fullName)
                updatedUsers.insert($0.objectID)
            }
        }
        return (newIdToPersonNameMap, updatedUsers)
    }
    
    /// Update the displayNames
    /// Return users that have a new displayName
    func updateDisplayNames() -> Set<NSManagedObjectID> {
        let givenNameCounts = NSCountedSet(array: idToPersonNameMap.values.flatMap{$0.givenName})
        var updatedUsers = Set<NSManagedObjectID>()
        idToPersonNameMap.forEach{ (key, personName) in
            if givenNameCounts.count(for: personName.givenName) < 2 {
                if personName.displayName != personName.givenName {
                    personName.displayName = personName.givenName
                    updatedUsers.insert(key)
                }
            } else {
                if personName.displayName != personName.fullName {
                    personName.displayName = personName.fullName
                    updatedUsers.insert(key)
                }
            }
        }
        return updatedUsers
    }
    
    func fetchAllUsers(in context:NSManagedObjectContext) -> Set<ZMUser> {
        let fetchRequest = ZMUser.sortedFetchRequest()
        guard let allUsers = context.executeFetchRequestOrAssert(fetchRequest) as? [ZMUser] else { return Set()}
        return Set(allUsers)
    }
    
    @discardableResult func mapUsersToNames(oldIDToPersonNameMap: [NSManagedObjectID : PersonName] = [:], returnChanges: Bool) -> Set<NSManagedObjectID> {
        guard let users = allUsers else { return Set()}
        
        let (idToPersonNameMap, updated1) = type(of:self).mapIDsToPersonName(oldMap: oldIDToPersonNameMap, users: users)
        self.idToPersonNameMap = idToPersonNameMap
        let updated2 = self.updateDisplayNames()
        return returnChanges ? updated1.union(updated2) : Set()
    }
    
    func fetchAllUsersIfNeeded() {
        guard allUsers == nil else { return }
        allUsers = fetchAllUsers(in:managedObjectContext)
        mapUsersToNames(returnChanges: false)
    }
    
}

let DisplayNameGeneratorKey = "DisplayNameGenerator"

extension NSManagedObjectContext {
    
    var nameGenerator : DisplayNameGenerator? {
        get {
            return userInfo.object(forKey: DisplayNameGeneratorKey) as? DisplayNameGenerator
        }
        set {
            if newValue == nil {
                userInfo.removeObject(forKey:DisplayNameGeneratorKey)
            } else {
                userInfo[DisplayNameGeneratorKey] = newValue
            }
        }
    }
    
    func updateNameGenerator(updatedUsers: Set<ZMUser>, insertedUsers: Set<ZMUser>, deletedUsers: Set<ZMUser>) -> Set<ZMUser> {
        guard let generator = nameGenerator else { return Set()}
        let (newGenerator, updatedUsers) = generator.updateWithChanges(updatedUsers: updatedUsers, insertedUsers: insertedUsers, deletedUsers: deletedUsers)
        self.nameGenerator = newGenerator
        return updatedUsers
    }

}


extension DisplayNameGenerator {

    func updateWithChanges(updatedUsers: Set<ZMUser>, insertedUsers: Set<ZMUser>, deletedUsers: Set<ZMUser>)
        -> (newGenerator:  DisplayNameGenerator, updatedUsers: Set<ZMUser>)
    {
        fetchAllUsersIfNeeded()
        
        if (insertedUsers.count == 0 && deletedUsers.count == 0 && updatedUsers.count == 0) {
            return (self, Set())
        }
        let newAllUsers = allUsers!.union(insertedUsers).subtracting(deletedUsers)
        
        //At this point inserted users should have temporary id's, but after the save they will have permament id's.
        //Display name generator maps names to user id's so it needs permament id's to be able to match them on subsecquent changes.
        try! managedObjectContext.obtainPermanentIDs(for: Array(newAllUsers))
        
        let (newGenerator, updatedUserIDs) = createCopy(with: newAllUsers)
        let usersToReturn = updatedUserIDs.flatMap{(try? managedObjectContext.existingObject(with: $0)) as? ZMUser}
        
        return (newGenerator, Set(usersToReturn))
    }
    
}


