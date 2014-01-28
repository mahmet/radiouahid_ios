//
//  ViewController.m
//  radiouahid
//
//  Created by Muhamed Ahmetovic on 11.01.14.
//  Copyright (c) 2014 Muhamed Ahmetovic. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>

@interface ViewController ()

@end

@implementation ViewController

@synthesize player;
@synthesize playPauseButton;

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    player = [[MPMoviePlayerController alloc] initWithContentURL:[NSURL URLWithString:@"http://174.36.1.92:5659/Live"]];
    player.movieSourceType = MPMovieSourceTypeStreaming;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(metadataUpdate:) name:MPMoviePlayerTimedMetadataUpdatedNotification object:nil];
    
    player.view.hidden = YES;
    [self.view addSubview:player.view];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)togglePlayingStream:(id)sender {
    if (!player.playbackState == MPMoviePlaybackStatePlaying) {
        AVAudioSession *audioSession = [AVAudioSession sharedInstance];
        [audioSession setCategory:AVAudioSessionCategoryPlayback error:nil];
        [audioSession setActive:YES error:nil];
        [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
        [player play];
        [playPauseButton setTitle:@"Stop" forState:UIControlStateNormal];
    } else if(player.playbackState == MPMoviePlaybackStatePlaying) {
        [player stop];
        [playPauseButton setTitle:@"Play" forState:UIControlStateNormal];
    }
}

- (void) metadataUpdate:(NSNotification*)notification
{
    if ([player timedMetadata] != nil && [[player timedMetadata] count] > 0) {
        NSArray *metadataArray = [player timedMetadata];
        
        for (int i = 0; i < [metadataArray count]; i++) {
            MPTimedMetadata *metaItem = [[player timedMetadata] objectAtIndex:i];
            NSLog(@"%@", metaItem.value);
            NSLog(@"%i", metadataArray.count);
        }
    }
}


@end
