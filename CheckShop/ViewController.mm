//
//  ViewController.m
//  CheckShop
//
//  Created by INTAEK HAN on 2020/01/24.
//  Copyright © 2020 INTAEK HAN. All rights reserved.
//

#import "ViewController.h"
#import <opencv2/imgproc/types_c.h>
#import <opencv2/imgproc/imgproc_c.h>
#import <opencv2/imgproc.hpp>
#import <opencv2/core.hpp>
#import <opencv2/imgcodecs.hpp>
//#include "opencv2/core/opencv.hpp"
//#import <opencv2/core/core.hpp>
#include "opencv2/core/core_c.h"
#import "HPCameraViewController.h"

using namespace cv;
using namespace std;

@interface ViewController () {
    
    __weak IBOutlet UIImageView *srcIV;
    __weak IBOutlet UIImageView *procIV;
    __weak IBOutlet UIImageView *dstIV;
    
}

@end

@implementation ViewController

    NSOperationQueue *operationQueue;

- (void)viewDidLoad {
    [super viewDidLoad];
    [self touchReloadButton:nil];
}
- (IBAction)touchExit:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}


- (IBAction)touchReloadButton:(id)sender {
    //    dispatch_after(2.0, dispatch_get_main_queue(), ^{
            //원본 영상 Mat화
                   UIImage *sampleImage;
                   if (self.pImage != nil) {
                       sampleImage = self.pImage;
                   } else {
                       sampleImage = [UIImage imageNamed:@"sample"];
                   }
                   
                   cv::Mat inputMat = [self cvMatFromUIImage:sampleImage];
               //    inputMat = inputMat*2.0f; //밝은영상샘플
                   inputMat = inputMat;
               //    inputMat = inputMat/2.f; //어두운영상샘플
                   
               //    Mat srcYcrcb;
               //    cvtColor(inputMat, srcYcrcb, COLOR_BGR2YCrCb);
               //
               //    vector<Mat> ycrcbPlanes;
               //    split(srcYcrcb, ycrcbPlanes);
               //    equalizeHist(ycrcbPlanes[0], ycrcbPlanes[1]);
               //
               //    Mat dstYcrcb;
               //    merge(ycrcbPlanes, dstYcrcb);
               //    Mat dst;
               //    cvtColor(dstYcrcb, dst, COLOR_YCrCb2BGR);
                   
                    UIImage *srcImage = [self UIImageFromCVMat:inputMat];
    //               [srcIV setImage:srcImage];
                   printf("src ! height >> %d * width >> %d\n",inputMat.rows,inputMat.cols);
                   
                   //밝기의 분포를 구해본다.
                   //정상 밝기 -> 208.x의 값이 나왔고
                   ///2로 어둡게 한 경우 -> 128.0이 나왔음.
                   float lp = [self getLightPoint:inputMat];
                   
                   //Gray로
                   Mat grayMat;
                   cv::cvtColor(inputMat, grayMat, CV_RGB2GRAY);
               //    float grayLP = [self getLightPoint:grayMat];
               //
               //    //어두운 gray면 밝게...
               //    printf("grayLP : [ %f ]",grayLP);
                   

                   
                   Mat gray2;
                   gray2 = Mat(grayMat.rows, grayMat.cols, grayMat.type());
                   
                   double sumLP = 0.0;
                      double avrLP = 0.0;
                      int count = 0;
                      for(int j=0;j<grayMat.rows;j++) {
                          for(int i=0;i<grayMat.cols;i++) {
                              int lp = grayMat.at<uchar>(j,i);
                              if (lp < 100) {
                                  gray2.at<uchar>(j,i) = 0;
                              } else {
                                  gray2.at<uchar>(j,i) = 255;
                              }
                          }
                      }
                   
                   UIImage *procImage = [self UIImageFromCVMat:gray2];
    //               [procIV setImage:procImage];
                   
                   //get Edge
                   Mat edgeMat;
               //    cv::Canny(inputMat, edgeMat, 200, 210); //정상밝기 - 집 - 형광등 하에서
                   cv::Canny(gray2, edgeMat, lp, 255); //정상밝기에  를 한값  - 집 - 형광등 하에서

                   
                   
                   std::vector<std::vector<cv::Point>> contours;
                   cv::findContours(grayMat, contours, RETR_LIST, CHAIN_APPROX_SIMPLE);
                   
                   for(std::vector<cv::Point> &pts:contours) {
                       if (contourArea(pts) < 400) {
               //            rectangle(grayMat, pts[0], pts[1], COLORMAP_PINK);
                           continue;
                       }
                       
                       std::vector<cv::Point> approx;
                       approxPolyDP(pts, approx, arcLength(pts, true) * 0.02, true);
                       
                       int vtc = (int)approx.size();
                   
                       if(vtc == 4) {
                           double len = arcLength(pts, true);
                           double area = contourArea(pts);
                           double ratio = 4. * CV_PI * area / (len * len);
                           if (ratio > 0.7) {
                               cv::Rect rc = boundingRect(pts);
                               rectangle(grayMat, rc, Scalar(0,0,255), 1);
                           }
                       }
                   }
                   
                    std::vector<cv::Vec4i> lines;
                   
                   cv::Mat img_proc;
                   double scale = 1.0;
                   int w = edgeMat.size().width;
                   int h = edgeMat.size().height;
                   int w_proc = w * 1.0 / scale;
                   int h_proc = h * 1.0 / scale;
                   
                   HoughLinesP(edgeMat, lines, 1, CV_PI / 180, 160,50,5);
                   
                   Mat dst2;
                   cvtColor(edgeMat, dst2, COLOR_GRAY2BGR);
                   
                   for (Vec4i l:lines) {
                       line(dst2,cv::Point(l[0],l[1]),cv::Point(l[2],l[3]),Scalar(0,0,255),2,LINE_AA);
                   }
                   UIImage *dstImage = [self UIImageFromCVMat:dst2];
    //               [dstIV setImage:dstImage];
                   
                   //글자 뽑기
    UIImage *dstImage2 = [self UIImageFromCVMat:edgeMat];
                   [self recognizeImageWithTesseract:dstImage2];
                   
    //        [self.tableView reloadData];
    //    });
        
        dispatch_time_t time = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0f * NSEC_PER_SEC));
        dispatch_after(time, dispatch_get_main_queue(), ^{
            [srcIV setImage:srcImage];
            [procIV setImage:procImage];
            [dstIV setImage:dstImage];
            
//            [self recognizeImageWithTesseract:srcImage];
        });
    
}

- (cv::Mat)cvMatGrayFromUIImage:(UIImage *)image
{
  CGColorSpaceRef colorSpace = CGImageGetColorSpace(image.CGImage);
  CGFloat cols = image.size.width;
  CGFloat rows = image.size.height;

  cv::Mat cvMat(rows, cols, CV_8UC1); // 8 bits per component, 1 channels

  CGContextRef contextRef = CGBitmapContextCreate(cvMat.data,                 // Pointer to data
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

-(float) getLightPoint:(const Mat &) mata {
    double sumLP = 0.0;
    double avrLP = 0.0;
    int count = 0;
    for(int j=0;j<mata.rows;j++) {
        for(int i=0;i<mata.cols;i++) {
            int lp = mata.at<uchar>(j,i);
            if (lp > 127) {
                sumLP = sumLP + lp;
                count = count + 1;
            }
        }
    }
    printf("img avr lightpoint : %f",(sumLP / count));
    return (sumLP / count);
}
- (cv::Mat)cvMatFromUIImage:(UIImage *)image
{
  CGColorSpaceRef colorSpace = CGImageGetColorSpace(image.CGImage);
  CGFloat cols = image.size.width;
  CGFloat rows = image.size.height;

  cv::Mat cvMat(rows, cols, CV_8UC4); // 8 bits per component, 4 channels (color channels + alpha)

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

Mat calcGrayHist(const Mat &img) {
    CV_Assert(img.type() == CV_8UC1);
    
    Mat hist;
    int channels[] = { 0 };
    int dims = 1;
    const int histSize[] = { 256 };
    float graylevel[] = { 0, 256 };
    const float* ranges[] = { graylevel };
    calcHist(&img, 1, channels, noArray(), hist, dims, histSize, ranges);
    
    return hist;
}

Mat adaptiveThreshold(const Mat &src,const Mat &dst){
    //적응형 이진화
    Mat blackAndWhiteMat = dst; //    cv::equalizeHist(grayMat, blackAndWhiteMat);
    int bsize = 100;
    if (bsize%2 == 0 ) bsize--;
    if (bsize < 3 ) bsize = 3;
    cv::adaptiveThreshold(src, blackAndWhiteMat, 255, ADAPTIVE_THRESH_GAUSSIAN_C, THRESH_BINARY,bsize,5);
    return blackAndWhiteMat;
}

Mat equalizeHist(const Mat &src,const Mat &dst){
    Mat equalizeHistMat = dst;
    cv::equalizeHist(src, equalizeHistMat);
    return equalizeHistMat;
}

#pragma mark - scan method
double angle(  cv::Point2f pt1,  cv::Point2f pt2,  cv::Point2f pt0 ) {
    
    double dx1 = pt1.x - pt0.x;
    double dy1 = pt1.y - pt0.y;
    double dx2 = pt2.x - pt0.x;
    double dy2 = pt2.y - pt0.y;
    return (dx1*dx2 + dy1*dy2)/sqrt((dx1*dx1 + dy1*dy1)*(dx2*dx2 + dy2*dy2) + 1e-10);
}

struct Line {
    cv::Point _p1;
    cv::Point _p2;
    cv::Point _center;
    
    Line(cv::Point p1, cv::Point p2) {
        _p1 = p1;
        _p2 = p2;
        _center = cv::Point((p1.x + p2.x) / 2, (p1.y + p2.y) / 2);
    }
};

bool cmp_y(const Line &p1, const Line &p2) {
    return p1._center.y < p2._center.y;
}

bool cmp_x(const Line &p1, const Line &p2) {
    return p1._center.x < p2._center.x;
}

cv::Point2f computeIntersect2(cv::Vec4i a, cv::Vec4i b)
{
    int x1 = a[0], y1 = a[1], x2 = a[2], y2 = a[3];
    int x3 = b[0], y3 = b[1], x4 = b[2], y4 = b[3];
    
    if (float d = ((float)(x1-x2) * (y3-y4)) - ((y1-y2) * (x3-x4)))
    {
        cv::Point2f pt;
        pt.x = ((x1*y2 - y1*x2) * (x3-x4) - (x1-x2) * (x3*y4 - y3*x4)) / d;
        pt.y = ((x1*y2 - y1*x2) * (y3-y4) - (y1-y2) * (x3*y4 - y3*x4)) / d;
        return pt;
    }
    else
        return cv::Point2f(-1, -1);
}

/**
 * Compute intersect point of two lines l1 and l2
 * @param l1
 * @param l2
 * @return Intersect Point
 */
cv::Point2f computeIntersect(Line l1, Line l2) {
    int x1 = l1._p1.x, x2 = l1._p2.x, y1 = l1._p1.y, y2 = l1._p2.y;
    int x3 = l2._p1.x, x4 = l2._p2.x, y3 = l2._p1.y, y4 = l2._p2.y;
    if (float d = (x1 - x2) * (y3 - y4) - (y1 - y2) * (x3 - x4)) {
        cv::Point2f pt;
        pt.x = ((x1 * y2 - y1 * x2) * (x3 - x4) - (x1 - x2) * (x3 * y4 - y3 * x4)) / d;
        pt.y = ((x1 * y2 - y1 * x2) * (y3 - y4) - (y1 - y2) * (x3 * y4 - y3 * x4)) / d;
        return pt;
    }
    return cv::Point2f(-1, -1);
}

//MARK:-Tessoract Method Management
- (void) recognizeImageWithTesseract:(UIImage*) image {
    NSLog(@"tess ver. %@",[G8Tesseract version]);
    dispatch_async(dispatch_get_main_queue(), ^{
        G8RecognitionOperation *operation = [[G8RecognitionOperation alloc] initWithLanguage:@"eng"];
        if (operation == nil) {
            return;
        }
        
        [operation.tesseract setDelegate:self];
        [operation.tesseract setEngineMode:G8OCREngineModeTesseractOnly];
        [operation.tesseract setPageSegmentationMode:G8PageSegmentationModeAutoOnly];
        [operation.tesseract setImage:image];
//        [operation.tesseract setCharWhitelist:@"0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz'"];
        
        [operation setRecognitionCompleteBlock:^(G8Tesseract * _Nullable tesseract) {
            NSString *recogString = [tesseract recognizedText];
            NSLog(@"text : %@",recogString);
        }];
        if (operationQueue == nil) {
            operationQueue = [[NSOperationQueue alloc] init];
        }
        [operationQueue addOperation:operation];
    });
}

@end
