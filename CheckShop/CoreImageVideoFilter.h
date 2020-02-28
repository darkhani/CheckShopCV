//
//  CoreImageVideoFilter.h
//  Hanpass
//
//  Created by INTAEK HAN on 2018. 5. 2..
//  Copyright © 2018년 hanpass. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreImage/CoreImage.h>
#import <CoreMedia/CoreMedia.h>
#import <QuartzCore/QuartzCore.h>
#import <GLKit/GLKit.h>

@interface CoreImageVideoFilter : NSObject<AVCaptureVideoDataOutputSampleBufferDelegate,AVCapturePhotoCaptureDelegate>{
    
}

typedef CIImage *(^FilterBlock)(CIImage *cim);
@property (nonatomic) FilterBlock applyFilter;
//(void (^)(UIImage *))completionHandler
///@property (nonatomic, copy, nullability) returnType (^blockName)(parameterTypes);
@property GLKView *videoDisplayView;
@property CGRect videoDisplayViewBounds;
@property CIContext *renderContext;
@property AVCaptureSession *avSession;
@property dispatch_queue_t sessionQueue;
@property CIDetector *detector;
@property BOOL isLandScape;


@property AVCaptureVideoOrientation newOrientation;

- (id) initWithView:(UIView*)superView callBack:(CIImage* (^)(CIImage*))callback;
- (void) startFiltering;
- (void) stopFiltering;
@end
