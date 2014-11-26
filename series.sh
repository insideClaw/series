#!/bin/bash
#
# Script: series.sh
# Desc: A script for automating series watching, can be used from home for a guide of available ones,
# or from a folder with "saved" file for watching the next series. Main usage is without arguments.
#
# Author: Mario Staykov

# ===== Initialization =====

# BASH_SOURCE[0] gets the script directory even if it was invoked with 'source <name>'
scriptDir=$( dirname "${BASH_SOURCE[0]}" )
configFile="$HOME/.config/series/config"
# Sample movie files are excluded. Add new formats here.
formats='mkv\|mpe?g\|avi\|ts\|mp4\|wmv'
# Default options used, simple playback with extras disabled
playMode=true
rewind=false
onlyReady=false
reconfigure=false
endless=false

# As the main script is called with source, exit would destroy the running shell, kill -SIGINT $$ is used instead.
quit() {
	kill -SIGINT $$
}

#TODO: If series -r | grep 'Akame', doesn't work as intended

# Makes the majority of the functions used available
source $scriptDir/corefunc.sh

#===== Parameter parsing =====

# Explicit OPTIND reset, as it's retained between runs because of sourcing the script
OPTIND=1
# Select mode and play, based on the mode given as argument
while getopts "hcbrse" inputMode
do
	case $inputMode in
		-help | h)
			echo '-=- Help: Run without arguments, either from home or a specific series directory. --check shows the series guide. Refer to README for details.'
			quit;
			;;

		-check | c)
			playMode=false;
			echo '-=- Checking mode activated, inhibits playing, will only show guide for the chosen series.'
			;;

		-back | b)
			rewind=true;
			echo '-=- Rewinding mode activated, reverts the saved file for that series to the previous episode.'
			;;

		-ready | r)
			echo "-=- Ready-only mode activated, the guide displays only the series with episodes yet to watch."
			onlyReady=true;
			;;

		-set | s)
			echo "-=- Redoing configuration, asking for details. "
			reconfigure=true;
			;;

		-endless | e)
			echo "-=- Endless mode, play ALL the episodes!"
			endless=true;
			;;

		\?)
			echo "-!- Unrecognized parameter. Try again or -h for help."
			quit;
	esac
done

#===== Running logic =====

# tries to load variables from config file to make them available to use in further functions
loadConfig;

# if the config file doesn't exist or the reconfigure flag is called, call the configation function
if [ ! -e $configFile ] || $reconfigure
then
	configure;
fi

# only used if ran from ~, seeks to the series directory wanted
chooseDirFromHome;
# create the file, containing the list of video files for that series
populateList;


if $rewind
then
	rewindEpisode;
fi

# having the details of the episode settled, play the desired file, then increment the next episode counter
if $playMode
then
	playNext;
	incrementSaved;
fi

# If continuous mode is specified (endless=true), do the above with extra outputting. Continue until episodes run out or stopped
if $playMode && $endless
then
	loopPlaying;
fi

# Prints a guide of available series and episodes at the end 
showGuide;
