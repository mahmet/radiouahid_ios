//
//  ViewController.h
//  radiouahid
//
//  Created by Muhamed Ahmetovic on 11.01.14.
//  Copyright (c) 2014 Muhamed Ahmetovic. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MediaPlayer/MediaPlayer.h>

@interface ViewController : UIViewController

@property (nonatomic, strong) MPMoviePlayerController *player;
- (IBAction)togglePlayingStream:(id)sender;
@property (strong, nonatomic) IBOutlet UIButton *playPauseButton;
@property (weak, nonatomic) IBOutlet UILabel *playingLabel;
- (IBAction)stopButtonTouched:(id)sender;

@property (strong, nonatomic) NSArray *metadataArray;
@property (strong, nonatomic) MPTimedMetadata *metaItem;


@end
