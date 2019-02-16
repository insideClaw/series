series
======

A bash script for automating selection and playing of series. Why have to remember which episode of a series to watch next...

## Install:
1. Download and extract to a suitable place for the script. Example: ~/scripts/series/
2. In a terminal, run:
> cd <scriptDir>
> . series.sh

  * If running for the first time, you will be guided through setting some basic configuration.
  * Note that it will add "alias series='source <scriptDir>/series.sh'" to your .bashrc, unless it already exists as an entry.

3. Open a new terminal or type 'bash' to renew the known aliases.

Note: Confirmed to run on Windows, under an out-of-the-box Cygwin environment. Same instructions apply, only you provide the full path for a Windows player of your choice.

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
  Guides through setting up the config file.

-e (endless)
  Endless mode, continuous playback of episodes - until episodes run out or script stopped with CTRL-C.

-l (volume)
  mplayer-only switch, passes the parameters "--softvol-max 600 -softvol" in order to allow volume of sounds past the usual 100%.

## Additional details:

* Uses a 'saved' file in the series directory for keeping track of the next episode to play, it's created upon initialization of new series.  
* 'saved' file can be edited manually for episode navigation (potential feature for adding to the script, if requested!)  
* If it's invoked with 'bash' instead of 'source' the script will be limited in functionality, as it cannot change the shell's working directory.  
* You can combine arguments, i.e series -rb will show only series with unwatched episodes, then play the last watched one. Add -c to that and it will only revert to it, without playing.

**Contact**:  
For any questions, comments, or requests, contact me at mariost6@gmail.com
