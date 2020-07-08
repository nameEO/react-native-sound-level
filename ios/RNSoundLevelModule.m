//
//  Created by Vladimir Osipov on 2018-07-09.
//  Copyright (c) 2018 Vladimir Osipov. All rights reserved.
//
 
#import "RNSoundLevelModule.h"
#import <React/RCTConvert.h>
#import <React/RCTBridge.h>
#import <React/RCTUtils.h>
#import <React/RCTEventDispatcher.h>
#import <AVFoundation/AVFoundation.h>
 
@implementation RNSoundLevelModule {
 
  AVAudioRecorder *_audioRecorder;
  id _progressUpdateTimer;
  int _frameId;
  int _progressUpdateInterval;
  NSDate *_prevProgressUpdateTime;
  AVAudioSession *_recordSession;
}
 
@synthesize bridge = _bridge;
 
RCT_EXPORT_MODULE();
 
- (void)sendProgressUpdate:(NSTimer *)timer {
  if (!_audioRecorder || !_audioRecorder.isRecording) {
    return;
  }
 
  if (_prevProgressUpdateTime == nil ||
   (([_prevProgressUpdateTime timeIntervalSinceNow] * -1000.0) >= _progressUpdateInterval)) {
      _frameId++;
      NSMutableDictionary *body = [[NSMutableDictionary alloc] init];
      [body setObject:[NSNumber numberWithFloat:_frameId] forKey:@"id"];
 
      [_audioRecorder updateMeters];
      float _currentLevel = [_audioRecorder averagePowerForChannel: 0];
      [body setObject:[NSNumber numberWithFloat:_currentLevel] forKey:@"value"];
      [body setObject:[NSNumber numberWithFloat:_currentLevel] forKey:@"rawValue"];
 
      [self.bridge.eventDispatcher sendAppEventWithName:@"frame" body:body];
      
      // NSLog(@"LEVEL: %f", _currentLevel);
    
      _prevProgressUpdateTime = [NSDate date];
  }
}
 
- (void)stopProgressTimer {
  [_progressUpdateTimer invalidate];
}
 
- (void)startProgressTimer:(int)monitorInterval {
  _progressUpdateInterval = monitorInterval;
 
  // [self stopProgressTimer];
 
  dispatch_async(dispatch_get_main_queue(), ^{
      _progressUpdateTimer = [NSTimer
                              scheduledTimerWithTimeInterval:0.1
                              target:self
                              selector:@selector(sendProgressUpdate:)
                              userInfo:nil repeats:YES];
  });
}
 
- (void)audioSessionHandleIntrruption:(NSNotification *)notification {
    NSDictionary *userInfo = notification.userInfo;
    int interruptionType = [userInfo[AVAudioSessionInterruptionTypeKey] intValue];
 
    if (interruptionType == AVAudioSessionInterruptionTypeBegan) {
        NSLog(@"Interruption begun");
        [_audioRecorder pause];
        [_recordSession setActive:NO error:nil];
        [self stopProgressTimer];
    } else if (interruptionType == AVAudioSessionInterruptionTypeEnded) {
        int interruptionOption = [userInfo[AVAudioSessionInterruptionOptionKey] intValue];
 
        BOOL shouldResumePlayback = interruptionOption == AVAudioSessionInterruptionOptionShouldResume;
 
        if (shouldResumePlayback) {
            NSLog(@"Interruption Resume");

            _frameId++;
            NSMutableDictionary *body = [[NSMutableDictionary alloc] init];
            [body setObject:[NSNumber numberWithFloat:_frameId] forKey:@"id"];
      
            [body setObject:[NSNumber numberWithFloat:9] forKey:@"value"];
            [body setObject:[NSNumber numberWithFloat:9] forKey:@"rawValue"];
      
            [self.bridge.eventDispatcher sendAppEventWithName:@"frame" body:body];

            // App will be killed in 5 seconds
        }
    }
}
 
RCT_EXPORT_METHOD(start:(int)monitorInterval)
{
  NSLog(@"Start Monitoring");
  _prevProgressUpdateTime = nil;
 
  NSDictionary *recordSettings = [NSDictionary dictionaryWithObjectsAndKeys:
          [NSNumber numberWithInt:AVAudioQualityLow], AVEncoderAudioQualityKey,
          [NSNumber numberWithInt:kAudioFormatMPEG4AAC], AVFormatIDKey,
          [NSNumber numberWithFloat:44100.0], AVSampleRateKey,
          [NSNumber numberWithInt:1], AVNumberOfChannelsKey,
          [NSNumber numberWithInt:96000], AVEncoderBitRateKey,
          nil];
 
  NSError *error = nil;
 
  _recordSession = [AVAudioSession sharedInstance];
  [_recordSession setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
  [_recordSession setMode:AVAudioSessionModeDefault error:nil];
 
  [[NSNotificationCenter defaultCenter] 
    addObserver:self 
    selector:@selector(audioSessionHandleIntrruption:) 
    name:AVAudioSessionInterruptionNotification 
    object:_recordSession];
 
  NSURL *_tempFileUrl = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:@"temp"]];
 
  _audioRecorder = [[AVAudioRecorder alloc]
                initWithURL:_tempFileUrl
                settings:recordSettings
                error:&error];
 
  _audioRecorder.delegate = self;
 
  if (error) {
      NSLog(@"error: %@", [error localizedDescription]);
    } else {
      [_audioRecorder prepareToRecord];
  }
 
  _audioRecorder.meteringEnabled = YES;
 
  [self startProgressTimer:monitorInterval];
  [_recordSession setActive:YES withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation error:nil];
  [_audioRecorder record];
}
 
RCT_EXPORT_METHOD(stop)
{
  NSLog(@"Stop Monitoring");
  [_audioRecorder stop];
  [_recordSession setCategory:AVAudioSessionCategoryMultiRoute error:nil];
  _prevProgressUpdateTime = nil;
  
  [[NSNotificationCenter defaultCenter]
    removeObserver:self
    name:AVAudioSessionInterruptionNotification
    object:_recordSession];
}
 
@end
