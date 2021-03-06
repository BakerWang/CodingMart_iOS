//
//  RootViewController.m
//  CodingMart
//
//  Created by Ease on 15/10/8.
//  Copyright © 2015年 net.coding. All rights reserved.
//

#import "RootRewardsViewController.h"
#import "RewardDetailViewController.h"
#import "Login.h"
#import "UserInfoViewController.h"
#import "LoginViewController.h"
#import "CaseListViewController.h"
#import "MartIntroduceViewController.h"
#import "Coding_NetAPIManager.h"
#import "RewardListCell.h"
#import "HighPaidAreaCell.h"
#import "NotificationViewController.h"
#import "RDVTabBarController.h"
#import "EaseDropListView.h"
#import <ReactiveCocoa/ReactiveCocoa.h>
#import "Rewards.h"
#import "SVPullToRefresh.h"
#import "EATipView.h"

@interface RootRewardsViewController ()<UITableViewDataSource, UITableViewDelegate>
@property (strong, nonatomic) NSArray *typeList, *statusList, *roleTypeList;
@property (strong, nonatomic) NSMutableDictionary *rewardsDict;

@property (strong, nonatomic) NSString *selectedType, *selectedStatus, *selectedRoleType;
@property (strong, nonatomic, readonly) NSString *type_status_roleType;
@property (strong, nonatomic, readonly) NSArray *dataList;
@property (strong, nonatomic, readonly) Rewards *curRewards;
@property (strong, nonatomic) Rewards *highPaidRewards;

@property (weak, nonatomic) IBOutlet UITableView *myTableView;
@property (weak, nonatomic) IBOutlet UIView *tabView;
@property (weak, nonatomic) IBOutlet UIButton *tabBtnType;
@property (weak, nonatomic) IBOutlet UIButton *tabBtnStatus;
@property (weak, nonatomic) IBOutlet UIButton *tabBtnRoleType;
@property (assign, nonatomic) NSInteger selectedTabIndex;
@property (strong, nonatomic) UIButton *rightNavBtn;
@property (strong, nonatomic) EATipView *tipV;
@end

@implementation RootRewardsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
//    _typeList = @[@"所有类型",
//                  @"Web 网站",
//                  @"APP 开发",
//                  @"微信公众号",
//                  @"HTML5 应用",
//                  @"小程序",
//                  @"咨询",
//                  @"其他"];
    _typeList = @[@"所有类型",
                  @"Web 网站",
                  @"APP 开发",
                  @"微信公众号",
                  @"HTML5 应用",
//                  @"小程序",
                  @"其他"];
    _statusList = @[@"所有进度",
                    @"未开始",
                    @"招募中",
                    @"开发中",
                    @"已结束"];
    _roleTypeList = @[@"所有角色",
                      @"全栈开发",
                      @"前端开发",
                      @"后端开发",
                      @"应用开发",
                      @"iOS开发",
                      @"Android开发",
                      @"产品经理",
                      @"设计师",
                      @"开发团队"];
    _selectedType = _typeList[0];
    _selectedStatus = _statusList[0];
    _selectedRoleType = _roleTypeList[0];
    _rewardsDict = [NSMutableDictionary new];

    [self p_setupContent];
    if (![FunctionTipsManager isAppUpdate]) {
        [MartFunctionTipView showFunctionImages:@[@"guidance_dev_rewards"] onlyOneTime:YES];
    }
}

- (void)p_setupContent{
    //tab
    [RACObserve(self, selectedType) subscribeNext:^(NSString *value) {
        [self.tabBtnType setTitle:value forState:UIControlStateNormal];
    }];
    [RACObserve(self, selectedStatus) subscribeNext:^(NSString *value) {
        [self.tabBtnStatus setTitle:value forState:UIControlStateNormal];
    }];
    [RACObserve(self, selectedRoleType) subscribeNext:^(NSString *value) {
        [self.tabBtnRoleType setTitle:value forState:UIControlStateNormal];
    }];
    self.selectedTabIndex = NSNotFound;
    //table
    UIEdgeInsets insets = UIEdgeInsetsMake(44, 0, CGRectGetHeight(self.rdv_tabBarController.tabBar.frame), 0);
    _myTableView.contentInset = insets;
    _myTableView.scrollIndicatorInsets = insets;
    _myTableView.separatorStyle = UITableViewCellSeparatorStyleNone;

    [_myTableView registerNib:[UINib nibWithNibName:kCellIdentifier_RewardListCell bundle:nil] forCellReuseIdentifier:kCellIdentifier_RewardListCell];
    [_myTableView registerNib:[UINib nibWithNibName:kCellIdentifier_HighPaidAreaCell bundle:nil] forCellReuseIdentifier:kCellIdentifier_HighPaidAreaCell];
    //        refresh
    [_myTableView eaAddPullToRefreshAction:@selector(refreshData) onTarget:self];
    __weak typeof(self) weakSelf = self;
    [_myTableView addInfiniteScrollingWithActionHandler:^{
        [weakSelf refreshDataMore:YES];
    }];
}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    [self refreshRightNavBtn];
    [self lazyRefreshData];
}

#pragma mark - Get_Set
- (NSString *)type_status_roleType{
    return [NSString stringWithFormat:@"%@_%@_%@", _selectedType, _selectedStatus, _selectedRoleType];
}

- (Rewards *)curRewards{
    Rewards *curRewards = self.rewardsDict[self.type_status_roleType];
    if (!curRewards) {
        curRewards = [Rewards RewardsWithType:_selectedType status:_selectedStatus roleType:_selectedRoleType];
        curRewards.isHighPaid = _isHighPaid;
        self.rewardsDict[self.type_status_roleType] = curRewards;
    }
    return curRewards;
}

- (NSArray *)dataList{
    return self.curRewards.list;
}

- (void)setSelectedTabIndex:(NSInteger)selectedTabIndex{
    _selectedTabIndex = selectedTabIndex;
    [self p_updateTabBtns];
}

#pragma mark refresh
- (void)lazyRefreshData{
    if (self.dataList.count > 0) {
        [self.myTableView removeBlankPageView];
        [_myTableView reloadData];
    }else{
        [_myTableView reloadData];
        [self refreshData];
    }
}

- (void)refreshData{
    [self refreshDataMore:NO];
    if (!_isHighPaid) {
        [self refreshHighPaidData];
    }
}

- (void)refreshDataMore:(BOOL)loadMore{
    if (self.curRewards.isLoading) {
        return;
    }
    if (!loadMore && self.dataList.count <= 0) {
        [self.view beginLoading];
    }
    self.curRewards.willLoadMore = loadMore;
    __weak typeof(self) weakSelf = self;
    [[Coding_NetAPIManager sharedManager] get_rewards:self.curRewards block:^(id data, NSError *error) {
        [weakSelf.view endLoading];
        [weakSelf.myTableView.pullRefreshCtrl endRefreshing];
        [weakSelf.myTableView.infiniteScrollingView stopAnimating];

        [weakSelf.myTableView reloadData];
        weakSelf.myTableView.showsInfiniteScrolling = weakSelf.curRewards.canLoadMore;
        [weakSelf configBlankPageHasError:error != nil hasData:self.dataList.count > 0];
    }];
}

- (void)refreshHighPaidData{
    if (!_highPaidRewards) {
        _highPaidRewards = [Rewards RewardsWithType:_typeList[0] status:_statusList[0] roleType:_roleTypeList[0]];
        _highPaidRewards.isHighPaid = YES;
    }
    if (self.highPaidRewards.isLoading) {
        return;
    }
    __weak typeof(self) weakSelf = self;
    [[Coding_NetAPIManager sharedManager] get_rewards:self.highPaidRewards block:^(id data, NSError *error) {
        [weakSelf.myTableView reloadData];
    }];
}

- (void)configBlankPageHasError:(BOOL)hasError hasData:(BOOL)hasData{
    __weak typeof(self) weakSelf = self;
    if (hasData) {
        [self.myTableView removeBlankPageView];
    }else if (hasError){
        [self.myTableView configBlankPageErrorBlock:^(id sender) {
            [weakSelf refreshData];
        }];
    }else{
        [self.myTableView configBlankPageImage:kBlankPageImageRewardList tipStr:@"当前还没有符合条件的项目"];
    }
    if (self.myTableView.blankPageView) {
        self.myTableView.blankPageView.frame = CGRectMake(0, 10, kScreen_Width, kScreen_Height - CGRectGetMaxY(self.tabView.frame));
    }
}

- (void)tabBarItemClicked{
    CGFloat contentOffsetY_Top = -CGRectGetMaxY(_tabView.frame);
    if (_myTableView.contentOffset.y > contentOffsetY_Top) {
        [_myTableView setContentOffset:CGPointMake(0, contentOffsetY_Top) animated:YES];
    }else if (!_myTableView.pullRefreshCtrl.isRefreshing){
        [_myTableView eaTriggerPullToRefresh];
        [self refreshData];
    }
}

#pragma mark - UnReadTip_NavBtn
- (void)refreshRightNavBtn{
    if (_isHighPaid) {
        if (!self.navigationItem.rightBarButtonItem) {
            self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"nav_icon_high_paid"] style:UIBarButtonItemStylePlain target:self action:@selector(showHighPaidTip)];
        }
    }else{
        self.navigationItem.rightBarButtonItem = nil;
    }
}

- (void)showHighPaidTip{
    if (!_tipV) {
        _tipV = [EATipView instancetypeWithTitle:@"码市直营项目专区" tipStr:@"码市直营作为服务商，直接面向需求方提供标准、稳定与有保障的软件开发服务。码市直营期待与优质开发者进行高效合作，共同完成项目交付，实现共赢。"];
    }
    if (_tipV.isShowing) {
        [_tipV dismiss];
    }else{
        [_tipV showInView:self.view];
    }
}

#pragma mark - tab_btn

- (IBAction)tabButtonClicked:(UIButton *)sender {
    NSInteger tag = sender.tag;

    if (self.tabView.easeDropListView.isShowing && self.selectedTabIndex == tag) {
        self.selectedTabIndex = NSNotFound;
        [self.tabView.easeDropListView dismissSendAction:NO];
    }else{
        self.selectedTabIndex = tag;
        NSArray *list = tag == 0? _typeList: tag == 1? _statusList: _roleTypeList;
        NSInteger index = [list indexOfObject:tag == 0? _selectedType: tag == 1? _selectedStatus: _selectedRoleType];
        CGFloat maxHeight = self.view.height - self.tabView.bottom - CGRectGetHeight(self.rdv_tabBarController.tabBar.frame);
        __weak typeof(self) weakSelf = self;
        [self.tabView showDropListWithData:list selectedIndex:index inView:self.view maxHeight:maxHeight actionBlock:^(EaseDropListView *dropView, BOOL isComfirmed) {
            if (dropView.selectedIndex != NSNotFound && isComfirmed) {
                NSString *tabStr = tag == 0? @"类型": tag == 1? @"进度": @"角色";
                NSString *valueStr = dropView.dataList[dropView.selectedIndex];
                [MobClick event:kUmeng_Event_UserAction label:[NSString stringWithFormat:@"项目_%@_%@", tabStr, valueStr]];
                if (tag == 0) {
                    weakSelf.selectedType = valueStr;
                }else if (tag == 1){
                    weakSelf.selectedStatus = valueStr;
                }else{
                    weakSelf.selectedRoleType = valueStr;
                }
                [weakSelf lazyRefreshData];
                weakSelf.myTableView.showsInfiniteScrolling = weakSelf.curRewards.canLoadMore;
            }
            self.selectedTabIndex = NSNotFound;
        }];
    }
}



- (void)p_updateTabBtns{
    for (UIButton *tabBtn in @[_tabBtnType, _tabBtnStatus, _tabBtnRoleType]) {
        tabBtn.imageView.transform = CGAffineTransformMakeRotation(self.selectedTabIndex == tabBtn.tag? M_PI: 0);
        CGFloat titleDiff = tabBtn.imageView.width + 2;
        CGFloat imageDiff = tabBtn.titleLabel.width + 2;
        tabBtn.titleEdgeInsets = UIEdgeInsetsMake(0, -titleDiff, 0, titleDiff);
        tabBtn.imageEdgeInsets = UIEdgeInsetsMake(0, imageDiff, 0, -imageDiff);
    }
}

#pragma mark Table M
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    if (_isHighPaid) {
        return self.dataList.count;
    }else{
        return self.dataList.count > 2? self.dataList.count + 1: self.dataList.count;
    }
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    if (_isHighPaid) {
        RewardListCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellIdentifier_RewardListCell forIndexPath:indexPath];
        cell.curReward = self.dataList[indexPath.row];
        return cell;
    }else{
        if (indexPath.row == 2) {
            HighPaidAreaCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellIdentifier_HighPaidAreaCell forIndexPath:indexPath];
            cell.dataList = _highPaidRewards.list;
            WEAKSELF
            [cell setItemClickedBlock:^(Reward *clickedR) {
                if (clickedR) {
                    [weakSelf goToReward:clickedR];
                }else{
                    RootRewardsViewController *vc = [RootRewardsViewController vcInStoryboard:@"Root"];
                    vc.isHighPaid = YES;
                    [weakSelf.navigationController pushViewController:vc animated:YES];
                }
            }];
            return cell;
        }else{
            RewardListCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellIdentifier_RewardListCell forIndexPath:indexPath];
            cell.curReward = self.dataList[indexPath.row > 2? indexPath.row - 1: indexPath.row];
            return cell;
        }
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    if (_isHighPaid) {
        return [RewardListCell cellHeight];
    }else{
        return indexPath.row == 2? [HighPaidAreaCell cellHeight]: [RewardListCell cellHeight];
    }
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath{
    if (_isHighPaid) {
        [tableView addLineforPlainCell:cell forRowAtIndexPath:indexPath withLeftSpace:12 hasSectionLine:YES];
    }else{
        [tableView addLineforPlainCell:cell forRowAtIndexPath:indexPath withLeftSpace:(indexPath.row == 1 || indexPath.row == 2)? 0: 12 hasSectionLine:YES];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (_isHighPaid) {
        [self goToReward:self.dataList[indexPath.row]];
    }else{
        if (indexPath.row != 2) {
            [self goToReward:self.dataList[indexPath.row > 2? indexPath.row - 1: indexPath.row]];
        }
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    return 10;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
    return [UIView new];
}

#pragma mark GoTo VC
- (void)goToReward:(Reward *)curReward{
    RewardDetailViewController *vc = [RewardDetailViewController vcWithReward:curReward];
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)goToNotificationVC{
    [MobClick event:kUmeng_Event_UserAction label:@"顶部导航_通知"];
    NotificationViewController *vc = [NotificationViewController storyboardVC];
    [self.navigationController pushViewController:vc animated:YES];
}
@end
