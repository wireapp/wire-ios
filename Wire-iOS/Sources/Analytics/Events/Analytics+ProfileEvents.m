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


#import "Analytics+ProfileEvents.h"


NSString *DownloadTypeToString(DownloadType downloadType);
NSString *ResetPasswordTypeToString(ResetPasswordType resetType);
NSString *SoundIntensityTypeToString(SoundIntensityType soundType);
NSString *TOSOpenedFromTypeToString(TOSOpenedFromType tosType);



@implementation Analytics (ProfileEvents)

- (void)tagAllowedAddressBook:(BOOL)allowed
{
    [self tagEvent:@"allowedAddressBook" attributes:@{@"allowed" : @(allowed)}];
}

- (void)tagHelp
{
    [self tagEvent:@"help"];
}

- (void)tagAbout
{
    [self tagEvent:@"about"];
}

- (void)tagSignOut
{
    [self tagEvent:@"signOut"];
}

- (void)tagViewedTOSFromPage:(TOSOpenedFromType)type
{
    [self tagEvent:@"viewedTOS" attributes:@{@"source" : TOSOpenedFromTypeToString(type)}];
}

- (void)tagViewedPrivacyPolicy
{
    [self tagEvent:@"viewedPrivacyPolicy"];
}

- (void)tagViewedLicenseInformation
{
    [self tagEvent:@"viewedLicenseInformation"];
}

- (void)tagViewedFingerprintLearnMore
{
    [self tagEvent:@"viewedFingerprintLearnMore"];
}

- (void)tagAddedPictureFromSource:(PictureUploadType)type
{
    [self tagEvent:@"addedPicture" attributes:@{@"addedPicture" : PictureUploadTypeToString(type)}];
}

- (void)tagSetAccentColor
{
    [self tagEvent:@"setAccentColor"];
}

- (void)tagResetPassword:(BOOL)reset fromType:(ResetPasswordType)type
{
    [self tagEvent:@"resetPassword" attributes:@{@"reset" : @(reset), @"resetLocation" : ResetPasswordTypeToString(type)}];
}

- (void)tagDownloadPreference:(DownloadType)type
{
    [self tagEvent:@"downloadPreference" attributes:@{@"downloadPreference" : DownloadTypeToString(type)}];
}

- (void)tagSoundIntensityPreference:(SoundIntensityType)type
{
    [self tagEvent:@"soundIntensityPreference" attributes:@{@"soundPreference" : SoundIntensityTypeToString(type)}];
}

- (void)tagProfilePictureFromSource:(PictureUploadType)type
{
    [self tagEvent:@"profilePicture" attributes:@{@"addedPicture" : PictureUploadTypeToString(type)}];
}

- (void)tagOnlyConnectedPeopleChange
{
    [self tagEvent:@"onlyConnectedPeopleChanged"];
}

- (void)tagShareContactsChangedInSettings
{
    [self tagEvent:@"shareContactsChangedInSettings"];
}

- (void)tagSendInviteViaMethod:(NSString *)method
{
    if (0 == method.length) {
        method = @"unknown";
    }
    [self tagEvent:@"sendInvite" attributes:@{@"method" : method}];
}

- (void)tagSendInviteCanceled
{
    [self tagEvent:@"sendInviteCanceled"];
}

@end


NSString *PictureUploadTypeToString(PictureUploadType type)
{
    switch (type) {
        case PictureUploadCamera:
            return @"fromCamera";
            break;
            
        case PictureUploadPhotoLibrary:
            return @"fromPhotoLibrary";
            break;
            
    }
}

NSString *DownloadTypeToString(DownloadType type)
{
    switch (type) {
        case DownloadOnlyWifi:
            return @"wifiOnly";
            break;
            
        case DownloadAlwaysDownload:
            return @"alwaysDownload";
            break;
            
    }
}

NSString *ResetPasswordTypeToString(ResetPasswordType type)
{
    switch (type) {
        case ResetFromProfile:
            return @"fromProfile";
            break;
            
        case ResetFromSignIn:
            return @"fromSignIn";
            break;
            
    }
}

NSString *SoundIntensityTypeToString(SoundIntensityType type)
{
    switch (type) {
        case SoundIntensityTypeAlways:
            return @"alwaysPlay";
            break;
            
        case SoundIntensityTypeFirstOnly:
            return @"firstMessageOnly";
            break;
            
        case SoundIntensityTypeNever:
            return @"neverPlay";
            break;
            
    }
}

NSString *TOSOpenedFromTypeToString(TOSOpenedFromType type)
{
    switch (type) {
        case TOSOpenedFromTypeJoinPage:
            return @"fromJoinPage";
            break;
            
        case TOSOpenedFromTypeAboutPage:
            return @"fromAboutPage";
            break;
    }
}
