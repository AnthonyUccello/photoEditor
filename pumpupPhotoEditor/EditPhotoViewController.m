//
//  EditPhotoViewController.m
//  pumpupPhotoEditor
//
//  Created by Anthony Uccello on 2014-09-30.
//  Copyright (c) 2014 pumpup inc. All rights reserved.
//

#import "EditPhotoViewController.h"
#import "Utility.h"
#import "TakePhotoViewController.h"
#import "DragLabel.h"
@import  QuartzCore;

@interface EditPhotoViewController ()

@end

@implementation EditPhotoViewController

//consts
float SCREEN_H;
float SCREEN_W;
enum LAYOUT {ONE,SIDE_BY_SIDE,BIG_LEFT_TWO_SMALL_RIGHT,BIG_RIGHT_TWO_SMALL_LEFT,FOUR_SQUARES};
enum LAYOUT _layout;

//photo preview
UIScrollView* _photoScrollViewSlot1;
UIScrollView* _photoScrollViewSlot2;
UIScrollView* _photoScrollViewSlot3;
UIScrollView* _photoScrollViewSlot4;
UIImageView* _photoImageViewSlot1;
UIImageView* _photoImageViewSlot2;
UIImageView* _photoImageViewSlot3;
UIImageView* _photoImageViewSlot4;
UIImage* _uiImage1;
UIImage* _uiImage2;
UIImage* _uiImage3;
UIImage* _uiImage4;
UIImage* _uiImage1Original;
UIImage* _uiImage2Original;
UIImage* _uiImage3Original;
UIImage* _uiImage4Original;
UIImageView* _selectedOptionImageView; //to be used for when user selects images in the tab options like filter, or text
UIImageView* _selectedImageView;//the photo the user is currently editing
UIImageView* _awaitingImageView; //if its not nil, set the incoming photo to this
BOOL _awaitingIncomingImage;
UIImageOrientation _imageOrientation;
NSMutableArray* _scrollViewReferences;//help managed tap gestures

//top bar ui elements
UIView* _topBar;
UILabel* _backButton;
UILabel* _saveButton;

//lower bar UI
UIView* _lowerBar;
UIButton* _textButton;
UIButton* _layoutButton;
UIButton* _filterButton;

//filtes
NSArray* _filters;
NSMutableArray* _filterPreviewImageViews;
UIScrollView* _filterScrollView;
BOOL _resetFilterPreviews;

//text images
NSDictionary* _textOptionNames;
NSMutableArray* _textPreviewImageViews;
NSMutableDictionary* _textPreviewImagesMap;
UIScrollView* _textScrollView;
DragLabel* _addedText;
UIView* _addTextView;

//layouts
NSArray* _layoutOptions;
UIScrollView* _layoutsScrollView;
NSMutableArray* _layoutPreviewImageViews;
NSMutableDictionary* _layoutPreviewImageMap;

//flags
BOOL _viewsInitialized;
BOOL _filterPreviewOpen;
BOOL _photo2Assigned;

//===initializers===//

//call all the inits for all the sections of the UIView
-(void)initView
{
    UIView* whiteBG = [[UIView alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height)];
    whiteBG.backgroundColor = [UIColor whiteColor];
    [self initFlags];
    [self.view addSubview:whiteBG];
    [self initTopBar];
    [self initViews];
    [self initLowerBar];
    [self initFilterOptions];
    [self initTextOptions];
    [self initLayoutOptions];

}

//in the flags
-(void)initFlags
{
    _viewsInitialized = NO;
    _awaitingIncomingImage = NO;
    _resetFilterPreviews = YES;
    _filterPreviewOpen = NO;
    _photo2Assigned = NO;
}

//create the images for the preview layout
-(void)initLayoutPreviewImages
{
    int i = 0;
    for(NSString* name in _layoutOptions)
    {
        UIImage* image = [UIImage imageNamed:name];
        UIImageView* imageView = [[UIImageView alloc] initWithImage:image];
        [imageView setFrame:CGRectMake(i* 175, 0,150, 150)];
        UITapGestureRecognizer *singleFingerTap =[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(layoutPreviewHandle:)];
        [imageView addGestureRecognizer:singleFingerTap];
        imageView.userInteractionEnabled = YES;
        [_layoutsScrollView addSubview:imageView];
        [_layoutPreviewImageViews addObject:imageView];
        [_layoutPreviewImageMap setObject:imageView forKey:name];
        i++;
    }
}

//create the variables needed for displaying the filter image options
-(void)initFilterOptions
{
    _filters = @[@"CIPhotoEffectTransfer",@"CIColorMonochrome",@"CIColorInvert",@"CIPhotoEffectNoir",@"CIPixellate",@"CIVignette",@"CIColorPosterize",@"CIExposureAdjust",@"CIFalseColor",@"CIGammaAdjust"];
    _filterPreviewImageViews = [[NSMutableArray alloc] init];
    _filterScrollView = [[UIScrollView alloc]  initWithFrame:CGRectMake(0, [UIScreen mainScreen].bounds.size.width + 90, [UIScreen mainScreen].bounds.size.width, 150)];
    _filterScrollView.contentSize = CGSizeMake(_filters.count*175, 150);
}

//create the variables needed for displaying the layout options
-(void)initLayoutOptions
{
    _layoutOptions = @[@"single",@"double"];
    _layoutsScrollView = [[UIScrollView alloc]  initWithFrame:CGRectMake(0, [UIScreen mainScreen].bounds.size.width + 90, [UIScreen mainScreen].bounds.size.width, 150)];
    _layoutsScrollView.contentSize = CGSizeMake(4*175, 150);
    _layoutPreviewImageViews = [[NSMutableArray alloc] init];
    _layoutPreviewImageMap = [[NSMutableDictionary alloc] init];
}

//create the variables needed for displaying adding text options
-(void)initTextOptions
{
    _textOptionNames = @{
                         @"none":[UIImage imageNamed:@"none"],
                         @"pumpup":[UIImage imageNamed:@"pumpup"],
                         @"hashtag":[UIImage imageNamed:@"hashtag"],
                         @"signature":[UIImage imageNamed:@"signature"],
                         @"weather":[UIImage imageNamed:@"weather"],
                         @"time":[UIImage imageNamed:@"time"]
                         };
    _textPreviewImageViews = [[NSMutableArray alloc] init];
    
    _textScrollView = [[UIScrollView alloc]  initWithFrame:CGRectMake(0, [UIScreen mainScreen].bounds.size.width + 90, [UIScreen mainScreen].bounds.size.width, 150)];
    _textScrollView.contentSize = CGSizeMake(6*175, 150);
    _textPreviewImagesMap = [[NSMutableDictionary alloc] init];
}

//inits the UIScrollviews and the UIImageViews needed for displaying the main photos the user wants to edit (and retain references to manage tap events)
-(void)initViews
{
    //init scroll views
    _photoScrollViewSlot1 = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
    _photoScrollViewSlot1.maximumZoomScale = 4.0;
    _photoScrollViewSlot1.minimumZoomScale = 1.0;
    _photoScrollViewSlot1.contentSize = CGSizeMake([UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.width);
    _photoScrollViewSlot1.delegate = self;
    _photoScrollViewSlot2 = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
    _photoScrollViewSlot3 = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
    _photoScrollViewSlot4 = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
    
    //init image views, ui images, and add them to their parent views
    _photoImageViewSlot1 = [[UIImageView alloc]  initWithFrame:CGRectMake(0, 0, 0, 0)];
    _photoImageViewSlot2 = [[UIImageView alloc]  initWithFrame:CGRectMake(0, 0, 0, 0)];
    _photoImageViewSlot3 = [[UIImageView alloc]  initWithFrame:CGRectMake(0, 0, 0, 0)];
    _photoImageViewSlot4 = [[UIImageView alloc]  initWithFrame:CGRectMake(0, 0, 0, 0)];
    
    [_photoScrollViewSlot1 addSubview:_photoImageViewSlot1];
    [_photoScrollViewSlot2 addSubview:_photoImageViewSlot2];
    [_photoScrollViewSlot3 addSubview:_photoImageViewSlot3];
    [_photoScrollViewSlot4 addSubview:_photoImageViewSlot4];
    
    _scrollViewReferences = [[NSMutableArray alloc] init];
    [_scrollViewReferences addObject:_photoScrollViewSlot1];
    [_scrollViewReferences addObject:_photoScrollViewSlot2];
    [_scrollViewReferences addObject:_photoScrollViewSlot3];
    [_scrollViewReferences addObject:_photoScrollViewSlot4];
}

//create all the top bar GUI objects and callbacks
-(void)initTopBar
{
    _topBar = [[UIView alloc] initWithFrame:CGRectMake(0,0,[UIScreen mainScreen].bounds.size.width, 30)];
    _topBar.backgroundColor = [UIColor colorWithRed:45.0/255.0 green:189.0/255.0 blue:242.0/255.0 alpha:1.0f];
    [self.view addSubview:_topBar];
    
    //TODO: create a text subsclass that handles text size bounds resizing
    _backButton = [Utility createTextButtonWithText:@"Back" Size:CGRectMake(10,8,50,18) Selector:@selector(backHandle) Target:self];
    [self.view addSubview:_backButton];
    
    _saveButton = [Utility createTextButtonWithText:@"Save" Size:CGRectMake(SCREEN_W - 40,8,50,18) Selector:@selector(saveHandle) Target:self];
    [self.view addSubview:_saveButton];
}

//Handles lower bar GUI objects and callbacks
-(void)initLowerBar
{
    _lowerBar = [[UIView alloc] initWithFrame:CGRectMake(0,[UIScreen mainScreen].bounds.size.width + 30,[UIScreen mainScreen].bounds.size.width, 50)];
    _lowerBar.backgroundColor = [UIColor colorWithRed:45.0/255.0 green:189.0/255.0 blue:242.0/255.0 alpha:1.0f];
    [self.view addSubview:_lowerBar];
    
    _textButton = [Utility createButtonImageName:@"text" Rect:CGRectMake([UIScreen mainScreen].bounds.size.width/2 - 22, [UIScreen mainScreen].bounds.size.width + 30, 44, 44) Selector:@selector(textTabHandle) Target:self];
    [self.view addSubview:_textButton];
    
    _layoutButton = [Utility createButtonImageName:@"layout" Rect:CGRectMake([UIScreen mainScreen].bounds.size.width - 50, [UIScreen mainScreen].bounds.size.width + 30, 44, 44) Selector:@selector(layoutTabHandle) Target:self];
    [self.view addSubview:_layoutButton];
    
    _filterButton = [Utility createButtonImageName:@"filter" Rect:CGRectMake(10, [UIScreen mainScreen].bounds.size.width + 30, 44, 44) Selector:@selector(filterTabHandle) Target:self];
    [self.view addSubview:_filterButton];
}

//create the images that go into the filters preview list
-(void)initFilterPreviewImages
{
    for(int i = 0; i<_filters.count; i++)
    {
        //for the first image add the original un-filtered preview
        if(i==0)
        {
            UIImageView* imageView = [[UIImageView alloc] initWithImage:_selectedImageView.image];
            imageView.userInteractionEnabled = YES;
            UITapGestureRecognizer *singleFingerTap =[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(filterImageTapHandle:)];
            [imageView setFrame:CGRectMake(10+i*175,0, 150, 150)];//move back to 50
            [imageView addGestureRecognizer:singleFingerTap];
            [_filterScrollView addSubview:imageView];
            
            UILabel *name = [ [UILabel alloc ] initWithFrame:CGRectMake(0,120,150, 30) ];
            name.textColor = [UIColor whiteColor];
            name.backgroundColor = [UIColor clearColor];
            name.font = [UIFont fontWithName:@"Arial Rounded MT Bold" size:(20.0)];
            [imageView addSubview:name];
            name.text = @"Original";
            [_filterPreviewImageViews addObject:imageView];
            name.adjustsFontSizeToFitWidth = YES;
            //set as selected
            imageView.layer.borderColor = [[UIColor greenColor] CGColor];
            imageView.layer.borderWidth = 5.0;
            continue;
        }
        
        //create the filtered image
        UIImage* image = [Utility createFilteredImage:_selectedImageView.image FilterName:_filters[i] Orientation:_imageOrientation];
        UIImageView* imageView = [[UIImageView alloc] initWithImage:image];
        imageView.userInteractionEnabled = YES;
        UITapGestureRecognizer *singleFingerTap =[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(filterImageTapHandle:)];
        [imageView setFrame:CGRectMake(10+i*175,0, 150, 150)];//move back to 50
        [imageView addGestureRecognizer:singleFingerTap];
        [_filterScrollView addSubview:imageView];
        
        //create the label for the image
        UILabel *name = [ [UILabel alloc ] initWithFrame:CGRectMake(0,120,150, 30) ];
        name.textColor = [UIColor whiteColor];
        name.backgroundColor = [UIColor clearColor];
        name.font = [UIFont fontWithName:@"Arial Rounded MT Bold" size:(20.0)];
        [imageView addSubview:name];
        NSString* ciText = _filters[i];
        name.text = [ciText stringByReplacingOccurrencesOfString:@"CI" withString:@""];
        name.adjustsFontSizeToFitWidth = YES;
        [_filterPreviewImageViews addObject:imageView];
    }
    
    //add each preview filtered version of the image
    for(UIImageView* imageView in _filterPreviewImageViews)
    {
        [_filterScrollView addSubview:imageView];
    }
}

//===implemenation==///

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.userInteractionEnabled = YES;
    // Do any additional setup after loading the view.
}

//takes image from photo and sets it to display
-(void)loadImage:(UIImage*)image Orientation:(UIImageOrientation)orientation
{
    _imageOrientation = orientation;
    if(!_viewsInitialized)
    {
        [self initView];
        _viewsInitialized = YES;
    }
    
    //check what view the incoming photo needs to be added to
    if(_awaitingIncomingImage)
    {
        _photoImageViewSlot2.image = [UIImage imageWithCGImage:image.CGImage scale:1.0 orientation:_imageOrientation];
        _uiImage2Original = [UIImage imageWithCGImage:image.CGImage scale:1.0 orientation:_imageOrientation];
        _photo2Assigned = YES;//set flag for side by side layout
    }else
    {
        //create first preview image as full screen
        _photoImageViewSlot1.image = [UIImage imageWithCGImage:image.CGImage scale:1.0 orientation:_imageOrientation];
        _uiImage1Original = [UIImage imageWithCGImage:image.CGImage scale:1.0 orientation:_imageOrientation];
        [_photoImageViewSlot1 setFrame:CGRectMake(0,0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.width)];
        [_photoScrollViewSlot1 setFrame:CGRectMake(0,30, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.width)];
        _selectedImageView = _photoImageViewSlot1;
        [self.view addSubview:_photoScrollViewSlot1];
    }
    
    [self goToLayout];
}

//sets the images up based on the users chosen layout
-(void)goToLayout
{
    if(_layout == SIDE_BY_SIDE)
    {
        [self goToDoubleLayout];
    }
}

-(BOOL)prefersStatusBarHidden{
    return YES;
}

//add tap to select listeners on all photo previews
-(void)addTapSelectionListeners
{
    [self clearEditPhotoSelection];
    for(UIScrollView* scrollView in _scrollViewReferences)
    {
        UITapGestureRecognizer* tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(photoEditHandle:)];
        [scrollView addGestureRecognizer:tap];
    }
}

//handle pan zoom of picked image
- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    //TODO: fix for selected image amongst layout
    return _photoImageViewSlot1;
}

//Hacked solution to simulate dragging on UILabels
//TODO: Fix touch event swallowing and extend UIView class to have a draggability
-(void)moveTextEvent:(UIPanGestureRecognizer*)tap
{
    CGPoint lastPoint = [tap locationInView:self.view];
    [tap.view setFrame:CGRectMake(lastPoint.x, lastPoint.y,300,50)];
}

//remove selected filter border from selected preview option
-(void)clearFilterSelection
{
    for(UIImageView* imageView in _filterPreviewImageViews)
    {
        imageView.layer.borderWidth = 0;
    }
}

//remove selected text option border from selected preview option
-(void)clearTextSelection
{
    for(UIImageView* imageView in _textPreviewImageViews)
    {
        imageView.layer.borderWidth = 0;
    }
}

//clears the borders on selected layout option
-(void)clearLayoutSelection
{
    for(UIImageView* imageView in _layoutPreviewImageViews)
    {
        imageView.layer.borderWidth = 0;
    }
}

//clears all the borders on any selected photo
-(void)clearEditPhotoSelection
{
    for(UIScrollView* scrollView in _scrollViewReferences)
    {
        scrollView.layer.borderWidth = 0;
    }
}

//===handle methods===//

//apply filter selected by the user
-(void)filterImageTapHandle:(UITapGestureRecognizer*)tap
{
    [self clearFilterSelection];
    _selectedOptionImageView = (UIImageView*)tap.view;
    tap.view.layer.borderColor = [[UIColor greenColor] CGColor];
    tap.view.layer.borderWidth = 5.0;
    _selectedImageView.image = _selectedOptionImageView.image;
}

//semi hacked, this adds a text object from what the user selected
//TODO: refactor to have a draggable UIView class that lets views handle dragging themselves (and avoid touch swallowing)
-(void)textPreviewImageHandle:(UIGestureRecognizer*)tap
{
    [self clearTextSelection];
    if(_addedText)
    {
        [_addedText removeFromSuperview];
        [_addTextView removeFromSuperview];
    }
    _addedText = [[DragLabel alloc] initWithFrame:CGRectMake(0,0,300,50)];
    _addedText.textAlignment = NSTextAlignmentLeft;
    //init views
    _addedText.userInteractionEnabled = YES;
    _addTextView = [[UIImageView alloc] init];
    [_addTextView addSubview:_addedText];
    UIPanGestureRecognizer* singleTap = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(moveTextEvent:)];
    //[_addedText addGestureRecognizer:singleTap];
    
    //temporary hack to get simulated label dragging, there is a UIView swallowing the tap events inside the UILabel
    [_addTextView addGestureRecognizer:singleTap];
    [_addTextView addSubview:_addedText];
    [_addTextView setFrame:CGRectMake(0,0,300,50)];
    _addTextView.userInteractionEnabled = YES;
    _selectedImageView.userInteractionEnabled = YES;
    
    //set the border of the selected view
    _selectedOptionImageView = (UIImageView*)tap.view;
    _selectedOptionImageView.layer.borderColor = [[UIColor greenColor] CGColor];
    _selectedOptionImageView.layer.borderWidth = 5.0;
    
    //get the text type that was clicked and set the added text properties
    for(NSString* textName in _textPreviewImagesMap)
    {
        if(_textPreviewImagesMap[textName] == tap.view)
        {
            if([textName  isEqual: @"none"])
            {
                return;
            }
            _addedText.textColor = [UIColor blackColor];
            _addedText.text = textName;
            
            if([textName  isEqual: @"signature"])
            {
                _addedText.font = [UIFont fontWithName:@"Zapfino" size:(50.0)];
            }
            if([textName  isEqual: @"hashtag"])
            {
                _addedText.font = [UIFont fontWithName:@"Baskerville-Italic" size:(50.0)];
                _addedText.text = @"#teampumpup";
                _addedText.textColor = [UIColor blueColor];
            }
            
            if([textName  isEqual: @"pumpup"])
            {
                _addedText.font = [UIFont fontWithName:@"Thonburi" size:(50.0)];
                _addedText.textColor = [UIColor blueColor];
            }
            if([textName  isEqual: @"time"])
            {
                _addedText.font = [UIFont fontWithName:@"Symbol" size:(50.0)];
                _addedText.text = @"12:00 PM";
            }
            if([textName  isEqual: @"weather"])
            {
                _addedText.font = [UIFont fontWithName:@"Optima-Bold" size:(50.0)];
                _addedText.text = @"25\u00B0";
                _addedText.textColor = [UIColor yellowColor];
            }
        }
    }
    [_selectedImageView addSubview:_addTextView];
}

//recieves text tab click and initalizes preview for that tab
-(void)textTabHandle
{
    [self hideAllTabs];
    int i = 0;
    if(_textPreviewImageViews.count==0)
    {
        for(id key in _textOptionNames)//for each option create the image and label
        {
            NSString* textOptionName = key;
            UIImage* image = [UIImage imageNamed:textOptionName];
            UIImageView* imageView = [[UIImageView alloc] initWithImage:image];
            imageView.userInteractionEnabled = YES;
            UITapGestureRecognizer *singleFingerTap =[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(textPreviewImageHandle:)];
            [imageView setFrame:CGRectMake(10+i*175,0, 150, 150)];//move back to 50
            [imageView addGestureRecognizer:singleFingerTap];
            [_textScrollView addSubview:imageView];
            
            UILabel *name = [ [UILabel alloc ] initWithFrame:CGRectMake(0,120,150, 30) ];
            name.textColor = [UIColor blackColor];
            name.backgroundColor = [UIColor clearColor];
            name.font = [UIFont fontWithName:@"Arial Rounded MT Bold" size:(20.0)];
            [imageView addSubview:name];
            name.text = textOptionName;
            name.adjustsFontSizeToFitWidth = YES;
            imageView.userInteractionEnabled = YES;
            
            [_textPreviewImageViews addObject:imageView];
            [_textPreviewImagesMap setObject:imageView forKey:key];
            i++;
        }
    }
    [self.view addSubview:_textScrollView];
}

//creates scroll view with filter image previews, original image, and names below the filter images
-(void)filterTabHandle
{
    [self hideAllTabs];
    _filterPreviewOpen = YES;
    if(_resetFilterPreviews)
    {
        [_filterPreviewImageViews removeAllObjects];
        [self initFilterPreviewImages];
    }
    
    [self.view addSubview:_filterScrollView];
}

//recieves the layout tap and creates the preview images
-(void)layoutTabHandle
{
    [self hideAllTabs];
    if(_layoutPreviewImageViews.count == 0)
    {
        [self initLayoutPreviewImages];
    }
    
    [self.view addSubview:_layoutsScrollView];
}

//user has selected a preview layout option and this sets the display to represent that view
-(void)layoutPreviewHandle:(UIGestureRecognizer*)tap
{
    [self clearLayoutSelection];
    _selectedOptionImageView = (UIImageView*)tap.view;
    tap.view.layer.borderColor = [[UIColor greenColor] CGColor];
    tap.view.layer.borderWidth = 5.0;
    
    for(NSString* layout in _layoutPreviewImageMap)
    {
        if(_layoutPreviewImageMap[layout] == tap.view)
        {
            if([layout  isEqual: @"single"])
            {
                [self goToSingleLayout];
            }
            
            if([layout  isEqual: @"double"])
            {
                [self goToDoubleLayout];
            }
        }
    }
}

//handles the back click event, unloads view controller from view
-(void)backHandle
{
    //todo dismiss all the stuff (like all the lower previews they need to be reset)
    //[self disposeFilterImagePrewview];
    [self dismissViewControllerAnimated:NO completion:nil];
}

//TODO: make work with trigger io wrapper
-(void)saveHandle
{
    NSLog(@"Save stub");
}

//user wants to add another photo so this brings them back to the photo view and holds the view to add the photo to
-(void)addPhotoHandle:(UITapGestureRecognizer*)tap
{
    _awaitingImageView = (UIImageView*)tap.view;
    _awaitingIncomingImage = YES;
    [self dismissViewControllerAnimated:NO completion:nil];
}

//set the tapped photo to selected
//TODO map objects to swift dictionaries
-(void)photoEditHandle:(UIGestureRecognizer*)tap
{
    [self clearEditPhotoSelection];
    UIScrollView* scrollview = (UIScrollView*)tap.view;
    if(scrollview == _photoScrollViewSlot1)
    {
        _selectedImageView =_photoImageViewSlot1;
    }
    if(scrollview == _photoScrollViewSlot2)
    {
        _selectedImageView =_photoImageViewSlot2;
    }
    
    scrollview.layer.borderColor = [[UIColor blueColor] CGColor];
    scrollview.layer.borderWidth = 5.0;
    if(_filterPreviewOpen)
    {
        [self initFilterPreviewImages];
    }
}

//===hide methods===///

//hids filter, text, and layout tabs
-(void)hideAllTabs
{
    _filterPreviewOpen = NO;
    [self hideFilterTab];
    [self hideTextTab];
    [self hideLayoutTab];
}

//hides filters
-(void)hideFilterTab
{
    [_filterScrollView removeFromSuperview];
}

//hides text options
-(void)hideTextTab
{
    [_textScrollView removeFromSuperview];
}

//hides layout options
-(void)hideLayoutTab
{
    [_layoutsScrollView removeFromSuperview];
}


//===layout methods===//

//goes to side by side layout
//TODO extend UIImageView to have a resize event
//have a laytout manager class that takes UI images, and edits their orientations based on a view
-(void)goToDoubleLayout
{
    [self disposeScrollViewListeners];
    [self clearEditPhotoSelection];
    [self addTapSelectionListeners];
    
    _layout = SIDE_BY_SIDE;

    _photoScrollViewSlot1.transform = CGAffineTransformScale(CGAffineTransformIdentity, 0.5, 0.5);
    [_photoScrollViewSlot1 setFrame:CGRectMake(0,[UIScreen mainScreen].bounds.size.width/4 + 30, _photoScrollViewSlot1.bounds.size.width*0.5, _photoScrollViewSlot1.bounds.size.height*0.5)];
    
    [_photoScrollViewSlot2 setFrame:CGRectMake(400,[UIScreen mainScreen].bounds.size.width/4 + 30, _photoScrollViewSlot1.bounds.size.width*0.5, _photoScrollViewSlot1.bounds.size.height*0.5)];
    if(!_photo2Assigned)
    {
        [self disposeScrollViewOfListeners:_photoScrollViewSlot2];
        UIImage* addImage = [UIImage imageNamed:@"addNewImage"];
        [_photoImageViewSlot2 setImage:addImage];
        [_photoImageViewSlot2 setFrame:CGRectMake(0, 0,_photoScrollViewSlot2.bounds.size.width, _photoScrollViewSlot2.bounds.size.height)];
        [_photoScrollViewSlot2 addSubview:_photoImageViewSlot2];
        UITapGestureRecognizer* tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(addPhotoHandle:)];
        [_photoScrollViewSlot2 addGestureRecognizer:tap];
    }else
    {
        [_photoScrollViewSlot2 setFrame:CGRectMake(400,[UIScreen mainScreen].bounds.size.width/4 + 30, _photoScrollViewSlot2.bounds.size.width, _photoScrollViewSlot2.bounds.size.height)];
    }

    [self.view addSubview:_photoScrollViewSlot2];
}

//goes to single layout
-(void)goToSingleLayout
{
    _layout = ONE;
    
    _photoScrollViewSlot1.transform = CGAffineTransformScale(CGAffineTransformIdentity, 1, 1);
    [_photoScrollViewSlot1 setFrame:CGRectMake(0,30, _photoScrollViewSlot1.bounds.size.width, _photoScrollViewSlot1.bounds.size.height)];
    [_photoImageViewSlot1 setFrame:CGRectMake(0,0,[UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.width)];
    
    [_photoScrollViewSlot2 removeFromSuperview];
}


//===dispose methods===//

//remove listeners in scrollviews for tap events
-(void)disposeScrollViewListeners
{
    for(UIScrollView* scrollView in _scrollViewReferences)
    {
        for (UITapGestureRecognizer* tap in scrollView.gestureRecognizers)
        {
            [scrollView removeGestureRecognizer:tap];
        }
    }
}

//remove a specific scrollviews listeners
-(void)disposeScrollViewOfListeners:(UIScrollView*)scrollView
{
    for (UITapGestureRecognizer* tap in scrollView.gestureRecognizers)
    {
        [scrollView removeGestureRecognizer:tap];
    }
}

//TODO: add rest of dispose for cleanup
-(void)disposeFilterImagePreview
{
    for(UIImageView* imageView in _filterPreviewImageViews)
    {
        imageView.image = nil;
        [imageView removeFromSuperview];
    }
    [_filterPreviewImageViews removeAllObjects];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

@end
