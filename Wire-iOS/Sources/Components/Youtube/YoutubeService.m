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


#import "YoutubeService.h"
#import "MediaPreviewData.h"
#import "MediaPreviewData+YouTube.h"
#import "GTLYouTube.h"



static NSString * const YoutubeDetailsSnippetPartParameterName = @"snippet";



@interface YoutubeService ()

@property (nonatomic) GTLServiceYouTube *service;

@end



@implementation YoutubeService

+ (instancetype)sharedInstance
{
    static YoutubeService *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] initWithAPIKey:@STRINGIZE(YOUTUBE_API_KEY)];
    });
    
    return sharedInstance;
}

- (instancetype)initWithAPIKey:(NSString *)APIKey
{
    self = [super init];
    
    if (self) {
        self.service = [[GTLServiceYouTube alloc] init];
        self.service.APIKey = APIKey;
    }
    
    return self;
}

- (void)mediaPreviewDataForYoutubeVideoURL:(NSURL *)URL completion:(void (^)(MediaPreviewData *mediaPreviewData, NSError *error))completion
{
    NSString *videoID = [self videoIDFromURL:URL];
    
    if (videoID == nil) {
        completion(nil, nil);
    }
    
    GTLQueryYouTube *query = [GTLQueryYouTube queryForVideosListWithPart:YoutubeDetailsSnippetPartParameterName];
    query.identifier = videoID;
    [self.service executeQuery:query
             completionHandler:^(GTLServiceTicket *ticket, GTLYouTubeVideoListResponse *response, NSError *error) {
                 if (nil != error) {
                     completion(nil, error);
                 }
                 
                 for (GTLYouTubeVideo *video in response.items) {
                     if ([video.identifier isEqualToString:videoID]) {
                         MediaPreviewData *previewData = [[MediaPreviewData alloc] initWithYouTubeVideo:video];
                         completion(previewData, nil);
                         break;
                     }
                 }
             }];
}

- (NSString *)videoIDFromURL:(NSURL *)URL
{
    NSString *videoID = nil;
    
    if (URL.query.length != 0) {
        for (NSString *parameter in [URL.query componentsSeparatedByString:@"&"]) {
            NSArray *components = [parameter componentsSeparatedByString:@"="];
            if([components count] < 2) {
                continue;
            }
            
            if ([components[0] isEqualToString:@"v"]) {
                videoID = components[1];
            }
        }
    }
    
    if (videoID.length == 0 && URL.pathComponents.count != 0) {
        videoID = URL.pathComponents.lastObject;
    }
    
    return videoID;
}

@end
