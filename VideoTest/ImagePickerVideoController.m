//
//  ViewController.m
//  VideoTest
//
//  Created by zhangliucheng on 16/4/9.
//  Copyright © 2016年 zhangliucheng. All rights reserved.
//

#import "ImagePickerVideoController.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import <AVFoundation/AVFoundation.h>

static NSString *videoPath;

@interface ImagePickerVideoController () <UIImagePickerControllerDelegate, UINavigationControllerDelegate>

@property (strong ,nonatomic) AVPlayerLayer *playerLayer;     //播放器，用于录制完视频后播放视频

@end

@implementation ImagePickerVideoController

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (IBAction)recordBegin:(id)sender {
    UIImagePickerController *ipc = [[UIImagePickerController alloc]init];
    ipc.sourceType = UIImagePickerControllerSourceTypeCamera;
    ipc.cameraDevice = UIImagePickerControllerCameraDeviceRear;//设置使用哪个摄像头，这里设置为后置摄像头
    ipc.mediaTypes = @[(NSString *)kUTTypeMovie];
    ipc.videoQuality = UIImagePickerControllerQualityTypeIFrame1280x720;
    ipc.cameraCaptureMode = UIImagePickerControllerCameraCaptureModeVideo;
    ipc.delegate = self;
    [self presentViewController:ipc animated:YES completion:nil];
}

- (IBAction)palyVideo:(id)sender {
    if (!videoPath || [@"" isEqual:videoPath]) {
        self.title = @"请先录像";
        return;
    }
    self.title = @"正在播放";
    NSURL *url = [NSURL fileURLWithPath:videoPath];
    AVPlayer *player = [AVPlayer playerWithURL:url];
    self.playerLayer = [AVPlayerLayer playerLayerWithPlayer:player];
    self.playerLayer.frame = self.view.bounds;
    [self.view.layer insertSublayer:self.playerLayer atIndex:0];
    [player play];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(endPlay) name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
}

// 播放结束
- (void)endPlay {
    self.title = @"";
    [self.playerLayer removeFromSuperlayer];
}

#pragma mrak - UIImagePickerControllerDelegate
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info {
    NSString *mediaType=[info objectForKey:UIImagePickerControllerMediaType];
   if([mediaType isEqualToString:(NSString *)kUTTypeMovie]){
        NSURL *url = [info objectForKey:UIImagePickerControllerMediaURL];
        NSString *urlStr = [url path];
        if (UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(urlStr)) {
            UISaveVideoAtPathToSavedPhotosAlbum(urlStr, self,nil, nil);//保存视频到相簿
            videoPath = urlStr;
        }
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}
@end
