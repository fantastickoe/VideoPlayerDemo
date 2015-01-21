//
//  PlayerView.m
//  VideoPlayerDemo
//
//  Created by WangYinghao on 1/19/15.
//  Copyright (c) 2015 WangYinghao. All rights reserved.
//

#import "PlayerView.h"
#import <AVFoundation/AVFoundation.h>

@implementation PlayerView

+ (Class)layerClass {
    return [AVPlayerLayer class];
}

- (AVPlayer *)player {
    return [(AVPlayerLayer *)[self layer] player];
}

- (void)setPlayer:(AVPlayer *)player {
    [(AVPlayerLayer *)[self layer] setPlayer:player];
}

@end