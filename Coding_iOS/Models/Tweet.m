//
//  Tweet.m
//  Coding_iOS
//
//  Created by Ease on 15/3/9.
//  Copyright (c) 2015年 Coding. All rights reserved.
//

#import "Tweet.h"
#import "Login.h"


static Tweet *_tweetForSend = nil;

@implementation Tweet
- (instancetype)init
{
    self = [super init];
    if (self) {
        _propertyArrayMap = [NSDictionary dictionaryWithObjectsAndKeys:
                             @"Comment", @"comment_list",
                             @"User", @"like_users",
                             @"User", @"reward_users", nil];
        _canLoadMore = YES;
        _isLoading = _willLoadMore = NO;
        _contentHeight = 1;
    }
    return self;
}

- (void)setContent:(NSString *)content{
    if (_content != content) {
        _htmlMedia = [HtmlMedia htmlMediaWithString:content showType:MediaShowTypeNone];
        _content = _htmlMedia.contentDisplay;
    }
}

- (NSString *)address{
    if (!_address || _address.length == 0) {
        return @"未填写";
    }else{
        return _address;
    }
}

- (void)changeToLiked:(NSNumber *)liked{
    if (!liked) {
        return;
    }
    if (!_liked || ![_liked isEqualToNumber:liked]) {
        _liked = liked;
        User *cur_user = [Login curLoginUser];
        NSPredicate *finalPredicate = [NSPredicate predicateWithFormat:@"global_key == %@", cur_user.global_key];
        if (_liked.boolValue) {//喜欢
            if (!_like_users) {
                _like_users = [NSMutableArray arrayWithObject:cur_user];
                _likes = [NSNumber numberWithInteger:_likes.integerValue +1];
            }else{
                NSArray *fliterArray = [_like_users filteredArrayUsingPredicate:finalPredicate];
                if (!fliterArray || [fliterArray count] <= 0) {
                    [_like_users insertObject:cur_user atIndex:0];
                    _likes = [NSNumber numberWithInteger:_likes.integerValue +1];
                }
            }
        }else{//不喜欢
            if (_like_users) {
                NSArray *fliterArray = [_like_users filteredArrayUsingPredicate:finalPredicate];
                if (fliterArray && [fliterArray count] > 0) {
                    [_like_users removeObjectsInArray:fliterArray];
                    _likes = [NSNumber numberWithInteger:_likes.integerValue -1];
                }
            }
        }
    }
}

- (NSInteger)numOfComments{
    return MIN(_comment_list.count +1,
               MIN(_comments.intValue,
                   6));
}
- (BOOL)hasMoreComments{
    return (_comments.intValue > _comment_list.count || _comments.intValue > 5);
}

- (NSArray *)like_reward_users{
    NSMutableArray *like_reward_users = _like_users.count > 0? _like_users.mutableCopy: @[].mutableCopy;//点赞的人多，用点赞的人列表做基
    [_reward_users enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(User *obj, NSUInteger idx, BOOL *stop) {
        __block NSInteger originalIndex = NSNotFound;
        [like_reward_users enumerateObjectsUsingBlock:^(User *obj_, NSUInteger idx_, BOOL *stop_) {
            if ([obj.global_key isEqualToString:obj_.global_key]) {
                originalIndex = idx_;
            }
        }];
        if (originalIndex != NSNotFound) {
            [like_reward_users exchangeObjectAtIndex:originalIndex withObjectAtIndex:0];
        }else{
            [like_reward_users insertObject:obj atIndex:0];
        }
    }];
    return like_reward_users;
}
- (BOOL)hasLikesOrRewards{
    return (_likes.integerValue + _rewards.integerValue) > 0;
}
- (BOOL)hasMoreLikesOrRewards{
    return (_like_users.count + _reward_users.count == 10 && _likes.integerValue + _rewards.integerValue > 10);
//    return (_likes.integerValue > _like_users.count || _rewards.integerValue > _reward_users.count);
}
- (BOOL)rewardedBy:(User *)user{
    for (User *obj in _reward_users) {
        if ([obj.global_key isEqualToString:user.global_key]) {
            return YES;
        }
    }
    return NO;
}

- (NSString *)toDoLikePath{
    NSString *doLikePath;
    doLikePath = [NSString stringWithFormat:@"api/tweet/%d/%@", self.id.intValue, (!_liked.boolValue? @"unlike":@"like")];
    return doLikePath;
}

- (NSString *)toDoCommentPath{
    if (self.project_id) {
        return [NSString stringWithFormat:@"api/project/%@/tweet/%@/comment", self.project_id.stringValue, self.id.stringValue];
    }else{
        return [NSString stringWithFormat:@"api/tweet/%d/comment", self.id.intValue];
    }
}
- (NSDictionary *)toDoCommentParams{
    return @{@"content" : [self.nextCommentStr aliasedString]};
}


- (NSString *)toLikesAndRewardsPath{
    return [NSString stringWithFormat:@"api/tweet/%d/allLikesAndRewards", _id.intValue];
}
- (NSDictionary *)toLikesAndRewardsParams{
    return @{@"page" : [NSNumber numberWithInteger:1],
             @"pageSize" : [NSNumber numberWithInteger:500]};
}

- (NSString *)toLikersPath{
    return [NSString stringWithFormat:@"api/tweet/%d/likes", _id.intValue];
}
- (NSDictionary *)toLikersParams{
    return @{@"page" : [NSNumber numberWithInteger:1],
             @"pageSize" : [NSNumber numberWithInteger:500]};
}
- (NSString *)toCommentsPath{
    NSString *path;
    if (self.project_id) {
        path = [NSString stringWithFormat:@"api/project/%@/tweet/%@/comments", self.project_id.stringValue, self.id.stringValue];
    }else{
        path = [NSString stringWithFormat:@"api/tweet/%d/comments", _id.intValue];
    }
    return path;
}
- (NSDictionary *)toCommentsParams{
    return @{@"page" : [NSNumber numberWithInteger:1],
             @"pageSize" : [NSNumber numberWithInteger:500]};
}
- (NSString *)toDeletePath{
    if (self.project_id) {
        return [NSString stringWithFormat:@"api/project/%@/tweet/%@", self.project_id.stringValue, self.id.stringValue];
    }else{
        return [NSString stringWithFormat:@"api/tweet/%d", self.id.intValue];
    }
}
- (NSString *)toDetailPath{
    NSString *path;
    if (self.project_id) {
        path = [NSString stringWithFormat:@"api/project/%@/tweet/%@", self.project_id.stringValue, self.id.stringValue];
    }else if (self.project){
        //需要先去获取project_id
    }else if (self.user_global_key) {
        path = [NSString stringWithFormat:@"api/tweet/%@/%@", self.user_global_key, self.id.stringValue];
    }else{
        path = [NSString stringWithFormat:@"api/tweet/%@/%@", self.owner.global_key, self.id.stringValue];
    }
    return path;
}

+(Tweet *)tweetForSend{
    if (!_tweetForSend) {
        _tweetForSend = [[Tweet alloc] init];
        [_tweetForSend loadSendData];
    }
    return _tweetForSend;
}

- (void)saveSendData{
    NSString *dataPath = [NSString stringWithFormat:@"%@_tweetForSend", [Login curLoginUser].global_key];
    NSMutableDictionary *tweetImagesDict = [NSMutableDictionary new];
    for (int i = 0; i < [self.tweetImages count]; i++) {
        TweetImage *tImg = [self.tweetImages objectAtIndex:i];
        if (tImg.image) {
            NSString *imgNameStr = [NSString stringWithFormat:@"%@_%d.jpg", dataPath, i];
            if (tImg.assetURL.absoluteString) {
                [tweetImagesDict setObject:tImg.assetURL.absoluteString forKey:imgNameStr];
            }
            [NSObject saveImage:tImg.image imageName:imgNameStr inFolder:dataPath];
        }
    }
    [NSObject saveResponseData:@{@"content" : _tweetContent? _tweetContent: @"",
                                 @"locationData" : _locationData? [_locationData objectDictionary] : @"",
                                 @"tweetImagesDict" : tweetImagesDict,
                                 } toPath:dataPath];
}

- (void)loadSendData{
    NSString *dataPath = [NSString stringWithFormat:@"%@_tweetForSend", [Login curLoginUser].global_key];

    self.tweetContent = @"";
    NSDictionary *contentDict = [NSObject loadResponseWithPath:dataPath];
    NSDictionary *tweetImagesDict = [contentDict objectForKey:@"tweetImagesDict"];
    if (contentDict) {
        self.tweetContent = [contentDict objectForKey:@"content"];
        self.locationData = [NSObject objectOfClass:@"TweetSendLocationResponse" fromJSON:[contentDict objectForKey:@"locationData"]];
    }
    _tweetImages = [NSMutableArray new];
    _selectedAssetURLs = [NSMutableArray new];
    [tweetImagesDict enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *obj, BOOL *stop) {
        NSURL *assetURL = [NSURL URLWithString:obj];
        NSData *imageData = [NSObject loadImageDataWithName:key inFolder:dataPath];
        if (imageData) {
            TweetImage *tImg = [TweetImage tweetImageWithAssetURL:assetURL andImage:[UIImage imageWithData:imageData]];
            [self.tweetImages addObject:tImg];
            [self.selectedAssetURLs addObject:assetURL];
        }
    }];
}

+ (void)deleteSendData{
    _tweetForSend = nil;
    NSString *dataPath = [NSString stringWithFormat:@"%@_tweetForSend", [Login curLoginUser].global_key];
    [NSObject deleteImageCacheInFolder:dataPath];
    [NSObject deleteResponseCacheForPath:dataPath];
}

+(Tweet *)tweetWithGlobalKey:(NSString *)user_global_key andPPID:(NSString *)pp_id{
    Tweet *tweet = [[Tweet alloc] init];
    tweet.id = [NSNumber numberWithInteger:pp_id.integerValue];
    tweet.user_global_key = user_global_key;
    return tweet;
}
+(Tweet *)tweetInProject:(Project *)project andPPID:(NSString *)pp_id{
    Tweet *tweet = [[Tweet alloc] init];
    tweet.id = [NSNumber numberWithInteger:pp_id.integerValue];
    tweet.project = project;
    return tweet;
}

- (NSDictionary *)toDoTweetParams{
    NSMutableString *contentStr = [[NSMutableString alloc] initWithString:_tweetContent? _tweetContent: @""];
    if (_tweetImages.count > 0) {
        [contentStr appendString:@"\n"];
    }
    for (TweetImage *imageItem in _tweetImages) {
        if (imageItem.imageStr && imageItem.imageStr.length > 0) {
            [contentStr appendString:imageItem.imageStr];
        }
    }
    NSDictionary *params;
    if (_locationData) {
        params = @{@"content" : contentStr,
                   @"location": _locationData.displayLocaiton,
                   @"coord": [NSString stringWithFormat:@"%@,%@,%i", _locationData.lat, _locationData.lng, _locationData.isCustomLocaiton],
                   @"address": _locationData.address? _locationData.address: @""};
    }else{
        params = @{@"content" : contentStr};
    }
    return params;
}
- (BOOL)isAllImagesDoneSucess{
    for (TweetImage *imageItem in _tweetImages) {
        if (imageItem.imageStr.length <= 0) {
            return NO;
        }
    }
    return YES;
}
- (void)addNewComment:(Comment *)comment{
    if (!comment) {
        return;
    }
    if (_comment_list) {
        [_comment_list insertObject:comment atIndex:0];
    }else{
        _comment_list = [NSMutableArray arrayWithObject:comment];
    }
    _comments = [NSNumber numberWithInteger:_comments.integerValue +1];
}
- (void)deleteComment:(Comment *)comment{
    if (_comment_list) {
        NSUInteger index = [_comment_list indexOfObject:comment];
        if (index != NSNotFound) {
            [_comment_list removeObjectAtIndex:index];
            _comments = [NSNumber numberWithInteger:_comments.integerValue -1];
        }
    }
}

- (NSString *)toShareLinkStr{
    NSString *shareLinkStr;
    if (_project) {
        shareLinkStr = [NSString stringWithFormat:@"%@u/%@/p/%@?pp=%@", [NSObject baseURLStr], _project.owner_user_name, _project.name, _id.stringValue];
    }else{
        shareLinkStr = [NSString stringWithFormat:@"%@u/%@/pp/%@", kBaseUrlStr_Phone, _owner.global_key, _id];
    }
    return shareLinkStr;
}

#pragma mark ALAsset
- (void)setSelectedAssetURLs:(NSMutableArray *)selectedAssetURLs{
    NSMutableArray *needToAdd = [NSMutableArray new];
    NSMutableArray *needToDelete = [NSMutableArray new];
    [self.selectedAssetURLs enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if (![selectedAssetURLs containsObject:obj]) {
            [needToDelete addObject:obj];
        }
    }];
    [needToDelete enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [self deleteASelectedAssetURL:obj];
    }];
    [selectedAssetURLs enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if (![self.selectedAssetURLs containsObject:obj]) {
            [needToAdd addObject:obj];
        }
    }];
    [needToAdd enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [self addASelectedAssetURL:obj];
    }];
}

- (BOOL)isProjectTweet{
    return self.project_id != nil || _project != nil;
}
- (void)addASelectedAssetURL:(NSURL *)assetURL{
    if (!_selectedAssetURLs) {
        _selectedAssetURLs = [NSMutableArray new];
    }
    if (!_tweetImages) {
        _tweetImages = [NSMutableArray new];
    }
    
    [_selectedAssetURLs addObject:assetURL];

    NSMutableArray *tweetImages = [self mutableArrayValueForKey:@"tweetImages"];//为了kvo
    TweetImage *tweetImg = [TweetImage tweetImageWithAssetURL:assetURL];
    [tweetImages addObject:tweetImg];
}

- (void)deleteASelectedAssetURL:(NSURL *)assetURL{
    [self.selectedAssetURLs removeObject:assetURL];
    NSMutableArray *tweetImages = [self mutableArrayValueForKey:@"tweetImages"];//为了kvo
    [tweetImages enumerateObjectsUsingBlock:^(TweetImage *obj, NSUInteger idx, BOOL *stop) {
        if (obj.assetURL == assetURL) {
            [tweetImages removeObject:obj];
            *stop = YES;
        }
    }];
}

- (void)deleteATweetImage:(TweetImage *)tweetImage{
    NSMutableArray *tweetImages = [self mutableArrayValueForKey:@"tweetImages"];//为了kvo
    [tweetImages removeObject:tweetImage];
    if (tweetImage.assetURL) {
        [self.selectedAssetURLs removeObject:tweetImage.assetURL];
    }
}

@end

@implementation TweetImage
+ (instancetype)tweetImageWithAssetURL:(NSURL *)assetURL{
    TweetImage *tweetImg = [[TweetImage alloc] init];
    tweetImg.uploadState = TweetImageUploadStateInit;
    tweetImg.assetURL = assetURL;
    
    void (^selectAsset)(ALAsset *) = ^(ALAsset *asset){
        if (asset) {
            UIImage *highQualityImage = [UIImage fullScreenImageALAsset:asset];
            UIImage *thumbnailImage = [UIImage imageWithCGImage:[asset thumbnail]];
            dispatch_async(dispatch_get_main_queue(), ^{
                tweetImg.image = highQualityImage;
                tweetImg.thumbnailImage = thumbnailImage;
            });
        }
    };
    
    ALAssetsLibrary *assetsLibrary = [[ALAssetsLibrary alloc] init];
    @weakify(assetsLibrary);
    [assetsLibrary assetForURL:assetURL resultBlock:^(ALAsset *asset) {
        if (asset) {
            selectAsset(asset);
        }else{
            @strongify(assetsLibrary);
            [assetsLibrary enumerateGroupsWithTypes:ALAssetsGroupPhotoStream usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
                [group enumerateAssetsUsingBlock:^(ALAsset *result, NSUInteger index, BOOL *stopG) {
                    if([result.defaultRepresentation.url isEqual:assetURL]) {
                        selectAsset(result);
                        *stop = YES;
                        *stopG = YES;
                    }
                }];
            } failureBlock:^(NSError *error) {
                [NSObject showHudTipStr:@"读取图片失败"];
            }];
        }
    }failureBlock:^(NSError *error) {
        [NSObject showHudTipStr:@"读取图片失败"];
    }];
    return tweetImg;

}

+ (instancetype)tweetImageWithAssetURL:(NSURL *)assetURL andImage:(UIImage *)image{
    TweetImage *tweetImg = [[TweetImage alloc] init];
    tweetImg.uploadState = TweetImageUploadStateInit;
    tweetImg.assetURL = assetURL;
    tweetImg.image = image;
    tweetImg.thumbnailImage = [image scaledToSize:CGSizeMake(kScaleFrom_iPhone5_Desgin(70), kScaleFrom_iPhone5_Desgin(70)) highQuality:YES];
    return tweetImg;
}

@end
