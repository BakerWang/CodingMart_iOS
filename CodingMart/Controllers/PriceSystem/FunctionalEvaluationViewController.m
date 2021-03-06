//
//  FunctionalEvaluationViewController.m
//  CodingMart
//
//  Created by Frank on 16/5/25.
//  Copyright © 2016年 net.coding. All rights reserved.
//

#define kFunctionalEvaluation_TopY 0.0

#import "FunctionalEvaluationViewController.h"
#import "UIView+BlocksKit.h"
#import "FunctionMenu.h"
#import "FunctionalSecondMenuCell.h"
#import "FunctionalThirdCell.h"
#import "FunctionalThirdMutableCell.h"
#import "FunctionalHeaderView.h"
#import "ShoppingCarHeaderView.h"
#import "ShoppingCarCell.h"
#import "CalcPriceViewController.h"
#import "Reward.h"
#import "PublishRewardViewController.h"
#import <FDFullscreenPopGesture/UINavigationController+FDFullscreenPopGesture.h>
#import "Login.h"
#import "LoginViewController.h"

@interface FunctionalEvaluationViewController () <UITableViewDelegate, UITableViewDataSource, UIAlertViewDelegate>

@property (strong, nonatomic) UIView *backgroundView, *lineView;
@property (strong, nonatomic) UIScrollView *topMenuView;
@property (strong, nonatomic) UIView *selectView;
@property (strong, nonatomic) NSDictionary *data;
@property (assign, nonatomic) NSInteger selectedIndex, selectedFirstIndex, selectedSecondIndex;
@property (strong, nonatomic) UIScrollView *firstMenuScrollView;
@property (strong, nonatomic) UIView *firstMenuSelectView; // 第一级菜单选中的背景
@property (strong, nonatomic) NSMutableArray *firstMenuArray, *secondMenuArray;
@property (strong, nonatomic) NSMutableDictionary *thirdMenuDict, *shoppingDict;
@property (strong, nonatomic) UITableView *secondMenuTableView, *thirdMenuTableView, *shoppingCarTableView;
@property (strong, nonatomic) UIView *bottomMenuView, *bubbleView;
@property (strong, nonatomic) UILabel *bottomMenuLabel, *numberLabel;
@property (strong, nonatomic) UIButton *calcButton;
@property (strong, nonatomic) UIView *bgView;
@property (strong, nonatomic) ShoppingCarHeaderView *header;
@property (strong, nonatomic) UIView *shoppingCarBgView;
@property (strong, nonatomic) NSMutableDictionary *shoppingCarDefaultDict;
@property (strong, nonatomic) UIView *platformView;
@property (assign, nonatomic) NSInteger notDefaultItemCount; // 不是默认的选项统计
@property (strong, nonatomic) NSNumber *webPageNumber;

@end

@implementation FunctionalEvaluationViewController

- (void)dealloc {
    [_secondMenuTableView setDelegate:nil];
    [_thirdMenuTableView setDelegate:nil];
    [_shoppingCarTableView setDelegate:nil];
    [_bgView removeFromSuperview];
    [_shoppingCarBgView removeFromSuperview];
    [_bottomMenuView removeFromSuperview];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.automaticallyAdjustsScrollViewInsets = NO;
    self.fd_interactivePopDisabled = YES;
    
    [self setTitle:@"功能评估"];
    UIButton *backButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [backButton setFrame:CGRectMake(0, 0, 100, 40)];
    [backButton setTitle:@"修改平台" forState:UIControlStateNormal];
    [backButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [backButton.titleLabel setFont:[UIFont systemFontOfSize:14.0f]];
    [backButton addTarget:self action:@selector(changePlatform) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *backItem = [[UIBarButtonItem alloc] initWithCustomView:backButton];
    UIBarButtonItem *space = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    space.width = -25;
    [self.navigationItem setRightBarButtonItems:@[space, backItem]];
    
    _data = [NSObject loadResponseWithPath:@"priceListData"];
    _firstMenuArray = [NSMutableArray array];
    _secondMenuArray = [NSMutableArray array];
    _thirdMenuDict = [NSMutableDictionary dictionary];
    _shoppingDict = [NSMutableDictionary dictionary];
    _shoppingCarDefaultDict = [NSMutableDictionary dictionary];
    _selectedIndex = 0;
    _selectedFirstIndex = 0;
    _notDefaultItemCount = 0;
    _webPageNumber = @0;
    
    // 加载顶部菜单
    [self addTopMenu];
    // 加载底部菜单
    [self addBottomMenu];
    // 生成默认数据
    [self generateDefaultShoppingCarData];
    
    UISwipeGestureRecognizer *leftSwip = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeMenu:)];
    [leftSwip setDirection:UISwipeGestureRecognizerDirectionRight];
    UISwipeGestureRecognizer *rightSwip = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeMenu:)];
    [rightSwip setDirection:UISwipeGestureRecognizerDirectionLeft];
    [self.view addGestureRecognizer:leftSwip];
    [self.view addGestureRecognizer:rightSwip];
}

// 生成购物车默认数据
- (void)generateDefaultShoppingCarData {
    [_shoppingCarDefaultDict removeAllObjects];
    
    NSMutableArray *carIDArray = [NSMutableArray arrayWithArray:_menuIDArray];
    for (int i = 0; i < carIDArray.count; i++) {
        NSMutableDictionary *allMenuDict = [_data objectForKey:@"quotations"];
        NSMutableArray *firstMenuArray = [NSMutableArray array];
        NSMutableArray *secondMenuArray = [NSMutableArray array];
        NSMutableArray *defalutArray = [NSMutableArray array];

        // 一级菜单
        FunctionMenu *firstMenu = [NSObject objectOfClass:@"FunctionMenu" fromJSON:[allMenuDict objectForKey:carIDArray[i]]];
        NSString *children = firstMenu.children;
        NSArray *childrenArray = [children componentsSeparatedByString:@","];
        for (int j = 0; j < childrenArray.count; j++) {
            FunctionMenu *menu = [NSObject objectOfClass:@"FunctionMenu" fromJSON:[allMenuDict objectForKey:childrenArray[j]]];
            [firstMenuArray addObject:menu];
        }
        
        // 二级菜单
        for (FunctionMenu *menu in firstMenuArray) {
            NSArray *array = [menu.children componentsSeparatedByString:@","];
            for (NSString *str in array) {
                FunctionMenu *secondMenu = [NSObject objectOfClass:@"FunctionMenu" fromJSON:[allMenuDict objectForKey:str]];
                [secondMenuArray addObject:secondMenu];
            }
        }
        
        // 三级菜单
        for (FunctionMenu *menu in secondMenuArray) {
            if ([menu.dom_type isEqual:@2]) {
                // 单选框默认添加第一个(改：有默认就用默认，没有的话才用第一个)
                NSArray *array = [menu.children componentsSeparatedByString:@","];
                FunctionMenu *thirdMenu = nil;
                for (NSString *str in array) {
                    if (str.length) {
                        thirdMenu = [NSObject objectOfClass:@"FunctionMenu" fromJSON:[allMenuDict objectForKey:str]];
                        if ([thirdMenu.is_default isEqual:@1]) {
                            [defalutArray addObject:thirdMenu];
                            break;
                        }else{
                            thirdMenu = nil;
                        }
                    }
                }
                if (!thirdMenu) {
                    NSString *str = [array firstObject];
                    if (str.length) {
                        FunctionMenu *thirdMenu = [NSObject objectOfClass:@"FunctionMenu" fromJSON:[allMenuDict objectForKey:str]];
                        [defalutArray addObject:thirdMenu];
                    }
                }
            } else {
                NSArray *array = [menu.children componentsSeparatedByString:@","];
                for (NSString *str in array) {
                    if (str.length) {
                        FunctionMenu *thirdMenu = [NSObject objectOfClass:@"FunctionMenu" fromJSON:[allMenuDict objectForKey:str]];
                        if ([thirdMenu.title isEqualToString:@"主内容增删改查"]) {
                            NSLog(@"zhuazhu");
                        }
                        if ([thirdMenu.is_default isEqual:@1]) {
                            [defalutArray addObject:thirdMenu];
                        }
                    }
                }
            }
        }
        
        [_shoppingCarDefaultDict setObject:defalutArray forKey:_selectedMenuArray[i]];
    }
    _shoppingDict = _shoppingCarDefaultDict;
    [self updateShoppingCar];
}

- (void)swipeMenu:(UISwipeGestureRecognizer *)swipe {
    if (swipe.direction == UISwipeGestureRecognizerDirectionRight) {
        if (_selectedIndex - 1 >= 0) {
            _selectedIndex--;
            UIButton *button = (UIButton *)[_topMenuView viewWithTag:_selectedIndex + 1];
            [self selectButtonAtIndex:button];
        }
    } else if (swipe.direction == UISwipeGestureRecognizerDirectionLeft) {
        if (_selectedIndex + 1 < _selectedMenuArray.count) {
            _selectedIndex++;
            UIButton *button = (UIButton *)[_topMenuView viewWithTag:_selectedIndex + 1];
            [self selectButtonAtIndex:button];
        }
    }
}

- (void)addTopMenu {
    if (_topMenuView) {
        [_topMenuView removeFromSuperview];
        _topMenuView = nil;
    }
    
    _topMenuView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, kFunctionalEvaluation_TopY, kScreen_Width, 44)];
    [_topMenuView setBackgroundColor:[UIColor whiteColor]];
    [_topMenuView setShowsHorizontalScrollIndicator:NO];
    [_topMenuView setShowsVerticalScrollIndicator:NO];
    [_topMenuView setClipsToBounds:YES];
    [self.view addSubview:_topMenuView];
    
    // 分割线
    if (_lineView) {
        [_lineView removeFromSuperview];
        _lineView = nil;
    }
    _lineView = [[UIView alloc] initWithFrame:CGRectMake(0, kFunctionalEvaluation_TopY + 44 - 0.5, _topMenuView.width, 0.5)];
    [_lineView setBackgroundColor:[UIColor colorWithHexString:@"DDDDDD"]];
    [self.view addSubview:_lineView];
    
    // 增加菜单
    float lastX = 0;
    UIButton *firstButton;
    for (int i = 0; i < _selectedMenuArray.count; i++) {
        NSString *title = _selectedMenuArray[i];
        CGSize size = [title getSizeWithFont:[UIFont systemFontOfSize:14.0f] constrainedToSize:CGSizeMake(CGFLOAT_MAX, 44)];
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        [button setTitle:title forState:UIControlStateNormal];
        [button setBackgroundColor:[UIColor whiteColor]];
        [button setFrame:CGRectMake(lastX, 0, size.width + 20, 44)];
        [button setTitleColor:[UIColor colorWithHexString:@"222222"] forState:UIControlStateNormal];
        [button setTitleColor:[UIColor colorWithHexString:@"4289DB"] forState:UIControlStateSelected];
        [button.titleLabel setFont:[UIFont systemFontOfSize:14.0f]];
        [button setTag:i+1];
        [button addTarget:self action:@selector(selectButtonAtIndex:) forControlEvents:UIControlEventTouchUpInside];
        float scrollWith = _topMenuView.contentSize.width;
        scrollWith += button.frame.size.width;
        [_topMenuView setContentSize:CGSizeMake(scrollWith, _topMenuView.frame.size.height)];
        [_topMenuView addSubview:button];
        lastX = CGRectGetMaxX(button.frame);
        if (i == _selectedIndex) {
            firstButton = button;
        }
    }
    
    // 选中指示条
    _selectView = [[UIView alloc] initWithFrame:CGRectMake(0, 42, 100, 2)];
    [_selectView setBackgroundColor:[UIColor colorWithHexString:@"4289DB"]];
    [_topMenuView addSubview:_selectView];
    
    [self selectButtonAtIndex:firstButton];
}

- (void)selectButtonAtIndex:(UIButton *)button {
    _selectedIndex = button.tag - 1;
    NSArray *array = _topMenuView.subviews;
    for (int i = 0; i < array.count; i++) {
        id v = [array objectAtIndex:i];
        if ([v isKindOfClass:[UIButton class]]) {
            UIButton *btn = (UIButton *)v;
            if (btn.tag == button.tag) {
                [btn setSelected:YES];
            } else {
                [btn setSelected:NO];
            }
        }
    }
    
    if (button.right > _topMenuView.width) {
        [_topMenuView setContentOffset:CGPointMake(button.right - _topMenuView.width, 0) animated:YES];
    } else if (button.left < _topMenuView.contentOffset.x) {
        [_topMenuView setContentOffset:CGPointMake(button.left - _topMenuView.contentOffset.x > 0 ? : 0, 0) animated:YES];
    }
    
    [_selectView setWidth:button.frame.size.width - 20];
    [UIView animateWithDuration:0.2 animations:^{
        [_selectView setCenterX:button.centerX];
    }];
    
    [UIView animateWithDuration:0.2 animations:^{
        [_thirdMenuTableView setX:kScreen_Width];
    }];

    [self addFirstMenu];
}

- (void)changePlatform {
    __weak typeof(self)weakSelf = self;
    if (!_backgroundView) {
        _backgroundView = [[UIView alloc] initWithFrame:kScreen_Bounds];
        [_backgroundView setBackgroundColor:[[UIColor blackColor] colorWithAlphaComponent:0.3]];
        [_backgroundView bk_whenTapped:^{
            [weakSelf dismiss];
        }];
        [kKeyWindow addSubview:_backgroundView];
    }
    
    // 选择平台窗口
    _platformView = [[UIView alloc] initWithFrame:CGRectMake(15, kScreen_Height, kScreen_Width - 30, 295)];
    [_platformView setBackgroundColor:[UIColor whiteColor]];
    [_platformView.layer setCornerRadius:2.0f];
    [_platformView setTag:99];
    [_backgroundView addSubview:_platformView];
    
    // 修改平台
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(15, 15, 100, 21)];
    [label setText:@"修改平台"];
    [label setTextColor:[UIColor blackColor]];
    [label setFont:[UIFont systemFontOfSize:15.0f]];
    [_platformView addSubview:label];
    
    // 分割线
    CGFloat lineWidth = 1.0 / [UIScreen mainScreen].scale;

    UIView *lineView = [[UIView alloc] initWithFrame:CGRectMake(15, 45, _platformView.frame.size.width - 30, lineWidth)];
    [lineView setBackgroundColor:[UIColor colorWithHexString:@"4289DB"]];
    [_platformView addSubview:lineView];
    
    // 平台按钮
    float buttonWidth = (_platformView.frame.size.width-15*3)/2;
    float buttonY = CGRectGetMaxY(lineView.frame);
    
    for (int i = 0; i < _menuArray.count; i++) {
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        UIImage *normalImage = [UIImage imageWithColor:[UIColor colorWithHexString:@"F3F3F3"]];
        UIImage *selectedImage = [UIImage imageWithColor:[UIColor colorWithHexString:@"4289DB"]];
        [button setBackgroundImage:normalImage forState:UIControlStateNormal];
        [button setBackgroundImage:selectedImage forState:UIControlStateSelected];
        [button setBackgroundImage:selectedImage forState:UIControlStateHighlighted];
        [button setTitle:_menuArray[i] forState:UIControlStateNormal];
        [button setTitleColor:[UIColor colorWithHexString:@"666666"] forState:UIControlStateNormal];
        [button setTitleColor:[UIColor whiteColor] forState:UIControlStateSelected];
        [button setTitleColor:[UIColor whiteColor] forState:UIControlStateHighlighted];
        [button.titleLabel setFont:[UIFont systemFontOfSize:15.0f]];
        [button setFrame:CGRectMake(i%2*buttonWidth + i%2*15 + 15, buttonY + i/2*36 + i/2*10 + 15, buttonWidth, 36)];
        [button.layer setCornerRadius:2.0f];
        [button setClipsToBounds:YES];
        [button setTag:i+100];
        [button addTarget:self action:@selector(platformButtonPress:) forControlEvents:UIControlEventTouchUpInside];
        [_platformView addSubview:button];
        
        for (int j = 0; j < _selectedMenuArray.count; j++) {
            NSString *selectedMenu = [_selectedMenuArray objectAtIndex:j];
            NSString *currentMenu = [_menuArray objectAtIndex:i];
            if ([selectedMenu isEqualToString:currentMenu]) {
                [button setSelected:YES];
            }
        }
    }
    
    float viewWidth = CGRectGetWidth(_platformView.frame);
    float viewHeight = CGRectGetHeight(_platformView.frame);
    
    // 底部分割线
    UIView *bottomLineView = [[UIView alloc] initWithFrame:CGRectMake(0, viewHeight - 45, _platformView.frame.size.width, lineWidth)];
    [bottomLineView setBackgroundColor:[UIColor colorWithHexString:@"CCCCCC"]];
    [_platformView addSubview:bottomLineView];
    
    // 取消按钮
    UIButton *cancelButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [cancelButton setFrame:CGRectMake(0, viewHeight - 44, viewWidth/2, 44)];
    [cancelButton setTitle:@"取消" forState:UIControlStateNormal];
    [cancelButton setTitleColor:[UIColor colorWithHexString:@"222222"] forState:UIControlStateNormal];
    [cancelButton.titleLabel setFont:[UIFont systemFontOfSize:15.0f]];
    [cancelButton addTarget:self action:@selector(cancelButtonPress) forControlEvents:UIControlEventTouchUpInside];
    [_platformView addSubview:cancelButton];
    
    // 确定按钮
    UIButton *confirmButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [confirmButton setFrame:CGRectMake(viewWidth/2, viewHeight - 44, viewWidth/2, 44)];
    [confirmButton setTitle:@"确定" forState:UIControlStateNormal];
    [confirmButton setTitleColor:[UIColor colorWithHexString:@"222222"] forState:UIControlStateNormal];
    [confirmButton.titleLabel setFont:[UIFont systemFontOfSize:15.0f]];
    [confirmButton addTarget:self action:@selector(confirmButtonPress) forControlEvents:UIControlEventTouchUpInside];
    [_platformView addSubview:confirmButton];
    
    // 按钮分割线
    UIView *buttonLine = [[UIView alloc] initWithFrame:CGRectMake(viewWidth/2, viewHeight-44, lineWidth, 44)];
    [buttonLine setBackgroundColor:[UIColor colorWithHexString:@"CCCCCC"]];
    [_platformView addSubview:buttonLine];
    
    [UIView animateWithDuration:0.2 animations:^{
        _platformView.centerY = kScreen_Height / 2;
    }];
}

- (void)platformButtonPress:(UIButton *)button {
    [button setSelected:!button.selected];
}

- (void)cancelButtonPress {
    [self dismiss];
}

- (void)confirmButtonPress {
    UIView *platformView = (UIView *)[_backgroundView viewWithTag:99];
    NSMutableArray *tempArray = [NSMutableArray array];
    NSMutableArray *tempIDArray = [NSMutableArray array];
    for (int i = 0; i < _menuArray.count; i++) {
        UIButton *button = (UIButton *)[platformView viewWithTag:i+100];
        if (button.selected) {
            [tempArray addObject:button.titleLabel.text];
            [tempIDArray addObject:[_allIDArray objectAtIndex:i]];
        }
    }
    if ([self p_needServerInList:tempIDArray]) {
        [tempIDArray addObject:@"P006"];
        [tempArray addObject:@"管理后台"];
    }

    _selectedMenuArray = tempArray;
    _menuIDArray = tempIDArray;
    [self dismiss];
    _selectedIndex = 0;
    [self addTopMenu];
    [self generateDefaultShoppingCarData];
}

- (BOOL)p_needServerInList:(NSArray *)idList{
    NSSet *idSet = [[NSSet alloc] initWithArray:idList];
    return ![idSet isSubsetOfSet:[NSSet setWithObjects:@"P007", @"P008", nil]];
}

+ (UIImage *)imageWithColor:(UIColor *)color
{
    CGRect rect = CGRectMake(0.0f, 0.0f, 1.0f, 1.0f);
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetFillColorWithColor(context, [color CGColor]);
    CGContextFillRect(context, rect);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

- (void)dismiss {
    [UIView animateWithDuration:0.2 animations:^{
        [_platformView setY:kScreen_Height];
    } completion:^(BOOL finished) {
        [_backgroundView removeFromSuperview];
        _backgroundView = nil;
    }];
}

#pragma mark - 一级菜单
// 加载一级菜单
- (void)addFirstMenu {
    if (_firstMenuScrollView) {
        for (id v in _firstMenuScrollView.subviews) {
            [v removeFromSuperview];
        }
        [_firstMenuScrollView setWidth:kScreen_Width * 0.33];
    } else {
        _firstMenuScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(_topMenuView.frame), kScreen_Width * 0.33, kScreen_Height - 44 - 64)];
        [_firstMenuScrollView setBackgroundColor:[UIColor colorWithHexString:@"8796A8"]];
        [self.view addSubview:_firstMenuScrollView];
    }
    [_firstMenuArray removeAllObjects];
    
    NSString *platforms = [_menuIDArray objectAtIndex:_selectedIndex];
    NSMutableDictionary *allMenuDict = [_data objectForKey:@"quotations"];
    NSDictionary *menuDict = [allMenuDict objectForKey:platforms];
    FunctionMenu *menu = [NSObject objectOfClass:@"FunctionMenu" fromJSON:menuDict];
    
    // 找出子模块
    NSString *children = menu.children;
    NSArray *childrenArray = [children componentsSeparatedByString:@","];
    for (int i = 0; i < childrenArray.count; i++) {
        FunctionMenu *menu = [NSObject objectOfClass:@"FunctionMenu" fromJSON:[allMenuDict objectForKey:childrenArray[i]]];
        [_firstMenuArray addObject:menu];
    }
    
    _firstMenuSelectView = [[UIView alloc] initWithFrame:CGRectMake(5, 8, _firstMenuScrollView.frame.size.width - 10, 45)];
    [_firstMenuSelectView setBackgroundColor:[UIColor whiteColor]];
    [_firstMenuSelectView setCornerRadius:2.0f];
    [_firstMenuScrollView addSubview:_firstMenuSelectView];
    
    UIButton *firstButton;
    for (int i = 0; i < _firstMenuArray.count; i++) {
        FunctionMenu *menu = [_firstMenuArray objectAtIndex:i];
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        [button setTitle:menu.title forState:UIControlStateNormal];
        [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [button setTitleColor:[UIColor colorWithHexString:@"8796A8"] forState:UIControlStateSelected];
        [button setTitleColor:[UIColor colorWithHexString:@"8796A8"] forState:UIControlStateHighlighted];
        [button setBackgroundColor:[UIColor clearColor]];
        [button setFrame:CGRectMake(10, i*60, _firstMenuScrollView.frame.size.width - 20, 60)];
        [button setTag:i+10];
        [button.titleLabel setFont:[UIFont systemFontOfSize:14.0f]];
        [button.titleLabel setTextAlignment:NSTextAlignmentLeft];
        [button.titleLabel setNumberOfLines:0];
        [button addTarget:self action:@selector(firstMenuButtonPress:) forControlEvents:UIControlEventTouchUpInside];
        [_firstMenuScrollView addSubview:button];
        if (i == 0) {
            [button setSelected:YES];
            firstButton = button;
        }
        
        // 分割线
        UIView *lineView = [[UIView alloc] initWithFrame:CGRectMake(10, CGRectGetMaxY(button.frame), _firstMenuScrollView.frame.size.width - 20, 1)];
        [lineView setBackgroundColor:[UIColor whiteColor]];
        [lineView setTag:i+20];
        [_firstMenuScrollView addSubview:lineView];
    }
    
    [self firstMenuButtonPress:firstButton];
}

- (void)firstMenuButtonPress:(UIButton *)button {
    _selectedFirstIndex = button.tag - 10;
    NSArray *array = _firstMenuScrollView.subviews;
    for (int i = 0; i < array.count; i++) {
        id v = [array objectAtIndex:i];
        if ([v isKindOfClass:[UIButton class]]) {
            UIButton *btn = (UIButton *)v;
            if (btn.tag == button.tag) {
                [btn setSelected:YES];
            } else {
                [btn setSelected:NO];
            }
        }
    }
    
    [UIView animateWithDuration:0.2 animations:^{
        [_firstMenuSelectView setCenterY:button.centerY];
    }];
    
    // 加载二级菜单
    if (!_secondMenuTableView) {
        [self addSecondMenu];
    } else {
        // 更新二级菜单
        [self generateSecondMenu];
        [_secondMenuTableView setX:CGRectGetMaxX(_firstMenuScrollView.frame)];
        [_secondMenuTableView setWidth:kScreen_Width - _firstMenuScrollView.width];
        [_secondMenuTableView reloadData];
    }
    
    if (_firstMenuScrollView.width == 34.0f) {
        [self reduceFirstMenu];
    }
}


#pragma mark - 二级菜单
- (void)generateSecondMenu {
    [_secondMenuArray removeAllObjects];
    if (_selectedFirstIndex >= _firstMenuArray.count) {
        return;
    }
    FunctionMenu *firstMenu = [_firstMenuArray objectAtIndex:_selectedFirstIndex];
    NSMutableDictionary *allMenuDict = [_data objectForKey:@"quotations"];
    
    // 找二级菜单
    NSString *children = firstMenu.children;
    NSArray *childrenArray = [children componentsSeparatedByString:@","];
    for (int i = 0; i < childrenArray.count; i++) {
        FunctionMenu *menu = [NSObject objectOfClass:@"FunctionMenu" fromJSON:[allMenuDict objectForKey:childrenArray[i]]];
        [_secondMenuArray addObject:menu];
    }
    
    if ([[_selectedMenuArray objectAtIndex:_selectedIndex] isEqualToString:@"前端项目"]) {
        FunctionMenu *h5Menu = [[FunctionMenu alloc] init];
        h5Menu.title = @"页面数量";
        [_secondMenuArray addObject:h5Menu];
    }
}

- (void)addSecondMenu {
    [self generateSecondMenu];
    _secondMenuTableView = [[UITableView alloc] initWithFrame:CGRectMake(CGRectGetMaxX(_firstMenuScrollView.frame), CGRectGetMaxY(_topMenuView.frame), kScreen_Width - _firstMenuScrollView.frame.size.width, kScreen_Height - 44 - 64)];
    [_secondMenuTableView setBackgroundColor:[UIColor colorWithHexString:@"eaecee"]];
    [_secondMenuTableView setDelegate:self];
    [_secondMenuTableView setDataSource:self];
    [_secondMenuTableView setSeparatorColor:[UIColor colorWithHexString:@"DDDDDD"]];
    [_secondMenuTableView registerClass:[FunctionalSecondMenuCell class] forCellReuseIdentifier:[FunctionalSecondMenuCell cellID]];
    [self.view addSubview:_secondMenuTableView];
    [self setExtraCellLineHidden:_secondMenuTableView];
}

#pragma mark - 三级菜单
- (void)addThirdMenu {
    [self generateThirdMenu];
    _thirdMenuTableView = [[UITableView alloc] initWithFrame:CGRectMake(CGRectGetMaxX(_secondMenuTableView.frame), CGRectGetMaxY(_topMenuView.frame), kScreen_Width - CGRectGetMaxX(_secondMenuTableView.frame), _secondMenuTableView.frame.size.height) style:UITableViewStylePlain];
    _thirdMenuTableView.contentInset = UIEdgeInsetsMake(0, 0, _bottomMenuView.height, 0);
    [_thirdMenuTableView setDelegate:self];
    [_thirdMenuTableView setDataSource:self];
    [_thirdMenuTableView setSeparatorColor:[UIColor colorWithHexString:@"DDDDDD"]];
    [_thirdMenuTableView registerClass:[FunctionalThirdCell class] forCellReuseIdentifier:[FunctionalThirdCell cellID]];
    [_thirdMenuTableView registerClass:[FunctionalThirdMutableCell class] forCellReuseIdentifier:[FunctionalThirdMutableCell cellID]];
    [_thirdMenuTableView registerClass:[FunctionalHeaderView class] forHeaderFooterViewReuseIdentifier:[FunctionalHeaderView viewID]];
    [_thirdMenuTableView setAllowsMultipleSelection:YES];
    [self.view insertSubview:_thirdMenuTableView belowSubview:_bottomMenuView];
//    [self.view addSubview:_thirdMenuTableView];
}

- (void)generateThirdMenu {
    [_thirdMenuDict removeAllObjects];
    NSMutableDictionary *allMenuDict = [_data objectForKey:@"quotations"];
    NSInteger count = _secondMenuArray.count;
    if ([[_selectedMenuArray objectAtIndex:_selectedIndex] isEqualToString:@"前端项目"]) {
        count--;
    }
    for (int i = 0; i < count; i++) {
        FunctionMenu *menu = [_secondMenuArray objectAtIndex:i];
        NSArray *array = [menu.children componentsSeparatedByString:@","];
        NSMutableArray *mArray = [NSMutableArray array];
        for (int j = 0; j < array.count; j++) {
            NSString *key = array[j];
            if (key.length) {
                FunctionMenu *thirdMenu = [NSObject objectOfClass:@"FunctionMenu" fromJSON:[allMenuDict objectForKey:key]];
                [mArray addObject:thirdMenu];
            }
        }
        [_thirdMenuDict setObject:[mArray copy] forKey:menu.code];
    }
    
    if ([[_selectedMenuArray objectAtIndex:_selectedIndex] isEqualToString:@"前端项目"]) {
        FunctionMenu *menu = [[FunctionMenu alloc] init];
        menu.title = @"页面数量";
        [_thirdMenuDict setObject:menu forKey:@"页面数量"];
    }
}

#pragma mark - 底部菜单栏
- (void)addBottomMenu {
    CGFloat bottomMenuHeight = 44 + kSafeArea_Bottom;
    _bottomMenuView = [[UIView alloc] initWithFrame:CGRectMake(0, kScreen_Height - 44 - kSafeArea_Top - bottomMenuHeight, kScreen_Width, bottomMenuHeight)];
    [_bottomMenuView setBackgroundColor:[UIColor colorWithHexString:@"414952" andAlpha:0.9]];
    [_bottomMenuView setUserInteractionEnabled:YES];
    
    // 购物车数量
    UIImage *image = [UIImage imageNamed:@"price_selected_menu_list"];
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(kScreen_Width*0.04, 12, image.size.width, image.size.height)];
    [imageView setImage:image];
    [_bottomMenuView addSubview:imageView];
    
    // 描述
    _bottomMenuLabel = [[UILabel alloc] initWithFrame:CGRectMake(imageView.right + 10, 0, kScreen_Width - _bottomMenuView.width * 0.36 - imageView.width - 10, 44)];
    [_bottomMenuLabel setText:nil];
    [_bottomMenuLabel setTextColor:[UIColor whiteColor]];
    [_bottomMenuLabel setFont:[UIFont systemFontOfSize:13.0f]];
    [_bottomMenuLabel setAdjustsFontSizeToFitWidth:YES];
    [_bottomMenuLabel setNumberOfLines:1];
    [_bottomMenuView addSubview:_bottomMenuLabel];
    
    // 点击手势
    UITapGestureRecognizer *tgr = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(toggleShoppingCarTableView)];
    [_bottomMenuView addGestureRecognizer:tgr];
    
    [self.view addSubview:_bottomMenuView];
}

#pragma mark - 购物车
- (void)generateShoppingCarData:(NSIndexPath *)indexPath {
    // 检查是否是单选
    // 获取二级菜单
    FunctionMenu *secondMenu = [_secondMenuArray objectAtIndex:indexPath.section];
    if ([secondMenu.dom_type isEqual:@2]) {
        // 如果是单选选项的话，清空其他cell选中状态
        for (int i = 0; i < _secondMenuArray.count; i++) {
            if (i != indexPath.row) {
                NSIndexPath *theIndexPath = [NSIndexPath indexPathForRow:i inSection:indexPath.section];
                FunctionalSecondMenuCell *cell = [_thirdMenuTableView cellForRowAtIndexPath:theIndexPath];
                if (cell.selected) {
                    [cell setSelected:NO animated:YES];
                    [_thirdMenuTableView deselectRowAtIndexPath:theIndexPath animated:NO];
                    [self removeShoppingCarData:theIndexPath];
                    [self updateShoppingCar];
                }
            }
        }
    }
    
    // 获取主菜单
    NSString *topMenu = [_selectedMenuArray objectAtIndex:_selectedIndex];
    NSMutableArray *array = [NSMutableArray array];
    if ([_shoppingDict objectForKey:topMenu]) {
        array = [NSMutableArray arrayWithArray:[_shoppingDict objectForKey:topMenu]];
    }
    
    // 添加用户点击的数据
    NSMutableDictionary *tempDict = [NSMutableDictionary dictionary];
    FunctionMenu *menu = [_secondMenuArray objectAtIndex:indexPath.section];
    NSArray *thirdMenuArray = [_thirdMenuDict objectForKey:menu.code];
    FunctionMenu *thirdMenu = [thirdMenuArray objectAtIndex:indexPath.row];
    if (![array containsObject:thirdMenu]) {
        [array addObject:thirdMenu];
        [tempDict setObject:array forKey:topMenu];
    }
    if ([thirdMenu.is_default isEqual:@0]) {
        _notDefaultItemCount++;
    }
    
    [_shoppingDict addEntriesFromDictionary:tempDict];
}

- (void)removeShoppingCarData:(NSIndexPath *)indexPath {
    // 获取主菜单
    NSString *topMenu = [_selectedMenuArray objectAtIndex:_selectedIndex];
    NSMutableArray *array = [NSMutableArray array];
    if ([_shoppingDict objectForKey:topMenu]) {
        [array addObjectsFromArray:[_shoppingDict objectForKey:topMenu]];
    }
    
    // 移除用户点击的数据
    FunctionMenu *menu = [_secondMenuArray objectAtIndex:indexPath.section];
    NSArray *thirdMenuArray = [_thirdMenuDict objectForKey:menu.code];
    FunctionMenu *thirdMenu = [thirdMenuArray objectAtIndex:indexPath.row];
    for (FunctionMenu *tempMenu in [NSArray arrayWithArray:array]) {
        if ([tempMenu.code isEqualToString:thirdMenu.code]) {
            if ([tempMenu.is_default isEqual:@0]) {
                _notDefaultItemCount--;
            }
            [array removeObject:tempMenu];
            if (array.count) {
                [_shoppingDict setObject:[NSArray arrayWithArray:array] forKey:topMenu];
            } else {
                [_shoppingDict removeObjectForKey:topMenu];
            }
        }
    }
}

- (void)removeShoppingCarTableViewData:(NSIndexPath *)indexPath {
    // 获取主菜单
    ShoppingCarSectionHeaderView *header = (ShoppingCarSectionHeaderView *)[_shoppingCarTableView headerViewForSection:indexPath.section];
    NSString *topMenu = header.titleLabel.text;
    NSMutableArray *array = [NSMutableArray arrayWithArray:[_shoppingDict objectForKey:topMenu]];

    // 用户点击的cell
    if (indexPath.row >= array.count) {
        _webPageNumber = @0;
        return;
    }
    FunctionMenu *menu = [array objectAtIndex:indexPath.row];
    if ([menu.is_default isEqual:@0]) {
        _notDefaultItemCount--;
    }
    [array removeObject:menu];
    if (array.count) {
        [_shoppingDict setObject:[array copy] forKey:topMenu];
    } else {
        [_shoppingDict removeObjectForKey:topMenu];
    }
}

- (float)shoppingCarTableViewHeight {
    // 计算购物车高度
    NSArray *array = [_shoppingDict allValues];
    NSInteger count = 0;
    for (NSArray *subArray in array) {
        count += subArray.count;
    }
    if ([_webPageNumber intValue] > 0) {
        count++;
    }
    if (count == 0) {
        return 0 ;
    }
    float maxHeight = kScreen_Height * 0.6;
    float allCellHeight = count * 44;
    float allSectionHeight = array.count * 30;
    float shoppingCarHeight = allCellHeight + allSectionHeight;
    return shoppingCarHeight = (shoppingCarHeight > maxHeight) ? maxHeight : shoppingCarHeight;
}

- (void)addShoppingCarTableView {
    float shoppingCarHeight = [self shoppingCarTableViewHeight];
    if (!_shoppingCarTableView) {
        // 背景
        _bgView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, kScreen_Width, kScreen_Height - _bottomMenuView.height)];
        UITapGestureRecognizer *tgr = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideShoppingCar)];
        [_bgView addGestureRecognizer:tgr];
        [kKeyWindow addSubview:_bgView];
        
        // 列表区域背景
        _shoppingCarBgView = [[UIView alloc] initWithFrame:CGRectMake(0, kScreen_Height, kScreen_Width, 100)];
        [kKeyWindow addSubview:_shoppingCarBgView];
        
        // 头部菜单
        _header = [[ShoppingCarHeaderView alloc] initWithFrame:CGRectMake(0, 0, kScreen_Width, 44)];
        [_shoppingCarBgView addSubview:_header];
        
        __weak typeof(self)weakSelf = self;
        _header.clearBlock = ^(){
            [weakSelf.shoppingDict removeAllObjects];
            [weakSelf updateShoppingCar];
            [weakSelf.shoppingCarTableView reloadData];
            [weakSelf hideShoppingCar];
            [weakSelf.thirdMenuTableView reloadData];
        };
        _header.resetBlock = ^(){
            [weakSelf.shoppingDict removeAllObjects];
            [weakSelf resetShoppingCar];
            [weakSelf.shoppingCarTableView reloadData];
            [weakSelf.thirdMenuTableView reloadData];
        };

        // 列表
        _shoppingCarTableView = [[ UITableView alloc] initWithFrame:CGRectMake(0, 44, kScreen_Width, 100) style:UITableViewStylePlain];
        [_shoppingCarTableView registerClass:[ShoppingCarSectionHeaderView class] forHeaderFooterViewReuseIdentifier:[ShoppingCarSectionHeaderView viewID]];
        [_shoppingCarTableView registerClass:[ShoppingCarCell class] forCellReuseIdentifier:[ShoppingCarCell cellID]];
        [_shoppingCarTableView setSeparatorColor:[UIColor colorWithHexString:@"EFEFEF"]];
        [_shoppingCarTableView setDelegate:self];
        [_shoppingCarTableView setDataSource:self];
        [_shoppingCarBgView addSubview:_shoppingCarTableView];
    }
    [_shoppingCarBgView setFrame:CGRectMake(0, _shoppingCarBgView.y, kScreen_Width, shoppingCarHeight + 44)];
    [_shoppingCarTableView setFrame:CGRectMake(0, 44, kScreen_Width, shoppingCarHeight)];
    [_shoppingCarTableView reloadData];
    [kKeyWindow bringSubviewToFront:_bottomMenuView];
}

- (void)deleteItemFromShoppingCar {
    float shoppingCarHeight = [self shoppingCarTableViewHeight];
    [_shoppingCarBgView setFrame:CGRectMake(0, kScreen_Height - shoppingCarHeight - 44 - _bottomMenuView.height, kScreen_Width, shoppingCarHeight + 44)];
    [_shoppingCarTableView setFrame:CGRectMake(0, 44, kScreen_Width, shoppingCarHeight)];
    [_shoppingCarTableView reloadData];
}

- (void)toggleShoppingCarTableView {
    NSArray *array = [_shoppingDict allValues];
    NSInteger count = 0;
    for (NSArray *subArray in array) {
        count += subArray.count;
    }
    
    [self addShoppingCarTableView];
    
    if (_shoppingCarBgView.y < kScreen_Height) {
        // 隐藏
        [UIView animateWithDuration:0.2 animations:^{
            [_shoppingCarBgView setY:kScreen_Height];
            [_bgView setBackgroundColor:[UIColor colorWithHexString:@"0x000000" andAlpha:0.0]];
        } completion:^(BOOL finished) {
            [_bgView setHidden:YES];
        }];
    } else {
        // 显示
        [_bgView setHidden:NO];
        [UIView animateWithDuration:0.2 animations:^{
            [_shoppingCarBgView setY:kScreen_Height - _shoppingCarBgView.height - _bottomMenuView.height];
            [_bgView setBackgroundColor:[UIColor colorWithHexString:@"0x000000" andAlpha:0.4]];
        }];
    }
}

- (void)hideShoppingCar {
    // 隐藏
    [UIView animateWithDuration:0.2 animations:^{
        [_shoppingCarBgView setY:kScreen_Height];
        [_bgView setBackgroundColor:[UIColor colorWithHexString:@"0x000000" andAlpha:0.0]];
    } completion:^(BOOL finished) {
        [_bgView setHidden:YES];
    }];
}

#pragma mark - UITableViewDelagate
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (tableView == _thirdMenuTableView) {
        return _secondMenuArray.count;
    } else if (tableView == _shoppingCarTableView) {
        return _shoppingDict.count;
    }
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (tableView == _secondMenuTableView) {
        return _secondMenuArray.count;
    } else if (tableView == _thirdMenuTableView) {
        if ([[_selectedMenuArray objectAtIndex:_selectedIndex] isEqualToString:@"前端项目"] && section+1 == _secondMenuArray.count) {
            return 1;
        }
        FunctionMenu *menu = [_secondMenuArray objectAtIndex:section];
        NSArray *array = [menu.children componentsSeparatedByString:@","];
        NSInteger count = 0;
        for (NSString *str in array) {
            if (str.length) {
                count++;
            }
        }
        return count;
    } else if (tableView == _shoppingCarTableView) {
        NSArray *keyArray = [_shoppingDict allKeys];
        NSString *key = [keyArray objectAtIndex:section];
        NSArray *array = [_shoppingDict objectForKey:key];
        if ([key isEqualToString:@"前端项目"] && [_webPageNumber intValue] > 0) {
            return array.count + 1;
        }
        return array.count;
    }
    return 0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == _secondMenuTableView) {
        float width = _secondMenuTableView.width;
        FunctionMenu *menu = [_secondMenuArray objectAtIndex:indexPath.row];
        return [FunctionalSecondMenuCell calcHeight:menu width:width];
    } else if (tableView == _thirdMenuTableView) {
        FunctionMenu *menu = [_secondMenuArray objectAtIndex:indexPath.section];
        NSArray *thirdMenuArray = [_thirdMenuDict objectForKey:menu.code];
        FunctionMenu *thirdMenu = [thirdMenuArray objectAtIndex:indexPath.row];
        float height = [FunctionalThirdCell cellHeight:thirdMenu];
        return height;
    } else if (tableView == _shoppingCarTableView) {
        return 44.0f;
    }
    return 0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (tableView == _thirdMenuTableView) {
        return 30.0f;
    } else if (tableView == _shoppingCarTableView) {
        return 30.0f;
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == _secondMenuTableView) {
        FunctionalSecondMenuCell *cell = [tableView dequeueReusableCellWithIdentifier:[FunctionalSecondMenuCell cellID]];
        if (!cell) {
            cell = [[FunctionalSecondMenuCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:[FunctionalSecondMenuCell cellID]];
        }
        FunctionMenu *menu = [_secondMenuArray objectAtIndex:indexPath.row];
        [cell updateCell:menu width:_secondMenuTableView.width];
        return cell;
    } else if (tableView == _thirdMenuTableView){
        if ([[_selectedMenuArray objectAtIndex:_selectedIndex] isEqualToString:@"前端项目"] && indexPath.section+1 == _secondMenuArray.count) {
            FunctionalThirdMutableCell *cell = [tableView dequeueReusableCellWithIdentifier:[FunctionalThirdMutableCell cellID]];
            if (!cell) {
                cell = [[FunctionalThirdMutableCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:[FunctionalThirdMutableCell cellID]];
            }
            FunctionMenu *menu = [[FunctionMenu alloc] init];
            menu.title = @"页面数量";
            __weak typeof(self) weakSelf = self;
            cell.block = ^(NSNumber *number){
                weakSelf.webPageNumber = number;
                [weakSelf updateShoppingCar];
            };
            [cell updateCell:menu number:_webPageNumber];
            return cell;
        }
        FunctionalThirdCell *cell = [tableView dequeueReusableCellWithIdentifier:[FunctionalThirdCell cellID]];
        if (!cell) {
            cell = [[FunctionalThirdCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:[FunctionalThirdCell cellID]];
        }
        FunctionMenu *menu = [_secondMenuArray objectAtIndex:indexPath.section];
        NSArray *thirdMenuArray = [_thirdMenuDict objectForKey:menu.code];
        FunctionMenu *thirdMenu = [thirdMenuArray objectAtIndex:indexPath.row];
        [cell updateCell:thirdMenu];
        return cell;
    } else {
        ShoppingCarCell *cell = [tableView dequeueReusableCellWithIdentifier:[ShoppingCarCell cellID]];
        if (!cell) {
            cell = [[ShoppingCarCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:[ShoppingCarCell cellID]];
        }
        NSArray *keyArray = [_shoppingDict allKeys];
        NSString *key = [keyArray objectAtIndex:indexPath.section];
        NSArray *menuArray = [_shoppingDict objectForKey:key];
        if ([key isEqualToString:@"前端项目"] && ([_webPageNumber intValue] > 0 ) && indexPath.row == menuArray.count) {
            FunctionMenu *h5Menu = [[FunctionMenu alloc] init];
            h5Menu.title = [NSString stringWithFormat:@"页面数量（%@个）", _webPageNumber];
            [cell updateCell:h5Menu];
        } else {
            FunctionMenu *menu = [menuArray objectAtIndex:indexPath.row];
            [cell updateCell:menu];
        }
        return cell;
    }
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (tableView == _thirdMenuTableView){
        FunctionMenu *menu = [_secondMenuArray objectAtIndex:indexPath.section];
        NSArray *thirdMenuArray = [_thirdMenuDict objectForKey:menu.code];
        FunctionMenu *thirdMenu = [thirdMenuArray objectAtIndex:indexPath.row];
        // 循环购物车判断是否选中该item
        NSArray *selectedArray = [_shoppingDict objectForKey:[_selectedMenuArray objectAtIndex:_selectedIndex]];
        if (selectedArray.count) {
            for (FunctionMenu *selectedMenu in selectedArray) {
                if ([selectedMenu.code isEqualToString:thirdMenu.code]) {
//                    [cell setSelected:YES animated:NO];
                    [tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionNone];
                }
            }
        }
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == _secondMenuTableView) {
        // 缩小一级菜单
        if (_firstMenuScrollView.width != 34.0f) {
            [self reduceFirstMenu];
        }
        if (![[_selectedMenuArray objectAtIndex:_selectedIndex] isEqualToString:@"前端项目"] && indexPath.section+1 != _secondMenuArray.count) {
            _selectedSecondIndex = indexPath.row;
        }
        if (!_thirdMenuTableView) {
            [self addThirdMenu];
        } else {
            // 更新三级菜单
            [self generateThirdMenu];
            [_thirdMenuTableView setX:CGRectGetMaxX(_secondMenuTableView.frame)];
            [_thirdMenuTableView reloadData];
        }
        [_thirdMenuTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:indexPath.row] atScrollPosition:UITableViewScrollPositionTop animated:NO];
    } else if (tableView == _thirdMenuTableView) {
        if ([[_selectedMenuArray objectAtIndex:_selectedIndex] isEqualToString:@"前端项目"] && indexPath.section+1 == _secondMenuArray.count) {
            return;
        }
        [self generateShoppingCarData:indexPath];
        [self updateShoppingCar];
    } else if (tableView == _shoppingCarTableView) {
        [_thirdMenuTableView reloadData];
        [self removeShoppingCarTableViewData:indexPath];
        [self deleteItemFromShoppingCar];
        [self updateShoppingCar];
        
        NSArray *calcArray = [_shoppingDict allValues];
        NSInteger count = 0;
        for (NSArray *subArray in calcArray) {
            count += subArray.count;
        }
        if (count == 0) {
            [self hideShoppingCar];
        }
    }
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == _thirdMenuTableView) {
        [self removeShoppingCarData:indexPath];
        [self updateShoppingCar];
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if (tableView == _thirdMenuTableView) {
        FunctionMenu *menu = [_secondMenuArray objectAtIndex:section];
        FunctionalHeaderView *view = (FunctionalHeaderView *)[tableView dequeueReusableHeaderFooterViewWithIdentifier:[FunctionalHeaderView viewID]];
        if (!view) {
            view = [[FunctionalHeaderView alloc] initWithReuseIdentifier:[FunctionalHeaderView viewID]];
        }
        [view updateView:menu];
        // 滚动二级列表
//        NSInteger secondIndex = [_secondMenuArray indexOfObject:menu];
//        [_secondMenuTableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:secondIndex inSection:0] animated:YES scrollPosition:UITableViewScrollPositionNone];
        return view;
    } else {
        ShoppingCarSectionHeaderView *view = (ShoppingCarSectionHeaderView *)[tableView dequeueReusableHeaderFooterViewWithIdentifier:[ShoppingCarSectionHeaderView viewID]];
        if (!view) {
            view = [[ShoppingCarSectionHeaderView alloc] initWithReuseIdentifier:[ShoppingCarSectionHeaderView viewID]];
        }
        
        NSArray *keyArray = [_shoppingDict allKeys];
        [view updateCell:[keyArray objectAtIndex:section]];
        return view;
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    if (scrollView == _thirdMenuTableView) {
        NSArray *cellArray = _thirdMenuTableView.visibleCells;
        if (cellArray.count) {
            FunctionalSecondMenuCell *cell = (FunctionalSecondMenuCell *)cellArray.firstObject;
            NSIndexPath *indexPath = [_thirdMenuTableView indexPathForCell:cell];
            [_secondMenuTableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:indexPath.section inSection:0] animated:YES scrollPosition:UITableViewScrollPositionTop];
        }
    }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if (scrollView == _secondMenuTableView) {
        CGFloat contentYoffset = scrollView.contentOffset.y;
        
        if (contentYoffset > 100.0f) {
            [self firstMenuScrollToNext];
        } else if (contentYoffset < -100.0f){
            [self firstMenuScrollToPrev];
        }
    } else if (scrollView == _thirdMenuTableView) {
        NSArray *cellArray = _thirdMenuTableView.visibleCells;
        if (cellArray.count) {
            FunctionalSecondMenuCell *cell = (FunctionalSecondMenuCell *)cellArray.firstObject;
            NSIndexPath *indexPath = [_thirdMenuTableView indexPathForCell:cell];
            [_secondMenuTableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:indexPath.section inSection:0] animated:YES scrollPosition:UITableViewScrollPositionTop];
        }
    }
}

- (void)firstMenuScrollToNext {
    if (_selectedFirstIndex + 1 < _firstMenuArray.count) {
        _selectedFirstIndex++;
        NSArray *array = _firstMenuScrollView.subviews;
        for (int i = 0; i < array.count; i++) {
            id v = [array objectAtIndex:i];
            if ([v isKindOfClass:[UIButton class]]) {
                UIButton *btn = (UIButton *)v;
                if (btn.tag == _selectedFirstIndex + 10) {
                    [self firstMenuButtonPress:btn];
                }
            }
        }
    }
}

- (void)firstMenuScrollToPrev {
    if (_selectedFirstIndex - 1 >= 0) {
        _selectedFirstIndex--;
        NSArray *array = _firstMenuScrollView.subviews;
        for (int i = 0; i < array.count; i++) {
            id v = [array objectAtIndex:i];
            if ([v isKindOfClass:[UIButton class]]) {
                UIButton *btn = (UIButton *)v;
                if (btn.tag == _selectedFirstIndex + 10) {
                    [self firstMenuButtonPress:btn];
                }
            }
        }
    }
}

// 一二级菜单缩放
- (void)reduceFirstMenu {
    // 复原
    if (_firstMenuScrollView.width == 34.0f) {
        [UIView animateWithDuration:0.2 animations:^{
            [_firstMenuScrollView setWidth:kScreen_Width * 0.33];
            [_firstMenuSelectView setWidth:_firstMenuScrollView.frame.size.width - 10];
            [_thirdMenuTableView setX:kScreen_Width];
            // 修改显示文字
            for (int i = 0; i < _firstMenuArray.count; i++) {
                UIButton *btn = [_firstMenuScrollView viewWithTag:i+10];
                if (i < _firstMenuArray.count) {
                    FunctionMenu *menu = [_firstMenuArray objectAtIndex:i];
                    [btn setTitle:menu.title forState:UIControlStateNormal];
                }
                [btn setWidth:_firstMenuScrollView.frame.size.width - 20];
                [btn setTitleEdgeInsets:UIEdgeInsetsZero];
                UIView *view = [_firstMenuScrollView viewWithTag:i+20];
                [view setWidth:_firstMenuScrollView.frame.size.width - 20];
            }
        }];
        
        [_secondMenuTableView setX:CGRectGetMaxX(_firstMenuScrollView.frame)];
        [_secondMenuTableView setWidth:kScreen_Width - _firstMenuScrollView.frame.size.width];
        [_secondMenuTableView reloadData];
        [_thirdMenuTableView setX:kScreen_Width];
    } else {
        // 缩小
        [UIView animateWithDuration:0.2 animations:^{
            [_firstMenuScrollView setWidth:34.0f];
            [_firstMenuSelectView setWidth:24.0f];
            [_thirdMenuTableView setX:CGRectGetMaxX(_secondMenuTableView.frame)];

            // 修改显示文字
            for (int i = 0; i < _firstMenuArray.count; i++) {
                UIButton *btn = [_firstMenuScrollView viewWithTag:i+10];
                if (i < _firstMenuArray.count) {
                    FunctionMenu *menu = [_firstMenuArray objectAtIndex:i];
                    [btn setTitle:[menu.title substringToIndex:1] forState:UIControlStateNormal];
                }
                [btn setWidth:18.0f];
                [btn setTitleEdgeInsets:UIEdgeInsetsMake(0, -5, 0, 0)];
                UIView *view = [_firstMenuScrollView viewWithTag:i+20];
                [view setWidth:14.0f];
            }
        }];
        
        [_secondMenuTableView setX:CGRectGetMaxX(_firstMenuScrollView.frame)];
        [_secondMenuTableView setWidth:kScreen_Width*0.3];
        [_secondMenuTableView reloadData];
        [_thirdMenuTableView setX:kScreen_Width];
    }
    
    NSArray *secondCellArray = _secondMenuTableView.visibleCells;
    for (int i = 0; i < secondCellArray.count; i++) {
        FunctionalSecondMenuCell *cell = [secondCellArray objectAtIndex:i];
        FunctionMenu *menu = [_secondMenuArray objectAtIndex:i];
        [cell updateCell:menu width:_secondMenuTableView.width];
    }
}

#pragma mark - 显示购物车商品数量
- (void)updateShoppingCar {
    if (_bgView.hidden == NO) {
        float shoppingCarHeight = [self shoppingCarTableViewHeight];
        [_shoppingCarBgView setFrame:CGRectMake(0, kScreen_Height - shoppingCarHeight - 44 - _bottomMenuView.height, kScreen_Width, shoppingCarHeight + 44)];
        [_shoppingCarTableView setFrame:CGRectMake(0, 44, kScreen_Width, shoppingCarHeight)];
    }
    NSArray *array = [_shoppingDict allValues];
    NSInteger count = 0;
    for (NSArray *subArray in array) {
        count += subArray.count;
    }
    if (count > 0) {
        if (!_bubbleView) {
            _bubbleView = [[UIView alloc] initWithFrame:CGRectMake(kScreen_Width*0.063, 5, 20, 20)];
            [_bubbleView setBackgroundColor:[UIColor colorWithHexString:@"F5A623"]];
            [_bubbleView setCornerRadius:10.0f];
            
            _numberLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 18, 18)];
            [_numberLabel setFont:[UIFont systemFontOfSize:12.0f]];
            [_numberLabel setTextColor:[UIColor whiteColor]];
            [_numberLabel setText:[NSString stringWithFormat:@"%ld", count+(_webPageNumber.intValue > 0 ? 1 : 0)]];
            [_numberLabel setCenter:_bubbleView.center];
            [_numberLabel setTextAlignment:NSTextAlignmentCenter];
            
            // 计算结果
            _calcButton = [UIButton buttonWithType:UIButtonTypeCustom];
            [_calcButton setTitle:@"计算结果" forState:UIControlStateNormal];
            _calcButton.contentVerticalAlignment = UIControlContentVerticalAlignmentTop;
            _calcButton.titleEdgeInsets = UIEdgeInsetsMake(12, 0, -12, 0);
            [_calcButton setTitleColor:[UIColor colorWithHexString:@"ffffff" andAlpha:1.0f] forState:UIControlStateNormal];
            [_calcButton setTitleColor:[UIColor colorWithHexString:@"ffffff" andAlpha:0.5f] forState:UIControlStateDisabled];
            [_calcButton.titleLabel setFont:[UIFont systemFontOfSize:16.0f]];
            [_calcButton setBackgroundColor:[UIColor colorWithHexString:@"4289DB"]];
            [_calcButton setFrame:CGRectMake(_bottomMenuView.frame.size.width *(1 - 0.36), 0, _bottomMenuView.frame.size.width * 0.36, _bottomMenuView.frame.size.height)];
            [_calcButton setEnabled:NO];
            [_calcButton addTarget:self action:@selector(calcPrice) forControlEvents:UIControlEventTouchUpInside];
            
            [_bottomMenuView addSubview:_bubbleView];
            [_bottomMenuView addSubview:_numberLabel];
            [_bottomMenuView addSubview:_calcButton];
            
            if (![self p_needServerInList:_menuIDArray]) {
                [_bottomMenuLabel setText:nil];
                [_calcButton setEnabled:YES];
            }else if (_notDefaultItemCount < 5) {
                if (_selectedMenuArray.count == 2 &&[_selectedMenuArray containsObject:@"前端项目"]) {
                    [_bottomMenuLabel setText:@"请选择前端项目页面数量"];
                } else {
                    [_bottomMenuLabel setText:@"请至少选择5个非默认选项"];
                }
            } else if ([_webPageNumber isEqual:@0] && [[_selectedMenuArray objectAtIndex:_selectedIndex] isEqualToString:@"前端项目"]) {
                [_bottomMenuLabel setText:@"请选择前端项目页面数量"];
            }
        } else {
            [_bubbleView setHidden:NO];
            [_numberLabel setHidden:NO];
            if (![self p_needServerInList:_menuIDArray]) {
                [_bottomMenuLabel setText:nil];
                [_calcButton setEnabled:YES];
            }else if (_notDefaultItemCount >= 5 || (_selectedMenuArray.count == 2 &&[_selectedMenuArray containsObject:@"前端项目"])) {
                [_bottomMenuLabel setText:nil];
                [_calcButton setEnabled:YES];
                if ([_webPageNumber isEqual:@0] && [_selectedMenuArray containsObject:@"前端项目"]) {
                    [_calcButton setEnabled:NO];
                    [_bottomMenuLabel setText:@"请选择前端项目页面数量"];
                }
            } else {
                [_calcButton setEnabled:NO];
                [_bottomMenuLabel setText:@"请至少选择5个非默认选项"];
            }
            [_numberLabel setText:[NSString stringWithFormat:@"%ld", count+(_webPageNumber.intValue > 0 ? 1 : 0)]];
        }
    } else {
        [_bubbleView setHidden:YES];
        [_numberLabel setHidden:YES];
        [_calcButton setEnabled:NO];
    }
}

// 重置购物车
- (void)resetShoppingCar {
    _notDefaultItemCount = 0;
    [self generateDefaultShoppingCarData];
    [self updateShoppingCar];
}

#pragma mark - 计算结果
- (void)calcPrice {
    if (![Login isLogin]) {
        WEAKSELF;
        LoginViewController *vc = [LoginViewController storyboardVCWithUserStr:nil];
        vc.loginSucessBlock = ^(){
            [weakSelf calcPrice];
        };
        [UIViewController presentVC:vc dismissBtnTitle:@"取消"];
        return;
    }
    
    NSMutableDictionary *allMenuDict = [_data objectForKey:@"quotations"];
    NSMutableString *string = [NSMutableString string];
    NSArray *keyArray = [_shoppingDict allKeys];
    NSMutableArray *categoryArray = [NSMutableArray array];
    NSMutableArray *modelArray = [NSMutableArray array];
    NSMutableArray *platformArray = [NSMutableArray array];
    
    // 找出所有catrgory&model
    for (int i = 0; i < keyArray.count; i++) {
        NSString *platform = [_menuIDArray objectAtIndex:i];
        FunctionMenu *firstMenu = [NSObject objectOfClass:@"FunctionMenu" fromJSON:[allMenuDict objectForKey:platform]];
        [platformArray addObject:firstMenu];
        NSString *children = firstMenu.children;
        NSArray *childrenArray = [children componentsSeparatedByString:@","];
        for (int i = 0; i < childrenArray.count; i++) {
            FunctionMenu *category = [NSObject objectOfClass:@"FunctionMenu" fromJSON:[allMenuDict objectForKey:childrenArray[i]]];
            NSArray *modelChildArray = [category.children componentsSeparatedByString:@","];
            [categoryArray addObject:category];
            for (NSString *str in modelChildArray) {
                if (str.length) {
                    FunctionMenu *modelMenu = [NSObject objectOfClass:@"FunctionMenu" fromJSON:[allMenuDict objectForKey:str]];
                    [modelArray addObject:modelMenu];
                }
            }
        }
    }
    
    for (int i = 0; i < keyArray.count; i++) {
        NSString *key = [keyArray objectAtIndex:i];
        NSArray *thirdMenuArray = [_shoppingDict objectForKey:key];

        for (int j = 0; j < thirdMenuArray.count; j++) {
            FunctionMenu *thirdMenu = [thirdMenuArray objectAtIndex:j];
            for (FunctionMenu *model in modelArray) {
                if ([model.children containsString:thirdMenu.code]) {
                    for (FunctionMenu *category in categoryArray) {
                        if ([category.children containsString:model.code]) {
                            // 平台
                            for (FunctionMenu *platform in platformArray) {
                                if ([platform.children containsString:category.code]) {
                                    [string appendFormat:@"%@>", platform.code];
                                }
                            }

                            // 分类
                            [string appendFormat:@"%@>", category.code];
                        }
                    }
                    // 模块
                    [string appendFormat:@"%@>", model.code];
                }
            }
            
            // 功能
            if (i == keyArray.count - 1 && j == thirdMenuArray.count - 1) {
                [string appendFormat:@"%@", thirdMenu.code];
            } else {
                [string appendFormat:@"%@,", thirdMenu.code];
            }
        }
    }
    
    // 再次过滤数据
    NSMutableArray *newCategoryArray = @[].mutableCopy;
    NSMutableArray *newModelArray = @[].mutableCopy;
    NSMutableArray *itemsMenuArray = @[].mutableCopy;
    for (int i = 0; i < platformArray.count; i++) {
        NSString *key = [keyArray objectAtIndex:i];
        NSArray *thirdMenuArray = [_shoppingDict objectForKey:key];
        [itemsMenuArray addObjectsFromArray:thirdMenuArray];
        FunctionMenu *platform = [platformArray objectAtIndex:i];
        for (FunctionMenu *category in categoryArray) {
            if ([platform.children containsString:category.code]) {
                // 模块
                for (FunctionMenu *module in modelArray) {
                    // item
                    for (FunctionMenu *item in thirdMenuArray) {
                        if ([module.children containsString:item.code]) {
                            BOOL find = NO;
                            for (FunctionMenu *m in newModelArray) {
                                if ([m.code isEqual:module.code]) {
                                    find = YES;
                                }
                            }
                            if (!find) {
                                [newModelArray addObject:module];
                            }
                        }
                    }
                }
            }
        }
    }
    
    for (FunctionMenu *category in categoryArray) {
        for (FunctionMenu *m in newModelArray) {
            if ([category.children containsString:m.code]) {
                BOOL find = NO;
                for (FunctionMenu *c in newCategoryArray) {
                    if ([c.code isEqual:category.code]) {
                        find = YES;
                    }
                }
                if (!find) {
                    [newCategoryArray addObject:category];
                }
            }
        }
    }
    
    // 生成HTML数据
    NSMutableArray *platformList = @[].mutableCopy;
    for (int i = 0; i < platformArray.count; i++) {
        FunctionMenu *platformMenu = [platformArray objectAtIndex:i];
        NSMutableDictionary *platformDict = @{@"platform":platformMenu.title}.mutableCopy;
        NSMutableArray *categoryList = @[].mutableCopy;
        
        // 分类
        for (FunctionMenu *category in newCategoryArray) {
            if ([platformMenu.children containsString:category.code]) {
                NSMutableDictionary *categoryDict = @{@"name": category.title}.mutableCopy;
                NSMutableArray *moduleList = @[].mutableCopy;
                // 模块
                for (FunctionMenu *module in newModelArray) {
                    NSMutableDictionary *moduleDict = @{}.mutableCopy;
                    NSMutableArray *functionList = @[].mutableCopy;
                    
                    if ([category.children containsString:module.code]) {
                        // item
                        for (FunctionMenu *item in itemsMenuArray) {
                            if ([module.children containsString:item.code]) {
                                [functionList addObject:item.title];
                            }
                        }
                        [moduleDict setObject:module.title forKey:@"name"];
                        moduleDict[@"function"] = functionList;
                        [moduleList addObject:moduleDict];
                    }
                }
                
                categoryDict[@"module"] = moduleList;
                [categoryList addObject:categoryDict];
                
                if ([platformMenu.code isEqualToString:@"P005"]) {
                    NSDictionary *tempDict = @{@"name": @"页面数量",
                                               @"count": _webPageNumber};
                    [categoryList addObject:tempDict];
                }
            }
        }
        platformDict[@"category"] = categoryList;
        [platformList addObject:platformDict];
    }
    
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:platformList options:NSJSONWritingPrettyPrinted error:nil];
    NSString *h5String = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];

    CalcPriceViewController *vc = [[CalcPriceViewController alloc] init];
    vc.parameter = string;
    vc.h5String = h5String;
    vc.webPageNumber = _webPageNumber;
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1) {
        // 选择了其他
        [self dismiss];
        // 跳转到发布需求页面
        Reward *reward = [Reward rewardToBePublished];
        reward.type = @4;
        PublishRewardViewController *vc = [PublishRewardViewController storyboardVCWithReward:reward];
        [self.navigationController pushViewController:vc animated:YES];
    }
}

#pragma mark - 去除多余分割线
- (void)setExtraCellLineHidden:(UITableView *)tableView{
    UIView *view =[ [UIView alloc]init];
    view.backgroundColor = [UIColor clearColor];
    [tableView setTableFooterView:view];
    [tableView setTableHeaderView:view];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
