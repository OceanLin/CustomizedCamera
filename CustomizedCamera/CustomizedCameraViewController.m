//
//  CustomizedCameraViewController.m
//  CustomizedCamera
//
//  Created by Ocean Lin on 2014/2/11.
//  Copyright (c) 2014年 PicsureHunt. All rights reserved.
//

#import "CustomizedCameraViewController.h"
#import <MobileCoreServices/MobileCoreServices.h> //For kUTTypeImage
#import "DrawingUIView.h"
#import "AVCameraViewController.h"
#import "InternalNotificationHelper.h"

@interface CustomizedCameraViewController () <UINavigationControllerDelegate, UIImagePickerControllerDelegate, UITextViewDelegate>
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (strong, nonatomic) UIImagePickerController *imagePickerController;
@property (strong, nonatomic) IBOutlet UIView *overlayView;
@property (weak, nonatomic) IBOutlet UIButton *flashModeBTN;
@property (nonatomic) BOOL isVersion4;
@property (weak, nonatomic) IBOutlet UITextView *inputTextView;
@property (strong, nonatomic) UIView *combinationView;
@property (strong, nonatomic) UIImageView *capturedImageView;
@property (strong, nonatomic) IBOutlet DrawingUIView *drawingView;

@property (strong, nonatomic) AVCameraViewController *avCameraVC;
@end

@implementation CustomizedCameraViewController

#define PreferenceFlashMode @"PreferenceFlashMode"
#define PreferenceDefaultCameraUI @"defaultCameraUI"
#define PreferenceSaveToPhotoAlbum @"saveToPhotoAlbum"
#define PreferenceAVCamera @"enableAVCamera"
#define CaptureResultImageGap 20.0
#define CaptureResultImageTotalGap CaptureResultImageGap*2

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
    
    self.inputTextView.delegate = self;
    
    //self.imageView.backgroundColor = [UIColor redColor];
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

- (UIView *)combinationView
{
    if (!_combinationView) {
        _combinationView = [[UIView alloc] initWithFrame:CGRectZero];
    }
    
    return _combinationView;
}

- (UIImageView *)capturedImageView
{
    if (!_capturedImageView) {
        _capturedImageView = [[UIImageView alloc] init];
    }
    
    return _capturedImageView;
}

#pragma mark - Delegate/Event handler

- (IBAction)enableCamera:(id)sender {
    if ([[NSUserDefaults standardUserDefaults] objectForKey:PreferenceAVCamera] && [[NSUserDefaults standardUserDefaults] boolForKey:PreferenceAVCamera]) {
        self.avCameraVC = [[AVCameraViewController alloc] init];
        [self presentViewController:self.avCameraVC animated:YES completion:NULL];
        [[NSNotificationCenter defaultCenter] addObserverForName:ImageReadyFromAVCapture object:nil queue:nil usingBlock:^(NSNotification *note) {
            UIImage *capturedImage = [UIImage imageWithData:note.userInfo[CapturedImageData]];
            self.imageView.image = capturedImage;
        }];
    } else {
        if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
            self.imagePickerController.delegate = self;
            self.imagePickerController.mediaTypes = [UIImagePickerController availableMediaTypesForSourceType:UIImagePickerControllerSourceTypeCamera];
            self.imagePickerController.sourceType = UIImagePickerControllerSourceTypeCamera;
            if (!self.isVersion4) {
                CGSize screenBounds = [UIScreen mainScreen].bounds.size;
                CGFloat cameraAspectRatio = 4.0f/3.0f;
                CGFloat camViewHeight = screenBounds.width * cameraAspectRatio;
                CGFloat scale = screenBounds.height / camViewHeight + 0.5;
            
    //        NSLog(@"Camera scale : %f", scale);
    //        NSLog(@"camViewH %f", camViewHeight);
                self.imagePickerController.cameraViewTransform = CGAffineTransformMakeTranslation(0, (screenBounds.height - camViewHeight) / 2.0);
                self.imagePickerController.cameraViewTransform = CGAffineTransformScale(self.imagePickerController.cameraViewTransform, scale, scale);
            }
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
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    if (self.imagePickerController.sourceType == UIImagePickerControllerSourceTypeCamera) {
        UIImage *capturedImage = info[UIImagePickerControllerOriginalImage];
        CGSize screenBounds = [UIScreen mainScreen].bounds.size;
        CGFloat cameraAspectRatio = capturedImage.size.width/capturedImage.size.height;
        CGFloat camViewWidth = screenBounds.height * cameraAspectRatio;
        capturedImage = [self resizeImage:info[UIImagePickerControllerOriginalImage] scaleToSize:CGSizeMake(camViewWidth, screenBounds.height)];
        CGFloat offectX = (capturedImage.size.width - screenBounds.width) / 2;
        capturedImage = [self cropImage:capturedImage withRect:CGRectMake(offectX, 0, screenBounds.width, screenBounds.height)];

        if (self.imagePickerController.cameraDevice == UIImagePickerControllerCameraDeviceFront) {
            UIImage *reverseImage = [UIImage imageWithCGImage:capturedImage.CGImage scale:capturedImage.scale orientation:UIImageOrientationUpMirrored];
            self.capturedImageView = [[UIImageView alloc] initWithImage:reverseImage];
        } else {
            self.capturedImageView = [[UIImageView alloc] initWithImage:capturedImage];
        }
    } else {
        UIImage *pickedImage;
        pickedImage = info[UIImagePickerControllerEditedImage];
        if (!pickedImage) {
            pickedImage = info[UIImagePickerControllerOriginalImage];
        }
        
        //We should based on pickedImage's aspect ratio to adjust the imageView's frame (size, location).
        self.capturedImageView.image = pickedImage;
    }
    
    if ([self shouldCombineImage]) {
        //Combine the text and line and captured image as an image
        [self.combinationView addSubview:self.capturedImageView];
        UIImageView *drawingImageView = [[UIImageView alloc] initWithImage:self.drawingView.incrementalPathImage];
        [self.combinationView addSubview:drawingImageView];
        [self.combinationView addSubview:self.inputTextView];
        UIGraphicsBeginImageContext(self.capturedImageView.frame.size);
        [[self.combinationView layer] renderInContext:UIGraphicsGetCurrentContext()];
        UIImage *combinedImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        //Adjust the result imageView to correct size and position
        //However, the size is controlled by the image but not the imageView.
        //If we want to resize it, we need to resize the image.
        CGSize screenBounds = [UIScreen mainScreen].bounds.size;
        CGFloat maxH = screenBounds.height - CaptureResultImageTotalGap;
        CGFloat maxW = screenBounds.width - CaptureResultImageTotalGap;
        CGFloat hRatio = maxH / self.imageView.frame.size.height;
        CGFloat wRatio = maxW / self.imageView.frame.size.width;
        CGFloat scaleRatio = hRatio < wRatio ? hRatio : wRatio;
        
        self.imageView.transform = CGAffineTransformMakeScale(scaleRatio, scaleRatio);
        self.imageView.transform = CGAffineTransformMakeTranslation(((screenBounds.width-self.imageView.frame.size.width)/2)-self.imageView.frame.origin.x, ((screenBounds.height-self.imageView.frame.size.height)/2)-self.imageView.frame.origin.y);
        self.imageView.contentMode = UIViewContentModeScaleAspectFit;
        self.imageView.image = combinedImage;

        if ([[NSUserDefaults standardUserDefaults] boolForKey:PreferenceSaveToPhotoAlbum]) {
            UIImageWriteToSavedPhotosAlbum(combinedImage, nil, nil, nil);
        }
        
        self.combinationView = nil;
    } else {
        [self setPreviewImageViewWithImageView:self.capturedImageView];
        self.capturedImageView = nil;
    }
    
    [self dismissViewControllerAnimated:YES completion:NULL];
    self.imagePickerController = nil;
//    if (self.imagePickerController) {
//        NSLog(@"picker instance is still there.");
//    }
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [self dismissViewControllerAnimated:YES completion:NULL];
    self.imagePickerController = nil;
//    if (self.imagePickerController) {
//        NSLog(@"picker instance is still there.");
//    }
}

#pragma mark - OverlayView Delegate/Event handler

- (IBAction)drawContent:(id)sender {
    [self.drawingView controlButtonaHidden:NO];
    [self overlayViewButtonsHidden:YES];
}


- (IBAction)textContent:(id)sender {
    self.inputTextView.userInteractionEnabled = YES;
    [self.inputTextView setSelectedRange:NSMakeRange(0, self.inputTextView.text.length)];
    [self.inputTextView becomeFirstResponder];
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    //When user tap the Done button on keyboard, it will hide the keyboard.
    if ([text isEqualToString:@"\n"]) {
        [textView resignFirstResponder];
        self.inputTextView.userInteractionEnabled = NO;
    }
    
    return YES;
}

- (IBAction)importPhoto:(id)sender {
    [self dismissViewControllerAnimated:NO completion:NULL];
    
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) {
        self.imagePickerController.delegate = self;
        //For the kUTTypeImage, we should import <MobileCoreServices/MobileCoreServices.h>
        self.imagePickerController.mediaTypes = [[NSArray alloc] initWithObjects: (NSString *) kUTTypeImage, nil];
        //self.imagePickerController.mediaTypes = [UIImagePickerController availableMediaTypesForSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
        self.imagePickerController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        self.imagePickerController.allowsEditing = YES;
        
        [self presentViewController:self.imagePickerController animated:YES completion:NULL];
    } else {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Import from library" message:@"Photo library is not available." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alertView show];
    }
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

#pragma mark - DrawingView Delegate/Event handler

- (IBAction)finishDraw:(id)sender {
    [self.drawingView controlButtonaHidden:YES];
    [self overlayViewButtonsHidden:NO];
}

- (IBAction)drawingColorSelection:(id)sender {
    UIButton *selectedBTN = (UIButton *)sender;
    [selectedBTN.layer setBorderWidth:3.0f];
    [selectedBTN.layer setBorderColor:[UIColor purpleColor].CGColor];
    self.drawingView.currentPathColor = selectedBTN.backgroundColor;
    
    for (id object in selectedBTN.superview.subviews) {
        if ([object isKindOfClass:[UIButton class]]) {
            UIButton *targetBTN = (UIButton *)object;
            if (targetBTN != sender && ![targetBTN.titleLabel.text isEqualToString:@"DONE"]) {
                [targetBTN.layer setBorderWidth:0.0f];
            }
        }
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
    
    //For text input
    self.inputTextView.backgroundColor = [UIColor clearColor];
    self.inputTextView.delegate = self;
    self.inputTextView.userInteractionEnabled = NO;
    [self setInputTextProperty];
    
    //For flash mode
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
    
    //For drawing
    [[NSBundle mainBundle] loadNibNamed:@"DrawingView" owner:self options:nil];
    [self.overlayView setFrame:CGRectMake(0, 0, [[UIScreen mainScreen] bounds].size.width, [[UIScreen mainScreen] bounds].size.height)];
    [self.overlayView addSubview:self.drawingView];
    [self.overlayView sendSubviewToBack:self.drawingView];

    //self.overlayView = nil;
}

- (void)setPreviewImageViewWithImage:(UIImage *)image
{
    self.imageView.image = image;
}

- (void)setPreviewImageViewWithImageView:(UIImageView *)imageView
{
    self.imageView = imageView;
}

- (BOOL)shouldCombineImage
{
    //We can check if there is addition drawing and text input.
    return YES;
}

- (void)setInputTextProperty
{
    self.inputTextView.layer.shadowColor = [[UIColor blackColor] CGColor];
    self.inputTextView.layer.shadowOffset = CGSizeMake(1.0f, 1.0f);
    self.inputTextView.layer.shadowOpacity = 1.0f;
    self.inputTextView.layer.shadowRadius = 1.0f;
}

- (void)overlayViewButtonsHidden:(BOOL)hidden
{
    for (id object in self.overlayView.subviews) {
        if ([object isKindOfClass:[UIButton class]]) {
            ((UIButton *)object).hidden = hidden;
        }
    }
}

- (UIImage *)resizeImage:(UIImage *)image scaleToSize:(CGSize)newSize
{
    UIGraphicsBeginImageContext(newSize);
    [image drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return newImage;
}

- (UIImage *)cropImage:(UIImage *)image withRect:(CGRect)cropRect
{
    cropRect = CGRectMake(cropRect.origin.x*image.scale, cropRect.origin.y*image.scale, cropRect.size.width*image.scale, cropRect.size.height*image.scale);
    CGImageRef imageRef = CGImageCreateWithImageInRect([image CGImage], cropRect);
    UIImage *croppedImage = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    
    return croppedImage;
}

@end
