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
// along with this program. If not, see http://www.gnu.org/licenses/.
// 


#import "Analytics+Screens.h"



@implementation Analytics (Screens)

- (void)internalTagWithScreen:(NSString *)key
{
    if (! key) {
        return;
    }
    
    [self tagScreen:[key uppercaseString]];
}

- (void)tagScreenSignIn
{
    [self internalTagWithScreen:@"SIGN_IN"];
}

- (void)tagScreenWelcome
{
    [self internalTagWithScreen:@"WELCOME"];
}

- (void)tagScreenRegistrationPhoto
{
    [self internalTagWithScreen:@"PHOTO"];
}

- (void)tagScreenRegistrationUserDetails
{
    [self internalTagWithScreen:@"REG_USER_DETAILS"];
}

- (void)tagScreenRegistrationEmailVerification
{
    [self internalTagWithScreen:@"EMAIL_VERIFICATION"];
}

- (void)tagScreenRegistrationError
{
    [self internalTagWithScreen:@"ERROR"];
}

- (void)tagScreenSelfProfile
{
    [self internalTagWithScreen:@"SELF_PROFILE"];
}

- (void)tagScreenSettings
{
    [self internalTagWithScreen:@"SETTINGS"];
}

- (void)tagScreenSendConnect
{
    [self internalTagWithScreen:@"SEND_CONNECT_REQUEST"];
}

- (void)tagScreenConversationParticipants
{
    [self internalTagWithScreen:@"CONVERSATION_PARTICIPANTS"];
}

- (void)tagScreenPeoplePickerAddParticipants
{
    [self internalTagWithScreen:@"PEOPLE_PICKER_ADD"];
}

- (void)tagScreenPeoplePickerSearch
{
    [self internalTagWithScreen:@"PEOPLE_PICKER_SEARCH"];
}

- (void)tagScreenSelfIsCalling
{
    [self internalTagWithScreen:@"OUTGOING_CALL"];
}

- (void)tagScreenOtherIsCalling
{
    [self internalTagWithScreen:@"INCOMING_CALL"];
}

- (void)tagScreenInviteContactList
{
    [self internalTagWithScreen:@"CONTACT_LIST"];
}

- (void)tagScreenGenericInvite
{
    [self internalTagWithScreen:@"GENERIC_INVITE"];
}


@end
