A package to dynamically measure sound input level in React Native applications.
Can be used to help user to adjust microphone sensitivity. On foreground.

This repo is a fork of [react-native-sound-level](https://github.com/punarinta/react-native-sound-level)

> ## !!! WARNING !!!
>
> # iOS
>
> This module will be turned off when :
>
> - Cell Broadcast warning alerts received
>
> - Incoming/Outgoing call event
>
> - Several hours of running on debug mode **even any interruption** (Recommend to test on release mode)
>
> - Something Unknown...
>
> and **never resume**. TAKE CARE OF THIS.
>
> # Android
>
> Just fine. Working with services in background.
> But android Battery saver or vender specific battery manager may turn off background service.

### Installation

Install the npm package and link it to your project:

```
npm install react-native-sound-level-foreground --save
react-native link react-native-sound-level-foreground
```

On _iOS_ you need to add a usage description and background modes to `Info.plist`:

```
<key>NSMicrophoneUsageDescription</key>
<string>This sample uses the microphone to analyze sound level.</string>

...

<key>UIBackgroundModes</key>
<array>
  <string>audio</string>
</array>
```

On _Android_ you need to add a permission to `AndroidManifest.xml`:

```
<uses-permission android:name="android.permission.RECORD_AUDIO" />
```

### Manual installation on iOS

```
In XCode, in the project navigator:

* Right click _Libraries_
* Add Files to _[your project's name]_
* Go to `node_modules/react-native-sound-level-foreground`
* Add the `.xcodeproj` file

In XCode, in the project navigator, select your project.

* Add the `libRNSoundLevel.a` from the _soundlevel_ project to your project's _Build Phases ➜ Link Binary With Libraries_
```

### Installation on Ubuntu

1. Add to package.json: `"desktopExternalModules": [ "node_modules/react-native-sound-level-foreground/desktop" ]`
2. You may need to make QT's multimedia library accessible for linker
   `sudo ln -s $YOUR_QT_DIR/5.9.1/gcc_64/lib/libQt5Multimedia.so /usr/local/lib/libQt5Multimedia.so`

### React Native 0.60+

To make it run correctly on iOS you may need the following:

1. Add `pod 'RNSoundLevel', :path => '../node_modules/react-native-sound-level-foreground'` to your `ios/Podfile` file.
2. Unlink the library if linked before (`react-native unlink react-native-sound-level-foreground`).
3. Run `pod install` from within your project `ios` directory

### Usage

```js
import RNSoundLevel from 'react-native-sound-level-foreground'

componentDidMount() {
  // request permission before use(android)

  RNSoundLevel.start(/* monitorInterval, notificationTitle(android), notificationMessage(android) */)

  RNSoundLevel.onNewFrame = (data) => {
    // see "Returned data" section below
    console.log('Sound level info', data)


    // `Deathrattle` (iOS only)
    if(data.value === 9) {
      // This value will not be sent if interruption handling fails.
      console.log('killed by interruption')
    }
  }
}

// don't forget to stop it
componentWillUnmount() {
  RNSoundLevel.stop()
}
```

### Returned data

```
{
  "id",             // frame number
  "value",          // sound level in decibels, -160 is a silence level
  "rawValue"        // raw level value, OS-dependent
}
```

Shamelessly copied from @vitor-hbr/react-native-sound-level and modified (Android)
