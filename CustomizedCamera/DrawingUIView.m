//
//  DrawingUIView.m
//  CustomizedCamera
//
//  Created by Ocean Lin on 2014/2/17.
//  Copyright (c) 2014年 PicsureHunt. All rights reserved.
//

#import "DrawingUIView.h"

@interface DrawingUIView ()
@property (weak, nonatomic) IBOutlet UIButton *color1BTN;
@property (weak, nonatomic) IBOutlet UIButton *color2BTN;
@property (weak, nonatomic) IBOutlet UIButton *color3BTN;
@property (weak, nonatomic) IBOutlet UIButton *color4BTN;
@property (weak, nonatomic) IBOutlet UIButton *color5BTN;
@property (weak, nonatomic) IBOutlet UIButton *doneBTN;
@property (strong, nonatomic) UIBezierPath *bezierPath;
@property (nonatomic) int pointCount;
@property (nonatomic) BOOL canEdit;
@end

@implementation DrawingUIView

#pragma mark - Initialization
#define NumberOfPointForCreatePath 4
{
    CGPoint pathPoints[5];
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        //[self colorButtonHidden:YES];
        self.backgroundColor = [UIColor clearColor];
        [self setMultipleTouchEnabled:NO];
        self.canEdit = NO;
        [self initColorSelection];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        //[self colorButtonHidden:YES];
        self.backgroundColor = [UIColor clearColor];
        [self setMultipleTouchEnabled:NO];
        self.canEdit = NO;
    }
    
    return self;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    [self initColorSelection];
    [self controlButtonaHidden:YES];
}

- (UIBezierPath *)bezierPath
{
    if (!_bezierPath) {
        _bezierPath = [[UIBezierPath alloc] init];
        [_bezierPath setLineWidth:2.0f];
    }
    
    return _bezierPath;
}

- (void)initColorSelection
{
    [self.color1BTN.layer setBorderWidth:3.0f];
    [self.color1BTN.layer setBorderColor:[UIColor purpleColor].CGColor];
    self.currentPathColor = self.color1BTN.backgroundColor;
}

#pragma mark - Delegate/Event handler

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (!self.canEdit)
        return;

    self.pointCount = 0;
    UITouch *touch = [touches anyObject];
    self->pathPoints[0] = [touch locationInView:self];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (!self.canEdit)
        return;
    
    UITouch *touch = [touches anyObject];
    CGPoint point = [touch locationInView:self];
    self.pointCount++;
    self->pathPoints[self.pointCount] = point;
    if (self.pointCount == NumberOfPointForCreatePath) {
        self->pathPoints[3] = CGPointMake((self->pathPoints[2].x+self->pathPoints[4].x)/2, (self->pathPoints[2].y+self->pathPoints[4].y)/2);
        [self.bezierPath moveToPoint:self->pathPoints[0]];
        [self.bezierPath addCurveToPoint:self->pathPoints[3] controlPoint1:self->pathPoints[1] controlPoint2:self->pathPoints[2]];
        
        [self setNeedsDisplay];
        
        self->pathPoints[0] = self->pathPoints[3];
        self->pathPoints[1] = self->pathPoints[4];
        self.pointCount = 1;
    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (!self.canEdit)
        return;
    
    [self drawCacheImage];
    [self setNeedsDisplay];
    [self.bezierPath removeAllPoints];
    self.pointCount = 0;
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (!self.canEdit)
        return;
    
    [self touchesEnded:touches withEvent:event];
}

#pragma mark - Functions

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    if (!self.canEdit)
        return;
    
    [self.currentPathColor setStroke];
    [self.incrementalPathImage drawInRect:rect];
    [self.bezierPath stroke];
}

- (void)controlButtonaHidden:(BOOL)hidden
{
    self.canEdit = !hidden;
    self.color1BTN.hidden = hidden;
    self.color2BTN.hidden = hidden;
    self.color3BTN.hidden = hidden;
    self.color4BTN.hidden = hidden;
    self.color5BTN.hidden = hidden;
    self.doneBTN.hidden = hidden;
}

- (void)drawCacheImage
{
//    NSLog(@"Bound H : %f, W : %f", self.bounds.size.height, self.bounds.size.width);
//    NSLog(@"Frame H : %f, W : %f", self.frame.size.height, self.frame.size.width);
    UIGraphicsBeginImageContextWithOptions(self.bounds.size, NO, 0);
    [self.incrementalPathImage drawAtPoint:CGPointZero];
    [self.currentPathColor setStroke];
    [self.bezierPath stroke];
    self.incrementalPathImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
}
@end
