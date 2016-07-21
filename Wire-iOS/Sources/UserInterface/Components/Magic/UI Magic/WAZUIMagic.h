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


#import <Foundation/Foundation.h>


@protocol WAZUIMagicObserver;



@protocol WAZUIMagicDelegate <NSObject>

@optional
- (UIColor *)accentColor;

@end



@interface WAZUIMagic : NSObject

+ (void)addUIMagicObserver:(id <WAZUIMagicObserver>)observer;
+ (void)removeUIMagicObserver:(id <WAZUIMagicObserver>)observer;

@property (weak, nonatomic) id <WAZUIMagicDelegate> delegate;

/// All magic items (configuration files) that are currently the active configuration.
@property (strong, nonatomic, readonly) NSArray *activeMagicItemNames;

/// Preload configuration from the given files, parsing them into an in-memory representation so that their subsequent activation is fast. Does not actually activate any configuration. This is an expensive operation that should be done only once, e.g at application startup.
+ (void)preloadItems:(NSArray *)items;

/// Activate one or more configuration items. This must be a subset of the items that have been previously loaded with preload. Notification to observers is sent after activation.
+ (void)activateItems:(NSArray *)items;

/// Shared instance. Public use is deprecated, except for setting the delegate atm.
+ (WAZUIMagic *)sharedMagic;

- (id)objectForKeyedSubscript:(id)key;
- (id)valueForKeyPath:(NSString *)keyPath;
- (void)reloadFromDisk;
@end


@interface WAZUIMagic (PrivateMethods)

+ (UIColor *)accentColor;

@end



@interface WAZUIMagic (DirectValueAccess)

+ (CGRect)cgRectForIdentifier:(NSString *)identifier;
+ (float)floatForIdentifier:(NSString *)identifier;
+ (double)doubleForIdentifier:(NSString *)identifier;
+ (CGFloat)cgFloatForIdentifier:(NSString *)identifier;
+ (NSUInteger)unsignedIntegerForIdentifier:(NSString *)identifier;
+ (BOOL)boolForIdentifier:(NSString *)identifier;
+ (NSNumber *)numberForIdentifier:(NSString *)identifier;
+ (NSString *)stringForIdentifier:(NSString *)identifier;


@end



@interface WAZUIMagic (iOS)

+ (UIEdgeInsets)edgeInsetsForIdentified:(NSString *)identifier;

@end



@protocol WAZUIMagicObserver <NSObject>

/** The notification object will be the uiMagic instance. Notification is sent every time that new configuration takes effect. */
- (void)UIMagicDidActivate:(NSNotification *)note;

@end



@interface NSNotification (WAZUIMagicObserver)

@property (readonly, nonatomic, strong) WAZUIMagic *uiMagic;

@end
