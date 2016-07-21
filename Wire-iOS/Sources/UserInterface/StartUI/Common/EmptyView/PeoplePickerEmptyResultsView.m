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


#import "PeoplePickerEmptyResultsView.h"

#import "WAZUIMagicIOS.h"

#import "UIView+Borders.h"
#import "PeoplePickerEmptyResultsActionView.h"
#import "NSLayoutConstraint+Helpers.h"


@interface PeoplePickerEmptyResultsView ()

@property (weak, nonatomic, readwrite) IBOutlet UITextView *messageTextView;
@property (weak, nonatomic) IBOutlet UIView *actionButtonsContainerView;
@property (strong, nonatomic) NSArray *actionButtonsContainerViewSizeConstraints;
@property (strong, nonatomic) NSMutableArray *mutableActionViews;

@end

@implementation PeoplePickerEmptyResultsView

+ (instancetype)peoplePickerEmptyResultsView
{
    NSString *className = NSStringFromClass([self class]);
    NSArray *contents = [[UINib nibWithNibName:className bundle:nil] instantiateWithOwner:nil options:nil];
    PeoplePickerEmptyResultsView *theView;
    for (NSObject *obj in contents){
        if ([obj isMemberOfClass:[self class]]){
            theView = (PeoplePickerEmptyResultsView *)obj;
            break;
        }
    }
    
    theView.backgroundColor = [UIColor clearColor];
    return theView;
}

#pragma mark - Init

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self setupActionViews];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        [self setupActionViews];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setupActionViews];
    }
    return self;
}

#pragma mark - Setup

- (void)setupActionViews
{
    self.actionButtonsContainerView.translatesAutoresizingMaskIntoConstraints = NO;
    self.mutableActionViews = [@[] mutableCopy];
    [self updateActionViews];
}

- (void)updateActionViews
{
    for (PeoplePickerEmptyResultsActionView *view in self.mutableActionViews) {
        [view removeConstraints:view.constraints];
    }
    [self.actionButtonsContainerView removeConstraints:self.actionButtonsContainerView.constraints];
    
    for (NSUInteger i = 0; i < self.mutableActionViews.count; i++) {
        PeoplePickerEmptyResultsActionView *view = self.mutableActionViews[i];
        if (view.superview != self.actionButtonsContainerView) {
            view.translatesAutoresizingMaskIntoConstraints = NO;
            [self.actionButtonsContainerView addSubview:view];
        }
        [view setupConstraints];
        [view addConstraintForTopMargin:0 relativeToView:self.actionButtonsContainerView];
        [view addConstraintForBottomMargin:0 relativeToView:self.actionButtonsContainerView];
        if (i > 0) {
            PeoplePickerEmptyResultsActionView *previousView = self.mutableActionViews[i - 1];
            [view addConstraintForAligningLeftToRightOfView:previousView distance:0];
        }
    }
    
    if (self.mutableActionViews.count > 0) {
        PeoplePickerEmptyResultsActionView *view = self.mutableActionViews[0];
        [view addConstraintForLeftMargin:0 relativeToView:self.actionButtonsContainerView];
        [self.mutableActionViews.lastObject addConstraintForRightMargin:0 relativeToView:self.actionButtonsContainerView];
    }
    
    // size of self.actionButtonsContainerView is defined by size of subviews, so in case there are no subviews need to add constraints
    if (self.mutableActionViews.count == 0) {
        self.actionButtonsContainerViewSizeConstraints = [self.actionButtonsContainerView addConstraintsForSize:CGSizeZero];
    } else if (self.actionButtonsContainerViewSizeConstraints.count > 0 && self.actionButtonsContainerViewSizeConstraints) {
        [self.actionButtonsContainerView removeConstraints:self.actionButtonsContainerViewSizeConstraints];
    }
    [self setNeedsUpdateConstraints];
}

#pragma mark - Properties

- (NSArray *)actionViews
{
    return self.mutableActionViews;
}

- (void)addActionView:(PeoplePickerEmptyResultsActionView *)actionView
{
    [self.mutableActionViews addObject:actionView];
    [self updateActionViews];
}

- (void)removeActionViewAtIndex:(NSUInteger)index
{
    PeoplePickerEmptyResultsActionView *view = self.mutableActionViews[index];
    [view removeFromSuperview];
    [self.mutableActionViews removeObjectAtIndex:index];
    [self updateActionViews];
}

@end
