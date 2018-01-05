//
//  Copyright (c) 2017年 shinren.pan@gmail.com All rights reserved.
//

#import "SRPPlayerTVConnectViewController.h"


@implementation SRPPlayerTVConnectViewController

#pragma mark - rotation
- (BOOL)shouldAutorotate
{
    return NO;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return ~UIInterfaceOrientationMaskAll;
}

@end
