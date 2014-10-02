//
//  Utility.m
//  pumpupPhotoEditor
//
//  Created by Anthony Uccello on 2014-09-30.
//  Copyright (c) 2014 pumpup inc. All rights reserved.
//

#import "Utility.h"

@implementation Utility


//creates and returns a text button object
+(UILabel*)createTextButtonWithText:(NSString*)text Size:(CGRect)rect Selector:(SEL)selector Target:(id)target
{
    UILabel * label = [[UILabel alloc] initWithFrame:rect];
    label.text = text;
    label.numberOfLines = 1;
    label.adjustsFontSizeToFitWidth = YES;
    label.textColor = [UIColor blackColor];
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:target action:selector];
    [label addGestureRecognizer:tap];
    label.userInteractionEnabled = YES;
    return label;
}

//creates and returns a button with an image and callback
+(UIButton*)createButtonImageName:(NSString*)imageName Rect:(CGRect)rect Selector:(SEL)selector Target:(id)target
{
    UIButton *button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [button addTarget:target action:selector forControlEvents:UIControlEventTouchUpInside];
    [button setImage:[UIImage imageNamed:imageName] forState:UIControlStateNormal];
    button.frame = rect;
    return button;
}

//create a filtered image based on a filter name and an image (with its orientation
+(UIImage*)createFilteredImage:(UIImage*)image FilterName:(NSString*)filterName Orientation:(UIImageOrientation)orientation
{
    //   Convert UIImage to CIImage
    CIImage *ciImage = [[CIImage alloc] initWithImage:image];
    //return [UIImage imageWithCIImage:ciImage];
    
    //  Set values for CIColorMonochrome Filter
    CIFilter *filter = [CIFilter filterWithName:filterName];
    [filter setValue:ciImage forKey:kCIInputImageKey];
    // [filter setValue:@1.0 forKey:@"inputIntensity"];
    // [filter setValue:coreColor forKey:@"inputColor"];
    
    CIImage *result = [filter valueForKey:kCIOutputImageKey];
    
    CGRect extent = [result extent];
    
    CIContext* context = [CIContext contextWithOptions:nil];
    CGImageRef cgImage = [context createCGImage:result fromRect:extent];
    
    UIImage *filteredImage = [[UIImage alloc] initWithCGImage:cgImage scale:1.0 orientation:orientation];
    
    return filteredImage;
}

@end
