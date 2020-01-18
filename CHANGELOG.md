# Changelog
All notable changes to this project will be documented in this file.        
The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## [Unreleased]
### Add
- Video compression for a faster upload to database.

## [3.3.5] - 2019-11-24
### Add
- Add precheck for app store in beta & screenshot lanes.
- Documentation folder (automatic execution) with [jazzy](https://github.com/realm/jazzy) lib visible here [LINK](https://rico237.github.io/weeclik-ios/).

### Changed
- Sharing icon was not called for SMS & Whatsapp sharing.
- Method function for globally showing alerts in App.
- Sometimes sharing function would not increase number information of commerce.
- Groupe sharing now trigger the already send check in commerce detail.
- SwiftLint to don't include Extensions folder in build check

## [3.3.4] - 2019-11-17
### Changed
- Set minimum iOS version from 13 to 11.

## [3.3.3] - 2019-11-17
### Canceled - X
- Build sent to testflight via fastlane then canceled.

## [3.3.2] - 2019-11-17
### Add
- Add encryption key in Info.plist for production & development environment (ITSAppUsesNonExemptEncryption = NO).
- Create a beta deployment lane for fastlane (usage: bundle exex fastlane beta).

### Changed
- Video fetch options: .original => .current (use last modified version of video). 
- Video fetch options: .automatic => .fastFormat (try to have a lightweight video file).
- Maximal length of video file: 20sec => 60sec.