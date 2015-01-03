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


#import "SRPMoviePlayerController.h"
#import <IJKMediaPlayer/IJKMediaPlayer.h>


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

@property (nonatomic, weak) IBOutlet UIView          *controlPanel; // 控制面板
@property (nonatomic, weak) IBOutlet UILabel         *playTimeLabel;// 播放時間
@property (nonatomic, weak) IBOutlet UISlider        *videoSeeker;  // 影片拖放
@property (nonatomic, weak) IBOutlet UILabel         *endTimeLabel; // 結束時間
@property (nonatomic, weak) IBOutlet UIBarButtonItem *playPuseItem; // 播放 / 暫停

@property (nonatomic, strong) NSTimer  *timer;           // Timer
@property (nonatomic, strong) UIWindow *TVWindow;        // 外接設備 Window
@property (nonatomic, assign) BOOL     seekerDragging;   // 是否正在拖放
@property (nonatomic, strong) id<IJKMediaPlayback>player;// Player
@end


@implementation SRPMoviePlayerController

#pragma mark - LifeCycle
- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if(_videoURL)
    {
        [self __setup];
    }
    else
    {
        [self __showErrorMessage];
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if(_player)
    {
        if([self __isConnected])
        {
            [self __handleConnected];
        }
        
        [_player prepareToPlay];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [UIApplication sharedApplication].idleTimerDisabled = NO;
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    [self __releaseTimer];
    [self __removeObserver];
    [_player shutdown];
}

- (BOOL)prefersStatusBarHidden
{
    return _controlPanel.hidden;
}

#pragma mark - IBAction
#pragma mark 離開
- (IBAction)doneItemDidClicked:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - 隱藏 / 顯示控制面板
- (IBAction)controlPanelDidTap:(id)sender
{
    _controlPanel.hidden = !_controlPanel.hidden;
    
    [self __setupTimer];
    [self setNeedsStatusBarAppearanceUpdate];
}

#pragma mark - 正在拖拉 slider
- (IBAction)videoSeekerIsDragging:(UISlider *)sender
{
    if(![_player isPreparedToPlay])
        return;

    self.seekerDragging      = YES;
    NSTimeInterval totalTime = [_player duration];
    NSTimeInterval playTime  = totalTime * sender.value;
    NSTimeInterval endTime   = totalTime - playTime;
    _playTimeLabel.text      = [self __videoTimeToString:playTime];
    _endTimeLabel.text       = [self __videoTimeToString:endTime];
}

#pragma mark - 拖拉 slider 結束
- (IBAction)videoSeekerValueDidChanged:(UISlider *)sender
{
    if(![_player isPreparedToPlay])
    {
        sender.value = 0.0;
        return;
    }

    self.seekerDragging      = NO;
    NSTimeInterval totalTime = [_player duration];
    NSTimeInterval seekTo    = totalTime * sender.value;
    
    if(seekTo >= totalTime)
    {
        seekTo = totalTime - 10.0;
    }
    else if(seekTo <= 0)
    {
        seekTo = 0.0;
    }
    
    [_player setCurrentPlaybackTime:seekTo];
}

#pragma mark - 切換模式
- (IBAction)modeItemDidClicked:(id)sender
{
    if(![_player isPreparedToPlay])
        return;
    
    MPMovieScalingMode mode = [_player scalingMode];
    mode++;
    
    if(mode > MPMovieScalingModeFill)
        mode = MPMovieScalingModeNone;
    
    [_player setScalingMode:mode];
}

#pragma mark - 播放 / 暫停
- (IBAction)palyPauseItemDidClicked:(id)sender
{
    if(![_player isPreparedToPlay])
        return;
    
    if([_player isPlaying])
    {
        [_player pause];
    }
    else
    {
        [_player play];
    }
}

#pragma mark - 後退
- (IBAction)backItemDidClicked:(id)sender
{
    if(![_player isPreparedToPlay])
        return;
    
    NSTimeInterval seekTo = [_player currentPlaybackTime];
    seekTo-=10.0;
    if(seekTo <= 0.0)
        seekTo = 0.0;
    
    [_player setCurrentPlaybackTime:seekTo];
}

#pragma mark - 快轉
- (IBAction)forwardItemDidClicked:(id)sender
{
    if(![_player isPreparedToPlay])
        return;
    
    NSTimeInterval seekTo = [_player currentPlaybackTime];
    seekTo+=10.0;
    if(seekTo >= [_player duration])
        seekTo = [_player duration]-10.0;
    
    [_player setCurrentPlaybackTime:seekTo];
}

#pragma mark - Private methods
#pragma mark 初始設置
- (void)__setup
{
    [UIApplication sharedApplication].idleTimerDisabled = YES;
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    [IJKFFMoviePlayerController setLogReport:NO];
    
    self.TVWindow               = [[UIWindow alloc]init];
    self.player                 = [[IJKFFMoviePlayerController alloc]initWithContentURL:_videoURL
                                                              withOptions:nil];
    UIView *playerView          = [_player view];
    playerView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    playerView.frame            = self.view.bounds;
    playerView.backgroundColor  = [UIColor blackColor];

    [self.view insertSubview:playerView atIndex:1];
    [_player setScalingMode:MPMovieScalingModeAspectFit];
    [self __addObserver];
}

#pragma mark - Add Observer
- (void)__addObserver
{
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    
    [center addObserver:self selector:@selector(__playerIsPreparedToPlay:)
                   name:IJKMediaPlaybackIsPreparedToPlayDidChangeNotification object:nil];
    
    [center addObserver:self selector:@selector(__playerLoadStateDidChanged:)
                   name:IJKMoviePlayerLoadStateDidChangeNotification object:nil];
    
    [center addObserver:self selector:@selector(__playerPlaybackDidFinish:)
                   name:IJKMoviePlayerPlaybackDidFinishNotification object:nil];
    
    [center addObserver:self selector:@selector(__playerPlaybackStateDidChanged:)
                   name:IJKMoviePlayerPlaybackStateDidChangeNotification object:nil];
    
    // 連接設備
    [center addObserver:self selector:@selector(__handleConnected)
                   name:UIScreenDidConnectNotification object:nil];
    
    // 移除連接
    [center addObserver:self selector:@selector(__handleDisconnected)
                   name:UIScreenDidDisconnectNotification object:nil];
}

#pragma mark - Remove Observer
- (void)__removeObserver
{
    [[NSNotificationCenter defaultCenter]removeObserver:self];
}

#pragma mark - Player Prepare
- (void)__playerIsPreparedToPlay:(NSNotification *)sender
{
    [_player play];
}

#pragma mark - Player Load
- (void)__playerLoadStateDidChanged:(NSNotification *)sender
{
    MPMovieLoadState state = [_player loadState];
    
    // Buffering ???
    if(state == MPMovieLoadStateStalled)
    {
        [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    }
    else
    {
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    }
}

#pragma mark - Player Finish
- (void)__playerPlaybackDidFinish:(NSNotification *)sender
{
    NSInteger reason =
    [[sender.userInfo valueForKey:MPMoviePlayerPlaybackDidFinishReasonUserInfoKey]integerValue];
    
    if(reason != MPMovieFinishReasonPlaybackEnded)
    {
        [self __showErrorMessage];
    }
}

#pragma mark - Player State
- (void)__playerPlaybackStateDidChanged:(NSNotification *)sender
{
    MPMoviePlaybackState state = [_player playbackState];
    
    switch (state)
    {
        case MPMoviePlaybackStatePlaying:
            _playPuseItem.title = @"暫停";
            [self __setupTimer];
            break;
        
        case MPMoviePlaybackStatePaused:
            _playPuseItem.title = @"播放";
            [self __releaseTimer];
            break;
            
        case MPMoviePlaybackStateStopped:
            _playPuseItem.title = @"播放";
            [self __releaseTimer];
            break;
            
        case MPMoviePlaybackStateInterrupted:
            break;
            
        case MPMoviePlaybackStateSeekingForward:
            break;
            
        case MPMoviePlaybackStateSeekingBackward:
            break;
            
        default:
            break;
    }
}

#pragma mark - 是否外接設備
- (BOOL)__isConnected
{
    return [UIScreen screens].count > 1;
}

#pragma mark - 處理連接設備
- (void)__handleConnected
{
    UIView *playerView           = [_player view];
    UIScreen *screen             = [UIScreen screens].lastObject;
    screen.overscanCompensation  = UIScreenOverscanCompensationInsetApplicationFrame;
    ConnectedController *mvc     = [[ConnectedController alloc]init];
    _TVWindow.rootViewController = mvc;
    _TVWindow.screen             = screen;
    _TVWindow.hidden             = NO;
    mvc.view.frame               = screen.bounds;
    playerView.frame             = screen.bounds;
    
    [mvc.view addSubview:playerView];
}

#pragma mark - 處理移除設備
- (void)__handleDisconnected
{
    UIView *playerView           = [_player view];
    _TVWindow.hidden             = YES;
    _TVWindow.screen             = nil;
    _TVWindow.rootViewController = nil;
    playerView.frame             = self.view.bounds;
    
    [self.view insertSubview:playerView atIndex:1];
}

#pragma mark - 設置 Timer
- (void)__setupTimer
{
    [self __releaseTimer];
    
    if(!_controlPanel.hidden)
    {
        self.timer = [NSTimer scheduledTimerWithTimeInterval:0.5
                                                      target:self
                                                    selector:@selector(__handelTimer:)
                                                    userInfo:nil
                                                     repeats:YES];
    }
}

#pragma mark - 處理 Timer
- (void)__handelTimer:(NSTimer *)timer
{
    if(_seekerDragging)
        return;
    
    NSTimeInterval totalTime = [_player duration];
    NSTimeInterval playTime  = [_player currentPlaybackTime];
    NSTimeInterval endTime   = totalTime - playTime;
    _playTimeLabel.text      = [self __videoTimeToString:playTime];
    _endTimeLabel.text       = [self __videoTimeToString:endTime];
    
    [_videoSeeker setValue:playTime / totalTime animated:NO];
}

#pragma mark - Release Timer
- (void)__releaseTimer
{
    [_timer invalidate];
    
    self.timer = nil;
}

#pragma mark - 將影片時間轉成 String
- (NSString *)__videoTimeToString:(NSTimeInterval)time
{
    NSInteger ti   = (NSInteger)time;
    NSInteger hour = ti / 3600;
    NSInteger min  = (ti / 60) % 60;
    NSInteger sec  = ti % 60;
    
    NSMutableString *string = [NSMutableString string];
    
    if(hour > 0)
    {
        [string appendString:[NSString stringWithFormat:@"%ld", (long)hour]];
    }
    
    [string appendString:[NSString stringWithFormat:@"%02ld:", (long)min]];
    [string appendString:[NSString stringWithFormat:@"%02ld", (long)sec]];
    
    return string;
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

@end