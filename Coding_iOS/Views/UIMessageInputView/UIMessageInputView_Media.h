//
//  UIMessageInputView_Media.h
//  Coding_iOS
//
//  Created by Ease on 15/4/7.
//  Copyright (c) 2015年 Coding. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, UIMessageInputView_MediaState) {
    UIMessageInputView_MediaStateInit,
    UIMessageInputView_MediaStateUploading,
    UIMessageInputView_MediaStateUploadSucess,
    UIMessageInputView_MediaStateUploadFailed
};

@interface UIMessageInputView_Media : NSObject
@property (strong, nonatomic) ALAsset *curAsset;
@property (strong, nonatomic) NSURL *assetURL;
@property (strong, nonatomic) NSString *urlStr;
@property (assign, nonatomic) UIMessageInputView_MediaState state;
+ (id)mediaWithAsset:(ALAsset *)asset urlStr:(NSString *)urlStr;
@end
