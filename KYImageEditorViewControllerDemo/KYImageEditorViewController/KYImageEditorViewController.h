//
//  KYImageEditorViewController.h
//  KYImageEditorViewControllerDemo
//
//  Created by KangYang on 16/1/19.
//  Copyright © 2016年 KangYang. All rights reserved.
//

#import <UIKit/UIKit.h>

@class KYImageEditorViewController;

typedef void (^KYImageEditorAcceptBlock)(KYImageEditorViewController *editor, NSDictionary *userInfo);
typedef void (^KYImageEditorCancelBlock)(KYImageEditorViewController *editor);

@interface KYImageEditorViewController : UIViewController

/** The cropping size. Default is view's size.width **/
@property (assign, nonatomic) CGSize cropSize;

/** The container for the editing image **/
@property (readonly, nonatomic) UIImageView *imageView;
/** The bottom left action button **/
@property (readonly, nonatomic) UIButton *leftButton;
/** The bottom right action button **/
@property (readonly, nonatomic) UIButton *rightButton;

/** A block to be executed when user accept the edit **/
@property (copy, nonatomic) KYImageEditorAcceptBlock acceptBlock;
/** A block to be executed when user cancel the edit **/
@property (copy, nonatomic) KYImageEditorCancelBlock cancelBlock;

/** Initializes a image editor with the image **/
- (instancetype)initWithImage:(UIImage *)image;

@end
