//
//  MPayWithdrawViewController.m
//  CodingMart
//
//  Created by Ease on 16/8/5.
//  Copyright © 2016年 net.coding. All rights reserved.
//

#import "MPayWithdrawViewController.h"
#import "Coding_NetAPIManager.h"
#import "EATextEditView.h"
#import "MPayWithdrawResultViewController.h"
#import "MPayPasswordByPhoneViewController.h"
#import "UITTTAttributedLabel.h"

@interface MPayWithdrawViewController ()
@property (weak, nonatomic) IBOutlet UITTTAttributedLabel *tipL;

@property (weak, nonatomic) IBOutlet UILabel *accountL;
@property (weak, nonatomic) IBOutlet UITextField *priceF;
@property (weak, nonatomic) IBOutlet UITextField *descriptionF;
@property (strong, nonatomic) NSNumber *balance;
@end

@implementation MPayWithdrawViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    WEAKSELF;
    [_tipL addLinkToStr:@"《码市开发宝服务协议》" value:nil hasUnderline:NO clickedBlock:^(id value) {
        [weakSelf goToWebVCWithUrlStr:@"https://dn-coding-net-public-file.qbox.me/fcc25988-7a53-4254-a3bb-0dc9f5f02e2c.pdf" title:value];
    }];
    _accountL.text = [NSString stringWithFormat:@"%@（%@）", _account.account, _account.name];
    [self refreshMaxPrice];
}

- (void)refreshMaxPrice{
    WEAKSELF;
    [[Coding_NetAPIManager sharedManager] get_MPayBalanceBlock:^(NSDictionary *data, NSError *error) {
        if (data) {
            weakSelf.priceF.placeholder = [NSString stringWithFormat:@"本次最大可提现金额 %@ 元", data[@"balance"]];
            weakSelf.balance = data[@"balanceValue"];
            if (weakSelf.balance.floatValue <= 0) {
                kTipAlert(@"账户余额不足，您无法进行提现操作。");
            }
        }
    }];
}

- (IBAction)footerBtnClicked:(id)sender {
    if (!_account) {
        _account = [MPayAccount new];
    }
    _account.price = _priceF.text;
    _account.description_mine = _descriptionF.text;

    NSString *tipStr;
    if (_balance.floatValue <= 0) {
        tipStr = @"账户余额不足，您无法进行提现操作。";
    }else if (!_account) {
        tipStr = @"未能获取到账户信息";
    }else if (_account.price.length <= 0 || _account.price.floatValue <= 0) {
        tipStr = @"提现金额必须大于 0";
    }
    if (tipStr) {
        [NSObject showHudTipStr:tipStr];
        return;
    }

    WEAKSELF;
    EATextEditView *psdView = [EATextEditView instancetypeWithTitle:@"请输入交易密码" tipStr:@"请输入交易密码" andConfirmBlock:^(NSString *text) {
        [weakSelf sendRequestWithPsd:[text sha1Str]];
    }];
    psdView.isForPassword = YES;
    psdView.forgetPasswordBlock = ^(){
        MPayPasswordByPhoneViewController *vc = [MPayPasswordByPhoneViewController vcInStoryboard:@"UserInfo"];
        [weakSelf.navigationController pushViewController:vc animated:YES];
    };
    [psdView showInView:self.view];
}

- (void)sendRequestWithPsd:(NSString *)psd{
    _account.password = psd;
    WEAKSELF;
    [NSObject showHUDQueryStr:@"正在提交..."];
    [[Coding_NetAPIManager sharedManager] post_WithdrawMPayAccount:_account block:^(id data, NSError *error) {
        [NSObject hideHUDQuery];
        if (data) {
            UINavigationController *nav = weakSelf.navigationController;
            [nav popViewControllerAnimated:NO];
            [nav pushViewController:[MPayWithdrawResultViewController vcWithWithdraw:data] animated:YES];
        }
    }];
}
@end
