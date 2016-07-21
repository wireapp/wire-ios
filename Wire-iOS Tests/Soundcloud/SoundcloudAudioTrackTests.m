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


#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

#import "SoundcloudAudioTrack.h"



@interface SoundcloudAudioTrackTests : XCTestCase

@end

@implementation SoundcloudAudioTrackTests

- (NSDictionary *)JSONObjectFromFile:(NSString *)file
{
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    NSString *absoluteFilePath = [bundle pathForResource:[file stringByDeletingPathExtension] ofType:[file pathExtension]];
    NSError *error = nil;
    NSDictionary *JSON = [NSJSONSerialization JSONObjectWithData:[NSData dataWithContentsOfFile:absoluteFilePath] options:0 error:&error];
    
    if (error != nil) {
        XCTFail(@"Error parsing JSON: %@", error);
    }
    
    return JSON;
}

- (void)testThatTrackWithAllFieldsIsParsed
{
    // given
    NSDictionary *JSON = [self JSONObjectFromFile:@"soundcloud-track1.json"];
    
    // when
    SoundcloudAudioTrack *audioTrack = [SoundcloudAudioTrack audioTrackFromJSON:JSON soundcloudService:nil];
    
    // then
    XCTAssertEqualObjects(audioTrack.title, @"Britta Arnold - The Crazy Dur Light - KATER100");
    XCTAssertEqualObjects(audioTrack.author, @"KaterMukke");
    XCTAssertEqualObjects(audioTrack.externalURL, [NSURL URLWithString:@"http://soundcloud.com/katermukke/09-britta-arnold-the-crazy-dur"]);
    XCTAssertEqualObjects(audioTrack.artworkURL, [NSURL URLWithString:@"https://i1.sndcdn.com/artworks-000123332787-l0g5ux-crop.jpg"]);
}

- (void)testThatTrackWithoutAnyFieldsIsParsed
{
    // given
    NSDictionary *JSON = [NSDictionary dictionary];
    
    // when
    SoundcloudAudioTrack *audioTrack = [SoundcloudAudioTrack audioTrackFromJSON:JSON soundcloudService:nil];
    
    // then
    XCTAssertTrue(audioTrack != nil, @"Expected empty audio track");
}

- (void)testThatUserAvatarIsReturnedIfArtworkIsMissing
{
    // given
    NSDictionary *JSON = [self JSONObjectFromFile:@"soundcloud-track2.json"];
    
    // when
    SoundcloudAudioTrack *audioTrack = [SoundcloudAudioTrack audioTrackFromJSON:JSON soundcloudService:nil];
    
    // then
    XCTAssertEqualObjects(audioTrack.artworkURL, [NSURL URLWithString:@"https://i1.sndcdn.com/avatars-000115518914-61c8az-crop.jpg"]);
}

- (void)testThatTrackWithNullFieldsIsParsed
{
    // given
    NSDictionary *JSON = [self JSONObjectFromFile:@"soundcloud-track3.json"];
    
    // when
    SoundcloudAudioTrack *audioTrack = [SoundcloudAudioTrack audioTrackFromJSON:JSON soundcloudService:nil];
    
    // then
    XCTAssertTrue(audioTrack != nil, @"Expected empty audio track");
}

- (void)testThatTrackWithUnxpectedFieldTypesIsParsed
{
    // given
    NSDictionary *JSON = [self JSONObjectFromFile:@"soundcloud-track4.json"];
    
    // when
    SoundcloudAudioTrack *audioTrack = [SoundcloudAudioTrack audioTrackFromJSON:JSON soundcloudService:nil];
    
    // then
    XCTAssertTrue(audioTrack != nil, @"Expected empty audio track");
}

- (void)testThatPlaylistWithAllFieldsIsParsed
{
    // given
    NSDictionary *JSON = [self JSONObjectFromFile:@"soundcloud-playlist1.json"];
    
    // when
    SoundcloudPlaylist *audioPlaylist = [SoundcloudPlaylist audioPlaylistFromJSON:JSON soundcloudService:nil];
    
    // then
    XCTAssertEqualObjects(audioPlaylist.title, @"Maskinen - Stora Fötter, Stora Skor EP");
    XCTAssertEqualObjects(audioPlaylist.author, @"GOLDENBEST");
    XCTAssertTrue(audioPlaylist.tracks.count  == 6, @"Expected 6 tracks in the playlist");
}

- (void)testThatPlaylistWithoutAnyFieldsIsParsed
{
    // given
    NSDictionary *JSON = [NSDictionary dictionary];
    
    // when
    SoundcloudPlaylist *audioPlaylist = [SoundcloudPlaylist audioPlaylistFromJSON:JSON soundcloudService:nil];
    
    // then
    XCTAssertTrue(audioPlaylist != nil, @"Expected empty audio playlist");
}

- (void)testThatPlaylistWithNullFieldsIsParsed
{
    // given
    NSDictionary *JSON = [self JSONObjectFromFile:@"soundcloud-playlist2.json"];
    
    // when
    SoundcloudPlaylist *audioPlaylist = [SoundcloudPlaylist audioPlaylistFromJSON:JSON soundcloudService:nil];
    
    // then
    XCTAssertTrue(audioPlaylist != nil, @"Expected empty audio playlist");
}

- (void)testThatPlaylistWithUnxpectedFieldTypesIsParsed
{
    // given
    NSDictionary *JSON = [self JSONObjectFromFile:@"soundcloud-playlist3.json"];
    
    // when
    SoundcloudPlaylist *audioPlaylist = [SoundcloudPlaylist audioPlaylistFromJSON:JSON soundcloudService:nil];
    
    // then
    XCTAssertTrue(audioPlaylist != nil, @"Expected empty audio playlist");
}

@end
