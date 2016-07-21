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


#import "ZMSnapshotTestCase.h"
#import "Wire_iOS_Tests-Swift.h"
#import "Wire-Swift.h"
#import <PureLayout/PureLayout.h>
#import <Classy/Classy.h>

@interface ToolTipViewControllerTests : ZMSnapshotTestCase
@property (nonatomic) ToolTipViewController *sut;
@end

@implementation ToolTipViewControllerTests

- (void)setUp {
    [super setUp];
    self.accentColor = ZMAccentColorBrightOrange;
    self.sut = [[ToolTipViewController alloc] initWithToolTip:[self toolTipWithHandler:nil]];
}

- (void)testThatItConfiguresTheViewCorrectlyWhenToolTipIsSet_ArrowLeft {
    // given
    UIView *contentView = [[UIView alloc] initForAutoLayout];
    UIView *referenceView = [[UIView alloc] initForAutoLayout];
    
    [contentView addSubview:referenceView];
    [contentView addSubview:self.sut.view];
    
    
    [self.sut.view autoPinEdgeToSuperviewEdge:ALEdgeLeft];
    [self.sut.view autoPinEdgeToSuperviewEdge:ALEdgeRight];
    [self.sut.view autoPinEdgeToSuperviewEdge:ALEdgeBottom];
    
    [referenceView autoSetDimensionsToSize:CGSizeMake(50, 50)];
    [referenceView autoPinEdgeToSuperviewEdge:ALEdgeTop];
    [referenceView autoPinEdgeToSuperviewEdge:ALEdgeLeft withInset:10];
    [referenceView autoPinEdge:ALEdgeBottom toEdge:ALEdgeTop ofView:self.sut.view];
    
    // when
    [self.sut makeTipPointToView:referenceView];
    
    // then
    ZMVerifyViewInAllIPhoneWidths(contentView);
}

- (void)testThatItConfiguresTheViewCorrectlyWhenToolTipIsSet_ArrowRight {
    // given
    
    UIView *contentView = [[UIView alloc] initForAutoLayout];
    UIView *referenceView = [[UIView alloc] initForAutoLayout];
    
    [contentView addSubview:referenceView];
    [contentView addSubview:self.sut.view];
    
    
    [self.sut.view autoPinEdgeToSuperviewEdge:ALEdgeLeft];
    [self.sut.view autoPinEdgeToSuperviewEdge:ALEdgeRight];
    [self.sut.view autoPinEdgeToSuperviewEdge:ALEdgeBottom];
    
    [referenceView autoSetDimensionsToSize:CGSizeMake(50, 50)];
    [referenceView autoPinEdgeToSuperviewEdge:ALEdgeTop];
    [referenceView autoPinEdgeToSuperviewEdge:ALEdgeRight withInset:10];
    [referenceView autoPinEdge:ALEdgeBottom toEdge:ALEdgeTop ofView:self.sut.view];
    
    // when
    [self.sut makeTipPointToView:referenceView];
    
    // then
    ZMVerifyViewInAllIPhoneWidths(contentView);
}

- (void)testThatItConfiguresTheViewCorrectlyWhenToolTipIsModified {
    // given
    
    UIView *contentView = [[UIView alloc] initForAutoLayout];
    UIView *referenceView1 = [[UIView alloc] initForAutoLayout];
    UIView *referenceView2 = [[UIView alloc] initForAutoLayout];
    
    [contentView addSubview:referenceView1];
    [contentView addSubview:referenceView2];
    [contentView addSubview:self.sut.view];
    
    
    [self.sut.view autoPinEdgeToSuperviewEdge:ALEdgeLeft];
    [self.sut.view autoPinEdgeToSuperviewEdge:ALEdgeRight];
    [self.sut.view autoPinEdgeToSuperviewEdge:ALEdgeBottom];
    
    [referenceView1 autoSetDimensionsToSize:CGSizeMake(50, 50)];
    [referenceView1 autoPinEdgeToSuperviewEdge:ALEdgeTop];
    [referenceView1 autoPinEdgeToSuperviewEdge:ALEdgeRight withInset:10];
    [referenceView1 autoPinEdge:ALEdgeBottom toEdge:ALEdgeTop ofView:self.sut.view];
    
    [referenceView2 autoSetDimensionsToSize:CGSizeMake(50, 50)];
    [referenceView2 autoPinEdgeToSuperviewEdge:ALEdgeTop];
    [referenceView2 autoPinEdgeToSuperviewEdge:ALEdgeLeft withInset:10];
    [referenceView2 autoPinEdge:ALEdgeBottom toEdge:ALEdgeTop ofView:self.sut.view];
    
    [self.sut makeTipPointToView:referenceView1];
    
    // when
    [self.sut makeTipPointToView:referenceView2];
    
    // then
    ZMVerifyViewInAllIPhoneWidths(contentView);
}

- (void)testThatItExecutesTheToolTipHandlerWhenTheViewIsTapped {
    // given
    __block NSUInteger tapCount = 0;
    self.sut = [[ToolTipViewController alloc] initWithToolTip:[self toolTipWithHandler:^{
        tapCount++;
    }]];
    
    // when
    [self.sut didTapView:[UITapGestureRecognizer new]];
    
    // then
    XCTAssertEqual(tapCount, 1lu);
}

#pragma mark - Helper

- (ToolTip *)toolTipWithHandler:(dispatch_block_t)handler
{
    return [[ToolTip alloc] initWithTitle:@"This is an awesome title!"
                              description:@"This is a very descriptive description. This describes exaclty what you should do next."
                                  handler:handler];
}

@end
