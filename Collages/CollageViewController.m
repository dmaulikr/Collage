//
//  ViewController.m
//  Collages
//
//  Created by Ekaterina Belinskaya on 12/03/15.
//  Copyright (c) 2015 Ekaterina Belinskaya. All rights reserved.
//

#import "CollageViewController.h"
#import "Collage.h"
#import "ImageCollectionViewCell.h"
#import "SearchUsersTableView.h"
#import "InstaPhoto.h"
#import "UIImageView+AFNetworking.h"

@interface CollageViewController ()
//Collection Views
@property (weak, nonatomic) IBOutlet UICollectionView *selectedPhotoCV;
@property (weak, nonatomic) IBOutlet UICollectionView *modesCV;

//Collages
@property (strong, nonatomic) Collage *collage;
@property (weak, nonatomic) IBOutlet UIView *collageFrame;


//Other properties
@property BOOL isFreeForm;
@property (weak, nonatomic) UIImageView *movingImage;
@property (strong, nonatomic) UIImageView *movingCell;

@end

@implementation CollageViewController

#pragma mark Variables
NSInteger photoIndex;
NSInteger selectedPhotoCount;


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    _isFreeForm = YES;
    
    
    UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
    [flowLayout setScrollDirection:UICollectionViewScrollDirectionHorizontal];
    [_selectedPhotoCV setCollectionViewLayout:flowLayout];
    //add Long Press Recognizer
    UILongPressGestureRecognizer *lpgr= [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
    lpgr.minimumPressDuration = .1; //seconds
    lpgr.delegate = self;
    [_selectedPhotoCV addGestureRecognizer: lpgr];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(createNewImage:)];
    tap.numberOfTapsRequired = 2;
    [_collageFrame addGestureRecognizer:tap];
    _collageFrame.layer.borderColor = [UIColor whiteColor].CGColor;
    _collageFrame.layer.borderWidth = 5.0f;
    [_collageFrame addSubview:_movingImage];

    
    UICollectionViewFlowLayout *flowLayoutForModes = [[UICollectionViewFlowLayout alloc] init];
    [flowLayoutForModes  setScrollDirection:UICollectionViewScrollDirectionHorizontal];
    [_modesCV setCollectionViewLayout:flowLayoutForModes];
    
    
    UIImage *image = [UIImage imageNamed:@"wall"];
    self.view.backgroundColor = [UIColor colorWithPatternImage:image];
    
    _modesCV.backgroundColor = [UIColor lightGrayColor];
    _selectedPhotoCV.backgroundColor = [UIColor clearColor];
    
    
    _collageFrame.backgroundColor = [UIColor lightGrayColor];//lightGrayColor
    _collageFrame.layer.borderColor = [UIColor whiteColor].CGColor;
    _collageFrame.layer.borderWidth = 5.0f;
    
    _collage = [Collage sharedInstance];
    selectedPhotoCount = [_collage.selectedPhotos count];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void) viewWillAppear:(BOOL)animated{
    NSMutableArray *arrayWithIndexPaths = [NSMutableArray array];
    for (NSInteger i = selectedPhotoCount; i < [_collage.selectedPhotos count]; i++) {
        [arrayWithIndexPaths addObject:[NSIndexPath indexPathForRow:i inSection:0]];
    }
    [_selectedPhotoCV insertItemsAtIndexPaths:arrayWithIndexPaths];
    selectedPhotoCount =[_collage.selectedPhotos count];
}

#pragma mark Gesture Recognizer Selectors

-(void)createNewImage:(UITapGestureRecognizer *) gesture{
    if (_isFreeForm){
        CGPoint locationPointInCollageView = [gesture locationInView:_collageFrame];
        float width = (_collageFrame.bounds.size.width - 5)/2;
        CGRect frame = CGRectMake(locationPointInCollageView.x, locationPointInCollageView.y, width, width);
        UIImageView *newImage = [[UIImageView alloc] initWithFrame:frame];
        newImage.layer.borderWidth = 5.0f;
        newImage.layer.borderColor = [UIColor whiteColor].CGColor;
        [newImage setUserInteractionEnabled:YES];
        UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(moveImageInCollage:)];
        pan.delegate = self;
        [newImage addGestureRecognizer:pan];
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(bringSubviewToFront:)];
        tap.delegate = self;
        [newImage addGestureRecognizer: tap];
        UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(chooseFromLibrary:)];
        doubleTap.numberOfTapsRequired = 2;
        [newImage addGestureRecognizer:doubleTap];
        [_collageFrame addSubview:newImage];
        newImage.center = locationPointInCollageView;
        UIActionSheet *action = [[UIActionSheet alloc] initWithTitle:@"Select image from" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"From library",@"From camera",  nil] ;
        
        [action showInView:self.view];
    }
}

-(void) handleLongPress:(UILongPressGestureRecognizer *)longRecognizer{
    //позиция в collectionView
    CGPoint locationPointInCollection = [longRecognizer locationInView:_selectedPhotoCV];
    //позиция на экране
    CGPoint locationPointInView = [longRecognizer locationInView:self.view];
    
    if (longRecognizer.state == UIGestureRecognizerStateBegan) {
        
        NSIndexPath *indexPathOfMovingCell = [_selectedPhotoCV indexPathForItemAtPoint:locationPointInCollection];
        photoIndex = indexPathOfMovingCell.row;
        
        NSDictionary *photoDict = [_collage.selectedPhotos objectAtIndex:indexPathOfMovingCell.row];
        UIImage *image = [photoDict objectForKey:@"smallImage"];
        CGRect frame = CGRectMake(locationPointInView.x, locationPointInView.y, 150.0f, 150.0f);
        _movingCell = [[UIImageView alloc] initWithFrame:frame];
        _movingCell.image = image;
        [_movingCell setCenter:locationPointInView];
        _movingCell.layer.borderWidth = 5.0f;
        _movingCell.layer.borderColor = [UIColor whiteColor].CGColor;
        [self.view addSubview:_movingCell];
        
    }
    
    if (longRecognizer.state == UIGestureRecognizerStateChanged) {
        [_movingCell setCenter:locationPointInView];
    }
    
    if (longRecognizer.state == UIGestureRecognizerStateEnded) {
        CGRect frameRelativeToParentCollageFrame = [_collageFrame convertRect:_collageFrame.bounds
                                                                           toView:self.view];
        if (CGRectContainsPoint( frameRelativeToParentCollageFrame, _movingCell.center)){
            if (_isFreeForm){
                CGPoint originInCollageView = [_collageFrame convertPoint:_movingCell.center fromView:self.view];
                float width = (_collageFrame.bounds.size.width - 5)/2;
                UIImageView *imgView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, width, width)];
                [self holdInContainer:imgView];
                [self tuneImageView:imgView withCenterPont: originInCollageView];
                [_collageFrame addSubview:imgView];
                [_collageFrame bringSubviewToFront:imgView];
                //[self.movingCell removeFromSuperview];
            } else{
                NSInteger s_i = 0;
                for (id i in _collageFrame.subviews){
                    if( [i isKindOfClass:[UIScrollView class]]){
                        UIScrollView *tmpScroll = (UIScrollView *)i;
                        CGRect frameRelativeToParent= [tmpScroll convertRect: tmpScroll.bounds
                                                                                           toView:self.view];
                        NSInteger img_i = 0;
                        
                        if (CGRectContainsPoint( frameRelativeToParent, _movingCell.center)){
                            for (id y in tmpScroll.subviews){
                                if( [y isKindOfClass:[UIImageView class]]){
                                    UIImageView *imgView = y;
                                    if (imgView.tag!=0){
                                        [self holdInContainer:imgView];
                                        [_movingCell removeFromSuperview];
                                    }
                                    img_i+=1;
                                }
                            }
                        }
                        s_i+=1;
                        
                    }
                }
            }
        }
        else{
            [_movingCell removeFromSuperview];
        }
    }
}

-(void)bringSubviewToFront:(UITapGestureRecognizer *) gesture{
    CGPoint locationPointInView = [gesture locationInView:_collageFrame];
    for (UIView *i in _collageFrame.subviews){
        if([i isKindOfClass:[UIImageView class]]){
            UIImageView *img = (UIImageView*)i;
            CGRect frameRelativeToParent = [img convertRect:img.bounds
                                                     toView:_collageFrame];
            if (CGRectContainsPoint( frameRelativeToParent , locationPointInView)){
                _movingImage = (UIImageView*)i;
                [_collageFrame bringSubviewToFront:_movingImage];
            }
        }
    }
}

-(void) moveImageInCollage: (UIPanGestureRecognizer *) gesture{
    CGPoint locationPointInView = [gesture locationInView: _collageFrame];
    CGPoint locationPointInSuperView = [gesture locationInView:self.view];
    if (gesture.state ==  UIGestureRecognizerStateBegan){
        for (UIView *i in _collageFrame.subviews){
            if([i isKindOfClass:[UIImageView class]]){
                UIImageView *img = (UIImageView*)i;
                CGRect frameRelativeToParent = [img convertRect:img.bounds
                                                         toView:_collageFrame];
                if (CGRectContainsPoint( frameRelativeToParent , locationPointInView)){
                    _movingImage = (UIImageView*)i;
                    [_collageFrame bringSubviewToFront:_movingImage];
                }
            }
        }
    }
    if (gesture.state == UIGestureRecognizerStateChanged) {
        CGRect frameRelativeToParent = [_movingImage convertRect:_movingImage.bounds
                                                              toView:_collageFrame];
        if (CGRectContainsPoint( frameRelativeToParent , locationPointInView)){
            _movingImage.center =locationPointInView;
        }
    }
    if(gesture.state == UIGestureRecognizerStateEnded){
        CGRect frameRelativeToParent = [_collageFrame convertRect:_collageFrame.bounds
                                                               toView:self.view];
        if (! CGRectContainsPoint( frameRelativeToParent , locationPointInSuperView)){
            [_movingImage removeFromSuperview];
            [_collage.collagePhotos removeObjectAtIndex:_movingImage.tag];
        }
    }
}

-(void)showActionSheet{
    UIActionSheet *action = [[UIActionSheet alloc] initWithTitle:@"Select image from" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"From library",@"From camera", @"From Instagram", nil] ;
    
    [action showInView:self.view];
}

-(void)chooseFromLibrary:(UITapGestureRecognizer *) gesture{
    [self showActionSheet];
}

#pragma mark - ActionSheet delegates

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    switch (buttonIndex) {
        case 0:
            {UIImagePickerController *pickerView = [[UIImagePickerController alloc] init];
                pickerView.allowsEditing = YES;
                pickerView.delegate = self;
                [pickerView setSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
                [self presentViewController:pickerView animated:YES completion:nil];
                break;
            }
        case 1:
        {
            if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
                UIImagePickerController *pickerView =[[UIImagePickerController alloc]init];
                pickerView.allowsEditing = YES;
                pickerView.delegate = self;
                pickerView.sourceType = UIImagePickerControllerSourceTypeCamera;
                [self presentViewController:pickerView animated:YES completion:nil];
                //[self presentModalViewController:pickerView animated:true];
            }
            break;
        }
        case 2:
            [self performSegueWithIdentifier:@"openSearch" sender:self];
            break;
        default:
            break;
    }
    // [self performSegueWithIdentifier:@"searchResultsSegue" sender:self];
}

#pragma mark - PickerDelegates

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info{
    
    [self dismissViewControllerAnimated:YES completion:nil];
    UIImage * img = [info valueForKey:UIImagePickerControllerEditedImage];
    _movingImage.image = img;
    [_collage.collagePhotos addObject:img];
    NSDictionary *photoDictionary = @{@"info": [NSNull null], @"smallImage": img};
    //NSInteger index = [_collage.selectedPhotos count];
    //NSArray *arrayWithIndexPaths = @[[NSIndexPath indexPathForRow:index inSection:0]];
    [_collage.selectedPhotos addObject:photoDictionary];
    //[_selectedPhotoCV insertItemsAtIndexPaths:arrayWithIndexPaths];
}

#pragma mark UICollectionView - sources

- (NSInteger)collectionView:(UICollectionView *)view numberOfItemsInSection:(NSInteger)section {
    if (view == _selectedPhotoCV) {
        return [_collage.selectedPhotos count];
    } else if (view == _modesCV){
        return 2;
    } else return 0;
}

- (NSInteger)numberOfSectionsInCollectionView: (UICollectionView *)collectionView {
    return 1;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)cv cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    ImageCollectionViewCell *cell = (ImageCollectionViewCell *)[cv dequeueReusableCellWithReuseIdentifier:@"ImageCell" forIndexPath:indexPath];
    if (cv == _modesCV){
        //CGRect frame = CGRectMake(5, 5, 30, 30);
        [cell.imageView setHidden:YES];
        UIView *freeForm = [[UIView alloc] initWithFrame:cell.bounds];
        freeForm.backgroundColor = [UIColor clearColor];
        freeForm.layer.borderWidth = 3.0f;
        freeForm.layer.borderColor = [UIColor whiteColor].CGColor;
        if (indexPath.row == 0) {
            [cell addSubview:freeForm];
        } else {
            UIBezierPath *path = [UIBezierPath bezierPath];
            [path moveToPoint:CGPointMake(20.0, 0.0)];
            [path addLineToPoint:CGPointMake(20.0, 20.0)];
            [path moveToPoint:CGPointMake(0.0, 20.0)];
            [path addLineToPoint:CGPointMake(40.0, 20.0)];
            CAShapeLayer *shapeLayer = [CAShapeLayer layer];
            shapeLayer.path = [path CGPath];
            shapeLayer.strokeColor = [[UIColor whiteColor] CGColor];
            shapeLayer.lineWidth = 3.0;
            shapeLayer.fillColor = [[UIColor clearColor] CGColor];
            [freeForm.layer addSublayer:shapeLayer];
            [cell addSubview:freeForm];
        }
    } else {
        NSDictionary *photoDict = [_collage.selectedPhotos objectAtIndex:indexPath.row];
        UIImage *image = [photoDict objectForKey:@"smallImage"];
        cell.imageView.image = image;
    }
    return cell;
}



#pragma mark UICollectionView - delegates
-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    UICollectionViewCell *cell =  [collectionView cellForItemAtIndexPath:indexPath];
    if (collectionView == _modesCV){
        if (indexPath.row == 0 ){
            _isFreeForm = YES;
            _collageFrame.backgroundColor = [UIColor lightGrayColor];
            [self deleteScrolls];
        } else
        {
            _isFreeForm=NO;
            _collageFrame.backgroundColor = [UIColor whiteColor];
            [self deleteUIImageView];
            [self addScrolls];
        }
        cell.layer.borderWidth = 2.0f;
        cell.layer.borderColor = self.navigationController.navigationBar.tintColor.CGColor;//[UIColor blueColor].CGColor;
    }
    
}
-(void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath{
    UICollectionViewCell *cell =  [collectionView cellForItemAtIndexPath:indexPath];
    if (collectionView == _modesCV){
        if (indexPath.row == 0 ){
            _isFreeForm = NO;
        } else
        {
            _isFreeForm=YES;
        }
        cell.layer.borderWidth = 0.0f;
    }
}

#pragma mark UICollectionView - layouts
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    if (collectionView == _selectedPhotoCV) {
        return CGSizeMake(100.0f, 100.0f);
    } else return CGSizeMake(40.0f, 40.0f);
}
- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
    if (collectionView == _modesCV) { return 30.0f; }
    return 10.0;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {
    //if (collectionView == self.modesCV) { return 30.0f; }
    return 10.0;
}

- (UIEdgeInsets)collectionView:
(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    if (collectionView == _modesCV){
        NSInteger cellCount = [collectionView.dataSource collectionView:collectionView numberOfItemsInSection:section];
        CGFloat cellWidth = ((UICollectionViewFlowLayout*)collectionViewLayout).itemSize.width+((UICollectionViewFlowLayout*)collectionViewLayout).minimumInteritemSpacing;
        CGFloat totalCellWidth = cellWidth*cellCount;
        CGFloat contentWidth = collectionView.frame.size.width-collectionView.contentInset.left-collectionView.contentInset.right;
        if( totalCellWidth<contentWidth )
        {
            CGFloat padding = (contentWidth - totalCellWidth) / 2.0;
            return UIEdgeInsetsMake(0, padding, 0, padding);
        }
    }
    return UIEdgeInsetsMake(0,5,0,5);  // top, left, bottom, right
}

#pragma mark Segue
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:@"openSearch"]) {
        
        SearchUsersTableView *destView = segue.destinationViewController;
        UIGraphicsBeginImageContextWithOptions(self.view.bounds.size, NO, 0.0);
        [self.view.layer renderInContext:UIGraphicsGetCurrentContext()];
        UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        destView.background= image;
    }
}
#pragma mark Utilities

-(void)addScrolls{
    float scrollWidth = (_collageFrame.bounds.size.width - 5)/2;
    //width = Height;
    
    UIScrollView *scroll = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, scrollWidth, scrollWidth)];
    scroll.backgroundColor = [UIColor redColor];
    [_collageFrame addSubview:scroll];
    [self tuneScroll:scroll withContentSize: CGSizeMake(scrollWidth, scrollWidth) withScrollIndex:0];
    
    UIScrollView *scroll2 = [[UIScrollView alloc] initWithFrame:CGRectMake(5 + scrollWidth, 0, scrollWidth, scrollWidth)];
    scroll2.backgroundColor = [UIColor greenColor];
    [_collageFrame addSubview:scroll2];
    [self tuneScroll:scroll2 withContentSize: CGSizeMake(scrollWidth, scrollWidth) withScrollIndex:1];
    
    
    UIScrollView *scroll3 = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 5 + scrollWidth, _collageFrame.bounds.size.width , scrollWidth)];
    scroll3.backgroundColor = [UIColor purpleColor];
    [_collageFrame addSubview:scroll3];
    [self tuneScroll:scroll3 withContentSize: CGSizeMake(_collageFrame.bounds.size.width, _collageFrame.bounds.size.width) withScrollIndex:2];
    
    
}

-(void) deleteScrolls{
    for (id i in _collageFrame.subviews){
        if( [i isKindOfClass:[UIScrollView class]]){
            [i removeFromSuperview];
        }
    }
    float x = 75.0f;
    float y = 75.0f;
    float offset = _collageFrame.bounds.size.width/ [_collage.collagePhotos count];
    for (UIImage *img in _collage.collagePhotos){
        float width = (_collageFrame.bounds.size.width - 5)/2;
        UIImageView *newImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, width, width)];
        newImageView.image = img;
        [self tuneImageView:newImageView withCenterPont:CGPointMake(x, y)];
        [_collageFrame addSubview:newImageView];
        [_collageFrame bringSubviewToFront:newImageView];
        x += offset;
        y += offset;
    }
    
}

-(void) deleteUIImageView{
    for (id i in _collageFrame.subviews){
        if( [i isKindOfClass:[UIImageView class]]){
            [i removeFromSuperview];
        }
    }
}

-(void)tuneScroll: (UIScrollView *)scroll withContentSize: (CGSize) size withScrollIndex: (NSInteger) index
{
    scroll.contentSize = size;
    CGRect frame = (CGRect){.origin=CGPointMake(0.0f, 0.0f), size};
    UIImageView *imView = [[UIImageView alloc] initWithFrame: frame];
    //UIScrollView by default contains 2 UIImageViews as subviews for scroll indicators.
    //so we need tag for mark ours
    imView.tag=101;
    //in case wrong array index
    @try {
        imView.image = [_collage.collagePhotos objectAtIndex:index];
    }
    @catch (NSException *exception) {
        //do nothing
    }

    [scroll addSubview:imView];
}

-(void) tuneImageView: (UIImageView *)imageView withCenterPont: (CGPoint) centerPont{

    imageView.center = centerPont;
    [imageView setUserInteractionEnabled:YES];
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(moveImageInCollage:)];
    pan.delegate = self;
    [imageView addGestureRecognizer:pan];
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(bringSubviewToFront:)];
    tap.delegate = self;
    [imageView addGestureRecognizer: tap];
    UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(chooseFromLibrary:)];
    doubleTap.numberOfTapsRequired = 2;
    [imageView addGestureRecognizer:doubleTap];
    imageView.layer.borderColor = [UIColor whiteColor].CGColor;
    imageView.layer.borderWidth = 5.0f;


}


-(void) holdInContainer: (UIImageView *) container{
    container.alpha = 0.0;
    container.image = _movingCell.image;
    
    //download big imgage's version
    NSDictionary *photoDict = _collage.selectedPhotos[photoIndex];
    id photo = [photoDict objectForKey:@"info"];
    if (photo != [NSNull null]){
        NSLog(@"i am here");
        NSURLRequest *request = [NSURLRequest requestWithURL:[photo getStandartResolutionURL]];
        __weak UIImageView *iView = container;
        [iView setImageWithURLRequest:request
                     placeholderImage:nil
                              success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
                                  iView.image = image;
                                  iView.tag = [_collage.collagePhotos count];
                                  [_collage.collagePhotos addObject:image];
                                  [UIView animateWithDuration:1.0f
                                                   animations:^{
                                                       container.alpha = 1.0f;
                                                   }
                                                   completion:nil];
                              }
                              failure:nil];
        //animate disappearance of moving cell
        CGPoint centerPoint = _movingCell.center;
        [UIView animateWithDuration: 0.5f
                         animations:^{CGRect frame = _movingCell.frame;
                             frame.size.width -= frame.size.width - 1.0f;
                             frame.size.height -= frame.size.height -  1.0f;
                             _movingCell.frame = frame;
                             _movingCell.center = centerPoint;}
                         completion:^(BOOL finished){[_movingCell removeFromSuperview]; }];
    } else{
        CGPoint centerPoint = _movingCell.center;
        [UIView animateWithDuration: 0.5f
                         animations:^{ container.alpha = 1.0f;
                             CGRect frame = _movingCell.frame;
                             frame.size.width -= frame.size.width - 1.0f;
                             frame.size.height -= frame.size.height -  1.0f;
                             _movingCell.frame = frame;
                             _movingCell.center = centerPoint;}
                         completion:^(BOOL finished){[_movingCell removeFromSuperview]; }];
    }
}
-(UIImage *) makeImage{
    //UIGraphicsBeginImageContext(self.collageFrame.bounds.size);
    UIGraphicsBeginImageContextWithOptions(_collageFrame.bounds.size, NO, 0.0);
    [_collageFrame.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}



#pragma mark IBActions
- (IBAction)addPhotos:(id)sender {
    [self showActionSheet];
}

- (IBAction)chooseAction:(id)sender {
    NSMutableArray *sharingItems = [NSMutableArray new];
    
    
    [sharingItems addObject:[self makeImage]];
    
    
    UIActivityViewController *activityController = [[UIActivityViewController alloc] initWithActivityItems:sharingItems applicationActivities:nil];
    [self presentViewController:activityController animated:YES completion:nil];
}

@end
