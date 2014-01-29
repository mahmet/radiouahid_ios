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
@synthesize reachability;
@synthesize remoteHostStatus;
@synthesize loadingLabel;
@synthesize spinner;

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(metadataUpdate:) name:MPMoviePlayerTimedMetadataUpdatedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(networkChanged:) name:kReachabilityChangedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerFinishedLoading:) name:MPMediaPlaybackIsPreparedToPlayDidChangeNotification object:player];
    
    spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    spinner.center = self.view.center;
    [self.view addSubview:spinner];
    
    
    reachability = [Reachability reachabilityForInternetConnection];
    [reachability startNotifier];
    
    remoteHostStatus = [reachability currentReachabilityStatus];
    
    if(remoteHostStatus == NotReachable) {
        [self handleNoInternetConnection];
    } else {
        [self initializePlayer];
    }
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)togglePlayingStream:(id)sender {
    if(player.playbackState == MPMoviePlaybackStateStopped) {
        [spinner startAnimating];
    }
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
            NSLog(@"%lu", (unsigned long)metadataArray.count);
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
            [player play];
            [playPauseButton setTitle:@"Pause" forState:UIControlStateNormal];
            break;
            
        case UIEventSubtypeRemoteControlPause:
            [player pause];
            [playPauseButton setTitle:@"Play" forState:UIControlStateNormal];
            break;
            
        default:
            break;
    }
}

-(void) networkChanged:(NSNotification *) notification
{
    remoteHostStatus = [reachability currentReachabilityStatus];
    
    if (remoteHostStatus == NotReachable) {
        [self handleNoInternetConnection];
    } else if(remoteHostStatus == ReachableViaWiFi) {
        NSLog(@"Reachable via Wifi");
        if ([playPauseButton state] == UIControlStateDisabled) {
            [self handleInternetConnectionReturned];
        }
    } else if(remoteHostStatus == ReachableViaWWAN) {
        NSLog(@"Reachable via 3g");
        if ([playPauseButton state] == UIControlStateDisabled) {
            [self handleInternetConnectionReturned];
        }
    }
}

-(void) playerFinishedLoading:(NSNotification *) notification
{
    [spinner stopAnimating];
}

-(void)initializePlayer
{
    
    [spinner startAnimating];
    
    player = [[MPMoviePlayerController alloc] initWithContentURL:[NSURL URLWithString:@"http://174.36.1.92:5659/Live"]];
    player.movieSourceType = MPMovieSourceTypeStreaming;
    
    player.view.hidden = YES;
    [self.view addSubview:player.view];
    
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    [audioSession setCategory:AVAudioSessionCategoryPlayback error:nil];
    [audioSession setActive:YES error:nil];
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
    [player setControlStyle:MPMovieControlStyleEmbedded];
    player.shouldAutoplay = NO;
    [player prepareToPlay];
    
    
    
}

-(void)handleNoInternetConnection
{
    NSLog(@"No internet connection");
    [player stop];
    [playPauseButton setTitle:@"Play" forState:UIControlStateNormal];
    [playPauseButton setEnabled:NO];
    UIAlertView *noInternetConnectionAlert = [[UIAlertView alloc] initWithTitle:@"Keine Internet Verbindung" message:@"Dein Gerät hat momentan keine Internet Verbindung, sobald du die Verbindung wieder hergestellt hast kannst du aur Radiouahid weiterhören!" delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
    [noInternetConnectionAlert show];
}

-(void)handleInternetConnectionReturned
{
    NSLog(@"initialize player now");
    [self initializePlayer];
    [playPauseButton setEnabled:YES];
}
@end
