//
//  DrawingUIView.h
//  CustomizedCamera
//
//  Created by Ocean Lin on 2014/2/17.
//  Copyright (c) 2014年 PicsureHunt. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DrawingUIView : UIView

- (void)controlButtonaHidden:(BOOL)hidden;
@property (strong, nonatomic) UIColor *currentPathColor;
@property (strong, nonatomic) UIImage *incrementalPathImage;

@end
