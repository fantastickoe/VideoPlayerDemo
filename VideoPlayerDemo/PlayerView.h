//
//  PlayerView.h
//  VideoPlayerDemo
//
//  Created by WangYinghao on 1/19/15.
//  Copyright (c) 2015 WangYinghao. All rights reserved.
//

#import <UIKit/UIKit.h>

@class AVPlayer;

@interface PlayerView : UIView

@property (nonatomic, weak) AVPlayer *player;

@end