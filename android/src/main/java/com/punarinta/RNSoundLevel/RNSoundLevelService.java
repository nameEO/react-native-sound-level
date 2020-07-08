package com.punarinta.RNSoundLevel;

import android.media.MediaRecorder;

import androidx.core.app.NotificationCompat;
import androidx.localbroadcastmanager.content.LocalBroadcastManager;

import android.os.HandlerThread;
import android.os.SystemClock;
import android.util.Log;

import android.app.Notification;
import android.app.PendingIntent;
import android.app.Service;
import android.content.Intent;
import android.os.Handler;
import android.os.IBinder;
import android.app.NotificationManager;
import android.app.NotificationChannel;
import android.os.Build;

import com.facebook.react.bridge.ReactApplicationContext;

public class RNSoundLevelService extends Service {
    private static final String CHANNEL_ID = "MusicStrobe";
    private MediaRecorder recorder;
    private boolean isRecording = false;
    private Handler handler;
    private HandlerThread handlerThread;
    private int id = 1;
    private int interval = 100;
    private Runnable runnableCode = new Runnable() {
        @Override
        public void run() {
            while(isRecording){
                int value;
                int amplitude = recorder.getMaxAmplitude();
                if (amplitude == 0) {
                    value = -160;
                } else {
                    value = (int) (20 * Math.log(((double) amplitude) / 32767d));
                }
                sendEvent(value, amplitude);

                SystemClock.sleep(interval);
            }
        }
    };

    @Override
    public IBinder onBind(Intent intent) {
        return null;
    }

    @Override
    public void onCreate() {
        super.onCreate();
    }

    @Override
    public void onDestroy() {
        super.onDestroy();
        if (!isRecording) {
            sendEventError(true, "INVALID_STATE", "Please call start before stopping recording");
        }
        isRecording = false;

        try {
            recorder.stop();
            recorder.release();
        } catch (final RuntimeException e) {
            sendEventError(true, "RUNTIME_EXCEPTION", "No valid audio data received. You may be using a device that can't record audio.");
        } finally {
            recorder = null;
        }
        handlerThread.quit();
    }

    @Override
    public int onStartCommand(Intent intent, int flags, int startId) {
        interval = intent.getIntExtra("interval", 250);

        if (isRecording) {
            sendEventError(true, "INVALID_STATE", "Please call stop before starting");
        } else {
            recorder = new MediaRecorder();
            try {
                recorder.setAudioSource(MediaRecorder.AudioSource.MIC);
                recorder.setOutputFormat(MediaRecorder.OutputFormat.MPEG_4);
                recorder.setAudioEncoder(MediaRecorder.AudioEncoder.AAC);
                recorder.setAudioSamplingRate(44100);
                recorder.setAudioChannels(1);
                recorder.setAudioEncodingBitRate(96000);
                recorder.setOutputFile(this.getApplicationContext().getCacheDir().getAbsolutePath() + "/soundlevel");
            } catch (final Exception e) {
                sendEventError(true,"COULDNT_CONFIGURE_MEDIA_RECORDER", "Make sure you've added RECORD_AUDIO " +
                        "permission to your AndroidManifest.xml file " + e.getMessage());
                return 	START_NOT_STICKY;
            }
            try {
                recorder.prepare();
            } catch (final Exception e) {
                sendEventError(true, "COULDNT_PREPARE_RECORDING", e.getMessage());
                return 	START_NOT_STICKY;
            }

            recorder.start();

            isRecording = true;
            handlerThread = new HandlerThread("HandlerThread");
            handlerThread.start();
            handler  = new Handler(handlerThread.getLooper());
            handler.post(this.runnableCode);


            Notification notification = new
                    NotificationCompat.Builder(this, CHANNEL_ID)
                    .setContentTitle(intent.getStringExtra("title"))
                    .setContentText(intent.getStringExtra("message"))
                    .setSmallIcon(R.drawable.ic_mic)
                    .build();

            startForeground(1, notification);

        }
        return 	START_NOT_STICKY;
    }

    private void sendEvent(int value, int rawValue) {
        LocalBroadcastManager localBroadcastManager = LocalBroadcastManager.getInstance(this);
        Intent customEvent = new Intent("toModule");
        customEvent.putExtra("id", id++);
        customEvent.putExtra("value", value);
        customEvent.putExtra("rawValue", rawValue);
        localBroadcastManager.sendBroadcast(customEvent);
    }

    private void sendEventError(boolean error, String errorCode, String errorMessage) {
        LocalBroadcastManager localBroadcastManager = LocalBroadcastManager.getInstance(this);
        Intent customEvent = new Intent("toModule");
        customEvent.putExtra("error", error);
        customEvent.putExtra("errorCode", errorCode);
        customEvent.putExtra("errorMessage", errorMessage);
        localBroadcastManager.sendBroadcast(customEvent);
    }

}
