# Collected Notes

Some interesting tips on [exporting system preferences is here](https://apple.stackexchange.com/a/118491/37586).  Particularly:

```
defaults read com.apple.screensaver
defaults read /Library/Preferences/com.apple.screensaver

defaults export /Library/Preferences/SystemConfiguration/com.apple.PowerManagement pm.plist

defaults import /Library/Preferences/SystemConfiguration/com.apple.PowerManagement sysprefs.plist
```

## Launchpad portability

The database for one's launchpad groupings can be found here](https://apple.stackexchange.com/a/368040/37586).  It is not clear if this folder can be progrommatically found.  Such could be solved once, manually, at setup via an ENV var.  

The DB groups name + parents can be found in the DB with via

```
select * 
from items i join groups g on g.item_id = i.rowid 
order by i.parent_id, i.ordering
```

The issue remains that apps are listed by a `UUID`, not name.  This suggests that they may not port well to a different computer, since a `UUID` is typically made in the local context.  However, apps registered via the app store or via Apple's dev program may have consistent UUIDs.