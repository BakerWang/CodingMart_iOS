//
//  ChooseSystemPayView.h
//  CodingMart
//
//  Created by Frank on 16/5/21.
//  Copyright © 2016年 net.coding. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void(^PayBlock)(NSInteger type);

@interface ChooseSystemPayView : UIView

@property (copy, nonatomic) PayBlock payBlock;

- (void)dismiss;

@end