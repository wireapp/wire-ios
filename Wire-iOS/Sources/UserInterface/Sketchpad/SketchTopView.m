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


#import "SketchTopView.h"

#import <PureLayout/PureLayout.h>



@interface SketchTopView ()

@property (nonatomic) UIView *separatorView;

@end

@implementation SketchTopView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.separatorView = [[UIView alloc] initForAutoLayout];
        [self addSubview:self.separatorView];
        
        [self.separatorView autoPinEdgeToSuperviewEdge:ALEdgeLeft];
        [self.separatorView autoPinEdgeToSuperviewEdge:ALEdgeRight];
        [self.separatorView autoPinEdgeToSuperviewEdge:ALEdgeBottom];
        [self.separatorView autoSetDimension:ALDimensionHeight toSize:0.5f];
        
        self.titleLabel = [[UILabel alloc] initForAutoLayout];
        self.titleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        self.titleLabel.textAlignment = NSTextAlignmentCenter;
        [self addSubview:self.titleLabel];
    }
    return self;
}

@end
