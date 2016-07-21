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


#import "TopItemsController.h"
#import "TopItemsView.h"

#import "zmessaging+iOS.h"
#import "WAZUIMagicIOS.h"

#import <PureLayout/PureLayout.h>



@interface TopItemsController () <ZMConversationListObserver>

@property (nonatomic, readwrite) ZMConversation *activeVoiceConversation;
@property (nonatomic) TopItemsView *topItems;
@property (nonatomic) id<ZMConversationListObserverOpaqueToken> conversationListObserverToken;

@end



@implementation TopItemsController

- (void)dealloc
{
    [[[SessionObjectCache sharedCache] activeCallConversations] removeConversationListObserverForToken:self.conversationListObserverToken];
}

- (void)loadView
{
    self.view = [[UIView alloc] init];
    
    self.topItems = [[TopItemsView alloc] initForAutoLayout];
    [self.view addSubview:self.topItems];
    
    [self.topItems addActiveVoiceChannelTarget:self action:@selector(activeVoiceConversationPressed:)];
    
    [self.topItems autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsZero excludingEdge:ALEdgeTop];
    
    CGFloat statusBarHeight = [UIApplication sharedApplication].statusBarFrame.size.height;
    [self.topItems autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:statusBarHeight];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.conversationListObserverToken = [[[SessionObjectCache sharedCache] activeCallConversations] addConversationListObserver:self];
    self.view.opaque = NO;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.topItems ensureAnimationsRunning];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        // we reload on rotation to make sure that the list cells lay themselves out correctly for the new
        // orientation
        [self.topItems updateForCurrentOrientation];
    } completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
    }];
    
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
}

- (void)selectActiveVoiceConversationAndFocusOnView:(BOOL)focus
{
    [self selectActiveVoiceConversationAndFocusOnView:focus completion:nil];
}

- (void)selectActiveVoiceConversationAndFocusOnView:(BOOL)focus completion:(dispatch_block_t)completion
{
    if ([self.topItems selectActiveVoiceConversation]) {
        [self.delegate topItemsControllerDidSelectActiveVoiceConversation:self focusOnView:focus completion:completion];
    }
}

- (void)deselectAll
{
    [self.topItems deselectAll];
}

- (void)plusButtonPressed:(id)sender
{
    [self.delegate topItemsControllerPlusButtonPressed:self];
}

- (void)activeVoiceConversationPressed:(id)sender
{
    [self.delegate topItemsControllerDidSelectActiveVoiceConversation:self focusOnView:YES completion:nil];
}

- (void)setActiveVoiceConversation:(ZMConversation *)activeVoiceConversation
{
    if (_activeVoiceConversation == activeVoiceConversation) {
        return;
    }
    
    _activeVoiceConversation = activeVoiceConversation;
    [self.topItems setActiveVoiceChannelConversation:activeVoiceConversation];
    [self.delegate topItemsController:self activeVoiceConversationChanged:self.activeVoiceConversation];
}

#pragma mark - ZMConversationListObserver

- (void)conversationListDidChange:(ConversationListChangeInfo *)changeInfo
{
    NSArray *activeCallConversation = [[SessionObjectCache sharedCache] activeCallConversations];
    self.activeVoiceConversation = activeCallConversation.firstObject;
}

@end
