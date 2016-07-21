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


// ui
#import "ParticipantsList.h"
#import "ParticipantsListCell.h"

// model
#import "zmessaging+iOS.h"

// helpers
#import "WAZUIMagicIOS.h"

#import "Constants.h"



@interface ParticipantsList ()
{
    BOOL doneRegisteringCell;
    NSMutableSet *userImageObserverTokens;
}


@end



static NSString *const ParticipantCellReuseIdentifier = @"ParticipantListCell";



@implementation ParticipantsList


- (void)viewDidLoad
{
    userImageObserverTokens = [NSMutableSet set];

    [super viewDidLoad];

    [self.collectionView registerClass:[ParticipantsListCell class] forCellWithReuseIdentifier:ParticipantCellReuseIdentifier];

    UITapGestureRecognizer *tapper = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTapOnCell:)];
    [self.collectionView addGestureRecognizer:tapper];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc
{
}


#pragma mark - Collection view

- (UICollectionViewCell *)collectionView:(UICollectionView *)cv cellForItemAtIndexPath:(NSIndexPath *)indexPath;
{
    ParticipantsListCell *cell = [cv dequeueReusableCellWithReuseIdentifier:ParticipantCellReuseIdentifier forIndexPath:indexPath];

    NSUInteger index = indexPath.section * [self.delegate participantsPerPage] + indexPath.row;
    id maybeUser = [NSNull null];

    if (self.participants.count > index) {
        maybeUser = [self.participants objectAtIndex:index];
    }

    if (! [maybeUser isKindOfClass:[NSNull class]]) {
        [self configureCell:cell atIndexPath:indexPath];
        CGFloat alpha = [self alphaForCell:cell atIndexPath:indexPath];
        cell.alpha = alpha;
    } else {
        cell.alpha = 0;
    }

    return cell;
}


#pragma mark - Model

- (void)setParticipants:(NSArray *)participants
{

    _participants = participants;

    [self.collectionView reloadData];
}


#pragma mark - UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{

    NSInteger perPage = [self.delegate participantsPerPage];

    return perPage;

//    if ((section + 1) * perPage < self.participants.count) {
//        // normal page, there are other pages after this
//        return perPage;
//    }
//    
//    // last page
//    NSInteger participantsOnLastPage = self.participants.count - section * perPage;
//    return participantsOnLastPage;
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{

    return 1;
}


#pragma mark - Gestures

- (void)didTapOnCell:(UITapGestureRecognizer *)tapper
{
    if (tapper.state == UIGestureRecognizerStateRecognized) {
        NSIndexPath *path = [self.collectionView indexPathForItemAtPoint:[tapper locationInView:self.collectionView]];
        if (path) {
            NSInteger userIndex = path.section * [self.delegate participantsPerPage] + path.row;
            if (userIndex < (NSInteger) self.participants.count) {
                ZMUser *user = self.participants[userIndex];
                if (user && ! [user isKindOfClass:[NSNull class]]) {
                    [self.delegate tappedOnUser:user];
                }
            }
        }
    }
}


#pragma mark - Custom UI

- (CGFloat)alphaForCell:(ParticipantsListCell *)cell atIndexPath:(NSIndexPath *)path
{

    CGFloat desiredAlpha = 1;
    if (path && self.conversation) {

        NSInteger targetIndex = path.section * [self.delegate participantsPerPage] + path.row;
        if (targetIndex < (NSInteger) self.participants.count) {
            ZMUser *user = self.participants[targetIndex];
            if ([user isKindOfClass:[NSNull class]]) {
                return 0.0f;
            }
            if (user) {
                if (! [self.conversation.activeParticipants containsObject:user]) {
                    desiredAlpha = 0.2;
                }
            }
        }
    }

    if (([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) && ! IS_IPAD_LANDSCAPE_LAYOUT) {
        CGFloat width = ((UICollectionViewFlowLayout *) self.collectionView.collectionViewLayout).itemSize.width;
        CGFloat computedX = cell.frame.origin.x - self.collectionView.contentOffset.x;
        if (computedX < 0) {
            return desiredAlpha * (width - fabsf((float)computedX)) / width;
        }
    }
    return desiredAlpha;
}

- (void)configureCell:(ParticipantsListCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    ZMUser *user = self.participants[indexPath.section * [self.delegate participantsPerPage] + indexPath.row];
    cell.representedObject = user;
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{

    // if an item is fading out to left on the ipad, fade it away through alpha

    for (ParticipantsListCell *cell in [self.collectionView visibleCells]) {
        CGFloat alpha = [self alphaForCell:cell atIndexPath:[self.collectionView indexPathForCell:cell]];
        cell.alpha = alpha;
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    [self.delegate participants:self didScrollToVisibleItemIndexPaths:[self.collectionView indexPathsForVisibleItems]];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    if (! decelerate) {
        [self.delegate participants:self didScrollToVisibleItemIndexPaths:[self.collectionView indexPathsForVisibleItems]];
    }
}

@end
