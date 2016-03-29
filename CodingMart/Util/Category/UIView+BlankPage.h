//
//  UIView+BlankPage.h
//  CodingMart
//
//  Created by Ease on 15/10/9.
//  Copyright © 2015年 net.coding. All rights reserved.
//
#define kBlankPageImageFail @"blankpage_image_load_fail"
#define kBlankPageImageActivities @"blankpage_image_activities"
#define kBlankPageImageNotification @"blankpage_image_notification"
#define kBlankPageImageRewardList @"blankpage_image_reward_list"
#define kBlankPageImagePublishJoin @"blankpage_image_reward_publish_jion"

#import <UIKit/UIKit.h>


typedef NS_ENUM(NSInteger, EaseBlankPageType)
{
    EaseBlankPageTypeView = 0,
    EaseBlankPageTypeActivity,
    EaseBlankPageTypeTask,
    EaseBlankPageTypeTopic,
    EaseBlankPageTypeTweet,
    EaseBlankPageTypeTweetOther,
    EaseBlankPageTypeProject,
    EaseBlankPageTypeProjectOther,
    EaseBlankPageTypeFileDleted,
    EaseBlankPageTypeFolderDleted,
    EaseBlankPageTypePrivateMsg,
    EaseBlankPageTypeMyWatchedTopic,
    EaseBlankPageTypeMyJoinedTopic,
    EaseBlankPageTypeOthersWatchedTopic,
    EaseBlankPageTypeOthersJoinedTopic,
    EaseBlankPageTypeFileTypeCannotSupport,
    EaseBlankPageTypeViewTips,
};

@class EaseBlankPageView;

@interface UIView (BlankPage)
@property (strong, nonatomic) EaseBlankPageView *blankPageView;

- (void)removeBlankPageView;
- (EaseBlankPageView *)makeBlankPageView;
- (void)configBlankPageImage:(NSString *)imageName tipStr:(NSString *)tipStr;
- (void)configBlankPageErrorBlock:(void(^)(id sender))block;
- (void)configBlankPageImage:(NSString *)imageName tipStr:(NSString *)tipStr buttonTitle:(NSString *)buttonTitle buttonBlock:(void(^)(id sender))block;

@end

@interface EaseBlankPageView : UIView
@property (strong, nonatomic) UIImageView *imageView;
@property (strong, nonatomic) UILabel *tipLabel;
@property (strong, nonatomic) UIButton *actionButton;
@property (copy, nonatomic) void(^actionButtonBlock)(id sender);

- (void)setupImage:(NSString *)imageName tipStr:(NSString *)tipStr buttonTitle:(NSString *)buttonTitle buttonBlock:(void(^)(id sender))block;//buttonTitle 默认是 「刷新一下」
@end