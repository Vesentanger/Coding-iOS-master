//
//  AddMDCommentViewController.m
//  Coding_iOS
//
//  Created by Ease on 15/6/1.
//  Copyright (c) 2015年 Coding. All rights reserved.
//

#import "AddMDCommentViewController.h"

#import "Coding_NetAPIManager.h"
#import "WebContentManager.h"
#import "EaseMarkdownTextView.h"
#import "WebViewController.h"

@interface AddMDCommentViewController ()
<UIWebViewDelegate>
@property (strong, nonatomic) UISegmentedControl *segmentedControl;
@property (assign, nonatomic) NSInteger curIndex;

@property (strong, nonatomic) UIWebView *preview;
@property (strong, nonatomic) UIActivityIndicatorView *activityIndicator;

@property (strong, nonatomic) EaseMarkdownTextView *editView;

@end

@implementation AddMDCommentViewController
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = kColorTableBG;
    if (!_segmentedControl) {
        _segmentedControl = ({
            UISegmentedControl *segmentedControl = [[UISegmentedControl alloc] initWithItems:@[@"编辑", @"预览"]];
            [segmentedControl setWidth:80 forSegmentAtIndex:0];
            [segmentedControl setWidth:80 forSegmentAtIndex:1];
            [segmentedControl setTitleTextAttributes:@{
                                                       NSFontAttributeName: [UIFont systemFontOfSize:16],
                                                       NSForegroundColorAttributeName: [UIColor whiteColor]
                                                       }
                                            forState:UIControlStateSelected];
            [segmentedControl setTitleTextAttributes:@{
                                                       NSFontAttributeName: [UIFont systemFontOfSize:16],
                                                       NSForegroundColorAttributeName: kColorNavTitle
                                                       } forState:UIControlStateNormal];
            [segmentedControl addTarget:self action:@selector(segmentedControlSelected:) forControlEvents:UIControlEventValueChanged];
            segmentedControl;
        });
        
        self.navigationItem.titleView = _segmentedControl;
    }
    
    [self.navigationItem setRightBarButtonItem:[UIBarButtonItem itemWithBtnTitle:@"发布" target:self action:@selector(saveBtnClicked)] animated:YES];
    self.navigationItem.rightBarButtonItem.enabled = NO;
    
    [[[[NSNotificationCenter defaultCenter] rac_addObserverForName:UIKeyboardWillChangeFrameNotification object:nil] takeUntil:self.rac_willDeallocSignal] subscribeNext:^(NSNotification *aNotification) {
        if (self.editView) {
            NSDictionary* userInfo = [aNotification userInfo];
            CGRect keyboardEndFrame = [[userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
            self.editView.contentInset = UIEdgeInsetsMake(0, 0, CGRectGetHeight(keyboardEndFrame), 0);
            self.editView.scrollIndicatorInsets = self.editView.contentInset;
        }
    }];
    
    self.curIndex = 0;
}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    if (self.curIndex == 0 && self.editView) {
        [self.editView becomeFirstResponder];
    }
}

#pragma mark UISegmentedControl
- (void)segmentedControlSelected:(id)sender{
    UISegmentedControl *segmentedControl = (UISegmentedControl *)sender;
    self.curIndex = segmentedControl.selectedSegmentIndex;
    if (self.curIndex == 0) {
        [_editView becomeFirstResponder];
    }else{
        [_editView resignFirstResponder];
    }
}

#pragma mark index_view

- (void)setCurIndex:(NSInteger)curIndex{
    _curIndex = curIndex;
    if (_segmentedControl.selectedSegmentIndex != curIndex) {
        [_segmentedControl setSelectedSegmentIndex:_curIndex];
    }
    
    if (_curIndex == 0) {
        [self loadEditView];
    }else{
        [self loadPreview];
    }
}

- (void)loadEditView{
    if (!_editView) {
        _editView = [[EaseMarkdownTextView alloc] initWithFrame:self.view.bounds];
        _editView.curProject = self.curProject;
        _editView.backgroundColor = [UIColor clearColor];
        _editView.textColor = kColor666;
        _editView.font = [UIFont systemFontOfSize:16];
        _editView.textContainerInset = UIEdgeInsetsMake(15, kPaddingLeftWidth - 5, 8, kPaddingLeftWidth - 5);
        _editView.placeholder = @"添加评论";
        
        _editView.text = _contentStr;
        [self.view addSubview:_editView];
        [_editView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self.view);
        }];
        
        @weakify(self);
        [_editView.rac_textSignal subscribeNext:^(NSString *mdStr) {
            @strongify(self);
            self.contentStr = mdStr;
            self.navigationItem.rightBarButtonItem.enabled = (self.contentStr.length > 0 && ![self.contentStr isEmptyOrListening]);
        }];
    }
    _editView.hidden = NO;
    _preview.hidden = YES;
}

- (void)loadPreview
{
    if (!_preview) {
        _preview = [[UIWebView alloc] initWithFrame:self.view.bounds];
        _preview.delegate = self;
        _preview.backgroundColor = [UIColor clearColor];
        _preview.opaque = NO;
        _preview.scalesPageToFit = YES;
        
        //webview加载指示
        _activityIndicator = [[UIActivityIndicatorView alloc]
                              initWithActivityIndicatorStyle:
                              UIActivityIndicatorViewStyleGray];
        _activityIndicator.hidesWhenStopped = YES;
        [_preview addSubview:_activityIndicator];
        [self.view addSubview:_preview];
        
        [_preview mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self.view);
        }];
        [_activityIndicator mas_makeConstraints:^(MASConstraintMaker *make) {
            make.center.equalTo(_preview);
        }];
    }
    _preview.hidden = NO;
    _editView.hidden = YES;
    [self previewLoadMDData];
}

- (void)previewLoadMDData{
    NSString *mdStr = self.editView? self.editView.text : _contentStr;
    [_activityIndicator startAnimating];
    
    @weakify(self);
    [[Coding_NetAPIManager sharedManager] request_MDHtmlStr_WithMDStr:mdStr inProject:self.curProject andBlock:^(id data, NSError *error) {
        @strongify(self);
        NSString *htmlStr = data? data : error.description;
        NSString *contentStr = [WebContentManager markdownPatternedWithContent:htmlStr];
        [self.preview loadHTMLString:contentStr baseURL:nil];
    }];
}


#pragma mark nav_btn

- (void)saveBtnClicked{
    _contentStr = [_contentStr aliasedString];
    [_requestParams setObject:_contentStr forKey:@"content"];
    
    [[Coding_NetAPIManager sharedManager] request_PostCommentWithPath:_requestPath params:_requestParams andBlock:^(id data, NSError *error) {
        if (data) {
            if (self.completeBlock) {
                self.completeBlock(data);
            }
            [self.navigationController popViewControllerAnimated:YES];
        }
    }];
}

#pragma mark UIWebViewDelegate
- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType{
    DebugLog(@"strLink=[%@]",request.URL.absoluteString);
    
    NSString *strLink = request.URL.absoluteString;
    if ([strLink rangeOfString:@"about:blank"].location != NSNotFound) {
        return YES;
    } else {
        [self analyseLinkStr:strLink];
        return NO;
    }
}
- (void)webViewDidStartLoad:(UIWebView *)webView{
    [_activityIndicator startAnimating];
}
- (void)webViewDidFinishLoad:(UIWebView *)webView{
    [_activityIndicator stopAnimating];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error{
    if([error code] == NSURLErrorCancelled)
        return;
    else{
        DebugLog(@"%@", error.description);
        [NSObject showError:error];
    }
}

#pragma mark analyseLinkStr
- (void)analyseLinkStr:(NSString *)linkStr
{
    if (linkStr.length <= 0) {
        return;
    }
    UIViewController *vc = [BaseViewController analyseVCFromLinkStr:linkStr];
    if (vc) {
        [self.navigationController pushViewController:vc animated:YES];
    }else{
        // 跳转去网页
        WebViewController *webVc = [WebViewController webVCWithUrlStr:linkStr];
        [self.navigationController pushViewController:webVc animated:YES];
    }
}

@end
