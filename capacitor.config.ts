import type { CapacitorConfig } from '@capacitor/cli'

const config: CapacitorConfig = {
  appId:   'com.aihomerun.app',
  appName: 'AIHomeRun',
  webDir:  'dist',

  ios: {
    scheme:                'AIHomeRun',
    contentInset:          'always',
    backgroundColor:       '#000000',
    preferredContentMode:  'mobile',
  },

  plugins: {
    SplashScreen: {
      launchShowDuration:  1500,
      launchAutoHide:      true,
      backgroundColor:     '#000000',
      androidSplashResourceName: 'splash',
      androidScaleType:    'CENTER_CROP',
      showSpinner:         false,
      splashFullScreen:    true,
      splashImmersive:     true,
    },
    StatusBar: {
      style:           'DARK',      // white text on dark bg
      backgroundColor: '#000000',
    },
  },
}

export default config
