//
//  ViewController.m
//  radiouahid
//
//  Created by Muhamed Ahmetovic on 11.01.14.
//  Copyright (c) 2014 Muhamed Ahmetovic. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <FacebookSDK/FacebookSDK.h>
#import <Social/Social.h>


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
    playPauseButton = [UIButton buttonWithType:UIButtonTypeCustom];
    playButtonImage = [UIImage imageNamed:@"play_button.png"];
    pauseButtonImage = [UIImage imageNamed:@"pause_button.png"];
    [playPauseButton setBackgroundImage:pauseButtonImage forState:UIControlStateNormal];
    [playPauseButton addTarget:self action:@selector(togglePlayingStream:) forControlEvents:UIControlEventTouchUpInside];
    
    stopButton = [UIButton buttonWithType:UIButtonTypeCustom];
    stopButtonImage = [UIImage imageNamed:@"stop_button.png"];
    [stopButton setBackgroundImage:stopButtonImage forState:UIControlStateNormal];
    [stopButton addTarget:self action:@selector(stopButtonTouched:) forControlEvents:UIControlEventTouchUpInside];
    
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
            [playPauseButton setFrame:CGRectMake(10, 523, 37, 35)];
            //[stopButton setFrame:CGRectMake(200, 490, 37, 35)];
            [infoButton setFrame:CGRectMake(150, 32, 37, 35)];
            volumeHolder = [[UIView alloc] initWithFrame: CGRectMake(50, 530, 220, 20)];
            [playingLabel setFrame:CGRectMake(15, 460, screenSize.width * 0.9, 50)];
        } else {
            //iphone 4
            [playPauseButton setFrame:CGRectMake(10, 440, 37, 35)];
            [stopButton setFrame:CGRectMake(275, 440, 37, 35)];
            [infoButton setFrame:CGRectMake(150, 32, 37, 35)];
            volumeHolder = [[UIView alloc] initWithFrame: CGRectMake(50, 450, 220, 20)];
            [playingLabel setFrame:CGRectMake(15, 383, screenSize.width * 0.9, 50)];
        }
    } else {
        //ipad
    }
    
    [self.view addSubview:playPauseButton];
    [self.view addSubview:stopButton];
    [self.view addSubview:infoButton];
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
        [playPauseButton setBackgroundImage:pauseButtonImage forState:UIControlStateNormal];
        
        
        
    } else if(player.playbackState == MPMoviePlaybackStatePlaying) {
        [player pause];
        [feedbackLabel setText:@"Pausiert"];
        [playPauseButton setBackgroundImage:playButtonImage forState:UIControlStateNormal];
    } else if(player.playbackState == MPMoviePlaybackStatePaused) {
        [player play];
        [feedbackLabel setText:@"On Air"];
        [playPauseButton setBackgroundImage:pauseButtonImage forState:UIControlStateNormal];
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
    
    [player stop];
    [feedbackLabel setText:@"Angehalten"];
    [playPauseButton setBackgroundImage:playButtonImage forState:UIControlStateNormal];
   
}

-(void)remoteControlReceivedWithEvent:(UIEvent *)event
{
    switch (event.subtype) {
        case UIEventSubtypeRemoteControlPlay:
            [player play];
            [playPauseButton setBackgroundImage:pauseButtonImage forState:UIControlStateNormal];
            break;
            
        case UIEventSubtypeRemoteControlPause:
            [player pause];
            [playPauseButton setBackgroundImage:playButtonImage forState:UIControlStateNormal];
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
    [feedbackLabel setText:@"On Air"];
}

-(void)initializePlayer
{
    
    [spinner startAnimating];
    [feedbackLabel setText:@"Verbindung wird hergestellt..."];
    
    player = [[MPMoviePlayerController alloc] initWithContentURL:[NSURL URLWithString:@"http://174.36.1.92:5659/Live"]];
    player.movieSourceType = MPMovieSourceTypeStreaming;
    
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
    [playPauseButton setBackgroundImage:[UIImage imageNamed:@"pause_button_disabled.png"] forState:UIControlStateDisabled];
    UIAlertView *noInternetConnectionAlert = [[UIAlertView alloc] initWithTitle:@"Keine Internet Verbindung" message:@"Dein Gerät hat momentan keine Internet Verbindung, sobald du die Verbindung wieder hergestellt hast kannst du auf Radiouahid weiterhören!" delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
    [noInternetConnectionAlert show];
}

-(void)handleInternetConnectionReturned
{
    NSLog(@"initialize player now");
    [self initializePlayer];
    [playPauseButton setEnabled:YES];
}

- (IBAction)shareOnFacebook:(id)sender {
    
    metaItem = [[player timedMetadata] objectAtIndex:0];
    
    FBLinkShareParams *params = [[FBLinkShareParams alloc] initWithLink:[NSURL URLWithString:@"http://radiouahid.fm"]
                                                                   name:@"Radio Uahid"
                                                                caption:@"Radio Uahid"
                                                            description:[NSString stringWithFormat:@"Ich höre gerade: %@ auf Radio Uahid. Mash Allah sehr schön!", metaItem.value]
                                                                picture:[NSURL URLWithString:@"http://radiouahid.fm/wp-content/uploads/2013/11/RadioUahid-Logo-ohne-Website-neuer-Slogan-300x250.png"]];
 
    
    if ([FBDialogs canPresentShareDialogWithParams:params]) {
        [FBDialogs presentShareDialogWithLink:params.link
                                         name:params.name
                                      caption:params.caption
                                  description:params.description
                                      picture:params.picture
                                  clientState:nil
                                      handler:^(FBAppCall *call, NSDictionary *results, NSError *error) {
                                          if (error) {
                                              //Error occured
                                              NSLog(@"Error publishing story: %@", error.description);
                                          } else {
                                              //Success
                                              NSLog(@"result %@", results);
                                          }
                                      }];
    } else {
        
        NSString *desc = [NSString stringWithFormat:@"Ich höre gerade: %@ auf Radio Uahid. Mash Allah sehr schön!", metaItem.value];
        
        //Native Facebook App not installed -> second method
        //Put together the dialog parameters
        NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                       @"Radio Uahid", @"name",
                                       @"Radio Uahid", @"caption",
                                       desc, @"description",
                                       @"http://radiouahid.fm", @"link",
                                       @"http://radiouahid.fm/wp-content/uploads/2013/11/RadioUahid-Logo-ohne-Website-neuer-Slogan-300x250.png", @"picture",
                                       nil];
        
        //Show the feed dialog
        [FBWebDialogs presentFeedDialogModallyWithSession:nil
                                               parameters:params
                                                  handler:^(FBWebDialogResult result, NSURL *resultURL, NSError *error) {
                                                   
                                                      if (error) {
                                                          NSLog(@"Error publishing story: %@", error.description);
                                                      } else {
                                                          if (result == FBWebDialogResultDialogNotCompleted) {
                                                              // User cancelled.
                                                              NSLog(@"User canceled");
                                                          } else {
                                                              // Handle the publish feed callback
                                                              NSDictionary *urlParams = [self parseURLParams:[resultURL query]];
                                                              
                                                              if (![urlParams valueForKey:@"post_id"]) {
                                                                  NSLog(@"User cancelled.");
                                                              } else {
                                                                  // User clicked the Share button
                                                                  NSString *result = [NSString stringWithFormat: @"Posted story, id: %@", [urlParams valueForKey:@"post_id"]];
                                                                  NSLog(@"result %@", result);
                                                              }
                                                          }
                                                      }
                                                      
                                                  }];
    }
}

- (IBAction)shareOnTwitter:(id)sender {
    
    metaItem = [[player timedMetadata] objectAtIndex:0];
    
    SLComposeViewController *twitterViewController = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeTwitter];
    NSString *titleToShare = [NSString stringWithFormat:@"Ich höre gerade: %@ auf Radio Uahid. Mash Allah sehr schön!", metaItem.value];
    
    if (titleToShare.length > 140) {
        titleToShare = [titleToShare substringToIndex:140];
    }
    
    [twitterViewController setInitialText:titleToShare];
    
    if (![twitterViewController addURL:[NSURL URLWithString:@"http://radiouahid.fm"]]) {
        NSLog(@"Couldn't add.");
    }
    
    [self presentViewController:twitterViewController animated:YES completion:nil];
    
}

// A function for parsing URL parameters returned by the Feed Dialog.
- (NSDictionary*)parseURLParams:(NSString *)query {
    NSArray *pairs = [query componentsSeparatedByString:@"&"];
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    for (NSString *pair in pairs) {
        NSArray *kv = [pair componentsSeparatedByString:@"="];
        NSString *val =
        [kv[1] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        params[kv[0]] = val;
    }
    return params;
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
