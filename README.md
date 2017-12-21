# Backlogger

[![Build Status](https://travis-ci.org/a-busman/Backlogger.svg?branch=master)](https://travis-ci.org/a-busman/Backlogger)

This is my simple video game backlog managing app for iOS. I didn't really like the current offerings on iOS, as they seemed kind of
clunky and non-straightforward. I built this using RealmSwift, Alamofire, and the GiantBomb API. This is my first swift iOS app, but
it's going pretty well so far. I took inspiration from Apple Music for some of my design choices as I like the organization of the
app (as of iOS 10...kind of really didn't like it before). I'm not a particularly good swift programmer, as I decided to just pick it
up one day (I'm mostly a firmware guy), so feel free to criticize anything you want.

## Features
* Now playing cards show game box art with an interface that allows you quickly update your progress in games, and see info about them.
* Searches GiantBomb, an ever-updating database of games for filling in all the details about a game.
* Allows for adding your own platforms in case you happen to have some sort of weird hack of a game released unofficially for a platform
(like if you wanted to beat Half-Life on your iPod mini).
* Make playlists so that you can create a list of games you'd like to play in any order you'd like. Make a spooky games list, or
games in a series, it really doesn't matter what you do, just don't not make any. That's sad :(
* Add games from your Steam library by logging in under the More tab. It's not perfect with matching games from Steam to GiantBomb, but it's not the worst. You can review the matches after logging in. It might take a bit for larger libraries, as GiantBomb restricts API queries to 1 per second.

## Bugs
* Performance of the Now Playing tab isn't the greatest.
* Since this is not complete, bugs are tracked in the Issues tab. Feel free to add some.

## Future
* I want to add Facebook and Twitter sharing for things like "I just completed this game! Neato!"
* Apple Watch support would be nice to update games in the Now Playing tab.
* If you want to see any particular features, again, feel free to add some to the Issues tab.

## Screenshots
### Now Playing &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Library
<img src="/../screenshots/Now_playing.png?raw=true" width=400 alt="Now Playing">   <img src="/../screenshots/Library.png?raw=true" width=400 alt="Library">
### 3D Touch &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Game Details
<img src="/../screenshots/3d_touch.png?raw=true" width=400 alt="3D Touch">   <img src="/../screenshots/Game_details.png?raw=true" width=400 alt="Game Details">
