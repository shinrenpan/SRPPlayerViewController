//
//  ViewController.m
//  Demo
//
//  Created by Shinren Pan on 2014/12/1.
//  Copyright (c) 2014年 Shinren Pan. All rights reserved.
//

#import "ViewController.h"
#import "SRPMoviePlayerController.h"


@interface ViewController ()<UITextFieldDelegate>

@property (nonatomic, weak) IBOutlet UITextField *field;

@end


@implementation ViewController

- (IBAction)playButtonDidClicked:(id)sender
{
    if(!_field.text.length)
    {
        return;
    }
    
    [self __gotoPlayerController];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if(textField.text.length)
    {
        [self __gotoPlayerController];
    }
    
    return YES;
}

- (void)__gotoPlayerController
{
    NSURL *URL = [NSURL URLWithString:_field.text];
    
    SRPMoviePlayerController *mvc =
    [[SRPMoviePlayerController alloc]initWithNibName:@"SRPMoviePlayerController" bundle:nil];
    
    mvc.videoURL = URL;
    
    [self presentViewController:mvc animated:YES completion:nil];
}

@end
