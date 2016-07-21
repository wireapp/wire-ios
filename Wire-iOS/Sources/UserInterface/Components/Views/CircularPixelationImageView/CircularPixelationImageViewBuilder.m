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


#import "CircularPixelationImageViewBuilder.h"

#import "WAZUIMagic.h"

#import "CircularPixelationImageView.h"
#import "Analytics+iOS.h"

#import <GLKit/GLKit.h>
#import <OpenGLES/ES1/glext.h>
#import <libkern/OSAtomic.h>



// buffer offset for glVertexAttribPointer()
static GLvoid const *BUFFER_OFFSET(int const i)
{
    return (GLvoid const *) ((char *) NULL + i);
}

// uniform indices for glGetUniformLocation()
enum
{
    UNIFORM_MODELVIEWPROJECTION_MATRIX,
    UNIFORM_TEXTURE_IMAGE,
    UNIFORM_TEXTURE_ASPECT,
    UNIFORM_FRACTIONAL_WIDTH_OF_PIXEL,
    NUM_UNIFORMS
};


// vertex positions and vertex texture coordinates
static GLfloat const rectangleVertexData[30] =
        {
                // x, y, z,  tex_x, tex_y,

                0.5f, 0.5f, 0.0f, 1.0f, 0.0f,
                - 0.5f, 0.5f, 0.0f, 0.0f, 0.0f, // origin of texture is top-left
                0.5f, - 0.5f, 0.0f, 1.0f, 1.0f,
                0.5f, - 0.5f, 0.0f, 1.0f, 1.0f,
                - 0.5f, 0.5f, 0.0f, 0.0f, 0.0f,
                - 0.5f, - 0.5f, 0.0f, 0.0f, 1.0f, // y is downwards
        };



@interface CircularPixelationImageViewBuilder ()
{
    GLuint _program;
    GLuint _vertexArray;
    GLuint _vertexBuffer;
    GLint _uniforms[NUM_UNIFORMS];
}

@property (strong, nonatomic) EAGLContext *context;
@property (strong, nonatomic) GLKTextureInfo *textureInfo;
@property (strong, nonatomic) GLKTextureLoader *textureLoader;

@end



@implementation CircularPixelationImageViewBuilder

+ (void)configureView:(CircularPixelationImageView *)view;
{
    [[self sharedInstance] configureView:view];
}

+ (instancetype)sharedInstance;
{
    CircularPixelationImageViewBuilder *result = nil;

    static OSSpinLock lock = OS_SPINLOCK_INIT;
    OSSpinLockLock(&lock);
    {
        static CircularPixelationImageViewBuilder *sharedBuilder;
        result = sharedBuilder;
        if (result == nil) {
            result = [[self alloc] init];
            sharedBuilder = result;
        }
    }
    OSSpinLockUnlock(&lock);

    return result;
}

- (void)configureView:(CircularPixelationImageView *)view;
{
    // Strongly retain the builder:
    view.builder = self;

    view.drawableColorFormat = GLKViewDrawableColorFormatRGBA8888;
    view.drawableDepthFormat = GLKViewDrawableDepthFormat24;
    view.drawableStencilFormat = GLKViewDrawableStencilFormat8;
    view.drawableMultisample = GLKViewDrawableMultisampleNone;

    static CGFloat previewPixelSize;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        previewPixelSize = [WAZUIMagic cgFloatForIdentifier:@"content.image_preview_circular_pixel_radius"];
    });

    view.pixelSize = previewPixelSize;
    view.layer.needsDisplayOnBoundsChange = YES;
    view.layer.opaque = NO;
    view.context = self.context;
    view.textureInfo = self.textureInfo;
    view.enableSetNeedsDisplay = YES;
    view.vertexArray = _vertexArray;
    view.program = _program;
    view.modelViewProjectionMatrixUniform = _uniforms[UNIFORM_MODELVIEWPROJECTION_MATRIX];
    view.textureImageUniform = _uniforms[UNIFORM_TEXTURE_IMAGE];
    view.textureAspectUniform = _uniforms[UNIFORM_TEXTURE_ASPECT];
    view.fractionalWidthOfPixelUniform = _uniforms[UNIFORM_FRACTIONAL_WIDTH_OF_PIXEL];
}

- (id)init
{
    self = [super init];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)dealloc
{
    [self tearDownGL];
}

- (void)setup
{
    // set graphics context
    self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES3];
    if (self.context == nil) {
        self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    }
    NSAssert(self.context != nil, @"EAGL context is nil");

    self.textureLoader = [[GLKTextureLoader alloc] initWithSharegroup:self.context.sharegroup];
    NSAssert(self.textureLoader != nil, @"texture loader is nil!");

    // set up OpenGL
    [self setUpGL];
}

- (void)setUpGL
{
    [EAGLContext setCurrentContext:self.context];

    [self loadShaders];

    // load and bind vertex data
    glGenVertexArraysOES(1, &_vertexArray);
    glBindVertexArrayOES(_vertexArray);
    glGenBuffers(1, &_vertexBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(rectangleVertexData), rectangleVertexData, GL_STATIC_DRAW);

    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, 20, BUFFER_OFFSET(0));
    glEnableVertexAttribArray(GLKVertexAttribTexCoord0);
    glVertexAttribPointer(GLKVertexAttribTexCoord0, 2, GL_FLOAT, GL_FALSE, 20, BUFFER_OFFSET(12));

    glBindVertexArrayOES(0);

    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
}

- (void)withContextPerformBlock:(dispatch_block_t)block
{
    EAGLContext *old = [EAGLContext currentContext];
    [EAGLContext setCurrentContext:self.context];
    block();
    [EAGLContext setCurrentContext:old];
}

- (void)textureWithImage:(UIImage *)image completionHandler:(GLKTextureLoaderCallback)block;
{
    CGImageRef cgImage = CGImageRetain(image.CGImage);
    [self.textureLoader textureWithCGImage:cgImage options:nil queue:NULL completionHandler:^(GLKTextureInfo *textureInfo, NSError *error) {
        if (error != nil) {
            [[Analytics shared] tagApplicationError:error.localizedDescription
                                      timeInSession:[[UIApplication sharedApplication] lastApplicationRunDuration]];
        }
        block(textureInfo, error);
        CGImageRelease(cgImage);
    }];
}

- (void)deleteTexture:(GLKTextureInfo *)textureInfo;
{
    if (textureInfo == nil) {
        return;
    }
    [self withContextPerformBlock:^{
        glDeleteTextures(1, (GLuint const[]) {textureInfo.name});
    }];
}

- (void)tearDownGL
{
    [self withContextPerformBlock:^{
        glDeleteBuffers(1, &_vertexBuffer);
        glDeleteVertexArraysOES(1, &_vertexArray);

        if (_program) {
            glDeleteProgram(_program);
            _program = 0;
        }
    }];
}

- (void)loadShaders
{
    _program = glCreateProgram();

    // create and compile vertex shader.
    NSURL *vertShaderURL = [[NSBundle mainBundle] URLForResource:@"CircularPixelation" withExtension:@"vsh"];
    GLuint vertShader = 0;
    BOOL shaderCreatedVert = [self createAndCompileShader:&vertShader type:GL_VERTEX_SHADER fileURL:vertShaderURL];
    NSAssert(shaderCreatedVert,
                    @"Failed to compile vertex shader");

    // create and compile fragment shader.
    NSURL *fragShaderURL = [[NSBundle mainBundle] URLForResource:@"CircularPixelation" withExtension:@"fsh"];
    GLuint fragShader = 0;
    BOOL shaderCreatedFrag = [self createAndCompileShader:&fragShader type:GL_FRAGMENT_SHADER fileURL:fragShaderURL];
    NSAssert(shaderCreatedFrag,
                    @"Failed to compile fragment shader");

    // attach vertex & fragment shader to program.
    glAttachShader(_program, vertShader);
    glAttachShader(_program, fragShader);

    // bind attribute locations.
    glBindAttribLocation(_program, GLKVertexAttribPosition, "position");
    glBindAttribLocation(_program, GLKVertexAttribTexCoord0, "textureCoords");


    // link program.
    BOOL linkSucceded = [self linkProgram:_program];
    NSAssert(linkSucceded,
                    @"Failed to link program: %d", _program);

    // Get uniform locations
    _uniforms[UNIFORM_MODELVIEWPROJECTION_MATRIX] = glGetUniformLocation(_program, "modelViewProjectionMatrix");
    _uniforms[UNIFORM_TEXTURE_IMAGE] = glGetUniformLocation(_program, "textureImage");
    _uniforms[UNIFORM_TEXTURE_ASPECT] = glGetUniformLocation(_program, "textureAspect");
    _uniforms[UNIFORM_FRACTIONAL_WIDTH_OF_PIXEL] = glGetUniformLocation(_program, "fractionalWidthOfPixel");

    // release vertex and fragment shaders.
    if (vertShader) {
        glDetachShader(_program, vertShader);
        glDeleteShader(vertShader);
    }
    if (fragShader) {
        glDetachShader(_program, fragShader);
        glDeleteShader(fragShader);
    }
}

static void logShaderInfo(GLuint shader)
{
#if DEBUG
    // Check the status of the compile/link
    GLint logLen = 0;
    glGetShaderiv(shader, GL_INFO_LOG_LENGTH, &logLen);
    if (0 < logLen) {
        // Show any errors as appropriate
        GLchar *log = malloc(logLen + 1);
        log[logLen] = 0;
        glGetShaderInfoLog(shader, logLen, &logLen, log);
        free(log);
    }
#endif
}

- (BOOL)createAndCompileShader:(GLuint *)shader type:(GLenum)type source:(NSString *)source
{
    if (source.length == 0) {
        return NO;
    }
    *shader = glCreateShader(type);
    assert(*shader != 0);
    GLchar const *sourceCode = [source UTF8String];
    glShaderSource(*shader, 1, &sourceCode, NULL);
    glCompileShader(*shader);

    GLint status = 0;
    glGetShaderiv(*shader, GL_COMPILE_STATUS, &status);
    logShaderInfo(*shader);
    if (status == GL_FALSE) {
        glDeleteShader(*shader);
        return NO;
    }
    return YES;
}

- (BOOL)createAndCompileShader:(GLuint *)shader type:(GLenum)type fileURL:(NSURL *)fileURL
{
    NSString *source = [NSString stringWithContentsOfURL:fileURL encoding:NSUTF8StringEncoding error:NULL];
    return [self createAndCompileShader:shader type:type source:source];
}

static void logProgramInfo(GLuint program)
{
#ifdef DEBUG
    // Check the status of the compile/link
    GLint logLen = 0;
    glGetProgramiv(program, GL_INFO_LOG_LENGTH, &logLen);
    if (0 < logLen) {
        // Show any errors as appropriate
        GLchar *log = malloc(logLen + 1);
        log[logLen] = 0;
        glGetProgramInfoLog(program, logLen, &logLen, log);
        free(log);
    }
#endif
}

- (BOOL)linkProgram:(GLuint)prog
{
    GLint status;
    glLinkProgram(prog);
    logProgramInfo(prog);
    glGetProgramiv(prog, GL_LINK_STATUS, &status);
    if (status == 0) {
        return NO;
    }

    return YES;
}

- (BOOL)validateProgram:(GLuint)prog
{
    glValidateProgram(prog);
    GLint logLength = 0;
    glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *) malloc(logLength);
        glGetProgramInfoLog(prog, logLength, &logLength, log);
        NSLog(@"Program validate log:\n%s", log);
        free(log);
    }

    GLint status = 0;
    glGetProgramiv(prog, GL_VALIDATE_STATUS, &status);
    if (status == 0) {
        return NO;
    }

    return YES;
}

@end
