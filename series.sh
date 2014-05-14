#!/bin/bash
#
# Script: series.sh
# Desc: A script for automating series watching, can be used from home for a guide of available ones,
# or from a folder with "saved" file for watching the next series. Main usage is without arguments.
#
# Author: Mario Staykov

scriptDir=$( dirname "${BASH_SOURCE[0]}" )
# Makes the majority of the functions used available
source $scriptDir/corefunc.sh
# a sample movie files is are excluded. Add new formats here.
formats='mkv\|mpe?g\|avi\|ts\|mp4\|wmv'

# Note: As the main script is called with source, exit would destroy the running shell, kill -SIGINT $$ is used instead.
# Select mode and play, based on the mode given as argument
inputMode=$1;
onlyReady=false;
case $inputMode in
	--help | -h)
		echo '-=- Usage: Run without arguments, either from home or a specific series directory. --check shows the series guide. Refer to README for details.'
		kill -SIGINT $$; 
		;;
		
	--check | -c)
		echo '-=- Checking mode activated, will only show guide for the chosen series.'
		chooseDirFromHome;
		populateList;
		;;

	--rewind)
		chooseDirFromHome;
		rewindEpisode;
		populateList;
		;;

	--install)
		echo "alias series='source $(readlink -m "${BASH_SOURCE[0]}")'" >> ~/.bashrc
		echo "-=- Alias appended to $HOME/.bashrc"
		checkFirstRun;
		kill -SIGINT $$;
		;;

	--newdir)
		echo '-?- Please specify the pathname of the new series directory. Example: ~/videos/series'
		read newDir;
		echo $newDir > $scriptDir/config.seriesDir;
		echo '-=- Series directory updated to $newDir...';
		kill -SIGINT $$;
		;;
		
	--newplayer)
		echo '-?- Please specify a new video player to be used. Example: mplayer'
		read newPlayer
		echo $newPlayer > $scriptDir/config.player;
		echo '-=- Player updated to $newDir...';
		kill -SIGINT $$;
		;;
	
	--ready | -r)
		onlyReady=true;
		;;&
		# because of the block terminator, next block is also evaluated

	*) 
		# only used if ran from ~, seeks to the series directory wanted
		checkFirstRun;
		# gets the directory path from the file, asks user for first time setup if there it's not in the script's folder
		chooseDirFromHome;
		# create the file, containing the list of video files for that series
		populateList;
		# having the details of the episode settled, play the desired file
		playNext;
		# after everything is completed, increment the next episode counter
		incrementSaved;
		;;
esac

# Prints a guide of available series and episodes at the end 
showGuide;
