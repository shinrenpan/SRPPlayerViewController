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
#import <MediaPlayer/MPVolumeView.h>
#import <AVFoundation/AVFoundation.h>


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


@interface SRPMoviePlayerController ()
<
    VMediaPlayerDelegate,
    UIGestureRecognizerDelegate
>

@property (nonatomic, weak) IBOutlet UINavigationBar *navBar;   // 上方 NavigationBar
@property (nonatomic, weak) IBOutlet UISlider *videoSeekSlider; // 調整影片時間的 slider
@property (nonatomic, weak) IBOutlet UILabel *endTimeLabel;     // 影片結束時間
@property (nonatomic, weak) IBOutlet UIView *playerView;        // 在 App 裡播放的 View
@property (nonatomic, weak) IBOutlet UIActivityIndicatorView *bufferView; // buffer 時的轉轉
@property (nonatomic, weak) IBOutlet UILabel *connectLabel;     // 告知連結至外接設備 Label
@property (nonatomic, weak) IBOutlet UIToolbar *toolbar;        // 下方 Toolbar
@property (nonatomic, weak) IBOutlet UIBarButtonItem *playPauseItem; // 播放暫停 item
@property (nonatomic, weak) IBOutlet UIBarButtonItem *volumeContainer; // 調整聲音 Slider Container

@property (nonatomic, assign) BOOL videoSeekSliderIsDragging; // videoSeekSlider 是否正在拖拉
@property (nonatomic, assign) long totalVideoTime;            // 影片總時間
@property (nonatomic, strong) CADisplayLink *timer;           // timer
@property (nonatomic, strong) VMediaPlayer *player;           // 播放器
@property (nonatomic, strong) UIWindow *playerWindow;         // 連接外接設備時播放的 View

@end


@implementation SRPMoviePlayerController

#pragma mark - 清除暫存
+ (void)cleanCache
{
    NSString *cache =
    [NSString stringWithFormat:@"%@/Library/Caches/SRPPlayerCache", NSHomeDirectory()];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        [[NSFileManager defaultManager]removeItemAtPath:cache error:nil];
    });
}

#pragma mark - LifeCycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    [self __setupInit];
    [self __setupVolumeViewWithSize:[UIScreen mainScreen].applicationFrame.size];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self __setupPlayer];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self __releaseTimer];
    [self __removeObserver];
    [_player reset];
    [_player unSetupPlayer];
    
    [UIApplication sharedApplication].idleTimerDisabled = NO;
    
    if([self __isConnected])
    {
        [self __didDisconnectScreen:nil];
    }
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:
(id<UIViewControllerTransitionCoordinator>)coordinator
{
    // 螢幕 roate 時要調整 volumeView
    [self __setupVolumeViewWithSize:size];
}

- (BOOL)prefersStatusBarHidden
{
    // 隱藏 statusBar 的時機 = _navBar 隱藏時
    return _navBar.hidden;
}

#pragma mark - UIGestureRecognizerDelegate
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer
       shouldReceiveTouch:(UITouch *)touch
{
    // 一定要設 delegate, 不然拖拉影片或是聲音, 會不小心觸發 tap,
    // 播放影片時的 View Class 為 GLVPlayerView
    return
    touch.view == self.view   ||
    touch.view == _playerView ||
    [touch.view isKindOfClass:NSClassFromString(@"GLVPlayerView")];
}

#pragma mark - IBAction
#pragma mark 按下 Done
- (IBAction)doneItemDidClicked:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - 按下播放 / 暫停
- (IBAction)playPauseItemDidClicked:(UIBarButtonItem *)sender
{
    if([_player isPlaying])
    {
        [_player pause];
    }
    else
    {
        [_player start];
    }
}

#pragma mark - videoSeekSlider 拖拉ing
- (IBAction)videoSeekSliderDragging:(UISlider *)sender
{
    self.videoSeekSliderIsDragging = YES;
    long endTime                   = _totalVideoTime * (1.0 - sender.value);
    _endTimeLabel.text             = [self __videoTimeToString:endTime];
}

#pragma mark - videoSeekSlider 拖拉結束
- (IBAction)videoSeekSliderValueDidChanged:(UISlider *)sender
{
    self.videoSeekSliderIsDragging = NO;
    long seekTo = _totalVideoTime * sender.value;
    [_player seekTo:seekTo];
}

#pragma mark - VMediaPlayerDelegate
- (void)mediaPlayer:(VMediaPlayer *)player didPrepared:(id)arg
{
    [player start];
    
    _bufferView.hidden = YES;
    _totalVideoTime    = [player getDuration];
    
    [self __startTimer];
}

- (void)mediaPlayer:(VMediaPlayer *)player playbackComplete:(id)arg
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)mediaPlayer:(VMediaPlayer *)player error:(id)arg
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

- (void)mediaPlayer:(VMediaPlayer *)player setupManagerPreference:(id)arg
{
    player.decodingSchemeHint       = VMDecodingSchemeSoftware;
    player.autoSwitchDecodingScheme = NO;
}

- (void)mediaPlayer:(VMediaPlayer *)player setupPlayerPreference:(id)arg
{
    player.useCache = YES;
    
    [player setBufferSize:1024*1024];
    [player setVideoQuality:VMVideoQualityLow];
    [player setCacheDirectory:[self __cacheDirectory]];
}

- (void)mediaPlayer:(VMediaPlayer *)player bufferingStart:(id)arg
{
    [_player pause];
    _bufferView.hidden = NO;
}

- (void)mediaPlayer:(VMediaPlayer *)player bufferingEnd:(id)arg
{
    [_player start];
    _bufferView.hidden = YES;
}

#pragma mark - Private methods
#pragma mark 初始設置
- (void)__setupInit
{
    // UINavigationBar titleView 不支援 autoLayout
    _navBar.topItem.titleView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    
    if(_videoURL)
    {
        [self __addObserver];
        
        self.player       = [VMediaPlayer sharedInstance];
        self.playerWindow = [[UIWindow alloc]initWithFrame:CGRectZero];
        
        [UIApplication sharedApplication].idleTimerDisabled = YES;
        
        UITapGestureRecognizer *tap =
        [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(__tapHandle:)];
        
        tap.delegate = self;
        
        [self.view addGestureRecognizer:tap];
    }
}

#pragma mark - 設置播放器
- (void)__setupPlayer
{
    if(_videoURL)
    {
        // see issue #1
        //[[AVAudioSession sharedInstance]setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
        
        [_player setupPlayerWithCarrierView:_playerView withDelegate:self];
        [_player setDataSource:_videoURL];
        [_player prepareAsync];
        
        if([self __isConnected])
        {
            UIScreen *screen = [[UIScreen screens]lastObject];
            [self __handleConnectedScreen:screen];
        }
    }
}

#pragma mark - 設置聲音 Slider
- (void)__setupVolumeViewWithSize:(CGSize)size
{
    // 左右各空 44
    _volumeContainer.width = size.width - (44 * 2);
    
    if(!_volumeContainer.customView)
    {
        // yep, 18.0 is magic number, 剛好置中
        MPVolumeView *volumeView = [[MPVolumeView alloc]initWithFrame:
                                    CGRectMake(0, 0, _volumeContainer.width, 18.0)];
        
        // see issue #1
        //volumeView.showsRouteButton = NO;
        _volumeContainer.customView = volumeView;
    }
    else
    {
        // yep, 18.0 is magic number, 剛好置中
        CGRect frame = CGRectMake(0, 0, _volumeContainer.width, 18.0);
        _volumeContainer.customView.frame = frame;
    }
}

#pragma mark - Notification
- (void)__addObserver
{
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    
    // 連接設備
    [center addObserver:self selector:@selector(__didConnectScreen:)
                   name:UIScreenDidConnectNotification object:nil];
    
    // 移除連接
    [center addObserver:self selector:@selector(__didDisconnectScreen:)
                   name:UIScreenDidDisconnectNotification object:nil];
    
    // 進入前景
    [center addObserver:self selector:@selector(__appWillEnterForeground:)
                   name:UIApplicationWillEnterForegroundNotification object:nil];
    
    // 進入背景
    [center addObserver:self selector:@selector(__appDidEnterBackground:)
                   name:UIApplicationDidEnterBackgroundNotification object:nil];
    
    // 可能有電話進來時
    [center addObserver:self selector:@selector(__handleInterruption:)
                   name:AVAudioSessionInterruptionNotification object:nil];
    
    /* 切換 AirPlay 時的 Notification
    [center addObserver:self selector:@selector(__handleRouteActive:)
                   name:MPVolumeViewWirelessRouteActiveDidChangeNotification object:nil];*/
}

- (void)__removeObserver
{
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    
    [center removeObserver:self];
}

#pragma mark - 外接設備處理
- (void)__didConnectScreen:(NSNotification *)sender
{
    UIScreen *screen = sender.object;

    [self __handleConnectedScreen:screen];
}

- (void)__handleConnectedScreen:(UIScreen *)screen
{
    _connectLabel.hidden             = NO;
    screen.overscanCompensation      = UIScreenOverscanCompensationInsetApplicationFrame;
    UIViewController *controller     = [[ConnectedController alloc]init];
    _playerWindow.rootViewController = controller;
    
    [controller.view addSubview:_playerView];
    
    controller.view.frame = screen.bounds;
    _playerView.frame     = screen.bounds;
    _playerWindow.screen  = screen;
    _playerWindow.hidden  = NO;
}

- (void)__didDisconnectScreen:(NSNotification *)sender
{
    _connectLabel.hidden = YES;
    
    [self.view addSubview:_playerView];
    [self.view sendSubviewToBack:_playerView];
    
    _playerView.frame                = self.view.frame;
    _playerWindow.hidden             = YES;
    _playerWindow.rootViewController = nil;
}

#pragma mark - 進入 / 退出背景

- (void)__appWillEnterForeground:(id)sender
{
    _timer.paused = NO;
    [_player start];
}

- (void)__appDidEnterBackground:(id)sender
{
    // 進入背景時, TV out 上的畫面不會 Render, 就關掉 player 吧
    _timer.paused = YES;
    [_player pause];
}

#pragma mark - 聲音中斷 (maybe 有電話打進來)
- (void)__handleInterruption:(NSNotification *)sender
{
    NSDictionary *info = sender.userInfo;
    NSNumber *type = info[AVAudioSessionInterruptionTypeKey];
    
    // 只 handle begin, end 的話, 讓 User 手動去 play video
    if([type integerValue] == AVAudioSessionInterruptionTypeBegan)
    {
        [_player pause];
    }
}

/* see issue #1
#pragma mark - 處理 User 切換 AirPlay
- (void)__handleRouteActive:(NSNotification *)sender
{
    
}
*/

#pragma mark - 點擊畫面
- (void)__tapHandle:(id)sender
{
    _navBar.hidden  = !_navBar.hidden;
    _toolbar.hidden = !_toolbar.hidden;
    
    [self setNeedsStatusBarAppearanceUpdate];
    [self.view layoutIfNeeded];
}

#pragma mark - Timer
- (void)__startTimer
{
    if(![_player isPlaying])
    {
        return;
    }
    
    if(!_timer)
    {
        self.timer = [CADisplayLink displayLinkWithTarget:self
                                                 selector:@selector(__timerHandle:)];
        
        _timer.frameInterval = 4;
        
        [_timer addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
    }
    
    _timer.paused = NO;
}

- (void)__releaseTimer
{
    _timer.paused = YES;
    
    [_timer removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
    [_timer invalidate];
    
    self.timer = nil;
}

- (void)__timerHandle:(id)sender
{
    _playPauseItem.title = [_player isPlaying] ? @"∎∎" : @"▶︎";
    
    // 當 videoSeekSlider 拖拉時, 不變動 UI
    if(!_videoSeekSliderIsDragging)
    {
        long playTime      = [_player getCurrentPosition];
        long endTime       = _totalVideoTime - playTime;
        _endTimeLabel.text = [self __videoTimeToString:endTime];
        
        [_videoSeekSlider setValue:(float)playTime / _totalVideoTime animated:NO];
    }
}

#pragma mark - Cache 目錄
- (NSString *)__cacheDirectory
{
    NSString *cache = [NSString stringWithFormat:@"%@/Library/Caches/SRPPlayerCache", NSHomeDirectory()];
    if (![[NSFileManager defaultManager] fileExistsAtPath:cache]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:cache
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
    
    NSMutableString *string = [NSMutableString stringWithFormat:@"-"];
    
    if(hour > 0)
    {
        [string appendString:[NSString stringWithFormat:@"%ld:", hour]];
    }
    
    [string appendString:[NSString stringWithFormat:@"%02ld:", min]];
    [string appendString:[NSString stringWithFormat:@"%02ld", sec]];
    
    return string;
}

#pragma mark - 是否連接外接設備
- (BOOL)__isConnected
{
    return [UIScreen screens].count > 1;
}

@end
