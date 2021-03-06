series
======

A bash script for automating selection and playing of series. Why have to remember which episode of a series to watch next...

## Windows-only prerequisite:
1. Download and install CygWin from the official site https://www.cygwin.com/ enabling package `git` during the install
2. Ensure you have a working video player. Could be beneficial to use not your main player, so you can configure some useful options like auto-close on playback finish
3. Launch a CygWin terminal

## Linux & Mac:
* Just ensure you have your media player path handy, such as `mplayer` for Linux or `/Applications/VLC.app/Contents/MacOS/VLC` for Mac
* It is advised to configure your player to auto-close on playback end and other options you may want
* Not designed to be used with zsh or any other shell other than Bash

## Install:
1. Use `cd` in Terminal to navigate to a suitable directory you want to place the script in
2. Execute `git clone https://github.com/insideClaw/series.git`
2. Then run for the first time and follow the on-screen instructions:
> cd series
>
> . series.sh

  * If running for the first time, you will be guided through setting some basic configuration.
  * You might want to open another terminal window to establish where your paths are, such as `/cygdrive/d/series` and `/cygdrive/c/Program\ Files/VideoLAN/VLC/vlc.exe`
  * Note that it will add "alias series='source <scriptDir>/series.sh'" to your .bashrc, unless it already exists as an entry.

3. Open a new terminal or type 'bash' (if that is your shell of choice) to renew the known aliases.

## Usage:

From home folder, just run without arguments to begin usage.

> series

On first run, if asked, provide the directory, containing all the the series you want to have included. The guide's contents (available titles) are based on the folders immediately (non-recursively) located in the series directory you provide.

Depending on where it's ran from, the script runs in two modes:

1. Guide mode:  
  When invoked from ~, choose the index of series to watch.  
  * After the episode is done, you are left in the folder of that series - the next invoke of the script uses the mode described next.

2. Direct in-folder mode  
  When invoked from a series folder, play the next episode of that series.  
  * If used from a folder with no 'saved' file, it initializes the series by playing the first episode and creating the saved file.

Arguments:  
-h (help)
  Gives a brief of the way of usage.

-c (check)
  Only show guide for the chosen series, without playing.

-r (ready)
  In the list of series, only show those with remaining unwatched episodes.

-b (back)
  Sets the next episode of the chosen series to one less.

-s (set)  
  Guides through setting up the config file, useful for resetting.

-e (endless)
  Endless mode, continuous playback of episodes - until episodes run out or script stopped with CTRL-C.

-l (volume)
  mplayer-only switch, passes the parameters `"--softvol-max 600 -softvol"` in order to allow volume of sounds past the usual 100%.

-q (noseq)
  Disables the sequential consistency check, in order to play series that don't conform to the regular naming convention (yet)

-x (random)
  Selects a (pseudo) random episode, making a playlist in random order so you don't watch the same thing twice

## Additional details:

* Uses a 'saved' file in the series directory for keeping track of the next episode to play, it's created upon initialization of new series.  
* 'saved' file can be edited manually for episode navigation (potential feature for adding to the script, if requested!)  
* If it's invoked with 'bash' instead of 'source' the script will be limited in functionality, as it cannot change the shell's working directory.  
* You can combine arguments, i.e series -rb will show only series with unwatched episodes, then play the last watched one. Add -c to that and it will only revert to it, without playing.  

**Contact**:  
For any questions, comments, or requests, contact me at mario.staykov@gmail.com
