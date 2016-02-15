//
//  ViewController.m
//  Demo
//
//  Created by Shinren Pan on 2016/2/15.
//  Copyright © 2016年 Shinren Pan. All rights reserved.
//

#import "ViewController.h"
#import "DemoPlayerViewController.h"

@interface ViewController ()<UITextFieldDelegate>

@property (nonatomic, weak) IBOutlet UITextField *mediaURLField;

@end


@implementation ViewController

#pragma mark - LifeCycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _mediaURLField.layer.borderColor = [UIColor lightGrayColor].CGColor;
    _mediaURLField.layer.borderWidth = 1.0;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if([segue.identifier isEqualToString:@"toDemoPlayerViewController"])
    {
        DemoPlayerViewController *mvc = segue.destinationViewController;
        mvc.mediaURL = [NSURL URLWithString:_mediaURLField.text];
    }
}

#pragma mark - UITextFieldDelegate
- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [self.view endEditing:YES];
    
    if(textField.text.length)
    {
        [self performSegueWithIdentifier:@"toDemoPlayerViewController" sender:nil];
    }
    
    return YES;
}

@end
