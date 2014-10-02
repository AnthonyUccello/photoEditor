//
//  ViewController.m
//  pumpupPhotoEditor
//
//  Created by Anthony Uccello on 2014-09-30.
//  Copyright (c) 2014 pumpup inc. All rights reserved.
//

#import "TakePhotoViewController.h"
@import AVFoundation;
#import "EditPhotoViewController.h"
#import "Utility.h"

@interface TakePhotoViewController ()

@end

@implementation TakePhotoViewController

//consts
float SCREEN_H;
float SCREEN_W;
EditPhotoViewController* _editPhotoViewController;

//top bar ui elements
UIView* _topBar;
UIView* _cameraFeed;
UILabel* _closeButton;
UILabel* _skipButton;

//lower bar UIElements
UIView* _lowerBar;
UIButton* _swapCameraButton;
UIButton* _flashButton;
UIButton* _gridLinesButton;
UIButton* _takePhoto;

//camera elements
AVCaptureVideoPreviewLayer *_captureVideoPreviewLayer;
AVCaptureStillImageOutput* _stillImageOutput;
AVCaptureSession *_session;
AVCaptureDevice *_frontCamera;
AVCaptureDevice *_backCamera;
AVCaptureDeviceInput *_cameraInput;
UIImage* _lastPhoto;
BOOL _frontCameraUsed;
BOOL _flashEnabled;
UIImageOrientation _lastPhotoOrientation;

//grid lines
NSMutableArray* _lines;
BOOL _addGridLines;
BOOL _pictureInProcess;

//photo selection
UIButton* _pickPhotoButton;

//===initializers===///

//initalizes all the constants
//TODO: move to utilty class
-(void)initConstants
{
    SCREEN_H = [UIScreen mainScreen].bounds.size.height;
    SCREEN_W = [UIScreen mainScreen].bounds.size.width;
    _frontCameraUsed = NO;
}

//intializes all top bar objects
-(void)initTopBar
{
    _topBar = [[UIView alloc] initWithFrame:CGRectMake(0,0,[UIScreen mainScreen].bounds.size.width, 30)];
    _topBar.backgroundColor = [UIColor colorWithRed:45.0/255.0 green:189.0/255.0 blue:242.0/255.0 alpha:1.0f];
    [self.view addSubview:_topBar];
    
    //TODO: minimize text bounds
    _closeButton = [Utility createTextButtonWithText:@"Cancel" Size:CGRectMake(10,8,50,18) Selector:@selector(closeHandle) Target:self];
    [self.view addSubview:_closeButton];
    
    _skipButton = [Utility createTextButtonWithText:@"Skip" Size:CGRectMake(SCREEN_W - 40,8,50,18) Selector:@selector(skipHandle) Target:self];
    [self.view addSubview:_skipButton];
}

//initalizes lower bar objects
-(void)initLowerBar
{
    _lowerBar = [[UIView alloc] initWithFrame:CGRectMake(0,[UIScreen mainScreen].bounds.size.width + 30,[UIScreen mainScreen].bounds.size.width, 50)];
    _lowerBar.backgroundColor = [UIColor colorWithRed:45.0/255.0 green:189.0/255.0 blue:242.0/255.0 alpha:1.0f];
    [self.view addSubview:_lowerBar];
    
    _swapCameraButton = [Utility createButtonImageName:@"swapCamera" Rect:CGRectMake([UIScreen mainScreen].bounds.size.width/2 - 22, [UIScreen mainScreen].bounds.size.width + 30, 44, 44) Selector:@selector(swapCameraHandle) Target:self];
    [self.view addSubview:_swapCameraButton];
    
    _flashButton = [Utility createButtonImageName:@"flashOff" Rect:CGRectMake([UIScreen mainScreen].bounds.size.width - 50, [UIScreen mainScreen].bounds.size.width + 30, 44, 44) Selector:@selector(flashHandle) Target:self];
    [self.view addSubview:_flashButton];
    
    _gridLinesButton = [Utility createButtonImageName:@"gridLines" Rect:CGRectMake(10, [UIScreen mainScreen].bounds.size.width + 30, 44, 44) Selector:@selector(gridHandle) Target:self];
    [self.view addSubview:_gridLinesButton];
    
    _takePhoto = [Utility createButtonImageName:@"takePhoto" Rect:CGRectMake([UIScreen mainScreen].bounds.size.width/2 - 233, [UIScreen mainScreen].bounds.size.width + 100, 150, 150) Selector:@selector(takePhotoHandle) Target:self];
    [self.view addSubview:_takePhoto];
    
    _pickPhotoButton = [Utility createButtonImageName:@"jenny" Rect:CGRectMake([UIScreen mainScreen].bounds.size.width/2 + 133, [UIScreen mainScreen].bounds.size.width + 100, 150, 150) Selector:@selector(selectPictureHandle) Target:self];
    [self.view addSubview:_pickPhotoButton];
}

//creates the preview layer that displayes the live feed to the user
- (void) initCamera
{
    _pictureInProcess = NO;//set flag to allow click
    _session = [[AVCaptureSession alloc] init];//coordinate the flow of data from AV input devices to outputs.
    _session.sessionPreset = AVCaptureSessionPresetPhoto;
    
    _captureVideoPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:_session];//is a subclass of CALayer that you use to display video as it is being captured by an input device.
    [_captureVideoPreviewLayer setVideoGravity:AVLayerVideoGravityResize];
    
    _captureVideoPreviewLayer.frame = CGRectMake(0,0,SCREEN_W,SCREEN_W);
    [self.view.layer addSublayer:_captureVideoPreviewLayer];
    
    _cameraFeed = [[UIView alloc] initWithFrame:CGRectMake(0,0,SCREEN_W,SCREEN_W)];
    CALayer *viewLayer = [_cameraFeed layer];
    [viewLayer setMasksToBounds:YES];
    
    [_captureVideoPreviewLayer setFrame:CGRectMake(0,30, SCREEN_W, SCREEN_W)];
    
    NSArray *devices = [AVCaptureDevice devices];
    
    for (AVCaptureDevice *device in devices)
    {
        if ([device hasMediaType:AVMediaTypeVideo])
        {
            if ([device position] == AVCaptureDevicePositionBack)
            {
                _backCamera = device;
            }
            else {
                _frontCamera = device;
            }
        }
    }
    
    NSError *error = nil;
    _cameraInput = [AVCaptureDeviceInput deviceInputWithDevice:_backCamera error:&error];
    [_session addInput:_cameraInput];
    _stillImageOutput = [[AVCaptureStillImageOutput alloc] init];
    NSDictionary *outputSettings = [[NSDictionary alloc] initWithObjectsAndKeys: AVVideoCodecJPEG, AVVideoCodecKey, nil];
    [_stillImageOutput setOutputSettings:outputSettings];
    [_session addOutput:_stillImageOutput];
    [_session startRunning];
    
    UITapGestureRecognizer *singleFingerTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(focusHandle:)];
    [self.view addGestureRecognizer:singleFingerTap];
}

//===implementation===//

//handle all initializations
- (void)viewDidLoad {
    
    [super viewDidLoad];
    [self initConstants];
    [self initTopBar];
    [self initLowerBar];
    [self initCamera];
    _lines = [[NSMutableArray alloc] init];
    _addGridLines = NO;
}

-(BOOL)prefersStatusBarHidden{
    return YES;
}

//switch to edit photo view
- (void)loadEditPhotoView
{
    if(!_editPhotoViewController)
    {
        UIStoryboard* board = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
        _editPhotoViewController = [board instantiateViewControllerWithIdentifier:@"editPhoto"];
    }
    [self dismissViewControllerAnimated:NO completion:nil];
    [_editPhotoViewController loadImage:_lastPhoto Orientation:_lastPhotoOrientation];
    [self presentViewController:_editPhotoViewController animated:NO completion:nil];
}

//creates a line
-(UIView*)createLine:(CGRect)rect
{
    UIView *lineView = [[UIView alloc] initWithFrame:rect];
    lineView.backgroundColor = [UIColor whiteColor];
    return lineView;
}

//create the 4 lines that appear as a grid over the camera feed
-(void)createLines
{
    float spacer = self.view.bounds.size.width/3;

    UIView* line = [self createLine:CGRectMake(0, spacer + 30, self.view.bounds.size.width, 1)];
    [self.view addSubview:line];
    [_lines addObject:line];
    
    line = [self createLine:CGRectMake(0,spacer*2 + 30, self.view.bounds.size.width, 1)];
    [self.view addSubview:line];
    [_lines addObject:line];
    
    line = [self createLine:CGRectMake(spacer,30, 1, self.view.bounds.size.width)];
    [self.view addSubview:line];
    [_lines addObject:line];
    
    line = [self createLine:CGRectMake(spacer*2,30, 1, self.view.bounds.size.width)];
    [self.view addSubview:line];
    [_lines addObject:line];
}

//===handlers===///

//TODO: integrate with trigger.io
-(void)closeHandle
{
    NSLog(@"Close Click");
}

//TODO: integrate with trigger.io
-(void)skipHandle
{
    NSLog(@"Skip Click");
}

-(void)selectPictureHandle
{
    UIImagePickerController *imagePickerController = [[UIImagePickerController alloc]init];
    imagePickerController = [[UIImagePickerController alloc] init];
    imagePickerController.delegate = self;
    imagePickerController.sourceType =  UIImagePickerControllerSourceTypePhotoLibrary;
    [self presentViewController:imagePickerController animated:NO completion:nil];
}

//user clicks the take photo image and this takes that photo, passes it to the eit view, and loads that view
-(void)takePhotoHandle
{
    if(_pictureInProcess)
    {
        return;
    }
    _pictureInProcess = YES;
    AVCaptureConnection *videoConnection = nil;
    for (AVCaptureConnection *connection in _stillImageOutput.connections) {
        
        for (AVCaptureInputPort *port in [connection inputPorts]) {
            
            if ([[port mediaType] isEqual:AVMediaTypeVideo] ) {
                videoConnection = connection;
                break;
            }
        }
        
        if (videoConnection) {
            break;
        }
    }
    [_stillImageOutput captureStillImageAsynchronouslyFromConnection:videoConnection completionHandler: ^(CMSampleBufferRef imageSampleBuffer, NSError *error)
        {
            if (imageSampleBuffer != NULL)
            {
                NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageSampleBuffer];
                _lastPhoto = [UIImage imageWithData:imageData];
                _lastPhotoOrientation = UIImageOrientationRight;
                if(_frontCameraUsed)//flip image because it was front camera
                {
                    _lastPhotoOrientation = UIImageOrientationLeftMirrored;
                    _lastPhoto = [UIImage imageWithCGImage:_lastPhoto.CGImage scale:1.0 orientation:UIImageOrientationLeftMirrored];
                }
                [self loadEditPhotoView];
                _pictureInProcess = NO;
            }
        }
     ];
}

//user tapped enable/disable grid lines and this creates/hides them
-(void)gridHandle
{
    if(!_addGridLines)
    {
        if(_lines.count==0)//if lines haven't been  made yet make them
        {
            [self createLines];
        }else
        {
            for(UIView* line in _lines)
            {
                [self.view addSubview:line];
            }
        }
        _addGridLines = YES;
    }else
    {
        _addGridLines = NO;
        for(UIView* line in _lines)
        {
            [line removeFromSuperview];
        }
    }
}

//user tapped swap camera and this switches the input display
-(void)swapCameraHandle
{
    [_session removeInput:_cameraInput];
    if (!_frontCameraUsed) {
        NSError *error = nil;
        _cameraInput = [AVCaptureDeviceInput deviceInputWithDevice:_frontCamera error:&error];
        _frontCameraUsed = YES;
    }else {
        NSError *error = nil;
        _cameraInput = [AVCaptureDeviceInput deviceInputWithDevice:_backCamera error:&error];
        _frontCameraUsed = NO;
    }
    [_session addInput:_cameraInput];
}

//user tapped flash and this turns on/off flash
-(void)flashHandle
{
    if(!_backCamera.hasFlash)
    {
        return;
    }
    
    if(!_flashEnabled)
    {
        [_flashButton setImage:[UIImage imageNamed:@"flashOn"] forState:UIControlStateNormal];
        [_backCamera lockForConfiguration:nil];
        [_backCamera setFlashMode:AVCaptureFlashModeOn];
        _flashEnabled = YES;
    }else
    {
        [_flashButton setImage:[UIImage imageNamed:@"flashOff"] forState:UIControlStateNormal];
        [_backCamera setFlashMode:AVCaptureFlashModeOff];
        _flashEnabled = NO;
    }
}

//user tapped on the screen and this focus the camera to that tap
-(void)focusHandle:(UIGestureRecognizer*)tap
{
    //must account for orientation
    if(!_frontCameraUsed)
    {
        if(![_backCamera isFocusModeSupported:AVCaptureFocusModeLocked])
        {
            return;
        }
        [_backCamera lockForConfiguration:nil];
        [_backCamera setFocusPointOfInterest:[tap locationInView:_cameraFeed]];
    }else
    {
        if(![_frontCamera isFocusModeSupported:AVCaptureFocusModeLocked])
        {
            return;
        }
    }
}

//handle the image select product
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingImage:(UIImage *)image editingInfo:(NSDictionary *)editingInfo
{
    [picker dismissViewControllerAnimated:NO completion:nil];
    _lastPhoto = image;
    _lastPhotoOrientation = image.imageOrientation;
    [self loadEditPhotoView];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}


@end
