//
//  MTInputView.m
//  MTInputView
//
//  Created by 马头 on 2019/3/14.
//  Copyright © 2019 马头. All rights reserved.
//

#import "MTInputView.h"

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
    _contentView.backgroundColor = [UIColor whiteColor];
    _contentView.layer.cornerRadius = 5;
    [self addSubview:_contentView];
    _textView = [[UITextView alloc]init];
    _textView.backgroundColor = [UIColor whiteColor];
    _textView.font = [UIFont systemFontOfSize:16];//lineHeight = 19(近似)
    [_contentView addSubview:_textView];
    // 默认textView文字里有个默认上下8的距离，去掉
    _textView.textContainerInset = UIEdgeInsetsZero;
    
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
        make.top.equalTo(self).offset(8);
        make.left.mas_equalTo(self.recordVoiceButton.mas_right).offset(5);
        make.right.mas_equalTo(self.emojiButton.mas_left).offset(-5);
        make.bottom.equalTo(self).offset( - 5);
    }];
    [_textView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.contentView).insets(UIEdgeInsetsMake(8, 5, 8, 5));
    }];
    
    
    // 初试高度48
    [_recordVoiceButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self).offset(7);
        make.bottom.equalTo(self.contentView);
        make.size.mas_equalTo(CGSizeMake(36, 36));
    }];
    [_moreFuncButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self).offset(-15);
        make.bottom.equalTo(self.contentView);
        make.size.mas_equalTo(CGSizeMake(36, 36));
    }];
    [_emojiButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.moreFuncButton.mas_left).offset(-5);
        make.bottom.equalTo(self.contentView);
        make.size.mas_equalTo(CGSizeMake(36, 36));
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
    
    CGFloat safeAreaBottom = self.superview.safeAreaInsets.bottom;
    
    if ([notifi.name isEqualToString:UIKeyboardWillShowNotification]) {
        self.bottomConstraint.offset( -keyboardFrame.size.height + safeAreaBottom );
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
    CGFloat maxTextHeight = ceilf(_textView.font.lineHeight * 5);//font:16  lineHight 约= 19
    
    
    // 高度不一样，行数改变了
    if (self.textHeight != height) {
        // 高度小于最大高度
        BOOL autoChangeHeight = height <= maxTextHeight;
        _textView.scrollEnabled = !autoChangeHeight;

        
        NSLog(@"height:%ld-----textheight:%ld------max:%f",height,(long)self.textHeight,maxTextHeight);

        // 粘贴文字高度大于最高高度
        if (height - self.textHeight > maxTextHeight) {
            [self mas_updateConstraints:^(MASConstraintMaker *make) {
                // textview文本高度 + safaArea底部高度 + 容器试图距离顶部/底部 + 文字在uitextview里的上下约束 + textview距离容器的上下高度
                make.height.mas_equalTo(maxTextHeight + 8+5+8+8);
            }];
        } else {
            if ( autoChangeHeight ) {
                [self mas_updateConstraints:^(MASConstraintMaker *make) {
                    // textview文本高度 + safaArea底部高度 + 容器试图距离顶部/底部 + 文字在uitextview里的上下约束 + textview距离容器的上下高度
                    make.height.mas_equalTo(height + 8+5+8+8);
                }];
            }
        }
        self.textHeight = height;
        [self layoutIfNeeded];
    }
    // 粘贴情况
    // 全选删除情况
}

@end
