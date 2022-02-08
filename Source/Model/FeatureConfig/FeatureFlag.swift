//
// Wire
// Copyright (C) 2020 Wire Swiss GmbH
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

public enum FeatureFlagType: String {
    case digitalSignature
}

@objcMembers
public class FeatureFlag: ZMManagedObject {
    public static let teamKey = #keyPath(FeatureFlag.team)

    @NSManaged public var identifier: String
    @NSManaged public var isEnabled: Bool
    @NSManaged public var updatedTimestamp: Date
    @NSManaged public var team: Team?

    open override var ignoredKeys: Set<AnyHashable>? {
        return (super.ignoredKeys ?? Set())
            .union([#keyPath(updatedTimestamp)])
    }

    public override static func entityName() -> String {
        return "FeatureFlag"
    }

    public var updatedAt: Date? {
        return updatedTimestamp
    }

    @discardableResult
    public static func updateOrCreate(with type: FeatureFlagType,
                                      value: Bool,
                                      team: Team,
                                      context: NSManagedObjectContext) -> FeatureFlag {
        precondition(context.zm_isSyncContext)

        if let existing = team.fetchFeatureFlag(with: type) {
            existing.identifier = type.rawValue
            existing.isEnabled = value
            existing.updatedTimestamp = Date()
            existing.team = team
            return existing
        }

        let featureFlag = insert(with: type,
                                 value: value,
                                 team: team,
                                 context: context)
        return featureFlag
    }

    @discardableResult
    public static func insert(with type: FeatureFlagType,
                              value: Bool,
                              team: Team,
                              context: NSManagedObjectContext) -> FeatureFlag {
        precondition(context.zm_isSyncContext)

        let featureFlag = FeatureFlag.insertNewObject(in: context)
        featureFlag.identifier = type.rawValue
        featureFlag.isEnabled = value
        featureFlag.updatedTimestamp = Date()
        featureFlag.team = team
        return featureFlag
    }

    @discardableResult
    public static func fetch(with type: FeatureFlagType,
                             team: Team,
                             context: NSManagedObjectContext) -> FeatureFlag? {
        precondition(context.zm_isSyncContext)

        let fetchRequest = NSFetchRequest<FeatureFlag>(entityName: FeatureFlag.entityName())
        fetchRequest.predicate = NSPredicate(format: "%K == %@ && identifier == %@",
                                             FeatureFlag.teamKey,
                                             team,
                                             type.rawValue)
        fetchRequest.fetchLimit = 1
        return context.fetchOrAssert(request: fetchRequest).first
    }
}
