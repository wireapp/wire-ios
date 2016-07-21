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


#import "MediaPreviewData+YouTube.h"
#import "MediaThumbnail.h"
#import "GTLYouTube.h"



@interface MediaThumbnail (YouTube)
- (instancetype)initWithYouTubeThumbnail:(GTLYouTubeThumbnail *)thumbnail;
@end



@implementation MediaPreviewData (YouTube)

- (instancetype)initWithYouTubeVideo:(GTLYouTubeVideo *)video
{
    NSString *title = video.snippet.title;
    NSMutableArray *thumbnails = [NSMutableArray new];
    GTLYouTubeThumbnailDetails *thumbnailDetails = video.snippet.thumbnails;
    if (thumbnailDetails) {
        NSMutableArray *youtubeThumbnails = [NSMutableArray new];
        if (thumbnailDetails.standard) {
            [youtubeThumbnails addObject:thumbnailDetails.standard];
        }
        if (thumbnailDetails.maxres) {
            [youtubeThumbnails addObject:thumbnailDetails.maxres];
        }
        if (thumbnailDetails.high) {
            [youtubeThumbnails addObject:thumbnailDetails.high];
        }
        if (thumbnailDetails.medium) {
            [youtubeThumbnails addObject:thumbnailDetails.medium];
        }
        if (thumbnailDetails.defaultProperty) {
            [youtubeThumbnails addObject:thumbnailDetails.defaultProperty];
        }
        
        for (GTLYouTubeThumbnail *youtubeThumbnail in youtubeThumbnails) {
            MediaThumbnail *thumbnail = [[MediaThumbnail alloc] initWithYouTubeThumbnail:youtubeThumbnail];
            if (thumbnail) {
                [thumbnails addObject:thumbnail];
            }
        }
    }
    return [self initWithTitle:title thumbnails:thumbnails provider:MediaPreviewDataProviderYoutube];
}

@end



@implementation  MediaThumbnail (YouTube)

- (instancetype)initWithYouTubeThumbnail:(GTLYouTubeThumbnail *)thumbnail
{
    if (thumbnail.url) {
        NSURL *url = [NSURL URLWithString:thumbnail.url];
        CGSize size = CGSizeZero;
        if (thumbnail.width && thumbnail.height) {
            size = CGSizeMake(thumbnail.width.floatValue, thumbnail.height.floatValue);
        }
        return [self initWithURL:url size:size];
    } else {
        return nil;
    }
}

@end
