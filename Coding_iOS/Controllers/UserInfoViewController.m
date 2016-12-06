//
//  UserInfoViewController.m
//  Coding_iOS
//
//  Created by Ease on 15/3/18.
//  Copyright (c) 2015年 Coding. All rights reserved.
//

#import "UserInfoViewController.h"
#import "Coding_NetAPIManager.h"
#import "FunctionTipsManager.h"
#import "MJPhotoBrowser.h"
#import "UsersViewController.h"
#import "ConversationViewController.h"
#import "UserOrProjectTweetsViewController.h"
#import "AddUserViewController.h"
#import "SettingViewController.h"
#import "SettingMineInfoViewController.h"
#import "UserInfoDetailViewController.h"
#import "ProjectListViewController.h"
#import "LocalFoldersViewController.h"

#import "RDVTabBarController.h"
#import "RDVTabBarItem.h"

#import "ODRefreshControl.h"

#import "UserInfoTextCell.h"
#import "UserInfoIconCell.h"
#import "TitleDisclosureCell.h"

#import "StartImagesManager.h"
#import "EaseUserHeaderView.h"
#import <APParallaxHeader/UIScrollView+APParallaxHeader.h>

#import "CSMyTopicVC.h"
#import "PointRecordsViewController.h"

@interface UserInfoViewController ()<UITableViewDataSource, UITableViewDelegate>
@property (strong, nonatomic) UITableView *myTableView;
@property (strong, nonatomic) EaseUserHeaderView *headerView;
@property (nonatomic, strong) ODRefreshControl *refreshControl;

@end

@implementation UserInfoViewController
- (void)viewDidLoad{
    [super viewDidLoad];
    self.title = _curUser.name;
    //    添加myTableView
    _myTableView = ({
        UITableView *tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
        tableView.backgroundColor = kColorTableSectionBg;
        tableView.dataSource = self;
        tableView.delegate = self;
        tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        [tableView registerClass:[UserInfoTextCell class] forCellReuseIdentifier:kCellIdentifier_UserInfoTextCell];
        [tableView registerClass:[UserInfoIconCell class] forCellReuseIdentifier:kCellIdentifier_UserInfoIconCell];
        [tableView registerClass:[TitleDisclosureCell class] forCellReuseIdentifier:kCellIdentifier_TitleDisclosure];
        [self.view addSubview:tableView];
        [tableView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self.view);
        }];
        tableView;
    });
    __weak typeof(self) weakSelf = self;
    _headerView = [EaseUserHeaderView userHeaderViewWithUser:_curUser image:[StartImagesManager shareManager].curImage.image];
    _headerView.userIconClicked = ^(){
        [weakSelf userIconClicked];
    };
    _headerView.fansCountBtnClicked = ^(){
        [weakSelf fansCountBtnClicked];
    };
    _headerView.followsCountBtnClicked = ^(){
        [weakSelf followsCountBtnClicked];
    };
    _headerView.followBtnClicked = ^(){
        [weakSelf followBtnClicked];
    };
    [_myTableView addParallaxWithView:_headerView andHeight:CGRectGetHeight(_headerView.frame)];
    _myTableView.tableFooterView = [self footerV];
    
    _refreshControl = [[ODRefreshControl alloc] initInScrollView:self.myTableView];
    [_refreshControl addTarget:self action:@selector(refresh) forControlEvents:UIControlEventValueChanged];
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self refresh];
}

- (void)refresh{
    __weak typeof(self) weakSelf = self;
    [[Coding_NetAPIManager sharedManager] request_UserInfo_WithObj:_curUser andBlock:^(id data, NSError *error) {
        [weakSelf.refreshControl endRefreshing];
        if (data) {
            weakSelf.curUser = data;
            weakSelf.headerView.curUser = data;
            weakSelf.title = weakSelf.curUser.name;
            [weakSelf.myTableView reloadData];
        }
    }];
}

#pragma mark footerV
- (UIView *)footerV{
    UIView *footerV = [[UIView alloc] initWithFrame:CGRectMake(0, 0, kScreen_Width, 72)];
    UIButton *footerBtn = [UIButton buttonWithStyle:StrapSuccessStyle andTitle:@"发消息" andFrame:CGRectMake(kPaddingLeftWidth, (CGRectGetHeight(footerV.frame)-44)/2 , kScreen_Width - 2*kPaddingLeftWidth, 44) target:self action:@selector(messageBtnClicked)];
    [footerV addSubview:footerBtn];
    return footerV;
}

#pragma mark Table M
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 2;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return section == 0? 4: 3;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    if (indexPath.section == 0) {
        if (indexPath.row < 3) {
            UserInfoTextCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellIdentifier_UserInfoTextCell forIndexPath:indexPath];
            switch (indexPath.row) {
                case 0:
                    [cell setTitle:@"所在地" value:_curUser.location];
                    break;
                case 1:
                    [cell setTitle:@"座右铭" value:_curUser.slogan];
                    break;
                default:
                    [cell setTitle:@"个性标签" value:_curUser.tags_str];
                    break;
            }
            [tableView addLineforPlainCell:cell forRowAtIndexPath:indexPath withLeftSpace:kPaddingLeftWidth];
            return cell;
        }else{
            TitleDisclosureCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellIdentifier_TitleDisclosure forIndexPath:indexPath];
            cell.titleLabel.font = [UIFont systemFontOfSize:15];
            cell.backgroundColor = [UIColor whiteColor];
            [cell setTitleStr:@"详细信息"];
            [tableView addLineforPlainCell:cell forRowAtIndexPath:indexPath withLeftSpace:kPaddingLeftWidth];
            return cell;
        }
    }else{
        UserInfoIconCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellIdentifier_UserInfoIconCell forIndexPath:indexPath];
        if (indexPath.row == 0) {
            [cell setTitle:@"Ta的项目" icon:@"user_info_project"];
        }else if(indexPath.row == 1){
            [cell setTitle:@"Ta的冒泡" icon:@"user_info_tweet"];
        }else {
            [cell setTitle:@"Ta的话题" icon:@"user_info_topic"];
        }
        [tableView addLineforPlainCell:cell forRowAtIndexPath:indexPath withLeftSpace:kPaddingLeftWidth];
        return cell;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 44.0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section{
    return 20.0;
}
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    return 0.5;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section{
    UIView *footerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, kScreen_Width, 20)];
    footerView.backgroundColor = kColorTableSectionBg;
    return footerView;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.section == 0 && indexPath.row == 3) {
        [self goToDetailInfo];
    }else if (indexPath.section == 1){
        if (indexPath.row == 0) {
            [self goToProjects];
        }else if(indexPath.row == 1){
            [self goToTweets];
        }else if (indexPath.row == 2){
            [self goToTopic];
        }
    }
}

#pragma mark Btn Clicked
- (void)fansCountBtnClicked{
    if (_curUser.id.integerValue == 93) {//Coding官方账号
        return;
    }
    UsersViewController *vc = [[UsersViewController alloc] init];
    vc.curUsers = [Users usersWithOwner:_curUser Type:UsersTypeFollowers];
    [self.navigationController pushViewController:vc animated:YES];
}
- (void)followsCountBtnClicked{
    if (_curUser.id.integerValue == 93) {//Coding官方账号
        return;
    }
    UsersViewController *vc = [[UsersViewController alloc] init];
    vc.curUsers = [Users usersWithOwner:_curUser Type:UsersTypeFriends_Attentive];
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)userIconClicked{
    //        显示大图
    MJPhoto *photo = [[MJPhoto alloc] init];
    photo.url = [_curUser.avatar urlWithCodePath];
    
    MJPhotoBrowser *browser = [[MJPhotoBrowser alloc] init];
    browser.currentPhotoIndex = 0;
    browser.photos = [NSArray arrayWithObject:photo];
    [browser show];
}

- (void)messageBtnClicked{
    ConversationViewController *vc = [[ConversationViewController alloc] init];
    vc.myPriMsgs = [PrivateMessages priMsgsWithUser:_curUser];
    [self.navigationController pushViewController:vc animated:YES];
}
- (void)followBtnClicked{
    __weak typeof(self) weakSelf = self;
    [[Coding_NetAPIManager sharedManager] request_FollowedOrNot_WithObj:_curUser andBlock:^(id data, NSError *error) {
        if (data) {
            weakSelf.curUser.followed = [NSNumber numberWithBool:!_curUser.followed.boolValue];
            weakSelf.headerView.curUser = weakSelf.curUser;
            if (weakSelf.followChanged) {
                weakSelf.followChanged(weakSelf.curUser);
            }
        }
    }];
}

- (void)goToTweets{
    UserOrProjectTweetsViewController *vc = [[UserOrProjectTweetsViewController alloc] init];
    vc.curTweets = [Tweets tweetsWithUser:_curUser];
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)goToTopic {
    CSMyTopicVC *vc = [[CSMyTopicVC alloc] init];
    vc.curUser = _curUser;
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)goToLocalFolders{
    LocalFoldersViewController *vc = [LocalFoldersViewController new];
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)goToPoint{
    PointRecordsViewController *vc = [PointRecordsViewController new];
    [self.navigationController pushViewController:vc animated:YES];
}

#pragma mark Nav
- (void)settingBtnClicked:(id)sender{
    SettingViewController *vc = [[SettingViewController alloc] init];
    vc.myUser = self.curUser;
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)addUserBtnClicked:(id)sender{
    AddUserViewController *vc = [[AddUserViewController alloc] init];
    vc.type = AddUserTypeFollow;
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)goToProjects{
    ProjectListViewController *vc = [[ProjectListViewController alloc] init];
    vc.curUser = _curUser;
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)goToDetailInfo{
    UserInfoDetailViewController *vc = [[UserInfoDetailViewController alloc] init];
    vc.curUser = self.curUser;
    [self.navigationController pushViewController:vc animated:YES];
}

@end
