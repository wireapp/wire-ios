// 
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
// 


@import ZMCSystem;
@import libPhoneNumber;
@import AddressBook;

#import "ZMAddressBook.h"
#import "ZMAddressBookContact.h"
#import "ZMUserSession+Internal.h"
#import "ZMNotifications+Internal.h"
#import "ZMPersonalInvitation+Internal.h"



# define ABMultiValueCount(x) ABMultiValueGetCount(x)
# define PersonPhoneProperty (kABPersonPhoneProperty)
# define PersonEmailProperty (kABPersonEmailProperty)


static char* const ZMLogTag ZM_UNUSED = "Addressbook";


static NSString * const ZMSentAddressBookInvitationsKey = @"ZMSentAddressBookInvitations";

@interface ZMAddressBook ()

@property (nonatomic, assign) ABAddressBookRef addressBook;
@property (nonatomic) NBPhoneNumberUtil *phoneNumberUtil;

@end



@interface ZMAddressBookIterator : NSObject <NSFastEnumeration>

@property (nonatomic) NBPhoneNumberUtil *phoneNumberUtil;
@property (nonatomic) NSArray *people;
@property (nonatomic) NSMutableSet *lastReturnedEntries;

- (instancetype)initWithPeople:(NSArray *)people phoneNumberUtil:(NBPhoneNumberUtil *)phoneNumberUtil;

@end



@interface NBPhoneNumberUtil (ZMAddressBook)

- (NSString *)zm_normalizePhoneNumber:(NSString *)number;

@end



@implementation ZMAddressBook
{
    ABAddressBookRef _addressBook;
}

+ (instancetype)addressBook;
{
    return [[ZMAddressBook alloc] init];
}

+ (BOOL)userHasAuthorizedAccess
{
    ABAuthorizationStatus const status = ABAddressBookGetAuthorizationStatus();
    return status == kABAuthorizationStatusAuthorized;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        if ([ZMAddressBook userHasAuthorizedAccess]) {
            CFErrorRef error = NULL;
            _addressBook = ABAddressBookCreateWithOptions(NULL, &error);
        }
        if (_addressBook == NULL) {
            ZMLogWarn(@"Unable to get address book.");
            dispatch_async(dispatch_get_main_queue(), ^{
                [[NSNotificationCenter defaultCenter] postNotificationName:ZMUserSessionFailedToAccessAddressBookNotificationName object:self];
            });
            return nil;
        }
        self.phoneNumberUtil = [[NBPhoneNumberUtil alloc] init];
    }
    return self;
}

- (id<NSFastEnumeration>)contacts;
{
    NSArray *peopleArray;
    peopleArray = CFBridgingRelease(ABAddressBookCopyArrayOfAllPeople(self.addressBook));
    return [[ZMAddressBookIterator alloc] initWithPeople:peopleArray phoneNumberUtil:self.phoneNumberUtil];
}

- (void)dealloc
{
    if (_addressBook != NULL) {
        CFRelease(_addressBook);
        _addressBook = NULL;
    }
}

@end


@implementation ZMAddressBookIterator

- (instancetype)initWithPeople:(NSArray *)people phoneNumberUtil:(NBPhoneNumberUtil *)phoneNumberUtil
{
    self = [super init];
    if(self) {
        self.people = people;
        self.phoneNumberUtil = phoneNumberUtil;
        self.lastReturnedEntries = [NSMutableSet set];
    }
    return self;
}

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(id __unsafe_unretained [])buffer count:(NSUInteger)len;
{
    (void) buffer;
    (void) len;
    
    // plan of action:
    // state is the next index in the array. mutationsPtr is not used.
    
    if(state->state == 0)
    {
        state->mutationsPtr = (__bridge void *) self;
    }
    
    [self.lastReturnedEntries removeAllObjects];
    
    state->itemsPtr = buffer;
    NSUInteger returnedValues = 0;
    
    // Now fill up at most 'len' items in 'buffer'.
    while ((returnedValues < len) && (state->state < self.people.count)) {
        ABRecordRef record = (ABRecordRef) CFBridgingRetain(self.people[state->state]);
        state->state++;
        
        // Phone numbers:
        NSMutableArray *phoneNumbers = [NSMutableArray array];
        {
            ABMultiValueRef multi = ABRecordCopyValue(record, PersonPhoneProperty);
            if (multi != NULL) {
                for (CFIndex i = 0; i < ABMultiValueCount(multi); i++) {
                    NSString *phoneNumber = CFBridgingRelease(ABMultiValueCopyValueAtIndex(multi, i));
                    if (0 < phoneNumber.length) {
                        NSString *normalized = [self.phoneNumberUtil zm_normalizePhoneNumber:phoneNumber];
                        if (0 < normalized.length) {
                            [phoneNumbers addObject:normalized];
                        }
                    }
                }
                CFRelease(multi);
            }
        }
        
        // Email addresses:
        NSMutableArray *emailAddresses = [NSMutableArray array];
        {
            ABMultiValueRef multi = ABRecordCopyValue(record, PersonEmailProperty);
            if (multi != NULL) {
                for (CFIndex i = 0; i < ABMultiValueCount(multi); i++) {
                    NSString *email = CFBridgingRelease(ABMultiValueCopyValueAtIndex(multi, i));
                    if (0 < email.length) {
                        if ([email rangeOfString:@"@"].location != NSNotFound) {
                            [emailAddresses addObject:email];
                        }
                    }
                }
                CFRelease(multi);
            }
        }
        
        if (phoneNumbers.count == 0 && emailAddresses.count == 0) {
            CFRelease(record);
            continue;
        }
        
        ZMAddressBookContact *person = [[ZMAddressBookContact alloc] init];
        [self.lastReturnedEntries addObject:person];
        buffer[returnedValues] = person;
        
        ++returnedValues;
        
        person.emailAddresses = emailAddresses;
        person.phoneNumbers = phoneNumbers;
        person.firstName = CFBridgingRelease(ABRecordCopyValue(record, kABPersonFirstNameProperty));
        person.middleName = CFBridgingRelease(ABRecordCopyValue(record, kABPersonMiddleNameProperty));
        person.lastName = CFBridgingRelease(ABRecordCopyValue(record, kABPersonLastNameProperty));
        
        person.nickname = CFBridgingRelease(ABRecordCopyValue(record, kABPersonNicknameProperty));
        person.organization = CFBridgingRelease(ABRecordCopyValue(record, kABPersonOrganizationProperty));
        
        CFRelease(record);
    }
    
    return returnedValues;
}

@end



@implementation NBPhoneNumberUtil (ZMAddressBook)

- (NSString *)zm_normalizePhoneNumber:(NSString *)number
{
    NSError *error;
    NBPhoneNumber *phoneNumber = [self parseWithPhoneCarrierRegion:number error:&error];
    if (phoneNumber == nil || error != nil) {
        ZMLogDebug(@"Failed to parse phone number \"%@\": %@", number, error);
        return nil;
    }
    
    
    NSString *result = [self format:phoneNumber numberFormat:NBEPhoneNumberFormatE164 error:&error];
    if (result == nil || error != nil) {
        ZMLogDebug(@"Failed to format phone number \"%@\" {%@}: %@", number, phoneNumber, error);
        return nil;
    }
    return result;
}

@end



@implementation ZMAddressBookContact

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.emailAddresses = @[];
        self.phoneNumbers = @[];
    }
    return self;
}

- (NSString *)name
{
    NSMutableArray *names = [NSMutableArray array];
    
    if (self.firstName.length > 0) {
        [names addObject:self.firstName];
    }
    
    if (self.middleName.length > 0) {
        [names addObject:self.middleName];
    }
    
    if (self.lastName.length > 0) {
        [names addObject:self.lastName];
    }
    
    if (names.count > 0) {
        return [names componentsJoinedByString:@" "];
    } else if (self.organization) {
        return self.organization;
    } else if (self.nickname) {
        return self.nickname;
    } else if (self.emailAddresses.count > 0) {
        return self.emailAddresses.firstObject;
    } else if (self.phoneNumbers.count > 0) {
        return self.phoneNumbers.firstObject;
    }
    return @"";
}

- (NSString *)description;
{
    return [NSString stringWithFormat:@"<%@: %p> email: {%@}, phone: {%@}",
            self.class, self,
            [self.emailAddresses componentsJoinedByString:@"; "],
            [self.phoneNumbers componentsJoinedByString:@"; "]];
}

- (NSArray *)contactDetails
{
    NSMutableArray *details = [NSMutableArray array];
    [details addObjectsFromArray:self.emailAddresses];
    [details addObjectsFromArray:self.phoneNumbers];
    return details;
}

- (NSArray *)invitationsInUserSession:(ZMUserSession *)userSession
{
    return [ZMPersonalInvitation fetchInvitationsFromUser:[ZMUser selfUserInUserSession:userSession]
                                                  contact:self
                                     managedObjectContext:userSession.managedObjectContext];
}

- (BOOL)hasBeenInvitedInUserSession:(ZMUserSession *)userSession
{
    return [[self invitationsInUserSession:userSession] count] > 0;
}

- (BOOL)requestedConnectionInUserSession:(ZMUserSession *)userSession
{
    NSArray *invitations = [self invitationsInUserSession:userSession];
    for (ZMPersonalInvitation *invitation in invitations) {
        if (invitation.status == ZMInvitationStatusConnectionRequestSent) {
            return YES;
        }
    }
    return NO;
}

- (BOOL)inviteWithEmail:(NSString *)emailAddress
    toGroupConversation:(ZMConversation *)conversation
            userSession:(ZMUserSession *)userSession
{
    if ([self requestedConnectionInUserSession:userSession]) {
        return NO;
    }
    ZMPersonalInvitation *invitation = [ZMPersonalInvitation invitationFromUser:[ZMUser selfUserInUserSession:userSession]
                                                                      toContact:self
                                                                          email:emailAddress
                                                                   conversation:conversation
                                                           managedObjectContext:userSession.managedObjectContext];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        ZMNotification *note = [ZMInvitationStatusChangedNotification invitationStatusChangedNotificationForContactEmailAddress:emailAddress
                                                                                                                         status:ZMInvitationStatusPending];
        [[NSNotificationCenter defaultCenter] postNotification:note];
    });
    return (invitation != nil);
}

- (BOOL)inviteWithPhoneNumber:(NSString *)phoneNumber
          toGroupConversation:(ZMConversation *)conversation
                  userSession:(ZMUserSession *)userSession
{
    if ([self requestedConnectionInUserSession:userSession]) {
        return NO;
    }
    ZMPersonalInvitation *invitation = [ZMPersonalInvitation invitationFromUser:[ZMUser selfUserInUserSession:userSession]
                                                                      toContact:self
                                                                    phoneNumber:phoneNumber
                                                                   conversation:conversation
                                                           managedObjectContext:userSession.managedObjectContext];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        ZMNotification *note = [ZMInvitationStatusChangedNotification invitationStatusChangedNotificationForContactPhoneNumber:phoneNumber
                                                                                                                        status:ZMInvitationStatusPending];
        [[NSNotificationCenter defaultCenter] postNotification:note];
    });
    return (invitation != nil);
}

@end
