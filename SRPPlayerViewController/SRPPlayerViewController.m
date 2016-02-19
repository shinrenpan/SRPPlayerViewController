//
//  SRPPlayerViewController.m
//  SRPPlayerViewController
//
//  Created by Shinren Pan on 2016/2/15.
//  Copyright © 2016年 Shinren Pan. All rights reserved.
//

#import "SRPPlayerViewController.h"
#import "SRPPlayerTVConnectViewController.h"


@interface SRPPlayerViewController ()

@property (nonatomic, strong) UIWindow *tvConnectWindow;
@property (nonatomic, strong) id<IJKMediaPlayback>player;

@end


@implementation SRPPlayerViewController

#pragma mark - LifeCycle
- (void)dealloc
{
    [self __removeObserver];
    [_player shutdown];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self __setup];
}

#pragma mark - Properties getter
- (NSTimeInterval)currentPlaybackTime
{
    return [_player currentPlaybackTime];
}

- (IJKMPMovieScalingMode)scalingMode
{
    return [_player scalingMode];
}

- (NSTimeInterval)duration
{
    return [_player duration];
}

- (NSTimeInterval)playableDuration
{
    return [_player playableDuration];
}

- (BOOL)isTVConnected
{
    return [UIScreen screens].count > 1;
}

- (BOOL)isPlaying
{
    return [_player isPlaying];
}

#pragma mark - Properties setter
- (void)setCurrentPlaybackTime:(NSTimeInterval)currentPlaybackTime
{
    [_player setCurrentPlaybackTime:currentPlaybackTime];
}

- (void)setScalingMode:(IJKMPMovieScalingMode)scalingMode
{
    if(scalingMode < 0)
    {
        scalingMode = IJKMPMovieScalingModeFill;
    }
    
    if(scalingMode > IJKMPMovieScalingModeFill)
    {
        scalingMode = IJKMPMovieScalingModeNone;
    }
    
    [_player setScalingMode:scalingMode];
}

#pragma mark - Public
- (void)play
{
    [_player play];
}

- (void)pause
{
    [_player pause];
}

- (void)stop
{
    [_player stop];
}

#pragma mark - Private
#pragma mark setup
- (void)__setup
{
    if(!_mediaURL)
    {
        return;
    }
    
    [IJKFFMoviePlayerController setLogReport:NO];
    
    _tvConnectWindow = [[UIWindow alloc]init];
    _player = [[IJKFFMoviePlayerController alloc]initWithContentURL:_mediaURL withOptions:nil];
    
    UIView *playerView          = [_player view];
    playerView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    playerView.frame            = self.view.bounds;
    playerView.backgroundColor  = [UIColor blackColor];
    
    [self.view insertSubview:playerView atIndex:0];
    [_player setShouldAutoplay:YES];
    [_player setScalingMode:IJKMPMovieScalingModeAspectFit];
    [self __addObserver];
}

#pragma mark Observer handle
- (void)__addObserver
{
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    
    [center addObserver:self selector:@selector(__playerPlaybackDidFinishNotification:)
                   name:IJKMPMoviePlayerPlaybackDidFinishNotification object:nil];
    
    [center addObserver:self selector:@selector(__playerPlaybackStateDidChangeNotification:)
                   name:IJKMPMoviePlayerPlaybackStateDidChangeNotification object:nil];
    
    [center addObserver:self selector:@selector(__playerLoadStateDidChangeNotification:)
                   name:IJKMPMoviePlayerLoadStateDidChangeNotification object:nil];
    
    [center addObserver:self selector:@selector(__screenDidConnectNotification:)
                   name:UIScreenDidConnectNotification object:nil];
    
    [center addObserver:self selector:@selector(__screenDidDisconnectNotification:)
                   name:UIScreenDidDisconnectNotification object:nil];
    
    [_player prepareToPlay];
    
    if(self.isTVConnected)
    {
        [self __screenDidConnectNotification:nil];
    }
}

- (void)__removeObserver
{
    [[NSNotificationCenter defaultCenter]removeObserver:self];
}

#pragma mark player handle
- (void)__playerPlaybackDidFinishNotification:(NSNotification *)sender
{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    
    if(_delegate && [_delegate respondsToSelector:@selector(playerController:finishReason:)])
    {
        NSInteger reason = [sender.object integerValue];
        
        [_delegate playerController:self finishReason:reason];
    }
}

- (void)__playerPlaybackStateDidChangeNotification:(NSNotification *)sender
{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    
    if(_delegate && [_delegate respondsToSelector:@selector(playerController:playbackStateChanged:)])
    {
        NSInteger state = [@([_player playbackState]) integerValue];
        
        [_delegate playerController:self playbackStateChanged:state];
    }
}

- (void)__playerLoadStateDidChangeNotification:(NSNotification *)sender
{
    [UIApplication sharedApplication].networkActivityIndicatorVisible =
    ([_player loadState] == IJKMPMovieLoadStateStalled) ? YES : NO;
    
    if(_delegate && [_delegate respondsToSelector:@selector(playerController:loadStateChanged:)])
    {
        NSInteger state = [@([_player loadState]) integerValue];
        
        [_delegate playerController:self loadStateChanged:state];
    }
}

#pragma mark TV connect handle
- (void)__screenDidConnectNotification:(NSNotification *)sender
{
    UIView *playerView                    = [_player view];
    UIScreen *screen                      = (sender.object) ? sender.object : [UIScreen screens].lastObject;
    screen.overscanCompensation           = UIScreenOverscanCompensationNone;
    SRPPlayerTVConnectViewController *mvc = [[SRPPlayerTVConnectViewController alloc]init];
    _tvConnectWindow.rootViewController   = mvc;
    _tvConnectWindow.screen               = screen;
    _tvConnectWindow.hidden               = NO;
    mvc.view.frame                        = screen.bounds;
    playerView.frame                      = screen.bounds;
    
    [mvc.view addSubview:playerView];
    
    if(_delegate && [_delegate respondsToSelector:@selector(playerControllerTVConnected)])
    {
        [_delegate playerControllerTVConnected];
    }
}

- (void)__screenDidDisconnectNotification:(NSNotification *)sender
{
    UIView *playerView                  = [_player view];
    _tvConnectWindow.hidden             = YES;
    _tvConnectWindow.rootViewController = nil;
    playerView.frame                    = self.view.bounds;
    
    [self.view insertSubview:playerView atIndex:0];
    
    if(_delegate && [_delegate respondsToSelector:@selector(playerControllerTVDisconnected)])
    {
        [_delegate playerControllerTVDisconnected];
    }
}

@end
