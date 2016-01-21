//
//  KYImageEditorViewController.m
//  KYImageEditorViewControllerDemo
//
//  Created by KangYang on 16/1/19.
//  Copyright © 2016年 KangYang. All rights reserved.
//

#import "KYImageEditorViewController.h"

@interface KYImageEditorViewController () <UIScrollViewDelegate>

@property (copy, nonatomic) UIImage *editingImage;

@property (readonly, nonatomic) UIScrollView *scrollView;
@property (readonly, nonatomic) UIImageView *maskView;
@property (readonly, nonatomic) UIView *bottomView;

@end

@implementation KYImageEditorViewController
@synthesize scrollView = _scrollView;
@synthesize maskView = _maskView;
@synthesize bottomView = _bottomView;
@synthesize imageView = _imageView;

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self _commonInit];
    }
    return self;
}

- (instancetype)initWithImage:(UIImage *)image
{
    self = [super init];
    if (self) {
        [self _commonInit];
        self.editingImage = image;
    }
    
    return self;
}

- (void)_commonInit
{
    self.automaticallyAdjustsScrollViewInsets = NO;
    self.view.backgroundColor = [UIColor blackColor];
    self.edgesForExtendedLayout = UIRectEdgeNone;
}

#pragma mark - life cycle

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    if (_scrollView.superview) return;
    
    [self.view addSubview:self.scrollView];
    [self.scrollView addSubview:self.imageView];
    [self.view addSubview:self.bottomView];
    
    CGSize contentSize = self.scrollView.contentSize;
    contentSize.height = MAX(contentSize.height, self.view.bounds.size.height);
    contentSize.height += fabs(self.cropSize.height - self.imageView.image.size.height);
    self.scrollView.contentSize = contentSize;
    
    CGPoint center = CGPointMake(contentSize.width / 2, contentSize.height / 2);
    self.imageView.center = center;
    
    center.x = (contentSize.width - self.view.bounds.size.width) / 2;
    center.y = (fabs(self.cropSize.height - self.imageView.image.size.height) / 2);
    self.scrollView.contentOffset = center;
    
    [self updateScrollViewContentInset];
    
    [self.view insertSubview:self.maskView aboveSubview:self.scrollView];
    
    NSDictionary *views = @{@"bottomView": self.bottomView};
    
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[bottomView]|" options:0 metrics:nil views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[bottomView(88)]|" options:0 metrics:nil views:views]];
    
    [self.view layoutSubviews];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:YES];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:YES];
}

- (void)dealloc
{
    _scrollView = nil;
    _editingImage = nil;
    _bottomView = nil;
    _imageView.image = nil;
    _imageView = nil;
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

#pragma mark - events response

- (void)cancelAction:(id)sender
{
    if (self.cancelBlock) {
        self.cancelBlock(self);
    }
}

- (void)acceptAction:(id)sender
{
    if ((self.scrollView.zoomScale > self.scrollView.maximumZoomScale) || !self.imageView.image) {
        return;
    }
    
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
    dispatch_async(queue, ^{
        
//        UIImage *editedImage = [self trimmedImage:[self editedImage]];
        UIImage *editedImage = [self editedImage];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (self.acceptBlock) {
                
                NSMutableDictionary *userInfo = [NSMutableDictionary new];
                
                [userInfo setObject:self.editingImage forKey:UIImagePickerControllerOriginalImage];
                [userInfo setObject:editedImage forKey:UIImagePickerControllerEditedImage];
                
                self.acceptBlock(self,userInfo);
            }
        });
    });
}

#pragma mark - getters and setters

- (UIScrollView *)scrollView
{
    if (!_scrollView) {
        _scrollView = [[UIScrollView alloc] initWithFrame:self.view.bounds];
        _scrollView.backgroundColor = [UIColor clearColor];
        _scrollView.minimumZoomScale = 1.0;
        _scrollView.maximumZoomScale = 2.0;
        _scrollView.showsHorizontalScrollIndicator = NO;
        _scrollView.showsVerticalScrollIndicator = NO;
        _scrollView.delegate = self;
        _scrollView.zoomScale = _scrollView.minimumZoomScale;
    }
    
    return _scrollView;
}

- (UIImageView *)imageView
{
    if (!_imageView) {
        
        _imageView = [[UIImageView alloc] initWithImage:self.editingImage];
        _imageView.contentMode = UIViewContentModeScaleAspectFill;
        _imageView.contentScaleFactor = [UIScreen mainScreen].scale;
    }
    
    return _imageView;
}

- (UIView *)bottomView
{
    if (!_bottomView) {
        _bottomView = [[UIView alloc] init];
        _bottomView.translatesAutoresizingMaskIntoConstraints = NO;
        _bottomView.tintColor = [UIColor whiteColor];
        _bottomView.userInteractionEnabled = YES;
        
        _leftButton = [self buttonWithTitle:@"Cancel"];
        _leftButton.translatesAutoresizingMaskIntoConstraints = NO;
        [_leftButton addTarget:self action:@selector(cancelAction:) forControlEvents:UIControlEventTouchUpInside];
        
        _rightButton = [self buttonWithTitle:@"Accept"];
        _rightButton.translatesAutoresizingMaskIntoConstraints = NO;
        [_rightButton addTarget:self action:@selector(acceptAction:) forControlEvents:UIControlEventTouchUpInside];
        
        [_bottomView addSubview:_leftButton];
        [_bottomView addSubview:_rightButton];
        
        NSDictionary *metrics = @{@"hmargin": @(13), @"barsHeight": @([self barHeight])};
        NSDictionary *views = @{@"leftButton": _leftButton, @"rightButton": _rightButton};
        
        [_bottomView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-hmargin-[leftButton]" options:0 metrics:metrics views:views]];
        [_bottomView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[rightButton]-hmargin-|" options:0 metrics:metrics views:views]];
        
        [_bottomView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[leftButton]|" options:0 metrics:metrics views:views]];
        [_bottomView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[rightButton]|" options:0 metrics:metrics views:views]];

    }
    return _bottomView;
}

- (UIImageView *)maskView
{
    if (!_maskView) {
        _maskView = [[UIImageView alloc] initWithImage:[self squareOverlayMask]];
        _maskView.userInteractionEnabled = NO;
    }
    return _maskView;
}

#pragma mark - private method

- (CGRect)guideRect
{
    CGFloat margin = (CGRectGetHeight(self.navigationController.view.bounds)-self.cropSize.height)/2;
    return CGRectMake(0.0, margin, self.cropSize.width, self.cropSize.height);
}

- (UIImage *)editedImage
{
    UIImage *image = nil;
    
    CGRect viewRect = self.navigationController.view.bounds;
    CGRect guideRect = [self guideRect];
    
    CGFloat verticalMargin = (viewRect.size.height-guideRect.size.height)/2;
    
    guideRect.origin.x = -self.scrollView.contentOffset.x;
    guideRect.origin.y = -self.scrollView.contentOffset.y - verticalMargin;
    
    UIGraphicsBeginImageContextWithOptions(guideRect.size, NO, 0);{
        CGContextRef context = UIGraphicsGetCurrentContext();
        
        CGContextTranslateCTM(context, guideRect.origin.x, guideRect.origin.y);
        [self.scrollView.layer renderInContext:context];
        
        image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
    }
    
    return image;
}


//去掉图片的透明部分 http://stackoverflow.com/a/12617031/590010
- (UIImage *)trimmedImage:(UIImage *)image
{
    CGImageRef inImage = image.CGImage;
    CFDataRef m_DataRef;
    m_DataRef = CGDataProviderCopyData(CGImageGetDataProvider(inImage));
    
    UInt8 * m_PixelBuf = (UInt8 *) CFDataGetBytePtr(m_DataRef);
    
    size_t width = CGImageGetWidth(inImage);
    size_t height = CGImageGetHeight(inImage);
    
    CGPoint top,left,right,bottom;
    
    BOOL breakOut = NO;
    for (int x = 0;breakOut==NO && x < width; x++) {
        for (int y = 0; y < height; y++) {
            NSInteger loc = x + (y * width);
            loc *= 4;
            if (m_PixelBuf[loc + 3] != 0) {
                left = CGPointMake(x, y);
                breakOut = YES;
                break;
            }
        }
    }
    
    breakOut = NO;
    for (int y = 0;breakOut==NO && y < height; y++) {
        
        for (int x = 0; x < width; x++) {
            
            NSInteger loc = x + (y * width);
            loc *= 4;
            if (m_PixelBuf[loc + 3] != 0) {
                top = CGPointMake(x, y);
                breakOut = YES;
                break;
            }
            
        }
    }
    
    breakOut = NO;
    for (NSInteger y = height-1;breakOut==NO && y >= 0; y--) {
        
        for (NSInteger x = width-1; x >= 0; x--) {
            
            NSInteger loc = x + (y * width);
            loc *= 4;
            if (m_PixelBuf[loc + 3] != 0) {
                bottom = CGPointMake(x, y);
                breakOut = YES;
                break;
            }
            
        }
    }
    
    breakOut = NO;
    for (NSInteger x = width-1;breakOut==NO && x >= 0; x--) {
        
        for (NSInteger y = height-1; y >= 0; y--) {
            
            NSInteger loc = x + (y * width);
            loc *= 4;
            if (m_PixelBuf[loc + 3] != 0) {
                right = CGPointMake(x, y);
                breakOut = YES;
                break;
            }
            
        }
    }
    
    
    CGFloat scale = image.scale;
    
    CGRect cropRect = CGRectMake(left.x / scale, top.y/scale, (right.x - left.x)/scale, (bottom.y - top.y) / scale);
    
    UIGraphicsBeginImageContextWithOptions(cropRect.size, NO, scale);
    [image drawAtPoint:CGPointMake(-cropRect.origin.x, -cropRect.origin.y) blendMode:kCGBlendModeCopy alpha:1.];
    
    UIImage *croppedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    CFRelease(m_DataRef);
    return croppedImage;
}

- (CGSize)cropSize
{
    CGSize viewSize = self.view.bounds.size;
    return CGSizeMake(viewSize.width, viewSize.width);
}

- (UIButton *)buttonWithTitle:(NSString *)title
{
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    [button.titleLabel setFont:[UIFont systemFontOfSize:18.0]];
    [button setTitle:title forState:UIControlStateNormal];
    [button setTitleEdgeInsets:UIEdgeInsetsMake(-1, 0, 0, 0)];
    [button setUserInteractionEnabled:YES];
    [button sizeToFit];
    return button;
}

- (CGFloat)barHeight
{
    CGFloat height = [UIApplication sharedApplication].statusBarFrame.size.height;
    height += self.navigationController.navigationBar.frame.size.height;
    return height;
}

- (UIImage *)squareOverlayMask
{
    CGRect bounds = self.navigationController.view.bounds;
    CGFloat width = self.cropSize.width;
    CGFloat height = self.cropSize.height;
    CGFloat margin = (bounds.size.height - height) / 2;
    CGFloat lineWidth = 1.0;
    
    UIGraphicsBeginImageContextWithOptions(bounds.size, NO, 0);
    
    UIBezierPath *path = [UIBezierPath bezierPath];
    [path moveToPoint:CGPointMake(width, margin)];
    [path addLineToPoint:CGPointMake(0, margin)];
    [path addLineToPoint:CGPointMake(0, 0)];
    [path addLineToPoint:CGPointMake(width, 0)];
    [path addLineToPoint:CGPointMake(width, margin)];
    [path closePath];
    [path moveToPoint:CGPointMake(width, bounds.size.height)];
    [path addLineToPoint:CGPointMake(0, bounds.size.height)];
    [path addLineToPoint:CGPointMake(0, margin + height)];
    [path addLineToPoint:CGPointMake(width, margin + height)];
    [path addLineToPoint:CGPointMake(width, bounds.size.height)];
    [path closePath];
    [[UIColor colorWithWhite:0 alpha:0.5] setFill];
    [path fill];
    
    CGRect rect = CGRectMake(lineWidth / 2, margin + lineWidth / 2, width - lineWidth, height - lineWidth);
    UIBezierPath *maskpath = [UIBezierPath bezierPathWithRect:rect];
    maskpath.lineWidth = lineWidth;
    [[UIColor colorWithWhite:1.0 alpha:0.5] setStroke];
    [maskpath stroke];
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

- (CGSize)sizeAspectFit:(CGSize)aspectRatio boundingSize:(CGSize)boundingSize
{
    CGFloat hRatio = boundingSize.width / aspectRatio.width;
    CGFloat vRation = boundingSize.height / aspectRatio.height;
    if (hRatio < vRation) {
        boundingSize.height = boundingSize.width / aspectRatio.width * aspectRatio.height;
    }
    else if (vRation < hRatio) {
        boundingSize.width = boundingSize.height / aspectRatio.height * aspectRatio.width;
    }
    return boundingSize;
}

- (void)updateScrollViewContentInset
{
    CGSize imageSize = [self sizeAspectFit:self.imageView.image.size boundingSize:self.imageView.frame.size];
    CGFloat maskHeight = self.cropSize.height;
    
    CGFloat hInset = 0.0;
    CGFloat vInset = fabs((maskHeight - imageSize.height) / 2);
    
    vInset = (self.view.bounds.size.height - imageSize.height) / 2;
    vInset += 0.25;
    
    if (vInset == 0) vInset = 0.25;
    
    UIEdgeInsets inset = UIEdgeInsetsMake(vInset, hInset, vInset, hInset);
    inset = UIEdgeInsetsMake(0.25, 0, 0.25, 0);
    
    self.scrollView.contentInset = inset;
}

#pragma mark - UIScrollViewDelegate

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    return self.imageView;
}

- (void)scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(UIView *)view atScale:(CGFloat)scale
{
    CGSize contentSize = self.scrollView.contentSize;
    contentSize.height = MAX(contentSize.height, self.view.bounds.size.height);
    contentSize.height += fabs(self.cropSize.height - view.frame.size.height);
    
    if (view.frame.size.height > self.view.bounds.size.height) {
        contentSize.height = view.frame.size.height;
        contentSize.height += self.view.bounds.size.height - self.cropSize.height;
    }
    
    self.scrollView.contentSize = contentSize;
}

#pragma mark - view auto rotation

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
{
    return UIInterfaceOrientationPortrait;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

- (BOOL)shouldAutorotate
{
    return NO;
}

@end
