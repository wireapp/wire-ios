//
//  StoredMeeting+CoreDataProperties.h
//  
//
//  Created by Christoph Aldrian on 01.07.26.
//
//  This file was automatically generated and should not be edited.
//

#import "WireDataModel.StoredMeeting+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface StoredMeeting (CoreDataProperties)

+ (NSFetchRequest<StoredMeeting *> *)fetchRequest NS_SWIFT_NAME(fetchRequest());

@property (nullable, nonatomic, copy) NSString *domain;
@property (nullable, nonatomic, copy) NSDate *end;
@property (nullable, nonatomic, copy) NSUUID *remoteIdentifier;
@property (nonatomic) int16_t repeatOptionRawValue;
@property (nullable, nonatomic, copy) NSDate *start;
@property (nullable, nonatomic, copy) NSString *title;
@property (nullable, nonatomic, retain) ZMConversation *conversation;
@property (nullable, nonatomic, retain) ZMUser *creator;

@end

NS_ASSUME_NONNULL_END
