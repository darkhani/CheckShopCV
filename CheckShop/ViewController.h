//
//  ViewController.h
//  CheckShop
//
//  Created by INTAEK HAN on 2020/01/24.
//  Copyright © 2020 INTAEK HAN. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <TesseractOCR/TesseractOCR.h>
#import "HPCameraViewController.h"
@interface ViewController : UITableViewController <G8TesseractDelegate, HPCameraViewControllerDelegate>

@property (nonatomic) UIImage *pImage;

@end

