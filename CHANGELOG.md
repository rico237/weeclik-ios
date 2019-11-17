# Changelog
All notable changes to this project will be documented in this file.        
The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## [Unreleased]
### Add
- Video compression for a faster upload to database.

## [3.3.2] - 2019-11-17
### Add
- Create a beta deployment lane for fastlane (usage: bundle exex fastlane beta).

### Changed
- Video fetch options: .original => .current (use last modified version of video). 
- Video fetch options: .automatic => .fastFormat (try to have a lightweight video file).
- Maximal length of video file: 20sec => 60sec.