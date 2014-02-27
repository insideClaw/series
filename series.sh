#!/bin/bash
#
# Script: series.sh
# Desc: A script for automating series watching, can be used from home for a guide of available ones,
# or from a folder with "saved" file for watching the next series. 
#
# Author: Mario Staykov

# a sample movie files is are excluded. Add new formats here.
formats='mkv\|mpe?g\|avi\|ts\|mp4'
function populateList {
	find . -iregex ".*\.\($formats\)" | grep -vi sample | sort > listpure
}
function ensureSaved {
	if [ ! -f saved ]
	then
	  echo 1 > saved
	fi
}
function playNext {
	ensureSaved;
	epnumber=$(cat saved)
	if [ "$(cat saved)" -le "$(cat listpure | wc -l)" ] # if there is at least one more episode
	then
	  #mplayer "$(cat listpure | head -$epnumber | tail -1)" -alang jpn,Japanese,eng,English -slang eng,English
	  $player "$(cat listpure | head -$epnumber | tail -1)" 
	fi
}
function incrementSaved {
	if [ $(cat saved) -le $(cat listpure | wc -l) ]
	then
	  echo $(( $epnumber + 1 )) > saved
	fi
}
function showGuide {
		# it prepares a "list" file in advance, then prints its contents
		prepareFirst;
		singleOutNext;
		prepareLast;
		printList;
}
function prepareFirst {
	# prints everything up to the next episode
	lastDone=$(( $(cat saved) - 1 )) # gets the next episode to watch from saved, then subtracts one for last ep watched
	cat listpure | head -$lastDone > list
}
function singleOutNext {
	echo "" >> list # literally makes a new line, better outlook
	if [ $(cat saved) -le $(cat listpure | wc -l) ]
	then
	  echo "> $(cat listpure | head -$(cat saved) | tail -1)" >> list
	else
	  echo "> Umad? No next episode available" >> list
	fi
	echo "" >> list
}
function prepareLast {
	savedVar=$(cat saved)
	savedUp=$(($savedVar + 1 ))
	cat listpure | tail -n +$savedUp >> list
}
function printList {
	# do the actual printing from file, displayRange refines the outlook for large series
	displayRange="$(( $(cat saved) + 20 ))"
	cat list | head -$displayRange
	rm list listpure
}
function specifySeries {
	# initialDir is already established, contains the directory the user specified as the directory, containing the series
	humanBit=1;
	i=0;
	seriesAmount="$(ls $initialDir | wc -l)"
	while [ "$i" -lt "$seriesAmount" ]
	do
	  nextToAdd="$(ls $initialDir | head -$(($i+1)) | tail -1)"; # need to increase by one for getting 0 last files is not worth for first case
	  dir[i]=$nextToAdd;
	  i=$(( i+1 ))
	done
}
function presentSeries {
	specifySeries;
	count=0;
	# the "i" variable refers to the one in specifySeries we use for counting, effectively it is the amount of entries in $dir
	while [ "$count" -lt "$i" ] 
	do
		saved=$( cat "$initialDir/${dir[$count]}/saved" 2>/dev/null )
		saved=$(( $saved - 1 )) # make it be the number of episodes watched, instead of next
		if [ "$saved" == "" ] || [ "$saved" == "-1" ]
		then
			saved="0"
		fi
		# uses the variable formats, announced previously
		total=$(find "$initialDir/${dir[$count]}" -iregex ".*\.\($formats\)" | grep -vi sample | wc -l)
		echo "$(($count + $humanBit)). ${dir[$count]} [$saved/$total]" # present the uncomfortable to press 0 into a 1
		count=$(( $count + 1 ));
	done
}

# gets the directory path from the file, asks user for first time setup if there it's not in the script's folder
function firstRun {	
	# BASH_SOURCE[0] gets the script directory even if it was invoked with 'source <name>'
	if [ ! -f $(dirname "${BASH_SOURCE[0]}")/config.seriesDir ] 
	then
		echo '-?- First time use detected. Please specify the pathname of the series directory. Example: ~/videos/series.'
		read initialDir
		# outputs to the a new file in the script's folder
		echo $initialDir > $(dirname "${BASH_SOURCE[0]}")/config.seriesDir
		echo '-=- Series directory initialized.'
	fi
	if [ ! -f $(dirname "${BASH_SOURCE[0]}")/config.player ]
	then
		echo '-?- Please specify the video player which you want to use. Example: mplayer'
		read player
		echo $player > $(dirname "${BASH_SOURCE[0]}")/config.player
		echo '-=- $player selected.'
	fi
}

# if current dir is ~, ask user to choose series to watch (changes the current dir accordingly after choice)
function seekDirFromHome {
	# eval is used so ~ is expanded
	eval initialDir=$(cat $(dirname "${BASH_SOURCE[0]}")/config.seriesDir)
	player=$(cat $(dirname "${BASH_SOURCE[0]}")/config.player)
	if [ "$(pwd)" == "$HOME" ]
	then
		echo "Series available:"
		presentSeries;
		echo "Choose what to watch... "
		read choice;
		choice=$(( $choice - humanBit)) # the choice entered was with human numericals in mind, revert it for computer use
		echo "${dir[$choice]} decided!"
		cd "$initialDir/${dir[$choice]}"
	# if the current directory is a descendant of the series directory, continue script, otherwise don't proceed as if it's a series directory.
	elif [ "$(pwd | grep $initialDir -o)" == "" ] || [ "$(pwd)" == "$initialDir" ] 
	then
		echo "-!- Use from ~ (home directory) for main menu, use from a series directory for direct play."
		kill -SIGINT $$ # exit doesn't work, as the script is called with source
	fi	
}
function selectModeAndPlay {
	# abort all but printing of guide, which requires populateList, if we have an expected argument
	case $inputMode in
		--help | -h)
			echo '-=- Usage: Run without arguments, either from home or a specific series directory. --check shows the series guide. Refer to README for details.'
			kill -SIGINT $$; # as script is called with source, exit would destroy the running shell
			;;
			
		--check)
			echo '-=- Checking mode activated, will only show guide for the chosen series.'
			seekDirFromHome;
			populateList;
			;;
			
		--newdir)
			echo '-?- Please specify the pathname of the new series directory. Example: ~/videos/series'
			read newDir;
			echo $newDir > $(dirname "${BASH_SOURCE[0]}")/config.seriesDir;
			echo '-=- Series directory updated to $newDir...';
			kill -SIGINT $$;
			;;
			
		--newplayer)
			echo '-?- Please specify a new video player to be used. Example: mplayer'
			read newPlayer
			echo $newPlayer > $(dirname "${BASH_SOURCE[0]}")/config.player;
			echo '-=- Player updated to $newDir...';
			kill -SIGINT $$;
			;;
			
		--install)
			echo "alias series='source $(readlink -m "${BASH_SOURCE[0]}")'" >> ~/.bashrc
			echo "-=- Alias put in .bashrc."
			firstRun;
			kill -SIGINT $$;
			;;
			
		*)
			firstRun;
			seekDirFromHome;
			populateList;
			#amixer set Master 42%
			playNext;
			incrementSaved;
			;;
	esac
}
inputMode=$1;
selectModeAndPlay;
showGuide;
