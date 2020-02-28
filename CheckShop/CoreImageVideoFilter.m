//
//  CoreImageVideoFilter.m
//  Hanpass
//
//  Created by INTAEK HAN on 2018. 5. 2..
//  Copyright © 2018년 hanpass. All rights reserved.
//

#import "CoreImageVideoFilter.h"
#import <OpenGLES/EAGL.h>

@implementation CoreImageVideoFilter
@synthesize applyFilter,videoDisplayView,videoDisplayViewBounds,avSession,detector,renderContext,sessionQueue;
@synthesize isLandScape;

- (id) initWithView:(UIView *)superView callBack:(CIImage *(^)(CIImage *))callback {
    self = [super init];
    self.applyFilter = callback;
    CGRect frame = [[UIScreen mainScreen] bounds];
    
    self.videoDisplayView = [[GLKView alloc] initWithFrame:frame context:[[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2]];
    self.videoDisplayView.transform = CGAffineTransformMakeRotation(M_PI_2);
    self.videoDisplayView.frame = frame;//[superView bounds];
    [self.videoDisplayView setBackgroundColor:[UIColor clearColor]];
    [superView addSubview:self.videoDisplayView];
    [superView sendSubviewToBack:videoDisplayView];
    
    self.renderContext = [CIContext contextWithEAGLContext:self.videoDisplayView.context];
    self.sessionQueue = dispatch_queue_create("AVSessionQueue", DISPATCH_QUEUE_SERIAL);
    [videoDisplayView bindDrawable];
//    videoDisplayViewBounds = CGRectMake(0, 0, videoDisplayView.drawableHeight, videoDisplayView.drawableHeight);
    videoDisplayViewBounds = CGRectMake(0, 0, videoDisplayView.drawableWidth, videoDisplayView.drawableHeight); //origin
    
    return self;
}

- (void) startFiltering {
    if ( avSession == nil ){
        avSession = [self createAVSession];
    }
    [avSession startRunning];
}

- (void) stopFiltering {
    [avSession stopRunning];
}

- (AVCaptureSession*) createAVSession {
    NSError *error = nil;
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:device error:&error];

    //Capture Session
    AVCaptureSession *session = [[AVCaptureSession alloc]init];
    session.sessionPreset = AVCaptureSessionPresetPhoto;
    
//    NSLog(@">>>>>>>> formats : %@",device.formats);
//    for (AVCaptureDeviceFormat *format in device.formats) {
//        NSLog(@" format : [ %@ ] ",format);
//    }
    //output
    
    AVCaptureVideoDataOutput *videoOutput = [[AVCaptureVideoDataOutput alloc] init];
    videoOutput.videoSettings = [[NSDictionary alloc] initWithObjectsAndKeys:[[NSNumber alloc] initWithInt:kCVPixelFormatType_32BGRA],kCVPixelBufferPixelFormatTypeKey, nil];
    [videoOutput setSampleBufferDelegate:self queue:self.sessionQueue];
    if (input != nil) {
        [session addInput:input];
    }
    
    if (videoOutput != nil) {
        [session addOutput:videoOutput];
    }
    
    return session;
}

-(void)captureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    
    CMSampleBufferRef *imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    CIImage *sourceImage = [[CIImage alloc] initWithCVPixelBuffer:imageBuffer options:nil];
    CIImage *detectionResult = applyFilter(sourceImage); // == Output Image
    [self.videoDisplayView bindDrawable];
    if ([videoDisplayView context] != [EAGLContext currentContext]) {
        [EAGLContext setCurrentContext:self.videoDisplayView.context];
    }
    
    CGRect drawFrame = [detectionResult extent];
//    drawFrame = CGRectMake(drawFrame.origin.x, drawFrame.origin.y, drawFrame.size.width, drawFrame.size.height);
    CGRect fillDrawFrame = [self aspectFill:drawFrame toRect:videoDisplayViewBounds];
    glClearColor(0.1, 0.1, 0.1, 1.0); // clear eagl view to grey
    glClear(0x00004000);
    glEnable(0x0BE2); // set the blend mode to "source over" so that CI will use that
    glBlendFunc(1, 0x0303);
    [renderContext drawImage:detectionResult inRect:fillDrawFrame fromRect:drawFrame];
    [videoDisplayView display];
}

- (CGRect) aspectFill:(CGRect)fromRect toRect:(CGRect)toRect {
    CGRect retFrame = toRect;
    CGFloat fromAspectRatio = fromRect.size.width / fromRect.size.height;
    CGFloat toAspectRatio = toRect.size.width / toRect.size.height;
    
    if (fromAspectRatio > toAspectRatio) {
        retFrame.size.width = toRect.size.height * fromAspectRatio;
        retFrame.origin.x += (toRect.size.width - retFrame.size.width) * 0.5;
    } else {
        retFrame.size.height = toRect.size.width / fromAspectRatio;
        retFrame.origin.y += (toRect.size.height - retFrame.size.height) * 0.5;
    }
    return CGRectIntegral(retFrame);
}

@end
