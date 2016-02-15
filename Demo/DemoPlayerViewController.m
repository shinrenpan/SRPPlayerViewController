//
//  DemoPlayerViewController.m
//  SRPPlayerViewController
//
//  Created by Shinren Pan on 2016/2/15.
//  Copyright © 2016年 Shinren Pan. All rights reserved.
//

#import "DemoPlayerViewController.h"

@interface DemoPlayerViewController ()<SRPPlayerViewControllerDelegate>

@property (nonatomic, weak) IBOutlet UIBarButtonItem *playOrPauseItem;

@end


@implementation DemoPlayerViewController

#pragma mark - LifeCycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.delegate = self;
}

#pragma mark - IBAction
- (IBAction)changeScaleClicked:(id)sender
{
    self.scalingMode++;
}

- (IBAction)back10SecsClicked:(id)sender
{
    self.currentPlaybackTime-=10;
}

- (IBAction)playOrPauseItemClicked:(UIBarButtonItem *)sender
{
    if(self.isPlaying)
    {
        [self pause];
    }
    else
    {
        [self play];
    }
}

- (IBAction)forward10SecsClicked:(id)sender
{
    self.currentPlaybackTime+=10;
}

#pragma mark - SRPPlayerViewControllerDelegate
- (void)playerController:(SRPPlayerViewController *)playerController
    playbackStateChanged:(IJKMPMoviePlaybackState)state
{
    _playOrPauseItem.title =
    (state == IJKMPMoviePlaybackStatePlaying) ? @"Pause" : @"Play";
}

@end
