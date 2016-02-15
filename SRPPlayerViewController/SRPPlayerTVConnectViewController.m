//
//  SRPPlayerTVConnectViewController.m
//  SRPPlayerViewController
//
//  Created by Shinren Pan on 2016/2/15.
//  Copyright © 2016年 Shinren Pan. All rights reserved.
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
