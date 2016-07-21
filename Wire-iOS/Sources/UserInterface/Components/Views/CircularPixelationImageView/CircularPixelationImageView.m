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


#import "CircularPixelationImageView.h"

#import "CircularPixelationImageViewBuilder.h"
#import "Analytics+iOS.h"

#import <OpenGLES/ES1/glext.h>



@interface CircularPixelationImageView ()

@property (nonatomic) CGFloat fractionalWidthOfPixel;

@end



@implementation CircularPixelationImageView
{
    GLKMatrix4 _modelViewProjectionMatrix;
}

- (id)initWithFrame:(CGRect)aRect
{
    self = [super initWithFrame:aRect];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    [self setup];
}

- (void)setup;
{
    [CircularPixelationImageViewBuilder configureView:self];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
}

- (void)setNeedsDisplay
{
    [super setNeedsDisplay];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self.builder deleteTexture:self.textureInfo];
}

- (void)applicationDidEnterBackground:(NSNotification *)note;
{
    [self deleteDrawable];
}

- (void)setImage:(UIImage *)image
{
    if (image == _image) {
        return;
    }
    _image = image;

    if (image == nil) {
        self.textureInfo = nil;
        [self deleteDrawable];
    } else {
        [self createTextureFromImage:self.image];
    }
}

- (void)createTextureFromImage:(UIImage *)image
{
    __weak CircularPixelationImageView *weakSelf = self;
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        // Draw the image to make sure we don't run into decoding issues.
        // As a nice side effect, this will also embed any rotation.
        UIGraphicsBeginImageContextWithOptions(image.size, NO, image.scale);
        [image drawInRect:(CGRect) {CGPointZero, image.size} blendMode:kCGBlendModeCopy alpha:1];
        UIImage *image2 = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();

        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf.builder textureWithImage:image2 completionHandler:^(GLKTextureInfo *textureInfo, NSError *error) {
                if (error != nil) {
                    [[Analytics shared] tagApplicationError:error.localizedDescription
                                              timeInSession:[[UIApplication sharedApplication] lastApplicationRunDuration]];
                }
                weakSelf.textureInfo = textureInfo;
            }];
        });
    });
}

- (void)setTextureInfo:(GLKTextureInfo *)textureInfo
{
    if (textureInfo == nil) {
        [self.builder deleteTexture:_textureInfo];
    }
    _textureInfo = textureInfo;
    [self setNeedsDisplay];
}

- (void)setBounds:(CGRect)bounds
{
    [super setBounds:bounds];
}

- (void)setPixelSize:(CGFloat)pixelSize
{
    if (_pixelSize == pixelSize) {
        return;
    }
    _pixelSize = pixelSize;
    [self setNeedsDisplay];
}

- (void)didMoveToWindow;
{
    [super didMoveToWindow];
    if (self.window == nil) {
        [self deleteDrawable];
    }
}

- (void)update
{
    if (self.textureInfo == nil) {
        return;
    }

    CGSize const viewSize = self.bounds.size;
    CGSize const textureSize = CGSizeMake(self.textureInfo.width, self.textureInfo.height);

    double const viewAspect = viewSize.width / viewSize.height;
    double const textureAspect = textureSize.width / textureSize.height;

    // Scale the texture to fill the view:
    GLKMatrix4 modelViewMatrix = ((textureAspect >= viewAspect) ?
            GLKMatrix4MakeScale(viewSize.width, viewSize.width / textureAspect, 1) :
            GLKMatrix4MakeScale(viewSize.height * textureAspect, viewSize.height, 1));
    // Map OpenGL coordinate space [-1 -> +1] to out view size:
    GLKMatrix4 projectionMatrix = GLKMatrix4MakeOrtho(- viewSize.width * 0.5, viewSize.width * 0.5, - viewSize.height * 0.5, viewSize.height * 0.5, 0, 1);
    _modelViewProjectionMatrix = GLKMatrix4Multiply(modelViewMatrix, projectionMatrix);

    double const effectiveWidth = ((textureAspect >= viewAspect) ? viewSize.width : viewSize.height * textureAspect);
    self.fractionalWidthOfPixel = self.pixelSize / effectiveWidth;
}

- (BOOL)isOpaque;
{
    return NO;
}

- (void)drawRect:(CGRect)rect
{
    [self update];
    [self clearBackground];
    [self drawImage];
}

- (void)clearBackground
{
    glClearColor(0, 0, 0, 0);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
}

- (void)drawImage;
{
    if (self.textureInfo == nil) {
        return;
    }
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, self.textureInfo.name);
    glUniform1i(self.textureImageUniform, 0);

    glBindVertexArrayOES(self.vertexArray);
    glUseProgram(self.program);

    // load uniforms
    glUniformMatrix4fv(self.modelViewProjectionMatrixUniform, 1, 0, _modelViewProjectionMatrix.m);
    double const aspectTexture = 1. * self.textureInfo.height / self.textureInfo.width;
    glUniform1f(self.textureAspectUniform, aspectTexture);
    glUniform1f(self.fractionalWidthOfPixelUniform, self.fractionalWidthOfPixel);

    // draw the two triangles
    glEnable(GL_BLEND); // Turn on blending
    glDrawArrays(GL_TRIANGLES, 0, 6);
    glDisable(GL_BLEND); // Turn off blending
}

@end
