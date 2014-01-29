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
@synthesize playingLabel;
@synthesize metaItem;
@synthesize metadataArray;

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    player = [[MPMoviePlayerController alloc] initWithContentURL:[NSURL URLWithString:@"http://174.36.1.92:5659/Live"]];
    player.movieSourceType = MPMovieSourceTypeStreaming;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(metadataUpdate:) name:MPMoviePlayerTimedMetadataUpdatedNotification object:nil];
    
    player.view.hidden = YES;
    [self.view addSubview:player.view];
    
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    [audioSession setCategory:AVAudioSessionCategoryPlayback error:nil];
    [audioSession setActive:YES error:nil];
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
    [player setControlStyle:MPMovieControlStyleEmbedded];
    
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)togglePlayingStream:(id)sender {
    if (!player.playbackState == MPMoviePlaybackStatePlaying) {
        
        [player play];
        [playPauseButton setTitle:@"Pause" forState:UIControlStateNormal];
        
        
    } else if(player.playbackState == MPMoviePlaybackStatePlaying) {
        [player pause];
        [playPauseButton setTitle:@"Play" forState:UIControlStateNormal];
    } else if(player.playbackState == MPMoviePlaybackStatePaused) {
        [player play];
        [playPauseButton setTitle:@"Pause" forState:UIControlStateNormal];
    }
}

- (void) metadataUpdate:(NSNotification*)notification
{
    if ([player timedMetadata] != nil && [[player timedMetadata] count] > 0) {
        metadataArray = [player timedMetadata];
        
        for (int i = 0; i < [metadataArray count]; i++) {
            metaItem = [[player timedMetadata] objectAtIndex:i];
            [playingLabel setText:metaItem.value];
            NSLog(@"%@", metaItem.value);
            NSLog(@"%i", metadataArray.count);
        }
        
        Class playingInfoCenter = NSClassFromString(@"MPNowPlayingInfoCenter");
        
        if (playingInfoCenter) {
            NSMutableDictionary *songInfo = [[NSMutableDictionary alloc] init];
            
            MPMediaItemArtwork *albumArt = [[MPMediaItemArtwork alloc] initWithImage:[UIImage imageNamed:@"radiouahid_logo.png"]];
            
            [songInfo setObject:metaItem.value forKey:MPMediaItemPropertyTitle];
            [songInfo setObject:albumArt forKey:MPMediaItemPropertyArtwork];
            [[MPNowPlayingInfoCenter defaultCenter] setNowPlayingInfo:songInfo];
        }
    }
}

- (IBAction)stopButtonTouched:(id)sender {
    if(player.playbackState == MPMoviePlaybackStatePlaying) {
        [player stop];
        [playPauseButton setTitle:@"Play" forState:UIControlStateNormal];
    }
}

-(void)remoteControlReceivedWithEvent:(UIEvent *)event
{
    switch (event.subtype) {
        case UIEventSubtypeRemoteControlPlay:
            
            break;
            
        case UIEventSubtypeRemoteControlPause:
            
            break;
            
        default:
            break;
    }
}
@end
