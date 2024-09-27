//
// Wire
// Copyright (C) 2024 Wire Swiss GmbH
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
import WireSystem

// MARK: - ParticipantRole + ObjectInSnapshot

extension ParticipantRole: ObjectInSnapshot {
    public static var observableKeys: Set<String> {
        [
            #keyPath(ParticipantRole.role),
        ]
    }

    public var notificationName: Notification.Name {
        .ParticipantRoleChange
    }
}

// MARK: - ParticipantRoleChangeInfo

@objcMembers
public final class ParticipantRoleChangeInfo: ObjectChangeInfo {
    static let ParticipantRoleChangeInfoKey = "participantRoleChanges"

    static func changeInfo(for participantRole: ParticipantRole, changes: Changes) -> ParticipantRoleChangeInfo? {
        ParticipantRoleChangeInfo(object: participantRole, changes: changes)
    }

    public required init(object: NSObject) {
        self.participantRole = object as! ParticipantRole
        super.init(object: object)
    }

    // swiftlint:disable:next todo_requires_jira_link
    // TODO: create ParticipantRoleType
    public let participantRole: ParticipantRole

    public var roleChanged: Bool {
        changedKeys.contains(#keyPath(ParticipantRole.role))
    }

    // MARK: Registering ParticipantRoleObservers

    /// Adds an observer for a participantRole
    ///
    /// You must hold on to the token and use it to unregister
    @objc(addParticipantRoleObserver:forParticipantRole:)
    public static func add(
        observer: ParticipantRoleObserver,
        for participantRole: ParticipantRole
    ) -> NSObjectProtocol {
        add(observer: observer, for: participantRole, managedObjectContext: participantRole.managedObjectContext!)
    }

    /// Adds an observer for the participantRole if one specified or to all ParticipantRoles is none is specified
    ///
    /// You must hold on to the token and use it to unregister
    @objc(addParticipantRoleObserver:forParticipantRole:managedObjectContext:)
    public static func add(
        observer: ParticipantRoleObserver,
        for participantRole: ParticipantRole?,
        managedObjectContext: NSManagedObjectContext
    ) -> NSObjectProtocol {
        ManagedObjectObserverToken(
            name: .ParticipantRoleChange,
            managedObjectContext: managedObjectContext,
            object: participantRole
        ) { [weak observer] note in
            guard let observer,
                  let changeInfo = note.changeInfo as? ParticipantRoleChangeInfo
            else { return }

            observer.participantRoleDidChange(changeInfo)
        }
    }
}

// MARK: - ParticipantRoleObserver

@objc
public protocol ParticipantRoleObserver: NSObjectProtocol {
    func participantRoleDidChange(_ changeInfo: ParticipantRoleChangeInfo)
}
