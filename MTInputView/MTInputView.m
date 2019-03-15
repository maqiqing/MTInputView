//
//  MTInputView.m
//  MTInputView
//
//  Created by 马头 on 2019/3/14.
//  Copyright © 2019 马头. All rights reserved.
//

#import "MTInputView.h"
//#import "MTTextView.h"
//屏幕宽高
#define kScreenW [UIScreen mainScreen].bounds.size.width
#define kScreenH [UIScreen mainScreen].bounds.size.height
// 刘海屏 宏定义
#define iPhoneX ((kScreenH == 812.f || kScreenH == 896.f) ? YES : NO)
// 适配iPhone X Tabbar距离底部的距离
#define MT_TabbarSafeBottomMargin (iPhoneX ? 34.f : 0.f)


#define textViewEdgeInsetPadding 4
#define contentViewTopPadding 7
#define contentViewBottomPadding 5
#define textContainerInsetMargin 6

@interface MTInputView()

@property (strong ,nonatomic)UIView *contentView;// textview 容器
@property (strong ,nonatomic)UITextView *textView;
@property (nonatomic, assign) CGFloat textHeight; //中间变量，控制高度

@property (strong ,nonatomic)UIButton *recordVoiceButton;
@property (strong ,nonatomic)UIButton *emojiButton;
@property (strong ,nonatomic)UIButton *moreFuncButton;
@end

@implementation MTInputView

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = [UIColor groupTableViewBackgroundColor];
        [self setupUI];
        [self setupConstraints];
        [self addObserve];
    }
    return self;
}

// UI
- (void)setupUI {
    _contentView = [[UIView alloc]init];
    _contentView.backgroundColor = [UIColor blackColor];
    _contentView.layer.cornerRadius = 5;
    [self addSubview:_contentView];
    _textView = [[UITextView alloc]init];
    _textView.backgroundColor = [UIColor orangeColor];
    _textView.font = [UIFont systemFontOfSize:17];//lineHeight = 20(近似)
    [_contentView addSubview:_textView];
    // 使用textContainerInset设置top、left、right
    _textView.textContainerInset = UIEdgeInsetsZero;
    //当光标在最后一行时，始终显示低边距，需使用contentInset设置bottom.
    _textView.contentInset = UIEdgeInsetsMake(textContainerInsetMargin, 0, textContainerInsetMargin, 0);
    //防止在拼音打字时抖动
    _textView.layoutManager.allowsNonContiguousLayout = NO;
    
    _recordVoiceButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_recordVoiceButton setImage:[UIImage imageNamed:@"play-circle"] forState:UIControlStateNormal];
    [self addSubview:_recordVoiceButton];
    _moreFuncButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_moreFuncButton setImage:[UIImage imageNamed:@"plus-circle"] forState:UIControlStateNormal];
    [self addSubview:_moreFuncButton];
    _emojiButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_emojiButton setImage:[UIImage imageNamed:@"smile"] forState:UIControlStateNormal];
    [self addSubview:_emojiButton];
}

// 添加约束
- (void)setupConstraints {
    [_contentView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self).offset(contentViewTopPadding);
        make.left.mas_equalTo(self.recordVoiceButton.mas_right).offset(5);
        make.right.mas_equalTo(self.emojiButton.mas_left).offset(-5);
        make.bottom.equalTo(self).offset( -MT_TabbarSafeBottomMargin - contentViewBottomPadding);
    }];
    [_textView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.contentView).insets(UIEdgeInsetsMake(textViewEdgeInsetPadding, textViewEdgeInsetPadding, textViewEdgeInsetPadding, textViewEdgeInsetPadding));
    }];
    
    [_recordVoiceButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self).offset(7);
        make.bottom.equalTo(self.contentView);
        make.size.mas_equalTo(CGSizeMake(40, 40));
    }];
    [_moreFuncButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self).offset(-15);
        make.bottom.equalTo(self.contentView);
        make.size.mas_equalTo(CGSizeMake(40, 40));
    }];
    [_emojiButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.moreFuncButton.mas_left).offset(-5);
        make.bottom.equalTo(self.contentView);
        make.size.mas_equalTo(CGSizeMake(40, 40));
    }];
}

// 添加监听键盘和textview
- (void)addObserve {
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(keyboardFrameChange:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(keyboardFrameChange:) name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(textDidChange) name:UITextViewTextDidChangeNotification object:nil];
}

- (void)keyboardFrameChange: (NSNotification *)notifi {
    
    CGRect keyboardFrame = [[notifi.userInfo valueForKey:@"UIKeyboardFrameEndUserInfoKey"] CGRectValue];
    CGFloat duration = [[notifi.userInfo valueForKey:@"UIKeyboardAnimationDurationUserInfoKey"] floatValue];
    
    if ([notifi.name isEqualToString:UIKeyboardWillShowNotification]) {
        self.bottomConstraint.offset(-keyboardFrame.size.height + MT_TabbarSafeBottomMargin);
    } else if ([notifi.name isEqualToString:UIKeyboardWillHideNotification]) {
        self.bottomConstraint.offset(0);
    }
    [UIView animateWithDuration:duration animations:^{
        [self.superview layoutIfNeeded];
    }];
}

- (void)textDidChange {
    /*
     ceilf 进1 函数
     */
    
    NSInteger height = ceilf([_textView sizeThatFits:CGSizeMake(_textView.bounds.size.width, MAXFLOAT)].height);
    
    // 至多5行
    CGFloat maxTextHeight = ceilf(_textView.font.lineHeight * 5 + 2*textContainerInsetMargin);//font:17  lineHight=20.287109
    
    NSLog(@"height:%ld-----textheight:%ld------max:%f",height,(long)self.textHeight,maxTextHeight);
    
    // 高度不一样，行数改变了
    if (self.textHeight != height) {
        self.textHeight = height;
        BOOL autoChangeHeight = height <= maxTextHeight;
        _textView.scrollEnabled = !autoChangeHeight;
        if ( autoChangeHeight ) {
            [self mas_updateConstraints:^(MASConstraintMaker *make) {
                make.height.mas_equalTo(self.textHeight + MT_TabbarSafeBottomMargin + contentViewTopPadding + contentViewBottomPadding + textContainerInsetMargin*2 + textViewEdgeInsetPadding*2);
            }];
        }
        [self layoutIfNeeded];
    }
}

- (void)dealloc {
    NSLog(@"%s", __func__);
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
