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

#import "BadgeUserImageView.h"



typedef NS_ENUM(NSUInteger, VoiceUserImageViewState) {
    
    /// Default look with fixed stroke
    VoiceUserImageViewStateDefault,
    
    ////
    // “Active” states, stroke is “outer” (added to image diameter)
    ////
    
    /// "Call connecting" treatment with spinning indicator around the tile
    VoiceUserImageViewStateConnecting,
    
    
    /// "Call connecting" to a group call
    VoiceUserImageViewStateConnectingGroup,
    
    /// Three rings animated based on voice gain
    VoiceUserImageViewStateTalking,
};



@interface VoiceUserImageView : BadgeUserImageView

/// If this tile represents a voice participant and tileState==talking, then this is the current voice gain level and is updated frequently as the person talks.
@property (nonatomic) CGFloat voiceGain;

@property (nonatomic) VoiceUserImageViewState state;

@end
