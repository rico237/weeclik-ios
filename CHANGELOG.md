# Changelog
All notable changes to this project will be documented in this file.        
The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## [Unreleased]
### Add
- Video compression for a faster upload to database.

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