//
//  LocalPlaybackViewController.m
//  VideoPlayerDemo
//
//  Created by WangYinghao on 1/19/15.
//  Copyright (c) 2015 WangYinghao. All rights reserved.
//

#import "PlayerViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "PlayerView.h"

@interface PlayerViewController()
@property (nonatomic,assign) BOOL localResourceLoaded;
@property (nonatomic,assign) BOOL onlineResourceLoaded;
@property (nonatomic, strong) id timeObserver;
@property (nonatomic, assign) BOOL scrubbing;
@property (nonatomic, assign) float lastPlaybackRate;

@end

@implementation PlayerViewController

static const NSString *ItemStatusContext;

- (IBAction)loadAssetOnline:(id)sender{
    NSLog(@"begin online loading");
    
    if(!self.onlineResourceLoaded){
        NSURL *fileURL = [NSURL URLWithString:@"https://devimages.apple.com.edgekey.net/streaming/examples/bipbop_16x9/bipbop_16x9_variant.m3u8"];
        
        AVURLAsset *asset = [AVURLAsset URLAssetWithURL:fileURL options:nil];
        NSString *tracksKey = @"tracks";
        // Define this constant for the key-value observation context.
        if (self.player){
            [self.playerItem removeObserver:self forKeyPath:@"status"];
            [self.player removeTimeObserver:self.timeObserver];
        }
        
        [asset loadValuesAsynchronouslyForKeys:@[tracksKey] completionHandler:
         ^{
             // The completion block goes here.
             // Completion handler block.
             dispatch_async(dispatch_get_main_queue(),
                            ^{
                                
                                NSError *error;
                                AVKeyValueStatus status = [asset statusOfValueForKey:tracksKey error:&error];
                                
                                if (status == AVKeyValueStatusLoaded) {
                                    self.playerItem = [AVPlayerItem playerItemWithAsset:asset];
                                    // ensure that this is done before the playerItem is associated with the player
                                    [self.playerItem addObserver:self forKeyPath:@"status"
                                                         options:NSKeyValueObservingOptionInitial context:&ItemStatusContext];
                                    [[NSNotificationCenter defaultCenter] addObserver:self
                                                                             selector:@selector(playerItemDidReachEnd:)
                                                                                 name:AVPlayerItemDidPlayToEndTimeNotification
                                                                               object:self.playerItem];
                                    self.player = [AVPlayer playerWithPlayerItem:self.playerItem];
                                    [self.playerView setPlayer:self.player];
                                    self.onlineResourceLoaded=YES;
                                    self.localResourceLoaded=NO;
                                    self.playButton.hidden=NO;
                                    self.pauseButton.hidden=YES;
                                }
                                else {
                                    // You should deal with the error appropriately.
                                    NSLog(@"The asset's tracks were not loaded:\n%@", [error localizedDescription]);
                                }
                            });
             
         }];
        
    }
    else {
        NSLog(@"do nothing");
    }
}




- (IBAction)loadAssetFromFile:sender {
    NSLog(@"begin local loading");
    
    if(!self.localResourceLoaded){
        NSURL *fileURL = [[NSBundle mainBundle]
                          URLForResource:@"charlie" withExtension:@"mp4"];
        
        AVURLAsset *asset = [AVURLAsset URLAssetWithURL:fileURL options:nil];
        NSString *tracksKey = @"tracks";
        // Define this constant for the key-value observation context.
        
        if (self.player){
            [self.playerItem removeObserver:self forKeyPath:@"status"];
            [self.player removeTimeObserver:self.timeObserver];        }

        
        [asset loadValuesAsynchronouslyForKeys:@[tracksKey] completionHandler:
         ^{
             // The completion block goes here.
             // Completion handler block.
             dispatch_async(dispatch_get_main_queue(),
                            ^{
                                
                                NSError *error;
                                AVKeyValueStatus status = [asset statusOfValueForKey:tracksKey error:&error];
                                
                                if (status == AVKeyValueStatusLoaded) {
                                    self.playerItem = [AVPlayerItem playerItemWithAsset:asset];
                                    // ensure that this is done before the playerItem is associated with the player
                                    [self.playerItem addObserver:self forKeyPath:@"status"
                                                         options:NSKeyValueObservingOptionInitial context:&ItemStatusContext];
                                    [[NSNotificationCenter defaultCenter] addObserver:self
                                                                             selector:@selector(playerItemDidReachEnd:)
                                                                                 name:AVPlayerItemDidPlayToEndTimeNotification
                                                                               object:self.playerItem];
                                    self.player = [AVPlayer playerWithPlayerItem:self.playerItem];
                                    [self.playerView setPlayer:self.player];
                                    self.localResourceLoaded=YES;
                                    self.onlineResourceLoaded=NO;
                                    self.playButton.hidden=NO;
                                    self.pauseButton.hidden=YES;
                                }
                                else {
                                    // You should deal with the error appropriately.
                                    NSLog(@"The asset's tracks were not loaded:\n%@", [error localizedDescription]);
                                }
                            });
             
         }];

    }
    else {
        NSLog(@"do nothing");
    }
}

- (void)addPlayerItemTimeObserver {
    __weak id weakSelf = self;
    self.timeObserver = [self.player addPeriodicTimeObserverForInterval:CMTimeMakeWithSeconds(0.5f, NSEC_PER_SEC)
                                                                  queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
                                                                      // Update UI state
                                                                      [weakSelf syncScrubberView];
                                                                  }];
}

- (void)syncScrubberView {
    //NSLog(@"syncScrubber start");
    
    if (self.playerItem.status==AVPlayerItemStatusReadyToPlay && !CMTIME_IS_INVALID(self.playerItem.duration)) {
        
        double currentTime = CMTimeGetSeconds([self.player currentTime]);
        double duration = CMTimeGetSeconds(self.playerItem.duration);
        
        self.scrubberSlider.minimumValue = 0;
        self.scrubberSlider.maximumValue = duration;
        self.scrubberSlider.value=currentTime;
        [self updateScrubberLabelsWithDuration:duration andCurrentTime:currentTime];
    } else {
        self.currentTimeLabel.text = @"-- : --";
    }
}
- (void)updateScrubberLabelsWithDuration:(double)duration andCurrentTime:(double)currentTime {
    NSInteger currentSeconds = ceilf(currentTime);
    self.currentTimeLabel.text = [self formatSeconds:currentSeconds];
    self.totalTimeLabel.text = [self formatSeconds:duration];
}

- (NSString *)formatSeconds:(NSInteger)value {
    NSInteger seconds = value % 60;
    NSInteger minutes = value / 60;
    return [NSString stringWithFormat:@"%02d:%02d", minutes, seconds];
}

- (void) syncUI{
    if ((self.player.currentItem != nil) &&
        ([self.player.currentItem status] == AVPlayerItemStatusReadyToPlay)) {
        self.playButton.enabled = YES;
    }
    else {
        self.playButton.enabled = NO;
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object
                        change:(NSDictionary *)change context:(void *)context {
    
    if (context == &ItemStatusContext) {
        dispatch_async(dispatch_get_main_queue(),
                       ^{
                           [self syncUI];
                           [self addPlayerItemTimeObserver];
                       });
        return;
    }
    [super observeValueForKeyPath:keyPath ofObject:object
                           change:change context:context];
    return;
}

- (IBAction)play:sender {
    [_player play];
    self.playButton.hidden=YES;
    self.pauseButton.hidden=NO;
}
- (IBAction)pause:(id)sender {
    [_player pause];
    self.pauseButton.hidden=YES;
    self.playButton.hidden=NO;
}


- (void)playerItemDidReachEnd:(NSNotification *)notification {
    [self.player seekToTime:kCMTimeZero];
    self.scrubberSlider.value=0;
    self.playButton.hidden=NO;
    self.pauseButton.hidden=YES;
}



- (IBAction)setVolume:(id)sender {
    
    self.player.volume=self.volumeSlider.value;
}

- (IBAction)close:(id)sender {
    
    if (self.player){
        [self.playerItem removeObserver:self forKeyPath:@"status"];
        [self.player removeTimeObserver:self.timeObserver];        }
    
    [self dismissViewControllerAnimated:YES completion:nil];
    
}

- (IBAction)switchChanged:(id)sender {
    self.player.closedCaptionDisplayEnabled=self.switchforCC.on;
}

- (IBAction)scrubbingDidStart:(id)sender {
    self.lastPlaybackRate = self.player.rate;
    //NSLog(@"%d",_lastPlaybackRate);
    self.scrubbing = YES;
    [self.player pause];
    [self.player removeTimeObserver:self.timeObserver];
}

- (IBAction)scrubbing:(id)sender {
    UISlider *slider = (UISlider *)sender;
    [self.player seekToTime:CMTimeMakeWithSeconds([slider value], NSEC_PER_SEC)];
    NSInteger currentSeconds = ceilf([slider value]);
}

- (IBAction)scrubbingDidEnd:(id)sender {
    self.scrubbing = NO;
    [self addPlayerItemTimeObserver];
    if (self.lastPlaybackRate > 0.0f) {
        [self.player play];
    }
    self.playButton.hidden=NO;
    self.pauseButton.hidden=YES;
}






- (void)viewDidLoad {
    [super viewDidLoad];
    [self syncUI];
    self.localResourceLoaded=NO;
    self.onlineResourceLoaded=NO;
    self.scrubberSlider.value=0;
    self.playButton.hidden=NO;
    self.pauseButton.hidden=YES;
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
