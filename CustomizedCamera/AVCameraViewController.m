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
#import "AVOverlayUIView.h"

@interface AVCameraViewController ()
@property (strong, nonatomic) AVCaptureSession *captureSession;
@property (strong, nonatomic) AVCaptureStillImageOutput *imageOutput;
@property (strong, nonatomic) UIView *cameraPreviewUIView;
@property (strong, nonatomic) IBOutlet AVOverlayUIView *avOverlayView;
@property (weak, nonatomic) IBOutlet UIButton *flashModeBTN;
@property (weak, nonatomic) IBOutlet UIButton *reverseBTN;
@property (nonatomic) BOOL enableTapToFocus;
@property (nonatomic) BOOL isFrontCamera;
@end

@implementation AVCameraViewController

#define PreferenceCameraDevice @"PreferenceCameraDevice"
#define PreferenceAVFlashMode @"PreferenceAVFlashMode"
#define PreferenceContinuallyFocus @"PreferenceContinuallyAutoFocus"
#define PreferenceFocusPOI @"PreferenceFocusPOI"
#define PreferenceEnableTapToFocus @"PreferenceEnableTapToFocus"

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
        //self.avOverlayView.enableTapToFocus = self.supportFocusPOI;
        self.avOverlayView.enableTapToFocus = YES;
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
    
    [[NSNotificationCenter defaultCenter] addObserverForName:AVCameraTouchToFocus object:nil queue:nil usingBlock:^(NSNotification *note) {
        NSDictionary *poiDic = (NSDictionary *)note.userInfo[FocusPOI];
        CGPoint poi = CGPointMake([((NSString *)poiDic[@"x"]) floatValue], [((NSString *)poiDic[@"y"]) floatValue]);
        //The origin for setFocusPointOfInterest and setExposurePointOfInterest is that
        //the CGPoint where {0,0} corresponds to the top left of the picture area,
        //and {1,1} corresponds to the bottom right in landscape mode with the
        //home button on the right—this applies even if the device is in portrait mode.
        //So, we need to convert the poi for the special origin.
        CGPoint convertedPOI = [self convertLTtoRTWithPoint:poi];
        CGPoint convertedPOIInPercentage = CGPointMake(convertedPOI.x/[UIScreen mainScreen].bounds.size.height, convertedPOI.y/[UIScreen mainScreen].bounds.size.width);
        
        for (AVCaptureDeviceInput *input in self.captureSession.inputs) {
            AVCaptureDevice *captureDevice = [input device];
            NSError *error;
            if ([captureDevice lockForConfiguration:&error]) {
                NSLog(@"%@", captureDevice.localizedName);
                if ([captureDevice isFocusPointOfInterestSupported]) {
                    [captureDevice setFocusPointOfInterest:convertedPOIInPercentage];
                    if ([captureDevice isFocusModeSupported:AVCaptureFocusModeAutoFocus]) {
                        [captureDevice setFocusMode:AVCaptureFocusModeAutoFocus];
                    } else {
                        NSLog(@"Can not support AutoFocus.");
                    }
                } else {
                    NSLog(@"Can not support POI focus.");
                }
                
                if ([captureDevice isExposurePointOfInterestSupported]) {
                    [captureDevice setExposurePointOfInterest:convertedPOIInPercentage];
                    if ([captureDevice isExposureModeSupported:AVCaptureExposureModeAutoExpose]) {
                        [captureDevice setExposureMode:AVCaptureExposureModeAutoExpose];
                    } else {
                        NSLog(@"Can not support AutoExpose.");
                        if ([captureDevice isExposureModeSupported:AVCaptureExposureModeContinuousAutoExposure]) {
                            [captureDevice setExposureMode:AVCaptureExposureModeContinuousAutoExposure];
                        } else {
                            NSLog(@"Can not support ContinuousAutoExposure also.");
                        }
                    }
                } else {
                    NSLog(@"Can not support POI exposure.");
                }
                
                /*
                if ([captureDevice isWhiteBalanceModeSupported:AVCaptureWhiteBalanceModeAutoWhiteBalance]) {
                    [captureDevice setWhiteBalanceMode:AVCaptureWhiteBalanceModeAutoWhiteBalance];
                } else {
                    NSLog(@"Can not support AutoWhiteBalance");
                    if ([captureDevice isWhiteBalanceModeSupported:AVCaptureWhiteBalanceModeContinuousAutoWhiteBalance]) {
                        [captureDevice setWhiteBalanceMode:AVCaptureWhiteBalanceModeContinuousAutoWhiteBalance];
                    } else {
                        NSLog(@"Can not support ContinuousAutoWhiteBalance also");
                    }
                }
                */
                [captureDevice unlockForConfiguration];
            } else {
                NSLog(@"Touch to set focus fail.");
            }
        }
    }];
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
                            if (preferenceDevicePosition == AVCaptureDevicePositionBack) {
                                self.isFrontCamera = NO;
                            } else {
                                self.isFrontCamera = YES;
                            }
                            [self setupFocusWithDevice:[deviceInput device]];
                            [_captureSession addInput:deviceInput];
                            break;
                        }
                    }
                    
                } else {
                    //The default camera device is back camera.
                    if ([device position] == AVCaptureDevicePositionBack) {
                        AVCaptureDeviceInput *deviceInput = [AVCaptureDeviceInput deviceInputWithDevice:device error:&error];
                        if (error) {
                            NSLog(@"Got error when set the device input.");
                            return nil;
                        } else {
                            self.isFrontCamera = NO;
                            [self setupFocusWithDevice:[deviceInput device]];
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
    [[NSNotificationCenter defaultCenter] removeObserver:self];
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
                UIImage *capturedImage;
                if (self.isFrontCamera) {
                    capturedImage = [UIImage imageWithCGImage:[UIImage imageWithData:imageData].CGImage scale:capturedImage.scale orientation:UIImageOrientationLeftMirrored];
                } else {
                    capturedImage = [UIImage imageWithData:imageData];
                }
                [[NSNotificationCenter defaultCenter] postNotificationName:ImageReadyFromAVCapture object:nil userInfo:@{CapturedImageData:capturedImage}];
                
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
                        [self setupFocusWithDevice:[deviceInput device]];
                        self.isFrontCamera =YES;
                        
                        [self.captureSession beginConfiguration];
                        [self.captureSession removeInput:oldInput];
                        [self.captureSession addInput:deviceInput];
                        [self.captureSession commitConfiguration];
                        self.flashModeBTN.hidden = YES;
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
                        [self setupFocusWithDevice:[deviceInput device]];
                        self.isFrontCamera = NO;
                        
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
                    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:captureDevice.flashMode] forKey:PreferenceAVFlashMode];
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
            if (captureDevice.isFlashAvailable) {
                if ([[NSUserDefaults standardUserDefaults] objectForKey:PreferenceAVFlashMode]) {
                    AVCaptureFlashMode flashMode = [[NSUserDefaults standardUserDefaults] integerForKey:PreferenceAVFlashMode];
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
            } else {
                self.flashModeBTN.hidden = YES;
            }
            break;
        } else {
            self.flashModeBTN.hidden = YES;
        }
    }
}

- (void)setupFocusWithDevice:(AVCaptureDevice *)captureDevice
{
    NSError *error;
    self.enableTapToFocus = YES;
    if ([captureDevice lockForConfiguration:&error]) {
        NSLog(@"%@", captureDevice.localizedName);
        if ([[NSUserDefaults standardUserDefaults] boolForKey:PreferenceEnableTapToFocus]) {
            if ([captureDevice isFocusPointOfInterestSupported]) {
                [captureDevice setFocusPointOfInterest:CGPointMake(0.5f, 0.5f)];
                if ([captureDevice isFocusModeSupported:AVCaptureFocusModeAutoFocus]) {
                    [captureDevice setFocusMode:AVCaptureFocusModeAutoFocus];
                } else {
                    NSLog(@"Can not support AutoFocus.");
                }
            } else {
                NSLog(@"Can not support POI focus.");
                /*
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Focus Setting" message:@"Can not support FocusPointOfInterest" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
                [alertView show];
                */
            }
            
            if ([captureDevice isExposurePointOfInterestSupported]) {
                [captureDevice setExposurePointOfInterest:CGPointMake(0.5f, 0.5f)];
                if ([captureDevice isExposureModeSupported:AVCaptureExposureModeAutoExpose]) {
                    [captureDevice setExposureMode:AVCaptureExposureModeAutoExpose];
                } else {
                    NSLog(@"Can not support AutoExpose.");
                    if ([captureDevice isExposureModeSupported:AVCaptureExposureModeContinuousAutoExposure]) {
                        [captureDevice setExposureMode:AVCaptureExposureModeContinuousAutoExposure];
                    } else {
                        NSLog(@"Can not support ContinuousAutoExposure also.");
                    }
                }
            } else {
                NSLog(@"Can not support POI exposure.");
            }
            
            /*
            if ([captureDevice isWhiteBalanceModeSupported:AVCaptureWhiteBalanceModeAutoWhiteBalance]) {
                [captureDevice setWhiteBalanceMode:AVCaptureWhiteBalanceModeAutoWhiteBalance];
            } else {
                NSLog(@"Can not support AutoWhiteBalance");
                if ([captureDevice isWhiteBalanceModeSupported:AVCaptureWhiteBalanceModeContinuousAutoWhiteBalance]) {
                    [captureDevice setWhiteBalanceMode:AVCaptureWhiteBalanceModeContinuousAutoWhiteBalance];
                } else {
                    NSLog(@"Can not support ContinuousAutoWhiteBalance also");
                }
            }
            */
        } else {
        //If the device doesn't support focus POI or user disable the focus POI option in settings.
            self.enableTapToFocus = NO;
            if ([[NSUserDefaults standardUserDefaults] boolForKey:PreferenceContinuallyFocus]) {
                if ([captureDevice isFocusModeSupported:AVCaptureFocusModeContinuousAutoFocus]) {
                    [captureDevice setFocusMode:AVCaptureFocusModeContinuousAutoFocus];
                } else {
                    NSLog(@"Can not support ContinuousAutoFocus.");
                    /*
                    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Focus Setting" message:@"Can not set AVCaptureFocusModeContinuousAutoFocus" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
                    [alertView show];
                    */
                }
            } else {
                if ([captureDevice isFocusModeSupported:AVCaptureFocusModeAutoFocus]) {
                    [captureDevice setFocusMode:AVCaptureFocusModeAutoFocus];
                } else {
                    NSLog(@"Can not support AVCaptureFocusModeAutoFocus.");
                    /*
                    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Focus Setting" message:@"Can not set AVCaptureFocusModeAutoFocus" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
                    [alertView show];
                    */
                }
            }
        
            if ([[NSUserDefaults standardUserDefaults] boolForKey:PreferenceFocusPOI]) {
                if ([captureDevice isFocusPointOfInterestSupported]) {
                    [captureDevice setFocusPointOfInterest:CGPointMake(0.5f, 0.5f)];
                } else {
                    NSLog(@"Can not support focus POI.");
                    /*
                    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Focus Setting" message:@"Can not set Focus POI" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
                    [alertView show];
                    */
                }
            }
        }
        
        [captureDevice unlockForConfiguration];
    } else {
        NSLog(@"Set up focus fail. Error : %@", error.localizedDescription);
    }
}

- (CGPoint)convertLTtoRTWithPoint:(CGPoint)targetPoint
{
    CGPoint convertedPoint = CGPointMake(targetPoint.y, [UIScreen mainScreen].bounds.size.width - targetPoint.x);
    
    return convertedPoint;
}

@end
