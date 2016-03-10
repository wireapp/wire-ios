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


#import "ZMUserSession+UserNotificationCategories.h"


NSString *const ZMConversationCategory = @"conversationCategory";
NSString *const ZMConversationOpenAction = @"conversationOpenAction";
NSString *const ZMConversationDirectReplyAction = @"conversationDirectReplyAction";

NSString *const ZMCallCategory = @"callCategory";
NSString *const ZMCallIgnoreAction = @"ignoreCallAction";
NSString *const ZMCallAcceptAction = @"acceptCallAction";

NSString *const ZMConnectCategory = @"connectCategory";
NSString *const ZMConnectAcceptAction = @"acceptConnectAction";


static NSString * ZMPushActionLocalizedString(NSString *key)
{
    return [[NSBundle bundleForClass:ZMUserSession.class] localizedStringForKey:[@"push.notification.action." stringByAppendingString:key] value:@"" table:@"Push"];
}

@implementation ZMUserSession (UserNotificationCategories)


- (UIUserNotificationCategory *)replyCategory
{
    UIMutableUserNotificationCategory *category = [[UIMutableUserNotificationCategory alloc] init];
    category.identifier = ZMConversationCategory;
    [category setActions:@[[self replyActionDirectMessage]] forContext:UIUserNotificationActionContextDefault];
    [category setActions:@[[self replyActionDirectMessage],[self openAction]] forContext:UIUserNotificationActionContextMinimal];
    return category;
}


- (UIUserNotificationCategory *)callCategory
{
    UIMutableUserNotificationCategory *category = [[UIMutableUserNotificationCategory alloc] init];
    category.identifier = ZMCallCategory;
    [category setActions:@[[self acceptCallAction], [self ignoreCallAction], [self replyActionDirectMessage]] forContext:UIUserNotificationActionContextDefault];
    [category setActions:@[[self acceptCallAction], [self ignoreCallAction], [self replyActionDirectMessage]] forContext:UIUserNotificationActionContextMinimal];
    return category;
}


- (UIUserNotificationCategory *)connectCategory
{
    UIMutableUserNotificationCategory *category = [[UIMutableUserNotificationCategory alloc] init];
    category.identifier = ZMConnectCategory;
    [category setActions:@[[self acceptConnectionAction]] forContext:UIUserNotificationActionContextDefault];
    [category setActions:@[[self acceptConnectionAction]] forContext:UIUserNotificationActionContextMinimal];
    return category;
}


- (UIUserNotificationAction *)openAction
{
    UIMutableUserNotificationAction *action = [[UIMutableUserNotificationAction alloc] init];
    action.identifier = ZMConversationOpenAction;
    action.destructive = NO;
    action.authenticationRequired = false;
    action.title = [NSString localizedStringWithFormat:ZMPushActionLocalizedString(@"message.open"), nil];
    action.activationMode = UIUserNotificationActivationModeForeground;
    return action;
}


- (UIUserNotificationAction *)replyActionDirectMessage
{
    UIMutableUserNotificationAction *action = [[UIMutableUserNotificationAction alloc] init];
    action.destructive = NO;
    action.authenticationRequired = false;
    action.identifier= ZMConversationDirectReplyAction;
    if ([action respondsToSelector:@selector(setBehavior:)]) { // This is only available in iOS9
        action.behavior = UIUserNotificationActionBehaviorTextInput;
        NSString *sendButtonTitle = [NSString localizedStringWithFormat:ZMPushActionLocalizedString(@"message.reply.button.title"), nil];
        action.parameters = @{UIUserNotificationTextInputActionButtonTitleKey: sendButtonTitle};
        action.title = [NSString localizedStringWithFormat:ZMPushActionLocalizedString(@"message.reply"), nil];
    }
    action.activationMode = UIUserNotificationActivationModeBackground;
    return action;
}


- (UIMutableUserNotificationAction *)acceptCallAction
{
    UIMutableUserNotificationAction *action = [[UIMutableUserNotificationAction alloc] init];
    action.identifier = ZMCallAcceptAction;
    action.title = [NSString localizedStringWithFormat:ZMPushActionLocalizedString(@"call.accept"), nil];
    action.destructive = NO;
    action.activationMode = UIUserNotificationActivationModeForeground;
    action.authenticationRequired = false;
    return action;
}


- (UIMutableUserNotificationAction *)ignoreCallAction
{
    UIMutableUserNotificationAction *action = [[UIMutableUserNotificationAction alloc] init];
    action.identifier = ZMCallIgnoreAction;
    action.title = [NSString localizedStringWithFormat:ZMPushActionLocalizedString(@"call.ignore"), nil];;
    action.destructive = NO;
    action.activationMode = UIUserNotificationActivationModeBackground;
    action.authenticationRequired = false;
    return action;
}


- (UIMutableUserNotificationAction *)acceptConnectionAction
{
    UIMutableUserNotificationAction *action = [[UIMutableUserNotificationAction alloc] init];
    action.identifier = ZMConnectAcceptAction;
    action.title = [NSString localizedStringWithFormat:ZMPushActionLocalizedString(@"connection.accept"), nil];;
    action.destructive = NO;
    action.activationMode = UIUserNotificationActivationModeForeground;
    action.authenticationRequired = false;
    return action;
}

@end
