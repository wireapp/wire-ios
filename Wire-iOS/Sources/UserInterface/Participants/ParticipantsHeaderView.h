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

@class ParticipantsHeaderView;
@protocol ParticipantsHeaderDelegate;



@interface ParticipantsHeaderView : UIView

@property (nonatomic, weak) id <ParticipantsHeaderDelegate> delegate;
@property (nonatomic, strong, readonly) UITextView *titleView;
@property (nonatomic, strong, readonly) UIView *topSeparatorLine;
@property (nonatomic, strong, readonly) UIView *separatorLine;
@property (nonatomic, assign, getter = areTopButtonsHidden) BOOL topButtonsHidden;
- (void)setTopButtonsHidden:(BOOL)topButtonsHidden animated:(BOOL)animated;
@property (nonatomic, assign, getter=isSubtitleHidden) BOOL subtitleHidden;
@property (nonatomic, readonly, copy) NSString *magicPostfix;

- (void)setTitle:(NSString *)title;

- (void)setSubtitle:(NSString *)subtitle;

- (void)setTitleAccessibilityIdentifier:(NSString *)identifier;

- (void)setSubtitleAccessibilityIdentifier:(NSString *)identifier;

- (void)setCancelButtonAccessibilityIdentifier:(NSString *)identifier;

@end



@protocol ParticipantsHeaderDelegate <NSObject>

@optional
- (void)participantsHeaderView:(ParticipantsHeaderView *)headerView didTapButton:(UIButton *)button;

- (BOOL)participantsHeaderView:(ParticipantsHeaderView *)headerView textViewShouldBeginEditing:(UITextView *)textView;

- (BOOL)participantsHeaderView:(ParticipantsHeaderView *)headerView textViewDidEndEditing:(UITextView *)textView;

- (BOOL)participantsHeaderView:(ParticipantsHeaderView *)headerView textView:(UITextView *)textView shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string;

@end
