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


#import "UserImageView.h"

/**
 * @class ContrastUserImageView is designed to display user avatar on the background of the same color as user's accent
 * color. By default if user got no picture then we display the initials on background of solid accent color. When
 * the background of parent is already of accent color we see no UserImageView border.
 * The solution is to display @c UserImageView with white background and initials in accent color.
 */
@interface ContrastUserImageView : UserImageView

@end
