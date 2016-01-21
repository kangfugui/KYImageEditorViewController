//
//  ViewController.m
//  KYImageEditorViewControllerDemo
//
//  Created by KangYang on 16/1/19.
//  Copyright © 2016年 KangYang. All rights reserved.
//

#import "ViewController.h"
#import "KYImageEditorViewController.h"

@interface ViewController ()

@property (strong, nonatomic) UIImageView *imageView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] init];
    [tap addTarget:self action:@selector(tapGestureAction:)];
    [self.view addGestureRecognizer:tap];
    
    CGFloat size = self.view.bounds.size.width;
    self.imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, size, size)];
    [self.view addSubview:self.imageView];
    
}

- (void)tapGestureAction:(id)sender
{
    KYImageEditorViewController *editor = [[KYImageEditorViewController alloc] initWithImage:[UIImage imageNamed:@"image_01"]];
    UINavigationController *navigation = [[UINavigationController alloc] initWithRootViewController:editor];
    
    [self presentViewController:navigation animated:YES completion:nil];
    
    [editor setAcceptBlock:^(KYImageEditorViewController *editor, NSDictionary *userInfo) {
        [editor.navigationController dismissViewControllerAnimated:YES completion:nil];
        self.imageView.image = userInfo[UIImagePickerControllerEditedImage];
    }];
    
    [editor setCancelBlock:^(KYImageEditorViewController *editor) {
        [editor.navigationController dismissViewControllerAnimated:YES completion:nil];
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
