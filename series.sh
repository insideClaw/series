#!/bin/bash
#
# Script: series.sh
# Desc: A script for automating series watching, can be used from home for a guide of available ones,
# or from a folder with "saved" file for watching the next series. 
#
# Author: Mario Staykov

function populateList {
	# a fix for not getting the sample movie files is used. Add new formats here.
	find . -iname "*.mkv" | grep -vi sample > listtmp
	find . -iname "*.avi" | grep -vi sample >> listtmp
	find . -iname "*.ts"  | grep -vi sample >> listtmp
	find . -iname "*.mp4" | grep -vi sample >> listtmp
	cat listtmp | sort > listpure; rm listtmp
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
	  #bash /home/discharge/scripts/1seriesMover& #it decides if to move
	  #wmctrl -r "/bin/bash" -e 0,840,1243,500,250 # move the terminal
	  #mplayer "$(cat listpure | head -$epnumber | tail -1)" -alang jpn,Japanese,eng,English -slang eng,English
	  mplayer "$(cat listpure | head -$epnumber | tail -1)" 
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
		# find only the related files for counting. Add new format here. Ignores sample files as well. 
		# Note: Don't put space after the line continuation indicating backslash.
		total=$( find "$initialDir/${dir[$count]}" \
		-iname "*.mkv" -and ! -iname "*sample*" -or \
		-iname "*.avi" -and ! -iname "*sample*" -or \
		-iname "*.ts" -and ! -iname "*sample*" -or \
		-iname "*.mp4" -and ! -iname "*sample*" \
		| wc -l )
		echo "$(($count + $humanBit)). ${dir[$count]} [$saved/$total]" # present the uncomfortable to press 0 into a 1
		count=$(( $count + 1 ));
	done
}

# gets the directory path from the file, asks user for first time setup if there it's not in the script's folder
function firstRun {	
	# BASH_SOURCE[0] gets the script directory even if it was invoked with 'source <name>'
	if [ ! -f $(dirname "${BASH_SOURCE[0]}")/initialDir ] 
	then
		echo '-=- First time use detected. Please specify the pathname of the series directory. Example: ~/videos/series.'
		read initialDir
		# outputs to the a new file in the script's folder
		echo $initialDir > $(dirname "${BASH_SOURCE[0]}")/initialDir
		echo '-=- Series directory initialized.'
	fi
}

# if current dir is ~, ask user to choose series to watch (changes the current dir accordingly after choice)
function seekDirFromHome {
	# eval is used so ~ is expanded
	eval initialDir=$(cat $(dirname "${BASH_SOURCE[0]}")/initialDir)
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
			kill -SIGINT $$;
			;;
			
		--check)
			echo '-=- Checking mode activated, will only show guide for the chosen series.'
			seekDirFromHome;
			populateList;
			;;
			
		--newdir)
			echo '-=- Please specify the pathname of the new series directory. Example: ~/videos/series'
			read newDir;
			echo $newDir > $(dirname "${BASH_SOURCE[0]}")/initialDir;
			echo '-=- Series directory updated to $newDir...';
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
