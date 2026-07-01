//
//  StoredMeetingMeeting+CoreDataProperties.swift
//  
//
//  Created by Christoph Aldrian on 01.07.26.
//
//  This file was automatically generated and should not be edited.
//

public import Foundation
public import CoreData


public typealias StoredMeetingMeetingCoreDataPropertiesSet = NSSet

extension StoredMeetingMeeting {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<StoredMeetingMeeting> {
        return NSFetchRequest<StoredMeetingMeeting>(entityName: "Meeting")
    }

    @NSManaged public var domain: String?
    @NSManaged public var end: Date?
    @NSManaged public var remoteIdentifier: UUID?
    @NSManaged public var repeatOptionRawValue: Int16
    @NSManaged public var start: Date?
    @NSManaged public var title: String?
    @NSManaged public var conversation: ZMConversation?
    @NSManaged public var creator: ZMUser?

}

extension StoredMeetingMeeting : Identifiable {

}
