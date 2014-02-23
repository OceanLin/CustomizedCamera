//
//  AVOverlayUIView.m
//  CustomizedCamera
//
//  Created by Ocean Lin on 2014/2/22.
//  Copyright (c) 2014年 PicsureHunt. All rights reserved.
//

#import "AVOverlayUIView.h"
#import "InternalNotificationHelper.h"

@interface AVOverlayUIView ()
@property (strong, nonatomic) UIBezierPath *focusRectangle;
@property (strong, nonatomic) NSTimer *focusUITimer;
@property (nonatomic) BOOL drawingFocus;
@property (nonatomic) BOOL enableTapToFocus;
@end

@implementation AVOverlayUIView

#define OffsetFromCenter 24.0f

#pragma mark - Initialization
- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        self.drawingFocus = NO;
        self.multipleTouchEnabled = NO;
        if ([[NSUserDefaults standardUserDefaults] objectForKey:@"enableTapToFocus"]) {
            self.enableTapToFocus = [[NSUserDefaults standardUserDefaults] boolForKey:@"enableTapToFocus"];
        }
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        // Initialization code
        self.drawingFocus = NO;
        self.multipleTouchEnabled = NO;
        if ([[NSUserDefaults standardUserDefaults] objectForKey:@"enableTapToFocus"]) {
            self.enableTapToFocus = [[NSUserDefaults standardUserDefaults] boolForKey:@"enableTapToFocus"];
        }
    }
    return self;
}

- (UIBezierPath *)focusRectangle
{
    if (!_focusRectangle) {
        _focusRectangle = [UIBezierPath bezierPathWithRect:CGRectMake(0, 0, 48, 48)];
        [_focusRectangle setLineWidth:2.0f];
    }
    
    return _focusRectangle;
}

- (NSTimer *)focusUITimer
{
    if (!_focusUITimer) {
        _focusUITimer = [NSTimer scheduledTimerWithTimeInterval:2.0f target:self selector:@selector(hideFocusRectangle) userInfo:nil repeats:NO];
    }
    
    return _focusUITimer;
}

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    if (self.drawingFocus) {
        [[UIColor redColor] setStroke];
        [self.focusRectangle stroke];
        //[self.focusRectangle strokeWithBlendMode:kCGBlendModeNormal alpha:0.1f];
    }
}

#pragma mark - Delegate/Event handler

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (self.enableTapToFocus) {
        UITouch *touch = [touches anyObject];
        CGPoint poi = [touch locationInView:self];
        [self showFocusRectangle:poi];
        //NSLog(@"POI (%f, %f)", poi.x, poi.y);
        NSDictionary *poiDic = @{@"x": [NSString stringWithFormat:@"%f", poi.x], @"y": [NSString stringWithFormat:@"%f", poi.y]};
        [[NSNotificationCenter defaultCenter] postNotificationName:AVCameraTouchToFocus object:nil userInfo:@{FocusPOI:poiDic}];
    }
}

#pragma mark - Functions

- (void)showFocusRectangle:(CGPoint)poi
{
    [self setNeedsDisplay];
    self.drawingFocus = YES;
    self.focusRectangle = [UIBezierPath bezierPathWithRect:CGRectMake(poi.x-OffsetFromCenter, poi.y-OffsetFromCenter, 2*OffsetFromCenter, 2*OffsetFromCenter)];
    if (self.focusUITimer) {
        [self.focusUITimer invalidate];
        self.focusUITimer = nil;
        self.focusUITimer = [NSTimer scheduledTimerWithTimeInterval:2.0f target:self selector:@selector(hideFocusRectangle) userInfo:nil repeats:NO];
    }
}

- (void)hideFocusRectangle
{
    //NSLog(@"hideFocusRectangle is called.");
    [self setNeedsDisplay];
    self.drawingFocus = NO;
}
@end
