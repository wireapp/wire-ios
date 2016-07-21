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


#import "TopItemsView.h"

#import <PureLayout/PureLayout.h>

#import "ConversationListItemView.h"
#import "ConversationListIndicator.h"

#import "WAZUIMagicIOS.h"
#import "zmessaging+iOS.h"
#import "UIView+Borders.h"
#import "AccentColorChangeHandler.h"
#import "avs+iOS.h"
#import "Constants.h"
#import "Settings.h"

@interface TopItemsView () <ZMConversationObserver, AVSMediaManagerClientObserver>

@property (nonatomic, assign) BOOL hasCreatedInitialConstraints;

@property (nonatomic, strong, readwrite) ConversationListItemView *activeVoiceChannelItem;

@property (nonatomic, strong) NSLayoutConstraint *activeVoiceChannelHeightConstraint;

@property (nonatomic, strong) UITapGestureRecognizer *activeVoiceChannelTapRecognizer;
@property (nonatomic, strong) UITapGestureRecognizer *selfItemTapRecognizer;

@property (nonatomic, strong) AccentColorChangeHandler *accentColorHandler;

@property (nonatomic) ZMConversation *conversation;
@property (nonatomic) id <ZMConversationObserverOpaqueToken> conversationObserverToken;

@end



@implementation TopItemsView

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self setupTopItemsView];
    }
    return self;
}

- (void)dealloc
{
    [ZMConversation removeConversationObserverForToken:self.conversationObserverToken];
    if (![[Settings sharedSettings] disableAVS]) {
        [AVSMediaManagerClientChangeNotification removeObserver:self];
    }
}

- (void)setupTopItemsView
{
    self.activeVoiceChannelItem = [[ConversationListItemView alloc] initForAutoLayout];
    self.activeVoiceChannelItem.clipsToBounds = YES;
    self.activeVoiceChannelTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTapOnActiveVoiceChannel)];
    [self.activeVoiceChannelItem addGestureRecognizer:self.activeVoiceChannelTapRecognizer];
    [self addSubview:self.activeVoiceChannelItem];

    self.accentColorHandler = [AccentColorChangeHandler addObserver:self handlerBlock:^(UIColor *newColor, TopItemsView *topItems) {
        topItems.activeVoiceChannelItem.selectionColor = newColor;
    }];
    
    if (![[Settings sharedSettings] disableAVS]) {
        [AVSMediaManagerClientChangeNotification addObserver:self];
    }
}


- (void)updateConstraints
{
    if (! self.hasCreatedInitialConstraints) {
        self.hasCreatedInitialConstraints = YES;

        self.activeVoiceChannelHeightConstraint = [self.activeVoiceChannelItem autoSetDimension:ALDimensionHeight toSize:0];
        [self.activeVoiceChannelItem autoPinEdgeToSuperviewEdge:ALEdgeTop];
        [self.activeVoiceChannelItem autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsZero excludingEdge:ALEdgeTop];
    }
    
    [super updateConstraints];
}

- (BOOL)selectActiveVoiceConversation
{
    if (self.activeVoiceChannelItem != nil) {
        self.activeVoiceChannelItem.selected = IS_IPAD;
        return YES;
    }
    return NO;
}

- (void)updateForCurrentOrientation
{
    [self.activeVoiceChannelItem updateForCurrentOrientation];
}

- (void)didTapOnActiveVoiceChannel
{
    [self selectActiveVoiceConversation];
}

- (void)deselectAll
{
    self.activeVoiceChannelItem.selected = NO;
}

- (void)addActiveVoiceChannelTarget:(id)target action:(SEL)action
{
    [self.activeVoiceChannelTapRecognizer addTarget:target action:action];
}

- (void)setActiveVoiceChannelConversation:(ZMConversation *)conversation
{
    if (self.conversationObserverToken != nil) {
        [ZMConversation removeConversationObserverForToken:self.conversationObserverToken];
    }
    
    self.conversation = conversation;
    
    if (conversation == nil) {
        self.activeVoiceChannelItem.statusIndicator.indicatorType = ZMConversationListIndicatorNone;
        self.activeVoiceChannelHeightConstraint.constant = 0;
        self.activeVoiceChannelItem.hidden = YES;
        self.activeVoiceChannelItem.rightAccessoryType = ConversationListRightAccessoryNone;
    }
    else {
        CGFloat conversationHeight = [[WAZUIMagic sharedMagic][@"list.tile_height"] floatValue];

        self.activeVoiceChannelHeightConstraint.constant = conversationHeight;
        self.activeVoiceChannelItem.titleText = conversation.displayName;
        self.activeVoiceChannelItem.statusIndicator.indicatorType = ZMConversationListIndicatorActiveCall;
        self.activeVoiceChannelItem.hidden = NO;
        self.activeVoiceChannelItem.rightAccessoryType = ConversationListRightAccessoryMuteVoiceButton;

        self.conversationObserverToken = [self.conversation addConversationObserver:self];
    }
}

- (void)conversationDidChange:(ConversationChangeInfo *)change
{
    self.activeVoiceChannelItem.titleText = change.conversation.displayName;
}

- (void)ensureAnimationsRunning
{
    [self.activeVoiceChannelItem.statusIndicator ensureAnimationsRunning];
}

- (void)mediaManagerDidChange:(AVSMediaManagerClientChangeNotification *)notification
{
    // AUDIO-548 AVMediaManager notifications arrive on a background thread.
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.activeVoiceChannelItem updateRightAccessoryAppearance];
    });
}

@end
