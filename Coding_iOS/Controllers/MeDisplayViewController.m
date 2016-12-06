//
//  MeDisplayViewController.m
//  Coding_iOS
//
//  Created by Ease on 2016/9/9.
//  Copyright © 2016年 Coding. All rights reserved.
//

#import "MeDisplayViewController.h"
#import "EaseUserHeaderView.h"
#import "StartImagesManager.h"
#import "Login.h"
#import "UsersViewController.h"
#import "MJPhotoBrowser.h"
#import <APParallaxHeader/UIScrollView+APParallaxHeader.h>
#import "XTSegmentControl.h"
#import "CSHotTopicView.h"
#import "CSTopicDetailVC.h"
#import "SVPullToRefresh.h"
#import "Coding_NetAPIManager.h"
#import "SettingMineInfoViewController.h"


@interface MeDisplayViewController ()
@property (strong, nonatomic) UIView *tableHeaderView;
@property (strong, nonatomic) EaseUserHeaderView *eaV;
@property (strong, nonatomic) UIView *sectionHeaderView;

@property (strong, nonatomic) User *curUser;
@property (assign, nonatomic) NSInteger dataIndex;
@property (strong, nonatomic) NSMutableArray *dataList;//特指「话题列表」的数据
@property (assign, nonatomic) BOOL canLoadMore, willLoadMore, isLoading;
@property (nonatomic, assign) NSInteger curPage;

@end

@implementation MeDisplayViewController

- (void)viewDidLoad{
    _curUser = [Login curLoginUser];
    _dataIndex = 0;
    _dataList = @[].mutableCopy;
    _canLoadMore = YES;
    _willLoadMore = _isLoading = NO;
    _curPage = 0;
    
    [super viewDidLoad];
    self.title = @"个人主页";
    [self.myTableView registerClass:[CSTopicCell class] forCellReuseIdentifier:kCellIdentifier_TopicCell];
    [self setupHeaderV];
}

- (void)setupHeaderV{
    __weak typeof(self) weakSelf = self;
    if (!_tableHeaderView) {
        _eaV = [EaseUserHeaderView userHeaderViewWithUser:_curUser image:[StartImagesManager shareManager].curImage.image];
        _eaV.userIconClicked = ^(){
            [weakSelf userIconClicked];
        };
        _eaV.fansCountBtnClicked = ^(){
            [weakSelf fansCountBtnClicked];
        };
        _eaV.followsCountBtnClicked = ^(){
            [weakSelf followsCountBtnClicked];
        };
        _eaV.nameBtnClicked = ^(){
            [weakSelf goToSettingInfo];
        };
        _eaV.clipsToBounds = YES;
        _tableHeaderView = [[UIView alloc] initWithFrame:_eaV.bounds];
        [_tableHeaderView addSubview:_eaV];
        self.myTableView.tableHeaderView = _tableHeaderView;
    }
    if (!_sectionHeaderView) {
        _sectionHeaderView = [[XTSegmentControl alloc] initWithFrame:CGRectMake(0, 0, kScreen_Width, 44.0) Items:@[@"冒泡", @"话题"] selectedBlock:^(NSInteger index) {
            weakSelf.dataIndex = index;
        }];
        _sectionHeaderView.backgroundColor = kColorTableBG;
    }
    [self.myTableView bringSubviewToFront:self.refreshControl];
}

- (void)setDataIndex:(NSInteger)dataIndex{
    _dataIndex = dataIndex;
    [self.myTableView reloadData];
    if ((_dataIndex == 0 && self.curTweets.list.count <= 0) ||
        (_dataIndex == 1 && _dataList.count <= 0)) {
        [self refresh];
    }
}

#pragma mark Refresh M

- (void)refresh{
    if (_dataIndex == 0) {
        [super refresh];
    }else{
        if (!_isLoading) {
            [self requestTopicsMore:NO];
        }
    }
}

- (void)refreshMore{
    if (_dataIndex == 0) {
        [super refreshMore];
    }else{
        if (!_isLoading && _canLoadMore) {
            [self requestTopicsMore:YES];
        }else{
            [self.myTableView.infiniteScrollingView stopAnimating];
        }
    }
}

- (void)requestTopicsMore:(BOOL)loadMore{
    _willLoadMore = loadMore;
    _curPage = _willLoadMore? _curPage + 1: 0;
    if (_dataList.count <= 0) {
        [self.view beginLoading];
    }
    __weak typeof(self) weakSelf = self;
    [[Coding_NetAPIManager sharedManager] request_JoinedTopicsWithUserGK:_curUser.global_key page:weakSelf.curPage block:^(id data, BOOL hasMoreData, NSError *error) {
        [weakSelf.refreshControl endRefreshing];
        [weakSelf.view endLoading];
        [weakSelf.myTableView.infiniteScrollingView stopAnimating];
        if (data) {
            if (weakSelf.willLoadMore) {
                [weakSelf.dataList addObjectsFromArray:data[@"list"]];
            }else{
                weakSelf.dataList = data[@"list"]? [data[@"list"] mutableCopy]: @[].mutableCopy;
            }
            [weakSelf.myTableView reloadData];
            weakSelf.myTableView.showsInfiniteScrolling = hasMoreData;
        }
        [weakSelf.view configBlankPage:EaseBlankPageTypeMyJoinedTopic hasData:weakSelf.dataList.count > 0 hasError:error != nil offsetY:[_eaV originalHeight] + 60 reloadButtonBlock:^(id sender) {
            [weakSelf refresh];
        }];

    }];
}

#pragma mark headerV
- (void)fansCountBtnClicked{
    UsersViewController *vc = [[UsersViewController alloc] init];
    vc.curUsers = [Users usersWithOwner:_curUser Type:UsersTypeFollowers];
    [self.navigationController pushViewController:vc animated:YES];
}
- (void)followsCountBtnClicked{
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

- (void)scrollViewDidScroll:(UIScrollView *)scrollView{
    if (scrollView == self.myTableView) {
        CGFloat offsetY = scrollView.contentOffset.y;
        CGFloat originalHeight = [_eaV originalHeight];
        CGRect eaFrame = CGRectMake(0, MIN(0, offsetY), _eaV.width, MAX(originalHeight, originalHeight - offsetY));
        _eaV.frame = eaFrame;
    }
}

#pragma mark TableM
- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
    return self.sectionHeaderView;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    return 44.0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    if (_dataIndex == 0) {
        return [super tableView:tableView numberOfRowsInSection:section];
    }else{
        return _dataList.count;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    if (_dataIndex == 0) {
        return [super tableView:tableView cellForRowAtIndexPath:indexPath];
    }else{
        NSDictionary *topic = _dataList[indexPath.row];
        CSTopicCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellIdentifier_TopicCell forIndexPath:indexPath];
        [cell updateDisplayByTopic:topic];
        [tableView addLineforPlainCell:cell forRowAtIndexPath:indexPath withLeftSpace:kPaddingLeftWidth];
        return cell;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    if (_dataIndex == 0) {
        return [super tableView:tableView heightForRowAtIndexPath:indexPath];
    }else{
        NSDictionary *topic = _dataList[indexPath.row];
        return [CSTopicCell cellHeightWithData:topic];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    if (_dataIndex == 0) {
        [super tableView:tableView didSelectRowAtIndexPath:indexPath];
    }else{
        NSDictionary *topic = _dataList[indexPath.row];
        [self goToTopic:topic];
    }
}

#pragma mark goTo
- (void)goToTopic:(NSDictionary*)topic{
    CSTopicDetailVC *vc = [[CSTopicDetailVC alloc] init];
    vc.topicID = [topic[@"id"] intValue];
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)goToSettingInfo{
    SettingMineInfoViewController *vc = [[SettingMineInfoViewController alloc] init];
    [self.navigationController pushViewController:vc animated:YES];
}

@end
