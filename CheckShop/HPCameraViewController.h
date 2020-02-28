//
//  HPCameraViewController.h
//  Hanpass
//
//  Created by INTAEK HAN on 2018. 5. 3..
//  Copyright © 2018년 hanpass. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CoreImageVideoFilter.h"

#import <MobileCoreServices/MobileCoreServices.h>
#import <CoreImage/CoreImage.h>
#import <AVFoundation/AVFoundation.h>

@protocol  HPCameraViewControllerDelegate
- (void)didFinishSaveFile:(UIViewController*)vc result:(UIImage*)image;
@end

@interface HPCameraViewController : UIViewController

@property CIDetector *detector;
@property CoreImageVideoFilter *videoFilter;
@property id<HPCameraViewControllerDelegate> delegate;

@property AVCaptureVideoPreviewLayer *previewLayer;
@property AVCaptureSession *captureSession;
@property AVCaptureDeviceInput *videoInputDevice;

@property NSInteger modeIndex; //3 = Passport, 4 = BankBook
@end
