//
//  ViewController.m
//  radiouahid
//
//  Created by Muhamed Ahmetovic on 11.01.14.
//  Copyright (c) 2014 Muhamed Ahmetovic. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <Social/Social.h>

#define STREAM_URL @"http://174.36.1.92:5659/Live"

@interface ViewController ()

@end

@implementation ViewController

@synthesize player;
@synthesize playPauseButton;
@synthesize stopButton;
@synthesize playingLabel;
@synthesize metaItem;
@synthesize metadataArray;
@synthesize reachability;
@synthesize remoteHostStatus;
@synthesize spinner;
@synthesize playButtonImage;
@synthesize stopButtonImage;
@synthesize pauseButtonImage;
@synthesize musicPlayer;
@synthesize firstStart;
@synthesize feedbackLabel;
@synthesize infoView;
@synthesize infoButton;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    firstStart = YES;
    
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
    
    //Set up buttons
    playButtonImage = [UIImage imageNamed:@"play_button.png"];
    pauseButtonImage = [UIImage imageNamed:@"pause_button.png"];
    [playPauseButton setImage:pauseButtonImage forState:UIControlStateNormal];
    
    infoButton = [UIButton buttonWithType:UIButtonTypeCustom];
    UIImage *infoButtonImage = [UIImage imageNamed:@"info.png"];
    [infoButton setBackgroundImage:infoButtonImage forState:UIControlStateNormal];
    [infoButton addTarget:self action:@selector(infoButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    
    playingLabel = [[MarqueeLabel alloc] init];
    [playingLabel setTextColor:[UIColor whiteColor]];
    [playingLabel setBackgroundColor:[UIColor clearColor]];
    [playingLabel setUserInteractionEnabled:NO];
    [playingLabel setTextAlignment:NSTextAlignmentCenter];
    [playingLabel setRate:20.0];
    [playingLabel setFadeLength:10.0f];
    [playingLabel setMarqueeType:MLContinuous];
    
    
    // Volumeholder
    UIView *volumeHolder;
    
    CGSize screenSize = [[UIScreen mainScreen] bounds].size;
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        if (screenSize.height > 480.0f) {
            //iphone 5
            [infoButton setFrame:CGRectMake(32, 32, 37, 35)];
            volumeHolder = [[UIView alloc] initWithFrame: CGRectMake(50, 530, 220, 20)];
            [playingLabel setFrame:CGRectMake(15, 460, screenSize.width * 0.9, 50)];
        } else {
            //iphone 4
            [infoButton setFrame:CGRectMake(32, 32, 37, 35)];
            volumeHolder = [[UIView alloc] initWithFrame: CGRectMake(50, 450, 220, 20)];
            [playingLabel setFrame:CGRectMake(15, 383, screenSize.width * 0.9, 50)];
        }
    }
    
    [self.view addSubview:playingLabel];
    
    [volumeHolder setBackgroundColor: [UIColor clearColor]];
    [self.view addSubview: volumeHolder];
    MPVolumeView *myVolumeView = [[MPVolumeView alloc] initWithFrame: volumeHolder.bounds];
    [volumeHolder addSubview: myVolumeView];
    
    playingLabel.textColor = [UIColor whiteColor];
    
    infoView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"milky.png"]];
    
    if ([self isFirstRun]) {
        //view appears
    } else {
        [infoView setHidden:YES];
    }
    
    [self prepareFirstRun];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (IBAction)togglePlayingStream:(id)sender {
    if(player.playbackState == MPMoviePlaybackStateStopped) {
        [spinner startAnimating];
        [feedbackLabel setText:@"Verbindung wird hergestellt..."];
    }
    if (!player.playbackState == MPMoviePlaybackStatePlaying) {
        
        [player play];
        [playPauseButton setImage:pauseButtonImage forState:UIControlStateNormal];
        
        
        
    } else if(player.playbackState == MPMoviePlaybackStatePlaying) {
        [player pause];
        [feedbackLabel setText:@"Pausiert"];
        [playPauseButton setImage:playButtonImage forState:UIControlStateNormal];
    } else if(player.playbackState == MPMoviePlaybackStatePaused) {
        [player play];
        [feedbackLabel setText:@"On Air"];
        [playPauseButton setImage:pauseButtonImage forState:UIControlStateNormal];
    }
}

- (void) metadataUpdate:(NSNotification*)notification
{
    if ([player timedMetadata] != nil && [[player timedMetadata] count] > 0) {
        metadataArray = [player timedMetadata];
        
        for (int i = 0; i < [metadataArray count]; i++) {
            metaItem = [[player timedMetadata] objectAtIndex:i];
            NSLog(@"%@", metaItem.key);
            NSString *decodedString = [[NSString alloc] initWithData:[metaItem.value dataUsingEncoding:NSISOLatin1StringEncoding allowLossyConversion:YES] encoding:NSUTF8StringEncoding];
            [playingLabel setText:decodedString];
            NSLog(@"%@", metaItem.value);
            NSLog(@"%lu", (unsigned long)metadataArray.count);
        }
        
        MPMediaItem *item = [[MPMusicPlayerController iPodMusicPlayer] nowPlayingItem];
        MPMediaItemArtwork *art = [item valueForProperty:MPMediaItemPropertyArtwork];
        NSLog(@"%@", art.description);
        
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
    
    [player stop];
    [feedbackLabel setText:@"Angehalten"];
    [playPauseButton setImage:playButtonImage forState:UIControlStateNormal];
   
}

-(void)remoteControlReceivedWithEvent:(UIEvent *)event
{
    switch (event.subtype) {
        case UIEventSubtypeRemoteControlPlay:
            [player play];
            [playPauseButton setImage:pauseButtonImage forState:UIControlStateNormal];
            break;
            
        case UIEventSubtypeRemoteControlPause:
            [player pause];
            [playPauseButton setImage:playButtonImage forState:UIControlStateNormal];
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
        [self stopButtonTouched:self];
        [self initializePlayer];
//        if ([playPauseButton state] == UIControlStateDisabled) {
//            [self handleInternetConnectionReturned];
//        }
    }
}

-(void) playerFinishedLoading:(NSNotification *) notification
{
    [spinner stopAnimating];
    [feedbackLabel setText:@"On Air"];
}

-(void)initializePlayer
{
    
    [spinner startAnimating];
    [feedbackLabel setText:@"Verbindung wird hergestellt..."];
    
    player = [[MPMoviePlayerController alloc] init];
    player.movieSourceType = MPMovieSourceTypeStreaming;
    [player setContentURL:[NSURL URLWithString:STREAM_URL]];
    
    player.view.hidden = YES;
    [self.view addSubview:player.view];
    
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    [audioSession setCategory:AVAudioSessionCategoryPlayback error:nil];
    [audioSession setActive:YES error:nil];
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
    [player setControlStyle:MPMovieControlStyleEmbedded];
    //player.shouldAutoplay = NO;
    [player prepareToPlay];
    
    
    
}

-(void)handleNoInternetConnection
{
    NSLog(@"No internet connection");
    [player stop];
    [playPauseButton setEnabled:NO];
    [playPauseButton setImage:[UIImage imageNamed:@"pause_button_disabled.png"] forState:UIControlStateDisabled];
    UIAlertView *noInternetConnectionAlert = [[UIAlertView alloc] initWithTitle:@"Keine Internet Verbindung" message:@"Dein Gerät hat momentan keine Internet Verbindung, sobald du die Verbindung wieder hergestellt hast kannst du auf Radiouahid weiterhören!" delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
    [noInternetConnectionAlert show];
}

-(void)handleInternetConnectionReturned
{
    NSLog(@"initialize player now");
    [self initializePlayer];
    [playPauseButton setEnabled:YES];
}


- (IBAction)shareOnTwitter:(id)sender {
    
    metaItem = [[player timedMetadata] objectAtIndex:0];
    NSString *decodedString = [[NSString alloc] initWithData:[metaItem.value dataUsingEncoding:NSISOLatin1StringEncoding allowLossyConversion:YES] encoding:NSUTF8StringEncoding];
    
    NSMutableArray *sharingItems = [NSMutableArray new];
    NSString *titleToShare = [NSString stringWithFormat:@"Ich höre gerade: %@ auf Radio Uahid. Mash Allah sehr schön!", decodedString];
    if (titleToShare.length > 140) {
        titleToShare = [titleToShare substringToIndex:140];
    }
    NSURL *shareUrl = [NSURL URLWithString:@"https://itunes.apple.com/ch/app/radio-uahid/id827657923"];
    [sharingItems addObject:titleToShare];
    [sharingItems addObject:shareUrl];
    UIActivityViewController *actController = [[UIActivityViewController alloc] initWithActivityItems:sharingItems applicationActivities:nil];
    [self presentViewController:actController animated:YES completion:nil];
    
}

- (IBAction)infoButtonPressed:(id)sender {
    if ([infoView isHidden]) {
        [infoView setHidden:NO];
    } else {
        [infoView setHidden:YES];
    }
}

- (IBAction)contactButtonPressed:(id)sender {
    
    if ([MFMailComposeViewController canSendMail]) {
        
        // Email Subject
        NSString *emailTitle = @"Nachricht vom RadioUahid App";
        // Email Content
        NSString *messageBody =@"";
        // To address
        NSArray *toRecipents = [NSArray arrayWithObject:@"info@radiouahid.fm"];
        
        MFMailComposeViewController *mc = [[MFMailComposeViewController alloc] init];
        mc.mailComposeDelegate = self;
        [mc setSubject:emailTitle];
        [mc setMessageBody:messageBody isHTML:NO];
        [mc setToRecipients:toRecipents];
        
        // Present mail view controller on screen
        [self presentViewController:mc animated:YES completion:NULL];
        
    } else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Fehler"
                                                        message:@"Dein Gerät unterstützt die direkte Email Funktion nicht!"
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
    }
    
}

-(void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error {
    
    switch (result)
    {
        case MFMailComposeResultCancelled:
            NSLog(@"Mail cancelled");
            break;
        case MFMailComposeResultSaved:
            NSLog(@"Mail saved");
            break;
        case MFMailComposeResultSent:
            NSLog(@"Mail sent");
            break;
        case MFMailComposeResultFailed:
            NSLog(@"Mail sent failure: %@", [error localizedDescription]);
            break;
        default:
            break;
    }
    
    // Close the Mail Interface
    [self dismissViewControllerAnimated:YES completion:NULL];
    
}

- (IBAction)hideInfoButton:(id)sender {
    [infoView setHidden:YES];
}

-(void)prepareFirstRun {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if (![defaults objectForKey:@"firstRun"]) {
        [defaults setObject:[NSDate date] forKey:@"firstRun"];
    }
    [[NSUserDefaults standardUserDefaults] synchronize];
}

-(BOOL)isFirstRun {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if (![defaults objectForKey:@"firstRun"]) {
        return YES;
    }
    return NO;
}

@end
