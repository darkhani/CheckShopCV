//
//  HPCameraViewController.m
//
//  Created by INTAEK HAN on 2018. 5. 3..
//  Copyright © 2018년 hanpass. All rights reserved.
//

#import "HPCameraViewController.h"

#import <MobileCoreServices/MobileCoreServices.h>
#import <CoreImage/CoreImage.h>
#import <AVFoundation/AVFoundation.h>

//#import <Vision/Vision.h>

#import "UIScreen+Utils.h"
#import "UIImage+ColorData.h"
#import "Constants.h"
#import <MetalPerformanceShaders/MetalPerformanceShaders.h>

// 신분증 Size로 촬영하는 (Edge 따서 딱 신분증만..) 모드 구현 - Smart 개념 구현

// 2020-01-30 디자인 작업시 추가분
// 신분증 = 0, 여권 = 1, 통장 모드 = 2로 설정하자
@interface HPCameraViewController (){
    CIImage *resultImageSelf;
    __weak IBOutlet UIImageView *idCardImageView;
    __weak IBOutlet UIView *preview;
    __weak IBOutlet UIView *guideImageView;
    __weak IBOutlet UIView *landscapeGuideView;
    __weak IBOutlet UILabel *toLandscapeLabel;
    __weak IBOutlet UILabel *pleaseSetLabel;
    
    
    //IF
    BOOL isBtnNationalIdOn;
    BOOL isBtnArcOn;
    BOOL isBtnPassportOn;
    BOOL isBtnDriverIdOn;
    
//    CGFloat boxAlpha;
//    BOOL isPlusMode;
    BOOL isLandscapeNow;
    
    //crop area
    CGFloat boxArea; //녹색영역 : 480,000 ~ 650,000 1차 성공 Zone으로 간주한다. 2020-02-02 한인택
    NSInteger magicPoint; // 로그상으로 1초당 8~12회 정도 탄다. 음 max 30회로 보자. 3초후 찰칵. 잠깐이라도 Green영역 벗어나면 0으로 초기화
    NSInteger getImageCount; // 1개만 던지자.
    
    BOOL nowGreenMode;
    
    __weak IBOutlet UIImageView *btnNationalId;
    __weak IBOutlet UIImageView *btnArcard;
    __weak IBOutlet UIImageView *btnPassport;
    __weak IBOutlet UIImageView *btnDriverLic;
    
    dispatch_semaphore_t semaphore;
    
    //LandScape모드일때..
    __weak IBOutlet UIView *guideLeftLine;
    __weak IBOutlet UIView *guideRightLine;
    __weak IBOutlet UIView *guideUpLine;
    __weak IBOutlet UIView *guideBottomLine;
    
    __weak IBOutlet UIVisualEffectView *effectView;
    
    __weak IBOutlet UIView *guideView;
    
}

@property (nonatomic) AVCaptureSession *session;
@end

@implementation HPCameraViewController
@synthesize videoFilter, detector, modeIndex;

//MARK:- View Lifecycle Management
- (void)viewDidLoad {
    [super viewDidLoad];
    videoFilter = [[CoreImageVideoFilter alloc] initWithView:preview callBack:nil];
    nowGreenMode = NO;
    magicPoint = 0;
    getImageCount = 0;
    
    [self settingUI];
    
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(orientationChanged:)
                                                 name:UIDeviceOrientationDidChangeNotification
                                               object:nil];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    dispatch_async(dispatch_get_main_queue(), ^{
        self.detector = [self prepareRectangleDetector];
//        self.textDetector = [self prepareTextDetector]; //add
        [self.videoFilter setApplyFilter:^CIImage *(CIImage *cim) {
            return [self performRectangleDetection:cim];
        }];
        [self.videoFilter startFiltering];
        
        [self updateBlurViewHole];
    });
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    [self updateBlurViewHole];
}

- (void) updateBlurViewHole {
    UIView *maskView = [[UIView alloc] initWithFrame:effectView.bounds];
    maskView.clipsToBounds = YES;
    [maskView setBackgroundColor:[UIColor clearColor]];
    
    UIBezierPath *outerBezierPath = [UIBezierPath bezierPathWithRoundedRect:effectView.bounds cornerRadius:0];
    CGRect rect = CGRectMake(self.view.frame.size.width * 0.2, self.view.frame.size.height*0.2, self.view.frame.size.width*0.6, self.view.frame.size.height*0.6);
    UIBezierPath *innerBezierPath = [UIBezierPath bezierPathWithRoundedRect:rect cornerRadius:0];
    [outerBezierPath appendPath:innerBezierPath];
    outerBezierPath.usesEvenOddFillRule = YES;
    
    
    CAShapeLayer *sLayer = [[CAShapeLayer alloc] init];
    sLayer.fillRule = kCAFillRuleEvenOdd;
    sLayer.fillColor = [UIColor greenColor].CGColor;
    sLayer.path = outerBezierPath.CGPath;
    [maskView.layer addSublayer:sLayer];
                          
    [effectView setMaskView: maskView];
    
    //guideView의 center를 맞춰 본다.
    guideView.center = effectView.center;
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [self.videoFilter stopFiltering];
    magicPoint = -1;
}

-(BOOL)shouldAutorotate{
    return NO;
}

//MARK:- Custom Method Management

- (void) startTextDetection:(UIImage*)image {
    
}

/*
 NSString *hexStr1 = @"123ABC";
 NSString *hexStr2 = @"#123ABC";
 NSString *hexStr3 = @"0x123ABC";
 */
- (unsigned int)intFromHexString:(NSString *)hexStr
{
  unsigned int hexInt = 0;

  // Create scanner
  NSScanner *scanner = [NSScanner scannerWithString:hexStr];

  // Tell scanner to skip the # character
  [scanner setCharactersToBeSkipped:[NSCharacterSet characterSetWithCharactersInString:@"#"]];

  // Scan hex value
  [scanner scanHexInt:&hexInt];

  return hexInt;
}

- (UIColor *)uiColorWithHexString:(NSString *)hexStr alpha:(CGFloat)alpha
{
  // Convert hex string to an integer
  unsigned int hexint = [self intFromHexString:hexStr];

  // Create a color object, specifying alpha as well
  UIColor *color =
    [UIColor colorWithRed:((CGFloat) ((hexint & 0xFF0000) >> 16))/255
    green:((CGFloat) ((hexint & 0xFF00) >> 8))/255
    blue:((CGFloat) (hexint & 0xFF))/255
    alpha:alpha];

  return color;
}

- (NSMutableAttributedString *) toLandscapeMent {
    
    NSMutableAttributedString *mas = [[NSMutableAttributedString alloc] init];
    NSDictionary *valueAttribute;
    NSAttributedString *valueString1;
    NSAttributedString *valueString2;
    NSAttributedString *valueString3;
    NSAttributedString *valueString4;
    NSAttributedString *valueString5;
    
    UIColor *colorGray = [self uiColorWithHexString:@"#999999" alpha:1.0]; //[UIColor colorWithRed:153 green:153 blue:153 alpha:1.0]; //999999
    UIColor *colorOrange = [self uiColorWithHexString:@"#FF9D00" alpha:1.0]; //[UIColor colorWithRed:255 green:157 blue:0 alpha:1.0]; //ff9d00
    
    NSDictionary *valueAttribute1 = @{NSForegroundColorAttributeName:colorGray};
    valueString1 = [[NSAttributedString alloc] initWithString:@"화면을 "  attributes:valueAttribute1];
    [mas appendAttributedString:valueString1];
    
    NSDictionary *valueAttribute2 = @{NSForegroundColorAttributeName:colorOrange};
    valueString2 = [[NSAttributedString alloc] initWithString:@"가로" attributes:valueAttribute2];
    [mas appendAttributedString:valueString2];
    
    valueString3 = [[NSAttributedString alloc] initWithString:@"로 " attributes:valueAttribute1];
    [mas appendAttributedString:valueString3];
    
    valueString4 = [[NSAttributedString alloc] initWithString:@"회전" attributes:valueAttribute2];
    [mas appendAttributedString:valueString4];
    
    valueString5 = [[NSAttributedString alloc] initWithString:@"하여 주시기 바랍니다" attributes:valueAttribute1];
    [mas appendAttributedString:valueString5];
    
    return mas;
}

- (NSMutableAttributedString *) pleaseSetALineMent {
    
    NSMutableAttributedString *mas = [[NSMutableAttributedString alloc] init];
    NSDictionary *valueAttribute;
    NSAttributedString *valueString1;
    NSAttributedString *valueString2;
    NSAttributedString *valueString3;
    NSAttributedString *valueString4;
    
    UIColor *colorGray = [self uiColorWithHexString:@"#999999" alpha:1.0]; //[UIColor colorWithRed:153 green:153 blue:153 alpha:1.0]; //999999
    UIColor *colorOrange = [self uiColorWithHexString:@"#FF9D00" alpha:1.0]; //[UIColor colorWithRed:255 green:157 blue:0 alpha:1.0]; //ff9d00
    
    NSDictionary *valueAttribute1 = @{NSForegroundColorAttributeName:colorOrange};
    valueString1 = [[NSAttributedString alloc] initWithString:@"사각틀안"  attributes:valueAttribute1];
    [mas appendAttributedString:valueString1];
    
    NSDictionary *valueAttribute2 = @{NSForegroundColorAttributeName:colorGray};
    valueString2 = [[NSAttributedString alloc] initWithString:@"에 이미지를 " attributes:valueAttribute2];
    [mas appendAttributedString:valueString2];
    
    valueString3 = [[NSAttributedString alloc] initWithString:@"일치" attributes:valueAttribute1];
    [mas appendAttributedString:valueString3];
    
    valueString4 = [[NSAttributedString alloc] initWithString:@"시켜 주시기 바랍니다" attributes:valueAttribute2];
    [mas appendAttributedString:valueString4];
    
    return mas;
}


- (void) settingUI {
    
//    boxAlpha = 0.1;
//    isPlusMode = YES;
    isLandscapeNow = NO;
    [landscapeGuideView setHidden:YES];
    
    NSAttributedString *mas = [self toLandscapeMent];
    [self->toLandscapeLabel setAttributedText:mas];
    
    NSAttributedString *mas2 = [self pleaseSetALineMent];
    [self->pleaseSetLabel setAttributedText:mas2];
    
    
}
#pragma mark - Touch Event Method Management
- (IBAction)shootCameraButton:(id)sender {
    [self shootAndPassImage];
}

- (IBAction)touchBackButton:(id)sender {
    [self dismissViewControllerAnimated:NO completion:nil];
}


#pragma mark - CIDetector Management

-(CIDetector*) prepareRectangleDetector {
    NSDictionary *options = @{CIDetectorAccuracy: CIDetectorAccuracyHigh, CIDetectorAspectRatio: @(1.0)};
    return [CIDetector detectorOfType:CIDetectorTypeRectangle context:nil options:options];
}

- (CIImage*) performRectangleDetection:(CIImage*) image {
    
    CIImage *resultImage = nil;
    CIImage *cropImage = nil;
    
    CGPoint topLeft;
    CGPoint topRight;
    CGPoint bottomLeft;
    CGPoint bottomRight;
    
    NSInteger natiWidth = (int)[[UIScreen mainScreen] nativeBounds].size.width;
    NSInteger natiHeight = (int)[[UIScreen mainScreen] nativeBounds].size.height;
//    NSLog(@"native [ Width : %.2i, Hieght : %.2i ]",natiWidth,natiHeight);
    
//    if (isLandscapeNow == NO) {
//        switch ((int)[[UIScreen mainScreen] nativeBounds].size.height) {
//
//            case 1136: //tested
//                //            printf("iPhone 5 or 5S or 5C");
//                topLeft = CGPointMake(natiHeight * 0.15, 20);
//                topRight = CGPointMake(natiHeight * 0.43, 20);// x=590이 300이 되면 녹색 y축이 줄어든다. (사람이 볼때)
//                bottomLeft = CGPointMake(natiHeight * 0.15, 620);
//                bottomRight = CGPointMake(natiHeight * 0.43, 620);
//                break;
//            case 1334: //tested
//                //            printf("iPhone 6/6S/7/8");
//                topLeft = CGPointMake(natiHeight * 0.15, 25);
//                topRight = CGPointMake(natiHeight * 0.43, 25);
//                bottomLeft = CGPointMake(natiHeight * 0.15, 725);
//                bottomRight = CGPointMake(natiHeight * 0.43, 725);
//                break;
//            case 1920: //tested
//                //            printf("iPhone 6+/7+");
//                topLeft = CGPointMake(natiHeight * 0.15, 28);
//                topRight = CGPointMake(natiHeight * 0.43, 28);
//                bottomLeft = CGPointMake(natiHeight * 0.15, 1050);
//                bottomRight = CGPointMake(natiHeight * 0.43, 1050);
//                break;
//            case 2208:
//                //            printf("iPhone 6S+/8+"); //?? Plus 는 다 1920일듯. 2208 안탐. 테스트 필요.
//                topLeft = CGPointMake(natiHeight * 0.15, 20 * 1.4);
//                topRight = CGPointMake(natiHeight * 0.43, 20 * 1.4);
//                bottomLeft = CGPointMake(natiHeight * 0.15, 750 * 1.4);
//                bottomRight = CGPointMake(natiHeight * 0.43, 750 * 1.4);
//                break;
//            case 2436: //tested
//                //            printf("iPhone X");
//                topLeft = CGPointMake(natiHeight * 0.15, 28);
//                topRight = CGPointMake(natiHeight * 0.32, 28);
//                bottomLeft = CGPointMake(natiHeight * 0.15, 1100);
//                bottomRight = CGPointMake(natiHeight * 0.32, 1100);
//                break;
//            case 2688: //1242 * 2688
//                //            printf("iPhone XS MAX");
//                topLeft = CGPointMake(natiHeight * 0.15, 28);
//                topRight = CGPointMake(natiHeight * 0.32, 28);
//                bottomLeft = CGPointMake(natiHeight * 0.15, 1214);
//                bottomRight = CGPointMake(natiHeight * 0.32, 1214);
//                break;
//
//            default:
//                //            printf("unknown");
//                topLeft = CGPointMake(natiHeight * 0.15, 25);
//                topRight = CGPointMake(natiHeight * 0.43, 25);
//                bottomLeft = CGPointMake(natiHeight * 0.15, 725);
//                bottomRight = CGPointMake(natiHeight * 0.43, 725);
//                break;
//        }
//    } else {
//        switch ((int)[[UIScreen mainScreen] nativeBounds].size.height) {
//            case 1136: //tested
//                //Landscape
//                topLeft = CGPointMake(20, 20); //x : 0->30 then, 내가볼때 topRight가 왼쪽으로 이동한다. ------+<---+
//                topRight = CGPointMake(natiHeight * 0.7, 20);// x=590이 300이 되면 녹색 y축이 줄어든다. (사람이 볼때)
//                bottomLeft = CGPointMake(20, natiWidth - 20);
//                bottomRight = CGPointMake(natiHeight * 0.7, natiWidth - 20);
//                break;
//            case 1334: //tested
//                //Landscape "iPhone 6/6S/7/8"
//                topLeft = CGPointMake(20, 20);
//                topRight = CGPointMake(natiHeight * 0.7, 20);
//                bottomLeft = CGPointMake(20, natiWidth - 20);
//                bottomRight = CGPointMake(natiHeight * 0.7, natiWidth - 20);
//                break;
//            case 1920: //tested "iPhone 6+/7+"
//                //Landscape
//                topLeft = CGPointMake(20, 20); //x : 0->30 then, 내가볼때 topRight가 왼쪽으로 이동한다. ------+<---+
//                topRight = CGPointMake(natiHeight * 0.7, 20);// x=590이 300이 되면 녹색 y축이 줄어든다. (사람이 볼때)
//                bottomLeft = CGPointMake(20, natiWidth - 20);
//                bottomRight = CGPointMake(natiHeight * 0.7, natiWidth - 20);
//                break;
//            case 2436: //tested
//                //            printf("iPhone X");
//                topLeft = CGPointMake(20, 20);
//                topRight = CGPointMake(natiHeight * 0.57, 20);
//                bottomLeft = CGPointMake(20, natiWidth - 20);
//                bottomRight = CGPointMake(natiHeight * 0.57, natiWidth - 20);
//                break;
//            case 2688: //1242 * 2688
//                //            printf("iPhone XS MAX");
//                topLeft = CGPointMake(20, 20);
//                topRight = CGPointMake(natiHeight * 0.57, 20);
//                bottomLeft = CGPointMake(20, natiWidth - 20);
//                bottomRight = CGPointMake(natiHeight * 0.57, natiWidth - 20);
//                break;
//            default:
//                //Landscape
//                //            printf("unknown");
//                topLeft = CGPointMake(20, 20);
//                topRight = CGPointMake(natiHeight * 0.7, 20);
//                bottomLeft = CGPointMake(20, natiWidth - 20);
//                bottomRight = CGPointMake(natiHeight * 0.7, natiWidth - 20);
//                break;
//        }
//    }

    NSArray *rectangleFeatures = [detector featuresInImage:image];
    CIRectangleFeature *rectangleFeature;
    if (rectangleFeatures!= nil && rectangleFeatures.count > 0){
        rectangleFeature = rectangleFeatures[0];
         topLeft = rectangleFeature.topLeft;
         topRight = rectangleFeature.topRight;
         bottomRight = rectangleFeature.bottomRight;
         bottomLeft = rectangleFeature.bottomLeft;
        
         UIBezierPath *path = [UIBezierPath new];
        [path moveToPoint:topLeft];
        [path addLineToPoint:topRight];
        [path addLineToPoint:bottomRight];
        [path addLineToPoint:bottomLeft];
        [path addLineToPoint:topLeft];
        [path closePath];
        
        //@2x : iPhone6S, @3x : iPhone6+, iPhoneX 모두 값이 50만대 정도에서 동작 확인 했음. ~60만대 사이를 적정 너비로 볼까? 한다. 1차
        //2020-02-02 한인택
        
        CGRect pathBounds = CGPathGetBoundingBox(path.CGPath);
        boxArea = pathBounds.size.width * pathBounds.size.height;
//        NSLog(@" >>>>> Area with green path : %f",boxArea);
        
        NSInteger minLimitArea = 0;
        NSInteger maxLimitArea = 0;
        NSInteger widthRatio = [UIScreen ratioWidth];
        
        if (widthRatio == 3) {
            minLimitArea = MIN_LIMIT_AREA_3X;
            maxLimitArea = MAX_LIMIT_AREA_3X;
        } else {
            minLimitArea = MIN_LIMIT_AREA_2X;
            maxLimitArea = MAX_LIMIT_AREA_2X;
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (self->boxArea >= minLimitArea && boxArea <= maxLimitArea) {
                [self->guideLeftLine setBackgroundColor:[UIColor greenColor]];
                [self->guideRightLine setBackgroundColor:[UIColor greenColor]];
                [self->guideUpLine setBackgroundColor:[UIColor greenColor]];
                [self->guideBottomLine setBackgroundColor:[UIColor greenColor]];
            } else {
                [self->guideLeftLine setBackgroundColor:[UIColor redColor]];
                [self->guideRightLine setBackgroundColor:[UIColor redColor]];
                [self->guideUpLine setBackgroundColor:[UIColor redColor]];
                [self->guideBottomLine setBackgroundColor:[UIColor redColor]];
            }
        });
    }
    
    resultImage = [self drawHighlightOverlayForPoints:image topLeft:topLeft topRight:topRight bottomLeft:bottomLeft bottomRight:bottomRight];
    cropImage = [self cropWithPoints:image topLeft:topLeft topRight:topRight bottomLeft:bottomLeft bottomRight:bottomRight];
    cropImage = [cropImage imageByApplyingTransform:CGAffineTransformMakeScale(0.4, 0.4)];
    
    //Gray
//    cropImage = [self toNoir:cropImage];
    
    //remove noise
//    cropImage = [self toRemoveNoise:cropImage];
//    cropImage = [self grayscaleImage:cropImage];
    
        CIFilter *filter = [CIFilter filterWithName:@"CIUnsharpMask"];
        [filter setValue:cropImage forKey:kCIInputImageKey];
        [filter setValue:@2.0 forKey:@"inputIntensity"];
        [filter setValue:@1.0 forKey:@"inputRadius"];
    
    CIFilter *filter2 = [CIFilter filterWithName:@"CIUnsharpMask"];
    [filter2 setValue:cropImage forKey:kCIInputImageKey];
    [filter2 setValue:@2.0 forKey:@"inputIntensity"];
    [filter2 setValue:@1.0 forKey:@"inputRadius"];
    
    
    
    //HISTOGRAM
//    [self histogram:cropImage];
    
    resultImageSelf = cropImage;
    return resultImage;
}

- (CIImage*) toNoir:(CIImage*)img {
    CIFilter *currentFilter = [CIFilter filterWithName:@"CIPhotoEffectNoir"];
    [currentFilter setValue:img forKey:kCIInputImageKey];
    CIImage *output = [currentFilter outputImage];
    return output;
}

- (CIImage *)grayscaleImage:(CIImage *)image {
    CIImage *ciImage = image;//[[CIImage alloc] initWithImage:image];
    CIImage *grayscale = [ciImage imageByApplyingFilter:@"CIColorControls"
        withInputParameters: @{
            kCIInputSaturationKey : @0.0,
            kCIInputContrastKey : @1.0,
        }];
    return grayscale;//[UIImage imageWithCIImage:grayscale];
}

- (CIImage*) toRemoveNoise:(CIImage*)img {
    CIFilter *currentFilter = [CIFilter filterWithName:@"CINoiseReduction"];
    [currentFilter setValue:img forKey:kCIInputImageKey];
    [currentFilter setValue:@0.0 forKey:@"inputNoiseLevel"];
    [currentFilter setValue:@5.0 forKey:@"inputSharpness"];
    CIImage *output = [currentFilter outputImage];
    return output;
}

- (void) histogram:(CIImage*)img {
    NSNumber* buckets = @10;
    CIImage* img_ = img;//[CIImage imageWithCGImage:img];
    CIFilter* histF = [CIFilter filterWithName:@"CIAreaHistogram"];
    [histF setValue:img_ forKey:@"inputImage"];
    
    CIVector *ciVec = [CIVector vectorWithX:0.0 Y:0.0 Z:[img extent].size.width W:[img extent].size.height];
    
    [histF setValue:ciVec forKey:@"inputExtent"];
    [histF setValue:buckets forKey:@"inputCount"];
    [histF setValue:@1.0 forKey:@"inputScale"];
    
    CIImage* histImg = [histF valueForKey:@"outputImage"];
    NSUInteger arraySize = [buckets intValue] * 4; // ARGB has 4 components
    
    // CHANGE 1: Since I will be rendering in float values, I set up the
    //           buffer using CGFloat
    CGFloat byteBuffer[arraySize]; // Buffer to render into
    
    // CHANGE 2: I wasn't supposed to call [[CIContext alloc] init]
    //           this is a more proper way of getting the context
    CIContext* ctx = [CIContext contextWithOptions:nil];
    
    // CHANGE 3: I use colorSpace:NULL to use the output cspace of the ctx
    // CHANGE 4: Format is now kCIFormatRGBAf
    [ctx render:histImg
       toBitmap:byteBuffer
       rowBytes:arraySize
         bounds:[histImg extent]
         format:kCIFormatRGBAf
     colorSpace:NULL]; // uses the output cspace of the contetxt
    
    // CHANGE 5: I print the float values
    for (int i=0; i<[buckets intValue]; i++) {
        const CGFloat* pixel = &byteBuffer[i*4];
        printf("%d: %0.2f , %0.2f , %0.2f , %0.2f\n", i,pixel[0]/10000,pixel[1]/10000,pixel[2]/10000,pixel[3]/10000);
    }
}

- (CIImage*) drawHighlightOverlayForPoints:(CIImage*)image topLeft:(CGPoint)topLeft topRight:(CGPoint)topRight bottomLeft:(CGPoint)bottomLeft bottomRight:(CGPoint)bottomRight  {
//    CIImage *overlay = [CIImage imageWithColor:[CIColor colorWithRed:0.0 green:0.1 blue:0.0 alpha:0.2]]; // green = 0.55, alpha = 0.3 정도이면 잡은 rectanlge 위에 녹색이 보인다.
    CIImage *overlay;
    
    CGRect rect;
   
    detector = [CIDetector detectorOfType:CIDetectorTypeRectangle context:nil options:@{CIDetectorAccuracy:CIDetectorAccuracyHigh}];
    
    //적정영역 아니면 색을 붉은계열을 노출하고, 적정 너비인 경우 녹색으로 변경한다.
    // x3일때
    // #1 : 적정영역 : 480,000 ~ 650,000 사이 = 녹색 0.0, 0.55, 0.0
    // #2 : 적정영역 : 480,000만 미안 = 붉은 0.55, 0.0, 0.0
    
    // x2인경우는 재설정 필요해 보임
    //#1 : 적정영역 : 240,000 ~ 320,000 사이 = 녹색 0.0, 0.55, 0.0
    
    CGFloat rPoint = 0.0;
    CGFloat gPoint = 0.0;
    CGFloat bPoint = 0.0;
    
    NSInteger minLimitArea = 0;
    NSInteger maxLimitArea = 0;
    NSInteger widthRatio = [UIScreen ratioWidth];
    
    if (widthRatio == 3) {
        minLimitArea = MIN_LIMIT_AREA_3X;
        maxLimitArea = MAX_LIMIT_AREA_3X;
    } else {
        minLimitArea = MIN_LIMIT_AREA_2X;
        maxLimitArea = MAX_LIMIT_AREA_2X;
    }
    
    if (boxArea >= minLimitArea && boxArea <= maxLimitArea) {
        rPoint = 0.0;
        gPoint = 0.55;
        bPoint = 0.0;
        nowGreenMode = YES;
        magicPoint = magicPoint + 1;
    } else {
        rPoint = 0.55;
        gPoint = 0.0;
        bPoint = 0.0;
        nowGreenMode = NO;
        magicPoint = 0;
    }
    
    if (isLandscapeNow == YES) {
        overlay = [CIImage imageWithColor:[CIColor colorWithRed:rPoint green:gPoint blue:bPoint alpha:0.3]]; // green = 0.55, alpha = 0.3 정도이면 잡은 rectanlge 위에 녹색이 보인다.
//        UIBezierPath *path = [UIBezierPath new];
//        [path moveToPoint:topLeft];
//        [path addLineToPoint:topRight];
//        [path addLineToPoint:bottomRight];
//        [path addLineToPoint:bottomLeft];
//        [path addLineToPoint:topLeft];
//        [path closePath];
////
//        CAShapeLayer *_shapeLayer = [CAShapeLayer layer];
//        _shapeLayer.fillColor = [UIColor colorWithRed:rPoint green:gPoint blue:bPoint alpha:boxAlpha].CGColor;
//        _shapeLayer.strokeColor = [UIColor blackColor].CGColor;
//        _shapeLayer.lineWidth = 2;
//        _shapeLayer.path = path.CGPath;
//
//        CGSize imageSize = CGPathGetBoundingBox(path.CGPath).size;
//        UIGraphicsBeginImageContextWithOptions(imageSize, NO, [UIScreen.mainScreen scale]);
//        CGContextRef context = UIGraphicsGetCurrentContext();
//        [_shapeLayer renderInContext:context];
//        UIGraphicsGetImageFromCurrentImageContext();
//        UIGraphicsEndImageContext();
////
//        CGImageRef cgImage = (__bridge CGImageRef)(_shapeLayer.contents);
//        CIImage *ciimage = [CIImage imageWithCGImage:cgImage];
        
    } else {
        overlay = [CIImage imageWithColor:[CIColor colorWithRed:0.0 green:0.00 blue:0.0 alpha:0.0]]; // green = 0.55, alpha = 0.3 정도이면 잡은 rectanlge 위에 녹색이 보인다.
    }

    NSDictionary *param = [[NSDictionary alloc] initWithObjectsAndKeys:
                           [CIVector vectorWithCGRect:[image extent]],@"inputExtent",
                           [CIVector vectorWithCGPoint:topLeft],@"inputTopLeft",
                           [CIVector vectorWithCGPoint:topRight],@"inputTopRight",
                           [CIVector vectorWithCGPoint:bottomLeft],@"inputBottomLeft",
                           [CIVector vectorWithCGPoint:bottomRight],@"inputBottomRight", nil];
    overlay = [overlay imageByCroppingToRect:[image extent]];
    overlay = [overlay imageByApplyingFilter:@"CIPerspectiveTransformWithExtent" withInputParameters:param];
    
    if (magicPoint >= 30) {
        if (getImageCount == 0) {
            getImageCount = 1;
            [self createImage];
        }
    }
    
    return [overlay imageByCompositingOverImage:image];
}

- (CIImage*) cropWithPoints:(CIImage*)image topLeft:(CGPoint)topLeft topRight:(CGPoint)topRight bottomLeft:(CGPoint)bottomLeft bottomRight:(CGPoint)bottomRight  {
//    CIImage *cropImage = [CIImage imageWithColor:[CIColor colorWithRed:0.0 green:0.1 blue:0.0 alpha:0.2]];
    CIImage *cropImage = [CIImage imageWithColor:[CIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.0]];
    
    
    NSDictionary *param = [[NSDictionary alloc] initWithObjectsAndKeys:
                           image,@"inputImage",
                           [CIVector vectorWithCGPoint:topLeft],@"inputTopLeft",
                           [CIVector vectorWithCGPoint:topRight],@"inputTopRight",
                           [CIVector vectorWithCGPoint:bottomLeft],@"inputBottomLeft",
                           [CIVector vectorWithCGPoint:bottomRight],@"inputBottomRight", nil];
    cropImage = [cropImage imageByApplyingFilter:@"CIPerspectiveCorrection" withInputParameters:param];//이게 원래것. //kCIAttributeTypeRectangle
    //CIPerspectiveTransform
    
    /*
     let filter = CIFilter(name: "CIUnsharpMask")
     filter.setValue(beginImage, forKey: kCIInputImageKey)
     filter.setValue(2.0, forKey: "inputIntensity")
     filter.setValue(1.0, forKey: "inputRadius")
     */
    
   
    
    // ======
//    CIImage *outputImage = cropImage;
//    // Your Idea to enhance contrast.
//    CIFilter *ciColorMonochrome = [CIFilter filterWithName:@"CIColorMonochrome"];
//    [ciColorMonochrome setValue:outputImage forKey:kCIInputImageKey];
//    [ciColorMonochrome setValue:@(1) forKey:@"inputIntensity"];
//    [ciColorMonochrome setValue:[[CIColor alloc] initWithColor:[UIColor whiteColor]] forKey:@"inputColor"];// Black and white
//    cropImage = [ciColorMonochrome valueForKey:kCIOutputImageKey];

    
//    CIFilter *filter = [CIFilter filterWithName:@"CIUnsharpMask"];
//       [filter setValue:cropImage forKey:kCIInputImageKey];
//       [filter setValue:@(15) forKey:@"inputIntensity"];
//       [filter setValue:@(1.0) forKey:@"inputRadius"];
    
    // Now go on with edge detection - 주민증 되는데, 운전증은 잘 안된다.
//    CIImage *result = [filter valueForKey:kCIOutputImageKey];
//    CIFilter *ciEdges = [CIFilter filterWithName:@"CIEdges"];
////    [ciEdges setValue:outputImage forKey:kCIInputImageKey];
//    [ciEdges setValue:cropImage forKey:kCIInputImageKey];
//    [ciEdges setValue:@(5) forKey:@"inputIntensity"];
//    cropImage = [ciEdges valueForKey:kCIOutputImageKey];
    // ======
    
    
    
    return cropImage;
}

-(void)shootAndPassImage{
    [self performSelectorInBackground:@selector(createImage) withObject:nil];
}

-(void)createImage{ //여기서 landscape 상태 파악하고, 회전이 필요한 경우 이미지 돌리자.
    UIImage *img = [[UIImage alloc] initWithCIImage:resultImageSelf];
    if (self.delegate != nil) {
        [[self delegate] didFinishSaveFile:self result:img];
    }
}

- (void) imageEqualizationRender {
//    id filter = MPSImageHistogramEqualization();
//    [filter setInput]
    
    
}

- (void)image: (UIImage *) image didFinishSavingWithError: (NSError *) error contextInfo: (void *) contextInfo { //can also handle error message as well
    
    
}

-(void)orientationChanged:(NSNotification *)notif {
    UIDeviceOrientation deviceOrientation = [[UIDevice currentDevice] orientation];

    // Calculate rotation angle
    CGFloat angle;
    switch (deviceOrientation) {
        case UIDeviceOrientationPortrait:
            angle = 0;
            isLandscapeNow = NO;
            [guideImageView setHidden:NO];
            [landscapeGuideView setHidden:YES];
//            NSLog(@"UIDeviceOrientationPortrait");
            break;
        case UIDeviceOrientationPortraitUpsideDown:
            angle = M_PI;
            isLandscapeNow = NO;
            [guideImageView setHidden:NO];
            [landscapeGuideView setHidden:YES];
//            NSLog(@"UIDeviceOrientationPortraitUpsideDown");
            break;
        case UIDeviceOrientationLandscapeLeft:
            angle = M_PI_2;
            isLandscapeNow = YES;
            [guideImageView setHidden:YES];
            [landscapeGuideView setHidden:NO];
//            NSLog(@"UIDeviceOrientationLandscapeLeft");
            break;
        case UIDeviceOrientationLandscapeRight:
            angle = - M_PI_2;
            isLandscapeNow = YES;
            [guideImageView setHidden:YES];
            [landscapeGuideView setHidden:NO];
//            NSLog(@"UIDeviceOrientationLandscapeRight");
            break;
        default:
            angle = 0;
            break;
    }
    
    videoFilter.isLandScape = isLandscapeNow;
    
}

#pragma mark - Memory Warnning Management
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
