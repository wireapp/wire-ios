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



#import "ProfileSelfNameFieldDelegate.h"
#import "NameField.h"
#import "Guidance.h"
#import "FormGuidance.h"
#import "NSError+Zeta.h"
#import "WAZUIMagicIOS.h"
#import "zmessaging+iOS.h"
#import "ZMUserSession+Additions.h"



@interface ProfileSelfNameFieldDelegate ()

@property (weak, nonatomic) id field;

@property (weak, nonatomic, readwrite) UIViewController *controller;

@property (strong, nonatomic) NSLayoutConstraint *springConstraint;
@property (nonatomic) CGFloat minDistanceFromInputAccessoryView;

@property (nonatomic, copy) void (^keyboardWillAppearBlock)(CGFloat keyboardHeight);
@property (nonatomic, copy) void (^keyboardWillDisappearBlock)(CGFloat keyboardHeight);

@property (nonatomic, assign) BOOL shouldEndEditing;

- (void)loadMagicValues;
- (void)presentGuidance:(Guidance *)guidance;
- (void)dismissGuidance;
@end



@implementation ProfileSelfNameFieldDelegate

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (instancetype)initWithController:(id )controller field:(id)field
{
	self = [super init];
	if (self) {
		self.controller = controller;
		self.field = field;

		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardFrameWillChange:) name:UIKeyboardWillChangeFrameNotification object:nil];

		[self loadMagicValues];

		self.keyboardWillAppearBlock = nil;
		self.keyboardWillDisappearBlock = nil;
	}

	return self;
}

- (void)loadMagicValues
{
	self.minDistanceFromInputAccessoryView = [WAZUIMagic cgFloatForIdentifier:@"profile.field_min_distance_form_input_accessory_view"];
}

- (void)forceEndEditing
{
    self.shouldEndEditing = YES;
    [self.field endEditing:YES];
    self.shouldEndEditing = NO;
}

#pragma mark - UIKeyBoard

- (void)keyboardFrameWillChange:(NSNotification *)notification
{

	NSDictionary *userInfo = notification.userInfo;
	CGRect endFrame = [[userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
	CGRect endFrameInView = [self.controller.view convertRect:endFrame fromView:self.controller.view.window];
	CGFloat keyboardHeight = CGRectGetMaxY(self.controller.view.bounds) - CGRectGetMinY(endFrameInView);
	double animationLength = [[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];

	UIViewAnimationCurve const curve = (UIViewAnimationCurve) [userInfo[UIKeyboardAnimationCurveUserInfoKey] intValue];
	UIViewAnimationOptions const options = (UIViewAnimationOptions) (curve << 16);

	if (keyboardHeight < 0) { // keyboard cannot be smaller than 0
		keyboardHeight = 0;
	}

	if (keyboardHeight != 0) {

		if (self.keyboardWillAppearBlock) {
			self.keyboardWillAppearBlock(keyboardHeight + self.minDistanceFromInputAccessoryView);
		}
	}
	else {
		if (self.keyboardWillDisappearBlock) {
			self.keyboardWillDisappearBlock(keyboardHeight);

		}
	}

	[UIView animateWithDuration:animationLength
						  delay:0
						options:options
					 animations:^
	 {

		 [self.controller.view layoutIfNeeded];
	 }

					 completion:nil];
}


- (BOOL)textViewShouldBeginEditing:(UITextView *)textView
{
    return YES;
}

- (void)textViewDidBeginEditing:(UITextView *)textView
{

}

- (BOOL)textViewShouldEndEditing:(UITextView *)textView
{
    NSError *error = [self verifyInput:textView.text];
    if (error == nil) {
        return YES;
    }
    else {
        [self presentGuidance:error.guidance];
        [self showGuidanceDot:YES];
    }
    
    return self.shouldEndEditing;
}

- (void)textViewDidEndEditing:(UITextView *)textView
{
    [self showGuidanceDot:NO];
    [self dismissGuidance];
    
    if (![textView.text isEqualToString:[ZMUser selfUser].name]) {
        [[ZMUserSession sharedSession] enqueueChanges:^{
            [ZMUser editableSelfUser].name = textView.text;
        }];
    }
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    if ([text isEqualToString:@"\n"]) {
        [textView resignFirstResponder];
        return NO;
    }
    NSString *newName = [textView.text stringByReplacingCharactersInRange:range withString:text];

    if (newName.length > NameFieldUserMaxLength && newName.length > textView.text.length) {
        return NO;
    }

    return YES;
}

- (void)textViewDidChange:(UITextView *)textView
{
    if (textView.text) {
        [self dismissGuidance];
        [self showGuidanceDot:NO];
    }
}

- (NSError *)verifyInput:(NSString *)string
{
    NSError *error = nil;
    
    BOOL isNameValid = [[ZMUser selfUser] validateValue:&string forKey:@"name" error:&error];
    
    NSString *key;
    
    if (error && !isNameValid) {
        
        switch (error.code) {
                
            case ZMObjectValidationErrorCodeStringTooLong:
                key = @"name.guidance.toolong";
                break;
            case ZMObjectValidationErrorCodeStringTooShort:
                key = @"name.guidance.tooshort";
            default:
                break;
        }
        
        Guidance *guidance = [Guidance guidanceWithTitle:NSLocalizedString(key, nil) explanation:@""];
        
        error = [NSError zetaValidationErrorWithGuidance:guidance];
    }
    
    return error;
}

- (void)showGuidanceDot:(BOOL)show
{
    NameField *nameField = (NameField *)self.field;
    nameField.showGuidanceDot = show;
}


#pragma mark - Overrides

- (void)presentGuidance:(Guidance *)guidance
{
    if (guidance == nil) {
        return;
    }
    
    self.formGuidance.alpha = 0.0f;
    self.formGuidance.guidance = guidance;
    
    [self.controller.view layoutIfNeeded];
    
    [UIView animateWithDuration:0.5f animations:^{
        self.formGuidance.alpha = 1.0f;
    }];
}

- (void)dismissGuidance
{
    self.formGuidance.guidance = nil;
    [self.controller.view layoutIfNeeded];
    
    [UIView animateWithDuration:0.3f animations:^{
        self.formGuidance.alpha = 0.0f;
    } completion:nil];
}

@end
