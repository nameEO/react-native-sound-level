'use strict'

import { NativeModules, NativeAppEventEmitter, Platform } from 'react-native'

var SoundLevelModule =
  Platform.OS === 'desktop'
    ? NativeModules.RNSoundLevel
    : NativeModules.RNSoundLevelModule

var SoundLevel = {
  timer: null,

  start: function (monitorInterval = 250, notificationTitle = 'Music Strobe', notificationMessage = 'Hearing microphone level') {
    if (this.frameSubscription) {
      this.frameSubscription.remove()
    }

    if (Platform.OS === 'desktop') {
      this.timer = setInterval(async () => {
        if (this.onNewFrame) {
          const frame = await SoundLevelModule.measure()
          this.onNewFrame(JSON.parse(frame))
        }
      }, monitorInterval)
    } else {
      this.frameSubscription = NativeAppEventEmitter.addListener(
        'frame',
        data => {
          if (this.onNewFrame) {
            this.onNewFrame(data)
          }
        }
      )
    }

    return Platform.OS === 'ios' ? SoundLevelModule.start(monitorInterval) : SoundLevelModule.start(monitorInterval, notificationTitle, notificationMessage)
  },

  stop: function () {
    if (this.frameSubscription) {
      this.frameSubscription.remove()
    }

    if (this.timer) {
      clearInterval(this.timer)
    }

    return SoundLevelModule.stop()
  }
}

module.exports = SoundLevel
