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


#import <GLKit/GLKit.h>

@class OVSViewController;
@class CircularPixelationImageViewBuilder;



@interface CircularPixelationImageView : GLKView

@property (nonatomic, strong) UIImage *image;
@property (nonatomic) CGFloat pixelSize;

@property (nonatomic, strong) CircularPixelationImageViewBuilder *builder;
@property (strong, nonatomic) GLKTextureInfo *textureInfo;
@property (nonatomic) GLuint vertexArray;
@property (nonatomic) GLuint program;
@property (nonatomic) GLuint modelViewProjectionMatrixUniform;
@property (nonatomic) GLuint textureImageUniform;
@property (nonatomic) GLuint textureAspectUniform;
@property (nonatomic) GLuint fractionalWidthOfPixelUniform;

@end
