//
//  CustomizedCameraViewController.m
//  CustomizedCamera
//
//  Created by Ocean Lin on 2014/2/11.
//  Copyright (c) 2014年 PicsureHunt. All rights reserved.
//

#import "CustomizedCameraViewController.h"

@interface CustomizedCameraViewController () <UINavigationControllerDelegate, UIImagePickerControllerDelegate>
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (strong, nonatomic) UIImagePickerController *imagePickerController;
@property (strong, nonatomic) IBOutlet UIView *overlayView;
@property (weak, nonatomic) IBOutlet UIButton *flashModeBTN;
@property (nonatomic) BOOL isVersion4;
@end

@implementation CustomizedCameraViewController

#define PreferenceFlashMode @"PreferenceFlashMode"
#define PreferenceDefaultCameraUI @"defaultCameraUI"

#pragma mark - Initialization

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    CGRect screenBounds = [[UIScreen mainScreen] bounds];
    if (screenBounds.size.height >= 568.0) {
        self.isVersion4 = NO;
    } else {
        self.isVersion4 = YES;
    }
    //    NSLog(@"Height : %f", screenBounds.size.height);
    //    NSLog(@"Width : %f", screenBounds.size.width);
   
//    [[NSBundle mainBundle] loadNibNamed:@"OverlayView" owner:self options:nil];
//    [self.overlayView setFrame:CGRectMake(0, 0, screenBounds.size.width, screenBounds.size.height)];
//    [self.view addSubview:self.overlayView];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (UIImagePickerController *)imagePickerController
{
    if (!_imagePickerController) {
        _imagePickerController = [[UIImagePickerController alloc] init];
    }
    
    return _imagePickerController;
}

#pragma mark - Delegate/Event handler

- (IBAction)enableCamera:(id)sender {
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        self.imagePickerController.delegate = self;
        self.imagePickerController.mediaTypes = [UIImagePickerController availableMediaTypesForSourceType:UIImagePickerControllerSourceTypeCamera];
        self.imagePickerController.sourceType = UIImagePickerControllerSourceTypeCamera;
        
        if ([[NSUserDefaults standardUserDefaults] boolForKey:PreferenceDefaultCameraUI]) {
            self.imagePickerController.showsCameraControls = YES;
        } else {
            [self setCustomizedCameraUI];
            self.imagePickerController.showsCameraControls = NO;
        }
        
        [self presentViewController:self.imagePickerController animated:YES completion:NULL];
    } else {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Enable camera" message:@"Camera is not available." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alertView show];
    }
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    self.imageView.image = info[UIImagePickerControllerOriginalImage];
    [self dismissViewControllerAnimated:YES completion:NULL];
    self.imagePickerController = nil;
    if (self.imagePickerController) {
        NSLog(@"picker instance is still there.");
    }
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [self dismissViewControllerAnimated:YES completion:NULL];
    self.imagePickerController = nil;
    if (self.imagePickerController) {
        NSLog(@"picker instance is still there.");
    }
}

//- (IBAction)capturePhoto:(id)sender
//{
//    [self.imagePickerController takePicture];
//}

#pragma mark - OverlayView Delegate/Event handler

- (IBAction)drawContent:(id)sender {
}


- (IBAction)textContent:(id)sender {
}


- (IBAction)importPhoto:(id)sender {
}

- (IBAction)captureWithSend:(id)sender {
    [self.imagePickerController takePicture];
}

- (IBAction)reverseCamera:(id)sender {
    if (self.imagePickerController.cameraDevice == UIImagePickerControllerCameraDeviceRear) {
        self.imagePickerController.cameraDevice = UIImagePickerControllerCameraDeviceFront;
        self.flashModeBTN.hidden = YES;
    } else {
        self.imagePickerController.cameraDevice = UIImagePickerControllerCameraDeviceRear;
        self.flashModeBTN.hidden = NO;
    }
}

- (IBAction)lightingControl:(id)sender {
    NSUserDefaults *userDefault = [NSUserDefaults standardUserDefaults];
    switch (self.imagePickerController.cameraFlashMode) {
        case UIImagePickerControllerCameraFlashModeAuto:
            [self.flashModeBTN setTitle:@"FlashOff" forState:UIControlStateNormal];
            self.imagePickerController.cameraFlashMode = UIImagePickerControllerCameraFlashModeOff;
            [userDefault setObject:[NSNumber numberWithInt:UIImagePickerControllerCameraFlashModeOff] forKey:PreferenceFlashMode];
            break;
            
        case UIImagePickerControllerCameraFlashModeOff:
            [self.flashModeBTN setTitle:@"FlashOn" forState:UIControlStateNormal];
            self.imagePickerController.cameraFlashMode = UIImagePickerControllerCameraFlashModeOn;
            [userDefault setObject:[NSNumber numberWithInt:UIImagePickerControllerCameraFlashModeOn] forKey:PreferenceFlashMode];
            break;
            
        case UIImagePickerControllerCameraFlashModeOn:
            [self.flashModeBTN setTitle:@"FlashAuto" forState:UIControlStateNormal];
            self.imagePickerController.cameraFlashMode = UIImagePickerControllerCameraFlashModeAuto;
            [userDefault setObject:[NSNumber numberWithInt:UIImagePickerControllerCameraFlashModeAuto] forKey:PreferenceFlashMode];
            break;
            
        default:
            break;
    }
}

#pragma mark - Functions

- (void)setCustomizedCameraUI
{
//Add a button to the cameraOverlayView directly
//    UIButton *captureBTN = [[UIButton alloc] init];
//    [captureBTN setImage:[UIImage imageNamed:@"camera_btn_n"] forState:UIControlStateNormal];
//    
//    CGRect captureBTNFrame = CGRectMake(50, 50, 50, 50);
//    captureBTN.frame = captureBTNFrame;
//    
//    [captureBTN addTarget:self action:@selector(capturePhoto:) forControlEvents:UIControlEventTouchUpInside];
//    
//    [imagePicker.cameraOverlayView addSubview:captureBTN];
    
    [[NSBundle mainBundle] loadNibNamed:@"OverlayView" owner:self options:nil];
    //self.overlayView.frame = self.imagePickerController.cameraOverlayView.frame;
    [self.overlayView setFrame:CGRectMake(0, 0, [[UIScreen mainScreen] bounds].size.width, [[UIScreen mainScreen] bounds].size.height)];
    self.imagePickerController.cameraOverlayView = self.overlayView;
    NSUserDefaults *userDefault = [NSUserDefaults standardUserDefaults];
    UIImagePickerControllerCameraFlashMode mode = (NSInteger)[userDefault integerForKey:PreferenceFlashMode];
    switch (mode) {
        case UIImagePickerControllerCameraFlashModeAuto:
            [self.flashModeBTN setTitle:@"FlashAuto" forState:UIControlStateNormal];
            break;
            
        case UIImagePickerControllerCameraFlashModeOff:
            [self.flashModeBTN setTitle:@"FlashOff" forState:UIControlStateNormal];
            break;
            
        case UIImagePickerControllerCameraFlashModeOn:
            [self.flashModeBTN setTitle:@"FlashOn" forState:UIControlStateNormal];
            break;
            
        default:
            break;
    }
    self.imagePickerController.cameraFlashMode = mode;

    self.overlayView = nil;
}

@end
