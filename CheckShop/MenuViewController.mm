//
//  MenuViewController.m
//  CheckShop
//
//  Created by INTAEK HAN on 2020/02/27.
//  Copyright © 2020 INTAEK HAN. All rights reserved.
//

#import "MenuViewController.h"
#import "HPCameraViewController.h"
#import "ViewController.h"

#import <opencv2/imgproc/types_c.h>
#import <opencv2/imgproc/imgproc_c.h>
#import <opencv2/imgproc.hpp>
#import <opencv2/core.hpp>
#import <opencv2/imgcodecs.hpp>
//#include "opencv2/core/opencv.hpp"
//#import <opencv2/core/core.hpp>
#include "opencv2/core/core_c.h"

#import "UIScreen+Utils.h"

#import <TesseractOCR/TesseractOCR.h>

using namespace cv;
using namespace std;

@interface MenuViewController ()<HPCameraViewControllerDelegate>{
    
    __weak IBOutlet UIImageView *resultImage;
    __weak IBOutlet UIButton *showResultButton;
    __weak IBOutlet UITextView *showRecogTextView;
    NSOperationQueue *operationQueue;
    UIImage *imgP;
    NSString *captureName;
    
    __weak IBOutlet UIActivityIndicatorView *indi;
}
@end

@implementation MenuViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [indi setHidden:YES];
    // Do any additional setup after loading the view.
}

- (IBAction)touchCameraButton:(id)sender {
    dispatch_async(dispatch_get_main_queue(), ^{
        if( [UIImagePickerController isCameraDeviceAvailable:UIImagePickerControllerCameraDeviceRear] == YES)
        {
            //신분증 새 뷰 올리는 부분
            HPCameraViewController *vc = [[HPCameraViewController alloc] initWithNibName:@"HPCameraViewController" bundle:nil];
            vc.modeIndex = 0;
            [vc setModalPresentationStyle:UIModalPresentationFullScreen];
            [vc setDelegate:self];
            [self presentViewController:vc animated:NO completion:nil];
        }
    });
    
    
}

- (void)didFinishSaveFile:(UIViewController *)vc result:(UIImage *)image {
    imgP = [image copy];
    dispatch_async(dispatch_get_main_queue(), ^{
        [vc dismissViewControllerAnimated:YES completion:nil];
        [self->showResultButton setHidden:NO];
        
        UIImage *photoImage = [[UIImage alloc] init];
        photoImage = image;
        NSLog(@"width : %f, height : %f",photoImage.size.width,photoImage.size.height);
        
        CGSize smallSize = CGSizeMake(photoImage.size.width, photoImage.size.height);
        if (photoImage.size.width > 0 && photoImage.size.height > 0) {
            UIGraphicsBeginImageContextWithOptions(smallSize, NO, 0.0);
            [photoImage drawInRect:CGRectMake(0, 0, smallSize.width, smallSize.height)];
            UIImage *orgImage = UIGraphicsGetImageFromCurrentImageContext();
            UIImage *newImage = orgImage;//rotate(orgImage, UIImageOrientationRight);
            UIGraphicsEndImageContext();
            photoImage = newImage;
            if (photoImage != nil) {
                
                //TODO!!! : 2배? 3배 구분 할것. 기기별로 나뉘게 됨.
                NSInteger zoomRatio = [UIScreen ratioWidth];
                
                //꼭지점 Magic Number 구하기
                NSInteger leftUpX = 0;
                NSInteger leftUpY = 0;
                NSInteger leftDownX = 0;
                NSInteger rightUpY = 0;
                
                //원래 로직
                //                if (zoomRatio == 3) {
                //                    leftUpX = 52;
                //                    leftUpY = 39;
                //                    leftDownX = 22;
                //                    rightUpY = 44;
                //                } else if(zoomRatio == 2) {
                //                    leftUpX = 32;
                //                    leftUpY = 25;
                //                    leftDownX = 32;
                //                    rightUpY = 15;
                //                }
                //테스트 로직
                if (zoomRatio == 3) {
                    leftUpX = 5;
                    leftUpY = 5;
                    leftDownX = 5;
                    rightUpY = 5;
                } else if(zoomRatio == 2) {
                    leftUpX = 2;
                    leftUpY = 2;
                    leftDownX = 2;
                    rightUpY = 2;
                }
                
                //이미지 사이즈를 구한다.
                CGFloat width = photoImage.size.width;
                CGFloat height = photoImage.size.height;
                
                NSInteger wInt = (NSInteger) (floor(width));
                NSInteger hInt = (NSInteger) (floor(height));
                //                NSLog(@"width : %d * height : %d",wInt,hInt);
                
                NSString *fileName = [NSString stringWithFormat:@"edgedimage-%ld-%ld-%ld-%ld-%ld-%ld-%ld-%ld.jpg",leftUpX,leftUpY,leftDownX,hInt*zoomRatio ,wInt*zoomRatio,rightUpY,wInt*zoomRatio,hInt*zoomRatio];
                self->captureName = fileName;
                NSString *returnFileName = [NSString stringWithFormat:@"return_edgedimage-%ld-%ld-%ld-%ld-%ld-%ld-%ld-%ld.jpg",leftUpX,leftUpY,leftDownX,hInt*zoomRatio,wInt*zoomRatio,rightUpY,wInt*zoomRatio,hInt*zoomRatio];
                
                NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
                NSString *documentsDirectory = [paths objectAtIndex:0];
                NSString *filePath1 = [documentsDirectory stringByAppendingString:[NSString stringWithFormat:@"/%@",fileName]];
                NSString *filePath2 = [documentsDirectory stringByAppendingString:[NSString stringWithFormat:@"/%@",returnFileName]];
                
                //로컬 저장
                [UIImageJPEGRepresentation(photoImage,1.0) writeToFile:filePath1 atomically:YES];
//                [UIImageJPEGRepresentation(photoImage,1.0) writeToFile:filePath2 atomically:YES];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self->indi setHidden:NO];
                    [self->indi startAnimating];
                    [self->showRecogTextView setText:@"텍스트 추출을 시작합니다."];
                });
                //텍스트 추출을 시도한다.
                [self recognizeImageWithTesseract2:photoImage];
                
                
                [self->resultImage setImage:image];
            }
        }
    });
    
//    [self recognizeImageWithTesseract2:image];
    
}

- (cv::Mat)cvMatFromUIImage2:(UIImage *)image
{
  CGColorSpaceRef colorSpace = CGImageGetColorSpace(image.CGImage);
  CGFloat cols = image.size.width;
  CGFloat rows = image.size.height;

  Mat cvMat(rows, cols, CV_8UC4); // 8 bits per component, 4 channels (color channels + alpha)

  CGContextRef contextRef = CGBitmapContextCreate(cvMat.data,                 // Pointer to  data
                                                 cols,                       // Width of bitmap
                                                 rows,                       // Height of bitmap
                                                 8,                          // Bits per component
                                                 cvMat.step[0],              // Bytes per row
                                                 colorSpace,                 // Colorspace
                                                 kCGImageAlphaNoneSkipLast |
                                                 kCGBitmapByteOrderDefault); // Bitmap info flags

  CGContextDrawImage(contextRef, CGRectMake(0, 0, cols, rows), image.CGImage);
  CGContextRelease(contextRef);

  return cvMat;
}

-(UIImage *)UIImageFromCVMat:(cv::Mat)cvMat
{
  NSData *data = [NSData dataWithBytes:cvMat.data length:cvMat.elemSize()*cvMat.total()];
  CGColorSpaceRef colorSpace;

  if (cvMat.elemSize() == 1) {
      colorSpace = CGColorSpaceCreateDeviceGray();
  } else {
      colorSpace = CGColorSpaceCreateDeviceRGB();
  }

  CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);

  // Creating CGImage from cv::Mat
  CGImageRef imageRef = CGImageCreate(cvMat.cols,                                 //width
                                     cvMat.rows,                                 //height
                                     8,                                          //bits per component
                                     8 * cvMat.elemSize(),                       //bits per pixel
                                     cvMat.step[0],                            //bytesPerRow
                                     colorSpace,                                 //colorspace
                                     kCGImageAlphaNone|kCGBitmapByteOrderDefault,// bitmap info
                                     provider,                                   //CGDataProviderRef
                                     NULL,                                       //decode
                                     false,                                      //should interpolate
                                     kCGRenderingIntentDefault                   //intent
                                     );


  // Getting UIImage from CGImage
  UIImage *finalImage = [UIImage imageWithCGImage:imageRef];
  CGImageRelease(imageRef);
  CGDataProviderRelease(provider);
  CGColorSpaceRelease(colorSpace);

  return finalImage;
 }

-(NSString*)fullPathWithName:(NSString *)name {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    return [documentsDirectory stringByAppendingString:[NSString stringWithFormat:@"/%@",name]];
}
- (IBAction)touchShowResultButton:(id)sender {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    ViewController * mainVC = [storyboard   instantiateViewControllerWithIdentifier:@"MainVC"] ;
    if (resultImage != nil) {
        
        NSString *filePath1 = [self fullPathWithName:captureName];
        NSData *imgData = [[NSData alloc] initWithContentsOfFile:filePath1];
        UIImage *img = [UIImage imageWithData:imgData];
        [mainVC setPImage:img];
        
    }
    [self presentViewController:mainVC animated:YES completion:nil];
}

- (IBAction)touchPhotoButton:(id)sender {
    [self recognizeImageWithTesseract2:imgP];
}

- (void) recognizeImageWithTesseract2:(UIImage*) image {
    NSLog(@"tess ver. %@",[G8Tesseract version]);
    
    //파일에서 읽어와 보기
    
    NSString *filePath1 = [self fullPathWithName:captureName];
    NSData *imgData = [[NSData alloc] initWithContentsOfFile:filePath1];
    UIImage *img = [UIImage imageWithData:imgData];
    
    
    UIImage *sampleImage = image;
    Mat inputMat = [self cvMatFromUIImage2:img];
//            UIImage *srcImage = [self UIImageFromCVMat:inputMat];
    
    //Gray로
    Mat grayMat;
    cvtColor(inputMat, grayMat, CV_RGB2GRAY);
    UIImage *convertGray = [self UIImageFromCVMat:grayMat];
    
    Mat cannyMat;
    Canny(grayMat, cannyMat, 80, 180);
    UIImage *cannytGray = [self UIImageFromCVMat:cannyMat];
     
    BOOL isSetCanny = NO;
    
    if (convertGray != nil && cannytGray != nil) {
//    if (cannytGray != nil) {
        dispatch_async(dispatch_get_main_queue(),^{
            if (isSetCanny == NO) {
                [self->resultImage setImage:convertGray];
            } else {
                [self->resultImage setImage:cannytGray];
            }
        });
        G8RecognitionOperation *operation = [[G8RecognitionOperation alloc] initWithLanguage:@"eng+kor"];
        if (operation == nil) {
            return;
        }
        
        [operation.tesseract setDelegate:self];
        [operation.tesseract setEngineMode:G8OCREngineModeTesseractOnly];
        [operation.tesseract setPageSegmentationMode:G8PageSegmentationModeAutoOnly];
        if (isSetCanny == NO) {
            [operation.tesseract setImage:convertGray];
        } else {
            [operation.tesseract setImage:cannytGray];
        }

        
        [operation setRecognitionCompleteBlock:^(G8Tesseract * _Nullable tesseract) {
            NSString *recogString = [tesseract recognizedText];
            //NSLog(@"text : %@",recogString);
            if (recogString != nil && [recogString isEqualToString:@""] == NO) {
                [self->showRecogTextView setText:recogString];
                NSLog(@"text : %@",recogString);
                 dispatch_async(dispatch_get_main_queue(), ^{
                                [self->indi stopAnimating];
                //                [self->indi setHidden:YES];
                            });
            } else {
                [self->showRecogTextView setText:@"텍스트 추출 실패"];
                 dispatch_async(dispatch_get_main_queue(), ^{
                                [self->indi stopAnimating];
                //                [self->indi setHidden:YES];
                            });
            }
        }];
        if (operationQueue == nil) {
            operationQueue = [[NSOperationQueue alloc] init];
        }
        [operationQueue addOperation:operation];
        
    }
}

@end
