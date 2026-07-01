//
//  StoredMeeting+CoreDataProperties.m
//  
//
//  Created by Christoph Aldrian on 01.07.26.
//
//  This file was automatically generated and should not be edited.
//

#import "StoredMeeting+CoreDataProperties.h"

@implementation StoredMeeting (CoreDataProperties)

+ (NSFetchRequest<StoredMeeting *> *)fetchRequest {
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
