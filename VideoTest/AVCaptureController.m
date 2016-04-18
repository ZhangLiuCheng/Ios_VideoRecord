//
//  AVCaptureController.m
//  VideoTest
//
//  Created by zhangliucheng on 16/4/12.
//  Copyright © 2016年 zhangliucheng. All rights reserved.
//

#import "AVCaptureController.h"
#import <AVFoundation/AVFoundation.h>
#import "PreviewVideoController.h"

@interface AVCaptureController () <AVCaptureFileOutputRecordingDelegate, UIAlertViewDelegate>

@property (weak, nonatomic) IBOutlet UIButton *videoBtn;
@property (weak, nonatomic) IBOutlet UIButton *previewBtn;
@property (weak, nonatomic) IBOutlet UIButton *sendBtn;
@property (weak, nonatomic) IBOutlet UIProgressView *duration;

@property (strong, nonatomic) CADisplayLink *link;
@property (strong, nonatomic) NSDate *startTime;

@property (strong, nonatomic) AVCaptureSession *captureSession;

@property (strong, nonatomic) AVCaptureDevice *videoDevice;
@property (strong, nonatomic) AVCaptureDevice *audioDevice;
@property (strong, nonatomic) AVCaptureDeviceInput *videoInput;
@property (strong, nonatomic) AVCaptureDeviceInput *audioInput;
@property (strong, nonatomic) AVCaptureMovieFileOutput *movieOutput;

@property (strong, nonatomic) AVCaptureVideoPreviewLayer *captureVideoPreviewLayer;

@end

@implementation AVCaptureController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self getAuthorization];
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)addGenstureRecognizer {
    UITapGestureRecognizer *doubleTapGesture=[[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(doubleTap:)];
    doubleTapGesture.numberOfTapsRequired = 2;
    doubleTapGesture.delaysTouchesBegan = YES;
    [self.view addGestureRecognizer:doubleTapGesture];
}

- (IBAction)back:(id)sender {
    [self dismissViewControllerAnimated:YES completion:^{
        [self quit];
        [self stopLink];
    }];
}

- (IBAction)video:(UIButton *)sender {
    if (sender.selected) {
        [self stopRecord];
        [self stopLink];
    } else {
        [self startRecord];
        [self startLink];
    }
    [sender setSelected:!sender.selected];
    self.previewBtn.hidden = sender.selected;
    self.sendBtn.hidden = sender.selected;
}

- (IBAction)preview:(id)sender {
    PreviewVideoController *controller = [PreviewVideoController new];
    controller.url = [self outPutFileURL];
    [self presentViewController:controller animated:NO completion:nil];
}

- (IBAction)send:(id)sender {
    
}

- (IBAction)changeCamera:(id)sender {
    [self toggleCamera];
}

- (void)doubleTap:(UITapGestureRecognizer *)tapGesture{
    [self changeDevicePropertySafety:^(AVCaptureDevice *captureDevice) {
        if (captureDevice.videoZoomFactor == 1.0) {
            CGFloat current = 1.5;
            if (current < captureDevice.activeFormat.videoMaxZoomFactor) {
                [captureDevice rampToVideoZoomFactor:current withRate:10];
            }
        }else{
            [captureDevice rampToVideoZoomFactor:1.0 withRate:10];
        }
    }];
}

- (CADisplayLink *)link {
    if (!_link) {
        _link = [CADisplayLink displayLinkWithTarget:self selector:@selector(refresh:)];
    }
    return _link;
}

- (void)startLink {
    self.duration.progress = 0;
    [self.link addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
    
    self.startTime = [NSDate dateWithTimeIntervalSinceNow:0];
}

- (void)stopLink {
    _link.paused = YES;
    [_link invalidate];
    _link = nil;
}

- (void)refresh:(CADisplayLink *)link {
    NSTimeInterval interval = [[NSDate dateWithTimeIntervalSinceNow:0] timeIntervalSinceDate:self.startTime];
    
    if (interval > 15) {
        [self video:self.videoBtn];
    } else {
        float p = interval / 15.0f;
        self.duration.progress = p;
    }
}

// 显示没有授权的提示框
- (void)showAuthorizationAlert {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"提示" message:@"拒绝授权,返回上一页.请检查下\n设置-->隐私/通用等权限设置" delegate:self cancelButtonTitle:nil otherButtonTitles:@"确定", nil];
    [alert show];
}

//获取授权
- (void)getAuthorization {
    //此处获取摄像头授权
    switch ([AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo]) {
        case AVAuthorizationStatusAuthorized: {  // 已授权，可使用
            [self setupAVCaptureInfo];
            break;
        }
        case AVAuthorizationStatusNotDetermined: { //未进行授权选择再次请求授权
            [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
                if (granted) {
                    [self setupAVCaptureInfo];
                } else {
                    [self showAuthorizationAlert];
                }
                return;
            }];
            break;
        }
        default: {  //用户拒绝授权/未授权
            [self showAuthorizationAlert];
            break;
        }
    }
}

- (void)setupAVCaptureInfo {
    _captureSession = [[AVCaptureSession alloc] init];
    if ([_captureSession canSetSessionPreset:AVCaptureSessionPreset640x480]) {
        [_captureSession setSessionPreset:AVCaptureSessionPreset640x480];
    }
    
    [_captureSession beginConfiguration];
    
    [self addVideo];
    [self addAudio];
    [self addOutput];
    [self addPreviewLayer];
    
    [_captureSession commitConfiguration];
    [_captureSession startRunning];
    
    [self addGenstureRecognizer];
}

- (void)addVideo {
    // 获取后置摄像头
    _videoDevice = [self deviceWithMediaType:AVMediaTypeVideo preferringPosition:AVCaptureDevicePositionBack];

    // 将视频输入添加到captureSession
    NSError *videoError;
    _videoInput = [[AVCaptureDeviceInput alloc] initWithDevice:_videoDevice error:&videoError];
    if (nil == videoError) {
        if ([_captureSession canAddInput:_videoInput]) {
            [_captureSession addInput:_videoInput];
        }
    }
}

- (void)addAudio {
    NSError *audioError;
    _audioDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
    _audioInput = [[AVCaptureDeviceInput alloc] initWithDevice:_audioDevice error:&audioError];
    if (nil == audioError) {
        // 将音频输入对象添加到会话 (AVCaptureSession) 中
        if ([_captureSession canAddInput:_audioInput]) {
            [_captureSession addInput:_audioInput];
        }
    }
}

- (void)addOutput {
    // 将视频输出添加到captureSession
    _movieOutput = [[AVCaptureMovieFileOutput alloc] init];
    if ([_captureSession canAddOutput:_movieOutput]) {
        [_captureSession addOutput:_movieOutput];
        AVCaptureConnection *captureConnection = [_movieOutput connectionWithMediaType:AVMediaTypeVideo];
        if ([captureConnection isVideoOrientationSupported]) {
            [captureConnection setVideoOrientation:AVCaptureVideoOrientationPortrait];
        }
        // 视频稳定设置
//        if ([captureConnection isVideoStabilizationSupported]) {
//            captureConnection.preferredVideoStabilizationMode = AVCaptureVideoStabilizationModeAuto;
//        }
        captureConnection.videoScaleAndCropFactor = captureConnection.videoMaxScaleAndCropFactor;
    }
}

- (void)addPreviewLayer {
    _captureVideoPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:_captureSession];
    _captureVideoPreviewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    _captureVideoPreviewLayer.connection.videoOrientation = [_movieOutput connectionWithMediaType:AVMediaTypeVideo].videoOrientation;
    _captureVideoPreviewLayer.frame = self.view.layer.bounds;
    [self.view.layer insertSublayer:_captureVideoPreviewLayer atIndex:0];
}

// 获取前/后摄像头
- (AVCaptureDevice *)deviceWithMediaType:(NSString *)mediaType preferringPosition:(AVCaptureDevicePosition)position {
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:mediaType];
    AVCaptureDevice *captureDevice = devices.firstObject;
    for (AVCaptureDevice *device in devices ) {
        if (device.position == position ) {
            captureDevice = device;
            break;
        }
    }
    return captureDevice;
}

-(void)changeDevicePropertySafety:(void (^)(AVCaptureDevice *captureDevice))propertyChange{
    //也可以直接用_videoDevice,但是下面这种更好
    AVCaptureDevice *captureDevice= [_videoInput device];
    NSError *error;
    //注意改变设备属性前一定要首先调用lockForConfiguration:调用完之后使用unlockForConfiguration方法解锁,意义是---进行修改期间,先锁定,防止多处同时修改
    BOOL lockAcquired = [captureDevice lockForConfiguration:&error];
    if (lockAcquired) {
        [_captureSession beginConfiguration];
        propertyChange(captureDevice);
        [captureDevice unlockForConfiguration];
        [_captureSession commitConfiguration];
    }
}

//切换前后镜头
- (void)toggleCamera {
    switch (_videoDevice.position) {
        case AVCaptureDevicePositionBack:
            _videoDevice = [self deviceWithMediaType:AVMediaTypeVideo preferringPosition:AVCaptureDevicePositionFront];
            break;
        case AVCaptureDevicePositionFront:
            _videoDevice = [self deviceWithMediaType:AVMediaTypeVideo preferringPosition:AVCaptureDevicePositionBack];
            break;
        default:
            return;
            break;
    }
    
    [self changeDevicePropertySafety:^(AVCaptureDevice *captureDevice) {
        NSError *error;
        AVCaptureDeviceInput *newVideoInput = [[AVCaptureDeviceInput alloc] initWithDevice:_videoDevice error:&error];
        
        if (newVideoInput != nil) {
            [_captureSession removeInput:_videoInput];
            if ([_captureSession canAddInput:newVideoInput]) {
                [_captureSession addInput:newVideoInput];
                _videoInput = newVideoInput;
            } else {
                [_captureSession addInput:_videoInput];
            }
            
        } else if (error) {
            NSLog(@"切换前/后摄像头失败, error = %@", error);
        }
    }];
}

//切换闪光灯    闪光模式开启后,并无明显感觉,所以还需要开启手电筒
- (IBAction)changeFlashlight:(UIButton *)sender {
    if ([_videoDevice hasTorch] && [_videoDevice hasFlash]) {
        [self changeDevicePropertySafety:^(AVCaptureDevice *captureDevice) {
            if (_videoDevice.flashMode == AVCaptureFlashModeOn) {           //闪光灯开
                [_videoDevice setFlashMode:AVCaptureFlashModeOff];
                [_videoDevice setTorchMode:AVCaptureTorchModeOff];
            }else if (_videoDevice.flashMode == AVCaptureFlashModeOff) {    //闪光灯关
                [_videoDevice setFlashMode:AVCaptureFlashModeOn];
                [_videoDevice setTorchMode:AVCaptureTorchModeOn];
            }
        }];
        sender.selected=!sender.isSelected;
    }
}

#pragma mark - 录制相关
- (void)startRecord {
    [_movieOutput startRecordingToOutputFileURL:[self outPutFileURL] recordingDelegate:self];
}

- (void)stopRecord {
    [_movieOutput stopRecording];
}

- (void)recordComplete {
//    self.canSave = YES;
}

- (void)quit {
    [_captureSession stopRunning];
}

- (NSURL *)outPutFileURL {
    return [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@%@", NSTemporaryDirectory(), @"outPut.mov"]];
}

#pragma mark - AVCaptureFileOutputRecordingDelegate
- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL fromConnections:(NSArray *)connections error:(NSError *)error {
    /*
    if (outputFileURL.absoluteString.length == 0 && captureOutput.outputFileURL.absoluteString.length == 0 ) {
        [self showMsgWithTitle:@"出错了" andContent:@"录制视频保存地址出错"];
        return;
    }
    
    if (self.canSave) {
        [self pushToPlay:outputFileURL];
        self.canSave = NO;
    }
     */
}

#pragma mark - UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 0) {
        [self.navigationController popViewControllerAnimated:YES];
    }
}
@end
