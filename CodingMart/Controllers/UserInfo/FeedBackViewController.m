//
//  FeedBackViewController.m
//  CodingMart
//
//  Created by Ease on 15/10/11.
//  Copyright © 2015年 net.coding. All rights reserved.
//

#import "FeedBackViewController.h"
#import "FeedBackInfo.h"
#import "TableViewFooterButton.h"
#import "Coding_NetAPIManager.h"
#import <BlocksKit/BlocksKit+UIKit.h>
#import <ReactiveCocoa/ReactiveCocoa.h>

@interface FeedBackViewController ()
@property (weak, nonatomic) IBOutlet UITextField *nameF;
@property (weak, nonatomic) IBOutlet UITextField *phoneF;
@property (weak, nonatomic) IBOutlet UITextField *emailF;
@property (weak, nonatomic) IBOutlet UITextView *contentF;
@property (weak, nonatomic) IBOutlet UITextField *j_captchaF;
@property (weak, nonatomic) IBOutlet UIView *j_captchaBgView;
@property (weak, nonatomic) IBOutlet UIImageView *j_captchaImgV;
@property (weak, nonatomic) IBOutlet TableViewFooterButton *submitBtn;

@property (strong, nonatomic) FeedBackInfo *feedBackInfo;
@end

@implementation FeedBackViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.title = @"意见反馈";
    self.feedBackInfo = [FeedBackInfo makeFeedBack];
    [_j_captchaBgView doBorderWidth:0.5 color:[UIColor colorWithHexString:@"0xCCCCCC"] cornerRadius:1.0];
    __weak typeof(self) weakSelf = self;
    [_j_captchaBgView bk_whenTapped:^{
        [weakSelf refreshCaptchaImage];
    }];
    RAC(self.submitBtn, enabled) = [RACSignal combineLatest:@[RACObserve(self, feedBackInfo.name),
                                                                RACObserve(self, feedBackInfo.phone),
                                                              RACObserve(self, feedBackInfo.email),
                                                              RACObserve(self, feedBackInfo.content),
                                                              RACObserve(self, feedBackInfo.j_captcha),
                                                                ] reduce:^id(NSString *name, NSString *phone, NSString *email, NSString *content, NSString *j_captcha){
                                                                    BOOL enabled = YES;
                                                                    enabled = (name.length > 0 && phone.length > 0 && email.length > 0 && content.length > 0 && j_captcha.length > 0);
                                                                    return @(enabled);
                                                                }];
    
    [self refreshCaptchaImage];
}

- (void)setFeedBackInfo:(FeedBackInfo *)feedBackInfo{
    _feedBackInfo = feedBackInfo;
    _nameF.text = _feedBackInfo.name;
    _phoneF.text = _feedBackInfo.phone;
    _emailF.text = _feedBackInfo.email;
    _contentF.text = _feedBackInfo.content;
    _j_captchaF.text = _feedBackInfo.j_captcha;
    
}
#pragma mark Btn
- (IBAction)submitBtnClicked:(id)sender {
    _feedBackInfo.name = _nameF.text;
    _feedBackInfo.phone = _phoneF.text;
    _feedBackInfo.email = _emailF.text;
    _feedBackInfo.content = _contentF.text;
    _feedBackInfo.j_captcha = _j_captchaF.text;
    NSString *tipStr = [_feedBackInfo hasErrorTip];
    if (tipStr.length > 0) {
        [NSObject showHUDQueryStr:tipStr];
        return;
    }
    [NSObject showHUDQueryStr:@"正在发送"];
    [[Coding_NetAPIManager sharedManager] post_FeedBack:_feedBackInfo andBlock:^(id data, NSError *error) {
        [NSObject hideHUDQuery];
        if (data) {
            [self.navigationController popViewControllerAnimated:YES];
            [NSObject showHudTipStr:@"反馈成功"];
        }
    }];
}
- (void)refreshCaptchaImage{
    [self.j_captchaImgV setImage:nil];
    [[Coding_NetAPIManager sharedManager] get_CurrentUserAutoShowError:NO andBlock:^(id dataNoUse, NSError *errorNoUse) {
        [[Coding_NetAPIManager sharedManager] loadCaptchaImgWithCompleteBlock:^(UIImage *image, NSError *error) {
            [self.j_captchaImgV setImage:image];
        }];
    }];
}
#pragma mark Table M
- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
    UIView *headerV;
    if (section > 0) {
        headerV = [UIView new];
    }
    return headerV;
}
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    CGFloat sectionH = 0;
    if (section > 0) {
        sectionH = 10;
    }
    return sectionH;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}



@end
