series
======

A bash script for automating selection and playing of series. Why have to remember which episode of a series to watch next...

##Install:
1. Download and extract to a suitable place for the script. Example: ~/scripts/series/
2. In a terminal, run:
> cd <scriptDir>
> . series.sh --install

  * If you prefer to do it manually, add "alias series='source <scriptDir>/series.sh'" to your .bashrc. If you do it that way, specifying the series directory will be done upon first run, instead of during install.  

3. Open a new terminal or type 'bash' to renew the known aliases.

##Usage:

From home folder, just run without arguments to begin usage.

> series

On first run, if asked, provide the directory, containing only the series you watch. The guide's contents are based on the folders available.

Depending from where it's ran, the script runs in two modes:

1. Guide mode:  
  When invoked from ~, choose the index of series to watch.  
  * After the episode is done, you are left in the folder of that series - the next invoke of the script uses the mode described next.

2. Direct in-folder mode  
  When invoked from a series folder, play the next episode of that series.  
  * If used from a folder with no 'saved' file, it inializes the series by playing the first episode and creating the saved file.

Arguments:  
--help  
Gives a brief of the way of usage.
		
--check  
Only show guide for the chosen series, without playing.
		
--newdir  
Prompts for entering a new main series directory.

--newplayer
Prompts for entering a new player to be used.

--install  
Automates the insertion of the alias in .bashrc.

##Additional details:

* Uses a 'saved' file in the series directory for keeping track of the next episode to play, it's created upon initialization of new series.  
* Can be edited manually for episode navigation (potential feature for adding to the script, if requested!)  
* If it's invoked with 'bash' instead of 'source' the script will be limited in functionality, as it cannot change the shell's working directory.  
* When choosing an episode, not entering a number and pressing enter plays the last series.  

**Contact**:  
For any questions, comments, or requests, contact me at mariost6@gmail.com
