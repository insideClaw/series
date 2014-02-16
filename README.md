A bash script for automating selection and playing of series. Why have to remember which episode of a series to watch next...

Install:

1. Download and extract to a suitable place for the script. Example: ~/scripts/series/
2. In a terminal, 'cd' into the script folder, then run:
        . series.sh --install
   or if you prefer to do it manually, add 
	alias series='source <scriptDir>/series.sh'
   as an alias to your .bashrc. If you do it that way, specifying the series directory will be done upon first run, instead of during install.

3. Open a new terminal and type 'series' to begin usage. Will be asked for main directory, unless already provided when ran with --install.

Usage options:

On first run, when asked, provide the directory, containing only the series you watch. The guide's contents are based on the folders available.

1. Guide mode
	Type 'series' from home folder( ~ ) to get a guide of available series and choose the index of series to watch.
	* After the episode is done, you are left in the folder of that series - the next invoke of the script uses the mode described next.
2. Direct in-folder mode
	Type 'series' in a folder of the series to be watched, instantly playing the next episode.
	* If used from a folder with no 'saved' file, it inializes series by playing the first episode and creating the saved file.

Arguments:
  --help
		Gives a brief of the way of usage.
  --check
		Only show guide for the chosen series, without playing.
  --newdir
		Prompts for entering a new main series directory.
  --install
  		Automates the insertion of the alias in .bashrc.

Script details:

Uses a 'saved' file in the series directory for keeping track of the next episode to play, it's created upon initialization of new series.
Can be edited manually for episode navigation (potential feature for adding to the script, if requested!)
If it's invoked with 'bash' instead of 'source' the script will be limited in functionality, as it cannot change the shell's working directory.
When choosing an episode, not entering a number and pressing enter plays the last series.

Contact:
For any questions, comments, or requests, contact me at mariost6@gmail.com
