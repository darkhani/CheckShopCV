//
//  MenuViewController.h
//  CheckShop
//
//  Created by INTAEK HAN on 2020/02/27.
//  Copyright © 2020 INTAEK HAN. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HPCameraViewController.h"
#import <TesseractOCR/TesseractOCR.h>
NS_ASSUME_NONNULL_BEGIN

@interface MenuViewController : UIViewController <HPCameraViewControllerDelegate,G8TesseractDelegate>

@end

NS_ASSUME_NONNULL_END
