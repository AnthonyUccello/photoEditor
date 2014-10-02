//
//  Utility.h
//  pumpupPhotoEditor
//
//  Created by Anthony Uccello on 2014-09-30.
//  Copyright (c) 2014 pumpup inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface Utility : UIView

+(UILabel*)createTextButtonWithText:(NSString*)text Size:(CGRect)rect Selector:(SEL)selector Target:(id)target;
+(UIButton*)createButtonImageName:(NSString*)imageName Rect:(CGRect)rect Selector:(SEL)selector Target:(id)target;
+(UIImage*)createFilteredImage:(UIImage*)image FilterName:(NSString*)filterName Orientation:(UIImageOrientation)orientation;

@end
