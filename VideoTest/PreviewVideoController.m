//
//  PreviewVideoController.m
//  VideoTest
//
//  Created by zhangliucheng on 16/4/14.
//  Copyright © 2016年 zhangliucheng. All rights reserved.
//

#import "PreviewVideoController.h"
#import <AVFoundation/AVFoundation.h>

@interface PreviewVideoController ()

@property (strong, nonatomic) AVPlayer *player;
@property (strong ,nonatomic) AVPlayerLayer *playerLayer;     //播放器，用于录制完视频后播放视频

@end

@implementation PreviewVideoController

- (void)viewDidLoad {
    [super viewDidLoad];
//    self.url = [NSURL URLWithString:@"http://clips.vorwaerts-gmbh.de/big_buck_bunny.mp4"];
    
    [self performSelector:@selector(playVideo) withObject:nil afterDelay:0.1f];
}

- (BOOL)shouldAutorotate {
    return YES;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAll;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)dealloc {
    [self.player removeObserver:self forKeyPath:@"status" context:nil];
    [[NSNotificationCenter defaultCenter]removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (IBAction)back:(id)sender {
    [self dismissViewControllerAnimated:NO completion:nil];
}

- (void)playVideo {
    self.player = [AVPlayer playerWithURL:self.url];
    self.playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
    self.playerLayer.frame = self.view.bounds;
    [self.view.layer insertSublayer:self.playerLayer atIndex:0];
    
    //检测视频加载状态，加载完成隐藏loadingView
    [self.player addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(endPlay) name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
    
    [self.player play];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{
    NSLog(@"keyPath:%@,object:%@", keyPath, NSStringFromClass([object class]));
    if ([keyPath isEqualToString:@"status"]) {
        AVPlayerItem *playerItem = (AVPlayerItem*)object;
        if (playerItem.status == AVPlayerStatusReadyToPlay) {
            
        }
    }
}

// 播放结束
- (void)endPlay {

}
@end
