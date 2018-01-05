//
//  Copyright (c) 2017年 shinren.pan@gmail.com All rights reserved.
//

#import <UIKit/UIKit.h>
#import <IJKMediaFramework/IJKMediaFramework.h>

NS_ASSUME_NONNULL_BEGIN

@class SRPPlayerViewController;

/**
 *  SRPPlayerViewController protocol
 */
@protocol SRPPlayerViewControllerDelegate <NSObject>
@optional


///-----------------------------------------------------------------------------
/// @name SRPPlayerViewControllerDelegate optional methods
///-----------------------------------------------------------------------------

/**
 *  SRPPlayerViewController playback state change.
 *
 *  @param playerController SRPPlayerViewController object.
 *  @param state            Changed playback state.
 */
- (void)playerController:(SRPPlayerViewController *)playerController
    playbackStateChanged:(IJKMPMoviePlaybackState)state;

/**
 *  SRPPlayerViewController
 *
 *  @param playerController SRPPlayerViewController object.
 *  @param state            Changed load state.
 */
- (void)playerController:(SRPPlayerViewController *)playerController
        loadStateChanged:(IJKMPMovieLoadState)state;

/**
 *  SRPPlayerViewController finished.
 *
 *  @param playerController SRPPlayerViewController object.
 *  @param reason           Finish reason.
 */
- (void)playerController:(SRPPlayerViewController *)playerController
            finishReason:(IJKMPMovieFinishReason)reason;

/**
 *  SRPPlayerViewController TV connected.
 */
- (void)playerControllerTVConnected;

/**
 *  SRPPlayerViewController TV disconnected.
 */
- (void)playerControllerTVDisconnected;

@end


/**
 *  A simply media play UIViewController.
 */
@interface SRPPlayerViewController : UIViewController


///-----------------------------------------------------------------------------
/// @name Properties
///-----------------------------------------------------------------------------

/**
 *  Media URL.
 */
@property (nonatomic, strong) NSURL *mediaURL;

/**
 *  Delegation.
 */
@property (nonatomic, weak, nullable) id<SRPPlayerViewControllerDelegate>delegate;

/**
 *  Current time.
 */
@property (nonatomic, assign) NSTimeInterval currentPlaybackTime;

/**
 *  Scale mode.
 */
@property (nonatomic, assign) IJKMPMovieScalingMode scalingMode;

/**
 *  Duration.
 */
@property (nonatomic, readonly) NSTimeInterval duration;

/**
 *  Playble duration.
 */
@property (nonatomic, readonly) NSTimeInterval playableDuration;

/**
 *  Buffer progress.
 */
@property (nonatomic, readonly) NSInteger bufferingProgress;

/**
 *  TV Connected.
 */
@property (nonatomic, readonly) BOOL isTVConnected;

/**
 *  Is playing.
 */
@property (nonatomic, readonly) BOOL isPlaying;


///-----------------------------------------------------------------------------
/// @name Public methods
///-----------------------------------------------------------------------------

/**
 *  Play media.
 */
- (void)play;

/**
 *  Pause media.
 */
- (void)pause;

/**
 *  Stop media.
 */
- (void)stop;

@end

NS_ASSUME_NONNULL_END
