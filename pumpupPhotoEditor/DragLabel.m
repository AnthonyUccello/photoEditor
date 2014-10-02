//
//  DragLabel.m
//  pumpupPhotoEditor
//
//  Created by Anthony Uccello on 2014-10-01.
//  Copyright (c) 2014 pumpup inc. All rights reserved.
//

#import "DragLabel.h"

@implementation DragLabel


-(void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    NSLog(@"move detected");
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    NSLog(@"Touch began event in drag label!!!");
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
