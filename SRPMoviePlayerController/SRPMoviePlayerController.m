// SRPMoviePlayerController.m
//
// Copyright (c) 2014年 Shinren Pan
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "Vitamio.h"
#import "SRPMoviePlayerController.h"


// 外接設備用的 ViewController
@interface ConnectedController : UIViewController
@end


@implementation ConnectedController

- (BOOL)shouldAutorotate
{
    return NO;
}

- (NSUInteger)supportedInterfaceOrientations
{
    return ~UIInterfaceOrientationMaskAll;
}

@end


@interface SRPMoviePlayerController ()<VMediaPlayerDelegate, UIGestureRecognizerDelegate>

@property (nonatomic, weak) IBOutlet UIView                  *toolView;
@property (nonatomic, weak) IBOutlet UILabel                 *playTimeLabel;
@property (nonatomic, weak) IBOutlet UISlider                *videoSeekSlider;
@property (nonatomic, weak) IBOutlet UILabel                 *endTimeLabel;
@property (nonatomic, weak) IBOutlet UIActivityIndicatorView *loadingView;
@property (nonatomic, weak) IBOutlet UILabel                 *loadingLabel;
@property (nonatomic, weak) IBOutlet UILabel                 *connectedLabel;
@property (nonatomic, weak) IBOutlet UIBarButtonItem         *playPauseItem;
@property (nonatomic, weak) IBOutlet UIBarButtonItem         *volumeContainer;

@property (nonatomic, strong) CADisplayLink *timer;
@property (nonatomic, strong) VMediaPlayer  *player;
@property (nonatomic, strong) UIView        *playerView;
@property (nonatomic, strong) UIWindow      *connectedWindow;
@property (nonatomic, assign) long          totalVideoTime;
@property (nonatomic, assign) BOOL          videoSeekSliderIsDragging;

@end


@implementation SRPMoviePlayerController

#pragma mark - 清除快取
+ (void)cleanCache
{
    NSString *cache =
    [NSString stringWithFormat:@"%@/Library/Caches/SRPPlayerCache", NSHomeDirectory()];

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        [[NSFileManager defaultManager]removeItemAtPath:cache error:nil];
    });
}

#pragma mark - LifeCycle
- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self __init];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if(_playerView)
    {
        self.player = [VMediaPlayer sharedInstance];
        
        [_player setupPlayerWithCarrierView:_playerView withDelegate:self];
        [_player setDataSource:_videoURL];
        [_player prepareAsync];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self __dealloc];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:
(id<UIViewControllerTransitionCoordinator>)coordinator
{
    // 螢幕 roate 時要調整 _VolumeContainer
    [self __setupVolumeContainerWidth:size.width];
}

- (BOOL)prefersStatusBarHidden
{
    // 隱藏 statusBar 的時機 = _toolView.Hidden
    return _toolView.hidden;
}

#pragma mark - UIGestureRecognizerDelegate
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer
       shouldReceiveTouch:(UITouch *)touch
{
    // 一定要設 delegate, 不然拖拉影片或是聲音, 會不小心觸發 tap,
    // 播放影片時的 View Class 為 GLVPlayerView
    return
    touch.view == self.view ||
    touch.view == _toolView ||
    [touch.view isKindOfClass:NSClassFromString(@"GLVPlayerView")];
}

#pragma mark - VMediaPlayerDelegate
#pragma mark Player LifeCycle
- (void)mediaPlayer:(VMediaPlayer *)player didPrepared:(id)arg
{
    self.totalVideoTime = [player getDuration];
    
    [self __play];
}

- (void)mediaPlayer:(VMediaPlayer *)player playbackComplete:(id)arg
{
    [self doneItemDidClicked:nil];
}

- (void)mediaPlayer:(VMediaPlayer *)player error:(id)arg
{
    [self __showErrorMessage];
}

#pragma mark - Player Setting
- (void)mediaPlayer:(VMediaPlayer *)player setupManagerPreference:(id)arg
{
    player.decodingSchemeHint       = VMDecodingSchemeHardware;
    player.autoSwitchDecodingScheme = NO;
}

- (void)mediaPlayer:(VMediaPlayer *)player setupPlayerPreference:(id)arg
{
    player.useCache = YES;
    
    [player setCacheDirectory:[self __cacheDirectory]];
}

#pragma mark - Player Buffer
- (void)mediaPlayer:(VMediaPlayer *)player bufferingStart:(id)arg
{
    // buffer 時, 隱藏不需要的 UI
    _playTimeLabel.hidden   = YES;
    _videoSeekSlider.hidden = YES;
    _endTimeLabel.hidden    = YES;
    _loadingView.hidden     = NO;
    _loadingLabel.hidden    = NO;
    _playPauseItem.enabled  = NO;
    
    [self __pause];
}

- (void)mediaPlayer:(VMediaPlayer *)player bufferingEnd:(id)arg
{
    [self __play];
}

#pragma mark - IBAction
#pragma mark Done item clicked
- (IBAction)doneItemDidClicked:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - 點擊隱藏 / 顯示 _toolView
- (IBAction)handleScreenTap:(UITapGestureRecognizer *)sender
{
    _toolView.hidden = !_toolView.hidden;
    [self setNeedsStatusBarAppearanceUpdate];
}


#pragma mark - 按下播放 / 暫停
- (IBAction)playPauseItemDidClicked:(UIBarButtonItem *)sender
{
    if([_player isPlaying])
    {
        [self __pause];
    }
    else
    {
        [self __play];
    }
}

#pragma mark - _videoSeekSlider 拖拉ing
- (IBAction)videoSeekSliderDragging:(UISlider *)sender
{
    self.videoSeekSliderIsDragging = YES;
    long playTime                  = _totalVideoTime * sender.value;
    long endTime                   = _totalVideoTime - playTime;
    _playTimeLabel.text            = [self __videoTimeToString:playTime];
    _endTimeLabel.text             = [self __videoTimeToString:endTime];
}

#pragma mark - _videoSeekSlider 拖拉結束
- (IBAction)videoSeekSliderValueDidChanged:(UISlider *)sender
{
    self.videoSeekSliderIsDragging = NO;
    long seekTo                    = _totalVideoTime * sender.value;
    
    [_player seekTo:seekTo];
}

#pragma mark - Private methods
#pragma mark 初始設置
- (void)__init
{
    CGSize appSize = [UIScreen mainScreen].applicationFrame.size;
    
    [self __setupVolumeContainerWidth:appSize.width];
    
    _playTimeLabel.hidden   = YES;
    _videoSeekSlider.hidden = YES;
    _endTimeLabel.hidden    = YES;
    _playPauseItem.enabled  = NO;
    
    if(!_videoURL)
    {
        [self __showErrorMessage];
    }
    else
    {
        [self __addObserver];
        [UIApplication sharedApplication].idleTimerDisabled = YES;
        
        self.playerView      = [[UIView alloc]init];
        self.connectedWindow = [[UIWindow alloc]init];
        
        _playerView.backgroundColor  = [UIColor clearColor];
        _playerView.autoresizingMask =
        UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        
        if([self __isConnected])
        {
            [self __handleConnected];
        }
        else
        {
            [self __handleDisconnected];
        }
    }
}

#pragma mark - 離開前設置
- (void)__dealloc
{
    [UIApplication sharedApplication].idleTimerDisabled = NO;
    [self __releaseTimer];
    [self __releasePlayer];
    [self __removeObserver];
}

#pragma mark - Add Observer
- (void)__addObserver
{
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    
    // 連接設備
    [center addObserver:self selector:@selector(__handleConnected)
                   name:UIScreenDidConnectNotification object:nil];
    
    // 移除連接
    [center addObserver:self selector:@selector(__handleDisconnected)
                   name:UIScreenDidDisconnectNotification object:nil];
    
    // 進入前景
    [center addObserver:self selector:@selector(__handleAppWillEnterForeground)
                   name:UIApplicationWillEnterForegroundNotification object:nil];

    // 進入背景
    [center addObserver:self selector:@selector(__handleAppDidEnterBackground)
                   name:UIApplicationDidEnterBackgroundNotification object:nil];

    // 可能有電話進來時
    [center addObserver:self selector:@selector(__handleAudioInterruption:)
                   name:AVAudioSessionInterruptionNotification object:nil];
}

#pragma mark - Remove Observer
- (void)__removeObserver
{
    [[NSNotificationCenter defaultCenter]removeObserver:self];
}

#pragma mark - Handle 連接設備
- (void)__handleConnected
{
    [_playerView removeFromSuperview];
    
    _connectedLabel.hidden              = NO;
    UIScreen *screen                    = [UIScreen screens].lastObject;
    screen.overscanCompensation         = UIScreenOverscanCompensationInsetApplicationFrame;
    ConnectedController *mvc            = [[ConnectedController alloc]init];
    _connectedWindow.rootViewController = mvc;
    _connectedWindow.screen             = screen;
    _connectedWindow.hidden             = NO;
    mvc.view.frame                      = screen.bounds;
    _playerView.frame                   = screen.bounds;
    
    [mvc.view addSubview:_playerView];
}

#pragma mark - Handle 移除設備
- (void)__handleDisconnected
{
    [_playerView removeFromSuperview];
    
    _connectedLabel.hidden              = YES;
    _connectedWindow.hidden             = YES;
    _connectedWindow.screen             = nil;
    _connectedWindow.rootViewController = nil;
    _playerView.frame                   = self.view.bounds;
    
    [self.view addSubview:_playerView];
    [self.view sendSubviewToBack:_playerView];
}

#pragma mark - Handle App 進入前景
- (void)__handleAppWillEnterForeground
{
    [self __play];
}

#pragma mark - Handle App 進入背景
- (void)__handleAppDidEnterBackground
{
    [self __pause];
}

#pragma mark - Handle Audio 中斷
- (void)__handleAudioInterruption:(NSNotification *)sender
{
    NSDictionary *info = sender.userInfo;
    NSNumber *type = info[AVAudioSessionInterruptionTypeKey];
    
    // 只 handle begin, end 的話, 讓 User 手動去 play video
    if([type integerValue] == AVAudioSessionInterruptionTypeBegan)
    {
        [self __pause];
    }
}

#pragma mark - 播放
- (void)__play
{
    _playTimeLabel.hidden   = NO;
    _videoSeekSlider.hidden = NO;
    _endTimeLabel.hidden    = NO;
    _loadingView.hidden     = YES;
    _loadingLabel.hidden    = YES;
    _playPauseItem.enabled  = YES;
    _playPauseItem.title    = @"∎∎";
    
    [_player start];
    
    if(!_timer)
    {
        self.timer = [CADisplayLink displayLinkWithTarget:self
                                                 selector:@selector(__handleTimer)];
        
        _timer.frameInterval = 4;
        
        [_timer addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    }
}

#pragma mark - 暫停
- (void)__pause
{
    _playPauseItem.title = @"▶︎";
    
    [_player pause];
    [self __releaseTimer];
}

#pragma mark - Release Player
- (void)__releasePlayer
{
    [self __pause];
    [_player reset];
    [_player unSetupPlayer];
    [_playerView removeFromSuperview];
    
    self.player     = nil;
    self.playerView = nil;
}

#pragma mark - Handle timer
- (void)__handleTimer
{
    if(![_player isPlaying] || _videoSeekSliderIsDragging)
        return;
    
    long playTime       = [_player getCurrentPosition];
    long endTime        = _totalVideoTime - playTime;
    _playTimeLabel.text = [self __videoTimeToString:playTime];
    _endTimeLabel.text  = [self __videoTimeToString:endTime];
    
    [_videoSeekSlider setValue:(float)playTime / _totalVideoTime animated:NO];
}

#pragma mark - Release Timer
- (void)__releaseTimer
{
    [_timer invalidate];
    self.timer = nil;
}

#pragma mark - 返回是否連接設備
- (BOOL)__isConnected
{
    return [UIScreen screens].count > 1;
}

#pragma mark - 設置 MPVolumeView 寬
- (void)__setupVolumeContainerWidth:(CGFloat)width
{
    // 左右各空 44
    _volumeContainer.width = width - (44 * 2);

    if(!_volumeContainer.customView)
    {
        // yep, 18.0 is magic number, 剛好置中
        MPVolumeView *volumeView = [[MPVolumeView alloc]initWithFrame:
                                    CGRectMake(0, 0, _volumeContainer.width, 18.0)];

        // see issue #1
        volumeView.showsRouteButton = NO;
        _volumeContainer.customView = volumeView;
    }
    else
    {
        // yep, 18.0 is magic number, 剛好置中
        CGRect frame = CGRectMake(0, 0, _volumeContainer.width, 18.0);
        _volumeContainer.customView.frame = frame;
    }
}

#pragma mark - 顯示錯誤訊息
- (void)__showErrorMessage
{
    UIAlertController *alert =
    [UIAlertController alertControllerWithTitle:@"錯誤"
                                        message:@"無法播放該影片"
                                 preferredStyle:UIAlertControllerStyleAlert];

    UIAlertAction *cancel =
    [UIAlertAction actionWithTitle:@"確定"
                             style:UIAlertActionStyleCancel
                           handler:^(UIAlertAction *action) {
        [self dismissViewControllerAnimated:YES completion:nil];
    }];

    [alert addAction:cancel];
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - 返回 Cache 目錄
- (NSString *)__cacheDirectory
{
    NSString *cache =
    [NSString stringWithFormat:@"%@/Library/Caches/SRPPlayerCache", NSHomeDirectory()];
    
    if (![[NSFileManager defaultManager]fileExistsAtPath:cache]) {
        [[NSFileManager defaultManager]createDirectoryAtPath:cache
                                 withIntermediateDirectories:YES
                                                  attributes:nil
                                                       error:NULL];
    }
    
    return cache;
}

#pragma mark - 將影片時間轉成 String
- (NSString *)__videoTimeToString:(long)time
{
    unsigned long toSeconds, hour, min, sec;

    toSeconds = time / 1000;
    hour      = toSeconds / 3600;
    min       = (toSeconds - hour * 3600) / 60;
    sec       = toSeconds - hour * 3600 - min * 60;

    NSMutableString *string = [NSMutableString string];

    if(hour > 0)
    {
        [string appendString:[NSString stringWithFormat:@"%ld:", hour]];
    }

    [string appendString:[NSString stringWithFormat:@"%02ld:", min]];
    [string appendString:[NSString stringWithFormat:@"%02ld", sec]];

    return string;
}

@end