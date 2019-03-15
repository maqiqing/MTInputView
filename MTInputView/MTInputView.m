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

/*
 textViewEdgeInsetPadding: textview和contentView的edgeInset边缘距离 (黑色一圈)
 contentViewTopPadding: contentView距离顶部距离
 contentViewBottomPadding: contentView距离safaAreaBottom距离
 textContentInsetMargin: textView 里文字
 */
#define textViewEdgeInsetPadding 4
#define contentViewTopPadding 7
#define contentViewBottomPadding 5
#define textContentInsetMargin 6

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
    // 默认textView文字里有个上下8的距离，去掉
    _textView.textContainerInset = UIEdgeInsetsZero;
    // 默认为 0，设置默认正文有个上下6的距离
    _textView.contentInset = UIEdgeInsetsMake(textContentInsetMargin, 0, textContentInsetMargin, 0);
    // 防止中文输入文字抖动？
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
        // 这里要用 self.superview，是父试图更新
        [self.superview layoutIfNeeded];
    }];
}

- (void)textDidChange {
    /*
     ceilf 进1 函数
     */
    
    NSInteger height = ceilf([_textView sizeThatFits:CGSizeMake(_textView.bounds.size.width, MAXFLOAT)].height);
    
    // 至多5行
    CGFloat maxTextHeight = ceilf(_textView.font.lineHeight * 5 + 2*textContentInsetMargin);//font:17  lineHight=20.287109
    
    NSLog(@"height:%ld-----textheight:%ld------max:%f",height,(long)self.textHeight,maxTextHeight);
    
    // 高度不一样，行数改变了
    if (self.textHeight != height) {
        self.textHeight = height;
        BOOL autoChangeHeight = height <= maxTextHeight;
        _textView.scrollEnabled = !autoChangeHeight;
        if ( autoChangeHeight ) {
            [self mas_updateConstraints:^(MASConstraintMaker *make) {
                // textview文本高度 + safaArea底部高度 + 容器试图距离顶部/底部 + 文字在uitextview里的上下约束 + textview距离容器的上下高度
                make.height.mas_equalTo(self.textHeight + MT_TabbarSafeBottomMargin + contentViewTopPadding + contentViewBottomPadding + textContentInsetMargin*2 + textViewEdgeInsetPadding*2);
            }];
        }
        [self layoutIfNeeded];
    }
    // 粘贴情况
    // 全选删除情况
}

- (void)dealloc {
    NSLog(@"%s", __func__);
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
