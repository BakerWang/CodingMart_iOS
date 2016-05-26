//
//  RewardPrivate.h
//  CodingMart
//
//  Created by Ease on 16/4/21.
//  Copyright © 2016年 net.coding. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Reward.h"
#import "RewardMetro.h"
#import "RewardApply.h"
#import "MartFile.h"

@interface RewardPrivate : NSObject
@property (strong, nonatomic) Reward *basicInfo;
@property (strong, nonatomic) RewardMetro *metro;
@property (strong, nonatomic) RewardApply *apply;
@property (strong, nonatomic, readonly) NSArray *filesToShow;
@property (strong, nonatomic) NSDictionary *prd;
- (void)prepareHandle;
- (void)dealWithPreRewardP:(RewardPrivate *)rewardP;
- (BOOL)isRewardOwner;
@end