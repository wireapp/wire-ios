 //
//  IconLabelButton.m
//  ZClient-iOS
//
//  Created by Mihail Gerasimenko on 1/25/16.
//  Copyright © 2016 Zeta Project Germany GmbH. All rights reserved.
//

#import "IconLabelButton.h"
#import "UILabel+TextTransform.h"

#import <PureLayout/PureLayout.h>

@interface IconLabelButton ()
@property (nonatomic) UIControlState priorState;
@end

@implementation IconLabelButton


- (instancetype)init
{
    self = [super init];
    if (nil != self) {
        self.iconButton = [IconButton iconButtonCircularLight];
        self.iconButton.translatesAutoresizingMaskIntoConstraints = NO;
        self.iconButton.userInteractionEnabled = NO;
        [self addSubview:self.iconButton];
        
        [self.iconButton autoMatchDimension:ALDimensionWidth toDimension:ALDimensionHeight ofView:self.iconButton];
        [self.iconButton autoPinEdgeToSuperviewEdge:ALEdgeLeft];
        [self.iconButton autoPinEdgeToSuperviewEdge:ALEdgeRight];
        [self.iconButton autoPinEdgeToSuperviewEdge:ALEdgeTop];
        
        self.subtitleLabel = [[UILabel alloc] init];
        self.subtitleLabel.translatesAutoresizingMaskIntoConstraints = NO;
        self.subtitleLabel.textTransform = TextTransformUpper;
        [self addSubview:self.subtitleLabel];
        
        [self.subtitleLabel autoPinEdgeToSuperviewEdge:ALEdgeBottom];
        [self.subtitleLabel autoAlignAxisToSuperviewAxis:ALAxisVertical];
        [self.subtitleLabel autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.iconButton withOffset:8];
        [self.subtitleLabel autoSetDimension:ALDimensionHeight toSize:16];
    }
    
    return self;
}

- (void)didMoveToWindow
{
    [super didMoveToWindow];
    
    [self updateForNewState];
}

#pragma mark - Observing state

- (void)setHighlighted:(BOOL)highlighted
{
    _priorState = self.state;
    [super setHighlighted:highlighted];
    [self.iconButton setHighlighted:highlighted];
    [self updateForNewStateIfNeeded];
}

- (void)setSelected:(BOOL)selected
{
    _priorState = self.state;
    [super setSelected:selected];
    [self.iconButton setSelected:selected];
    [self updateForNewStateIfNeeded];
}

- (void)setEnabled:(BOOL)enabled
{
    _priorState = self.state;
    [super setEnabled:enabled];
    [self.iconButton setEnabled:enabled];
    [self updateForNewStateIfNeeded];
}

- (void)updateForNewStateIfNeeded
{
    if(self.state != _priorState)
    {
        _priorState = self.state;
        [self updateForNewState];
    }
}

- (void)updateForNewState
{
    // Update for new state (selected, highlighted, disabled) here if needed
    self.subtitleLabel.font = self.titleLabel.font;
    self.subtitleLabel.textColor = [self titleColorForState:self.state];
}

@end
