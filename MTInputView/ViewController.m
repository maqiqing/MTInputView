//
//  ViewController.m
//  MTInputView
//
//  Created by 马头 on 2019/3/14.
//  Copyright © 2019 马头. All rights reserved.
//

#import "ViewController.h"
#import "MTInputView.h"
//屏幕宽高
#define kScreenW [UIScreen mainScreen].bounds.size.width
#define kScreenH [UIScreen mainScreen].bounds.size.height
// 刘海屏 宏定义
#define iPhoneX ((kScreenH == 812.f || kScreenH == 896.f) ? YES : NO)
// 适配iPhone X Tabbar距离底部的距离
#define MT_TabbarSafeBottomMargin (iPhoneX ? 34.f : 0.f)

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.view.backgroundColor = [UIColor darkGrayColor];
        
    CGFloat inputViewHeight = 52;
    CGFloat totalHeight = inputViewHeight + MT_TabbarSafeBottomMargin;
    MTInputView *inputView = [[MTInputView alloc]init];
    [self.view addSubview:inputView];
    
    [inputView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self.view);
        make.height.mas_equalTo(totalHeight);
        inputView.bottomConstraint = make.bottom.equalTo(self.view.mas_bottom);
    }];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self.view endEditing:YES];
}

@end
