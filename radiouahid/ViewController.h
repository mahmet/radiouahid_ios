//
//  ViewController.h
//  radiouahid
//
//  Created by Muhamed Ahmetovic on 11.01.14.
//  Copyright (c) 2014 Muhamed Ahmetovic. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MediaPlayer/MediaPlayer.h>
#import "Reachability.h"

@interface ViewController : UIViewController

@property (nonatomic, strong) MPMoviePlayerController *player;
@property (nonatomic, strong) MPMusicPlayerController *musicPlayer;
- (IBAction)togglePlayingStream:(id)sender;
@property (strong, nonatomic) IBOutlet UIButton *playPauseButton;
@property (weak, nonatomic) IBOutlet UILabel *playingLabel;
- (IBAction)stopButtonTouched:(id)sender;
@property (weak, nonatomic) IBOutlet UIButton *stopButton;


@property UIImage *playButtonImage;
@property UIImage *stopButtonImage;
@property UIImage *pauseButtonImage;


@property (strong, nonatomic) NSArray *metadataArray;
@property (strong, nonatomic) MPTimedMetadata *metaItem;
@property (strong, nonatomic) Reachability *reachability;
@property NetworkStatus remoteHostStatus;
@property (strong, nonatomic) UIActivityIndicatorView *spinner;

-(void) initializePlayer;
-(void) handleNoInternetConnection;
-(void) handleInternetConnectionReturned;


@end
