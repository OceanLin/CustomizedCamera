//
//  AVCameraViewController.m
//  CustomizedCamera
//
//  Created by Ocean Lin on 2014/2/19.
//  Copyright (c) 2014年 PicsureHunt. All rights reserved.
//

#import "AVCameraViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "InternalNotificationHelper.h"

@interface AVCameraViewController ()
@property (strong, nonatomic) AVCaptureSession *captureSession;
@property (strong, nonatomic) AVCaptureStillImageOutput *imageOutput;
@property (strong, nonatomic) UIView *cameraPreviewUIView;
@property (strong, nonatomic) IBOutlet UIView *avOverlayView;
@property (weak, nonatomic) IBOutlet UIButton *flashModeBTN;
@property (weak, nonatomic) IBOutlet UIButton *reverseBTN;
@end

@implementation AVCameraViewController

#define PreferenceCameraDevice @"PreferenceCameraDevice"
#define PreferenceFlashMode @"PreferenceFlashMode"

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
    
    //Set up the preview layer
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
        [self setCustomizedCameraUI];
        [self.view addSubview:self.avOverlayView];
        [self.captureSession startRunning];
    }
    
    //Set up the output
    if (self.captureSession) {
        self.imageOutput = [[AVCaptureStillImageOutput alloc] init];
        NSDictionary *outputSettings = [[NSDictionary alloc] initWithObjectsAndKeys:AVVideoCodecJPEG, AVVideoCodecKey, nil];
        [self.imageOutput setOutputSettings:outputSettings];
        [self.captureSession addOutput:self.imageOutput];
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
    if (self.captureSession && self.imageOutput) {
        AVCaptureConnection *captureConnection = nil;
        for (AVCaptureConnection *connection in self.imageOutput.connections) {
            BOOL foundConnection = NO;
            for (AVCaptureInputPort *inputPort in [connection inputPorts]) {
                if ([[inputPort mediaType] isEqual:AVMediaTypeVideo]) {
                    captureConnection = connection;
                    foundConnection = YES;
                    break;
                }
            }
            if (foundConnection) {
                break;
            }
        }
        
        [self.imageOutput captureStillImageAsynchronouslyFromConnection:captureConnection completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error) {
            if (error) {
                NSLog(@"Got error when capture the image. Code : %ld, Description : %@", (long)error.code, [error localizedDescription]);
            } else if (!imageDataSampleBuffer) {
                NSLog(@"No image data from the image output.");
            } else {
                NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
                [[NSNotificationCenter defaultCenter] postNotificationName:ImageReadyFromAVCapture object:nil userInfo:@{CapturedImageData:imageData}];
                
                //If we need the meta data, we can retrieve that by following call.
                //CFDictionaryRef myAttachments = CMGetAttachment(imageDataSampleBuffer, kCGImagePropertyExifDictionary, NULL);
                
                [self dismissViewControllerAnimated:YES completion:NULL];
            }
        }];
    }
}

- (IBAction)reverseCamera:(id)sender {
    for (AVCaptureDeviceInput *oldInput in self.captureSession.inputs) {
        BOOL finishReverse = NO;
        if ([oldInput device].position == AVCaptureDevicePositionBack) {
            for (AVCaptureDevice *device in [AVCaptureDevice devices]) {
                NSError *error;
                if ([device position] == AVCaptureDevicePositionFront) {
                    AVCaptureDeviceInput *deviceInput = [AVCaptureDeviceInput deviceInputWithDevice:device error:&error];
                    finishReverse = YES;
                    if (error) {
                        NSLog(@"Got error when reverse the camera.");
                        break;
                    } else {
                        self.flashModeBTN.hidden = YES;
                        [self.captureSession beginConfiguration];
                        [self.captureSession removeInput:oldInput];
                        [self.captureSession addInput:deviceInput];
                        [self.captureSession commitConfiguration];
                        [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:AVCaptureDevicePositionFront] forKey:PreferenceCameraDevice];
                        break;
                    }
                }
            }
        } else if ([oldInput device].position == AVCaptureDevicePositionFront) {
            for (AVCaptureDevice *device in [AVCaptureDevice devices]) {
                NSError *error;
                if ([device position] == AVCaptureDevicePositionBack) {
                    AVCaptureDeviceInput *deviceInput = [AVCaptureDeviceInput deviceInputWithDevice:device error:&error];
                    finishReverse = YES;
                    if (error) {
                        NSLog(@"Got error when reverse the camera.");
                        break;
                    } else {
                        [self.captureSession beginConfiguration];
                        [self.captureSession removeInput:oldInput];
                        [self.captureSession addInput:deviceInput];
                        [self.captureSession commitConfiguration];
                        self.flashModeBTN.hidden = NO;
                        [self setupFlashModeBTN];
                        [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:AVCaptureDevicePositionBack] forKey:PreferenceCameraDevice];
                        break;
                    }
                }
            }
        }
        
        if (finishReverse) {
            break;
        }
    }
}

- (IBAction)lightingControl:(id)sender {
    for (AVCaptureDeviceInput *input in self.captureSession.inputs) {
        if ([input device].position == AVCaptureDevicePositionBack) {
            AVCaptureDevice *captureDevice = [input device];
            if (captureDevice.isFlashAvailable) {
                NSError *error;
                if ([[input device] lockForConfiguration:&error]) {
                    switch (captureDevice.flashMode) {
                        case AVCaptureFlashModeOff:
                            if ([captureDevice isFlashModeSupported:AVCaptureFlashModeOn]) {
                                [captureDevice setFlashMode:AVCaptureFlashModeOn];
                                [self.flashModeBTN setTitle:@"FlashOn" forState:UIControlStateNormal];
                            }
                            break;
                            
                        case AVCaptureFlashModeOn:
                            if ([captureDevice isFlashModeSupported:AVCaptureFlashModeAuto]) {
                                [captureDevice setFlashMode:AVCaptureFlashModeAuto];
                                [self.flashModeBTN setTitle:@"FlashAuto" forState:UIControlStateNormal];
                            }
                            break;
                            
                        case AVCaptureFlashModeAuto:
                            if ([captureDevice isFlashModeSupported:AVCaptureFlashModeOff]) {
                                [captureDevice setFlashMode:AVCaptureFlashModeOff];
                                [self.flashModeBTN setTitle:@"FlashOff" forState:UIControlStateNormal];
                            }
                            break;
                            
                        default:
                            break;
                    }
                    [[input device] unlockForConfiguration];
                    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:captureDevice.flashMode] forKey:PreferenceFlashMode];
                } else {
                    NSLog(@"Change flash mode fail : error : %@", error.localizedDescription);
                }
            }
            break;
        }
    }
}

#pragma mark - Exception handler

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Functions

- (void)setCustomizedCameraUI
{
    [self setupFlashModeBTN];
}

- (void)setupFlashModeBTN
{
    for (AVCaptureDeviceInput *input in self.captureSession.inputs) {
        if ([input device].position == AVCaptureDevicePositionBack) {
            AVCaptureDevice *captureDevice = [input device];
            
            if ([[NSUserDefaults standardUserDefaults] objectForKey:PreferenceFlashMode]) {
                AVCaptureFlashMode flashMode = [[NSUserDefaults standardUserDefaults] integerForKey:PreferenceFlashMode];
                NSError *error;
                if ([captureDevice lockForConfiguration:&error]) {
                    [captureDevice setFlashMode:flashMode];
                    [captureDevice unlockForConfiguration];
                    switch (flashMode) {
                        case AVCaptureFlashModeOff:
                            [self.flashModeBTN setTitle:@"FlashOff" forState:UIControlStateNormal];
                            break;
                            
                        case AVCaptureFlashModeOn:
                            [self.flashModeBTN setTitle:@"FlashOn" forState:UIControlStateNormal];
                            break;
                            
                        case AVCaptureFlashModeAuto:
                            [self.flashModeBTN setTitle:@"FlashAuto" forState:UIControlStateNormal];
                            break;
                            
                        default:
                            break;
                    }
                } else {
                    NSLog(@"Change flash mode fail : error : %@", error.localizedDescription);
                }
            } else {
                switch (captureDevice.flashMode) {
                    case AVCaptureFlashModeOff:
                        [self.flashModeBTN setTitle:@"FlashOff" forState:UIControlStateNormal];
                        break;
                        
                    case AVCaptureFlashModeOn:
                        [self.flashModeBTN setTitle:@"FlashOn" forState:UIControlStateNormal];
                        break;
                        
                    case AVCaptureFlashModeAuto:
                        [self.flashModeBTN setTitle:@"FlashAuto" forState:UIControlStateNormal];
                        break;
                        
                    default:
                        break;
                }
            }
            break;
        } else {
            self.flashModeBTN.hidden = YES;
        }
    }
}

@end
