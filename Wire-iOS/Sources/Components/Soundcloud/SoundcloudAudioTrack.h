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


#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import "AudioTrack.h"
#import "AudioPlaylist.h"



@class SoundcloudService;



@interface SoundcloudAudioTrack : NSObject <AudioTrack>

@property (nonatomic, readonly) NSString *trackId;
@property (nonatomic) NSURL *internalStreamURL;
@property (nonatomic) NSURL *previewStreamURL;
@property (nonatomic) NSURL *resolvedStreamURL;

+ (SoundcloudAudioTrack *)audioTrackFromJSON:(NSDictionary *)JSON  soundcloudService:(SoundcloudService *)soundcloudService;

@end


@interface SoundcloudPlaylist : NSObject<AudioPlaylist>

+ (SoundcloudPlaylist *)audioPlaylistFromJSON:(NSDictionary *)JSON soundcloudService:(SoundcloudService *)soundcloudService;

@end
