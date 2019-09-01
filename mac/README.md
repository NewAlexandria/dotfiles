# Collected Notes

Some interesting tips on [exporting system preferences is here](https://apple.stackexchange.com/a/118491/37586).  Particularly:

```
defaults read com.apple.screensaver
defaults read /Library/Preferences/com.apple.screensaver

defaults export /Library/Preferences/SystemConfiguration/com.apple.PowerManagement pm.plist

defaults import /Library/Preferences/SystemConfiguration/com.apple.PowerManagement sysprefs.plist
```

## Launchpad portability

The database for one's launchpad groupings can be found here](https://apple.stackexchange.com/a/368040/37586).  It is not clear if this folder can be progrmmatically found.  Such could be solved once, manually, at setup via an ENV var.  
