//
//  LoginViewController.h
//  CodingMart
//
//  Created by Ease on 15/10/10.
//  Copyright © 2015年 net.coding. All rights reserved.
//

#import "BaseTableViewController.h"

@interface QuickLoginViewController : BaseTableViewController
@property (strong, nonatomic) NSString *mobile;

@property (copy, nonatomic) void (^loginSucessBlock)();
@end