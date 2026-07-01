//
//  StoredMeetingMeeting+CoreDataProperties.m
//  
//
//  Created by Christoph Aldrian on 01.07.26.
//
//  This file was automatically generated and should not be edited.
//

#import "StoredMeetingMeeting+CoreDataProperties.h"

@implementation StoredMeetingMeeting (CoreDataProperties)

+ (NSFetchRequest<StoredMeetingMeeting *> *)fetchRequest {
	return [NSFetchRequest fetchRequestWithEntityName:@"Meeting"];
}

@dynamic domain;
@dynamic end;
@dynamic remoteIdentifier;
@dynamic repeatOptionRawValue;
@dynamic start;
@dynamic title;
@dynamic conversation;
@dynamic creator;

@end
