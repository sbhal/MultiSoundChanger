# Steps to build

```
sudo gem install cocoapods
cd ~/git
git clone git@github.com:sbhal/MultiSoundChanger.git
cd MultiSoundChanger
# pod init
pod install
open -a Xcode MultiSoundChanger.xcworkspace
Xcode -> Product -> Build
cd /Users/sidbhal/Library/Developer/Xcode/DerivedData/MultiSourceChanger-xxxxxx
Xcode -> Product -> Run -> (remove existing permissions) -> Provide new permissions in security n privacy window
Xcode -> Project navigator -> MultiSourceChanger -> Products -> MultiSouceChanger

## Debugging
Xcode -> Product -> Edit Scheme -> Run -> Enable debug executable

# Distributing
Xcode -> Product -> Archive -> Distribute App -> Copy App -> `rm -rf /Applications/MultiSoundChanger*`
```