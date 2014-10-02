//
//  EditPhotoViewController.h
//  pumpupPhotoEditor
//
//  Created by Anthony Uccello on 2014-09-30.
//  Copyright (c) 2014 pumpup inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface EditPhotoViewController : UIViewController <UIScrollViewDelegate>

-(void)initView;
-(void)loadImage:(UIImage*)image Orientation:(UIImageOrientation)orientation;

@end
