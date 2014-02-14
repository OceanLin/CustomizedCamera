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

@end

@implementation CustomizedCameraViewController

#pragma mark - Initialization

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
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
        
        [self setCustomizedCameraUI];
        
        self.imagePickerController.showsCameraControls = NO;
        
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
}

- (IBAction)lightingControl:(id)sender {
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
    self.imagePickerController.cameraOverlayView = self.overlayView;
    self.overlayView = nil;
}

@end
