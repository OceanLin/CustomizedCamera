//
//  AVCameraViewController.m
//  CustomizedCamera
//
//  Created by Ocean Lin on 2014/2/19.
//  Copyright (c) 2014年 PicsureHunt. All rights reserved.
//

#import "AVCameraViewController.h"
#import <AVFoundation/AVFoundation.h>

@interface AVCameraViewController ()
@property (strong, nonatomic) AVCaptureSession *captureSession;
@property (strong, nonatomic) UIView *cameraPreviewUIView;
@property (strong, nonatomic) IBOutlet UIView *avOverlayView;
@end

@implementation AVCameraViewController

#define PreferenceCameraDevice @"PreferenceCameraDevice"

#pragma mark - Initialization

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    AVCaptureVideoPreviewLayer *previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.captureSession];
    if (previewLayer) {
        [previewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
        previewLayer.bounds = self.view.layer.bounds;
        previewLayer.position = CGPointMake(CGRectGetMidX(self.view.layer.bounds), CGRectGetMidY(self.view.layer.bounds));
        self.cameraPreviewUIView = [[UIView alloc] initWithFrame:self.view.layer.bounds];
        //NSLog(@"layer position : (%f, %f)", previewLayer.position.x, previewLayer.position.y);
        //NSLog(@"layer zPosition : %f", previewLayer.zPosition);
        //NSLog(@"layer bound : H : %f, W : %f, (%f, %f)", previewLayer.bounds.size.height, previewLayer.bounds.size.width, previewLayer.bounds.origin.x, previewLayer.bounds.origin.y);
        //NSLog(@"frame : H : %f, W : %f, (%f, %f)", self.cameraPreviewUIView.frame.size.height, self.cameraPreviewUIView.frame.size.width, self.cameraPreviewUIView.frame.origin.x, self.cameraPreviewUIView.frame.origin.y);
        [self.cameraPreviewUIView.layer addSublayer:previewLayer];
        [self.view addSubview:self.cameraPreviewUIView];
        [[NSBundle mainBundle] loadNibNamed:@"AVOverlayView" owner:self options:nil];
        [self.avOverlayView setFrame:CGRectMake(0, 0, [[UIScreen mainScreen] bounds].size.width, [[UIScreen mainScreen] bounds].size.height)];
        [self.view addSubview:self.avOverlayView];
        [self.captureSession startRunning];
    }
}

- (AVCaptureSession *)captureSession
{
    if (!_captureSession) {
        _captureSession = [[AVCaptureSession alloc] init];
        
        if ([_captureSession canSetSessionPreset:AVCaptureSessionPresetPhoto]) {
            _captureSession.sessionPreset = AVCaptureSessionPresetPhoto;
            NSError *error;
            BOOL hasPreferenceCamera = NO;
            AVCaptureDevicePosition preferenceDevicePosition;
            if ([[NSUserDefaults standardUserDefaults] objectForKey:PreferenceCameraDevice]) {
                hasPreferenceCamera = YES;
                preferenceDevicePosition = [[NSUserDefaults standardUserDefaults] integerForKey:PreferenceCameraDevice];
            }
            
            for (AVCaptureDevice *device in [AVCaptureDevice devices]) {
                //Check which device user used last time, if it is first launch, just set the back camera.
                if (hasPreferenceCamera) {
                    if (preferenceDevicePosition == [device position]) {
                        AVCaptureDeviceInput *deviceInput = [AVCaptureDeviceInput deviceInputWithDevice:device error:&error];
                        if (error) {
                            NSLog(@"Got error when set the device input.");
                            return nil;
                        } else {
                            [_captureSession addInput:deviceInput];
                            break;
                        }
                    }
                    
                } else {
                    if ([device position] == AVCaptureDevicePositionBack) {
                        AVCaptureDeviceInput *deviceInput = [AVCaptureDeviceInput deviceInputWithDevice:device error:&error];
                        if (error) {
                            NSLog(@"Got error when set the device input.");
                            return nil;
                        } else {
                            [_captureSession addInput:deviceInput];
                            break;
                        }
                    }
                }
            }
            return _captureSession;
        } else {
            return nil;
        }
    }
    
    return _captureSession;
}

#pragma mark - Delegate/Event handler
- (void)viewWillDisappear:(BOOL)animated
{
    if (self.captureSession) {
        [self.captureSession stopRunning];
    }
}

#pragma mark - Overlay Delegate/Event handler

- (IBAction)captureWithSend:(id)sender {
    [self dismissViewControllerAnimated:YES completion:NULL];
}


#pragma mark - Exception handler

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
