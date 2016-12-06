//
//  TeamListCell.h
//  Coding_iOS
//
//  Created by Ease on 2016/9/9.
//  Copyright © 2016年 Coding. All rights reserved.
//

#define kCellIdentifier_TeamListCell @"TeamListCell"


#import <UIKit/UIKit.h>
#import "Team.h"

@interface TeamListCell : UITableViewCell
@property (strong, nonatomic) Team *curTeam;
+ (CGFloat)cellHeight;

@end
