#!/bin/bash
# Supplementary file to series.sh, contains a majority of the functions used.

# Function level 1, next section's functions use these
##########################################################

function presentSeries {
	# $seriesDir is already allocated
	humanBit=1;
	entryCount=0;
	seriesAmount="$(ls $seriesDir | wc -l)"
	while [ "$entryCount" -lt "$seriesAmount" ]
	do
	  nextToAdd="$(ls $seriesDir | head -$(($entryCount+1)) | tail -1)"; # need to increase by one for getting 0 last files is not worth for first case
	  dir[$entryCount]=$nextToAdd;
	  entryCount=$(( $entryCount+1 ))
	done
	
	count=0;
	# the $entryCount variable is the amount of entries in $dir
	while [ "$count" -lt "$entryCount" ] 
	do
		saved=$( cat "$seriesDir/${dir[$count]}/saved" 2>/dev/null )
		saved=$(( $saved - 1 )) # make it be the number of episodes watched, instead of next
		if [ "$saved" == "" ] || [ "$saved" == "-1" ]
		then
			saved="0"
		fi
		# uses the variable formats, announced previously		
		total=$(find "$seriesDir/${dir[$count]}" -iregex ".*\.\($formats\)" | grep -vi sample | wc -l)
		# if the user specified they want only the ready series, print only if there are available episodes, otherwise skip the current item's iteration
		if $onlyReady
		then
			if [ $saved -ge $total ]
			then
				count=$(( $count + 1 ));
				continue;
			fi
		fi
		echo "$(($count + $humanBit)). ${dir[$count]} [$saved/$total]" # present the uncomfortable to press 0 into a 1
		count=$(( $count + 1 ));
	done
}
function checkNextEpisode {
	if	[ "$(cat saved)" -le "$(cat listpure | wc -l)" ]
	then 
		nextEpisodeAvailable=true;
	else
		nextEpisodeAvailable=false;
	fi
}


# Function level 0
##################

function loadConfig {
	# loads variables needed from the config file
	if [ -f $configFile ] 
	then
		seriesDir="$(grep 'Directory:' $configFile | cut -f2 -d ':')"
		player="$(grep 'Player:' $configFile | cut -f2 -d ':')"
	else
		echo "-!- No config file to load!"
	fi
}
# it prepares a "list" file in advance, then prints its contents
function showGuide {
	# prints everything up to the next episode
	lastDone=$(( $(cat saved) - 1 )) # gets the next episode to watch from saved, then subtracts one for last ep watched
	cat listpure | head -$lastDone > list

	# prints the structure surrounding and the name of the next episode
	echo "" >> list # literally makes a new line, better outlook
	if [ $(cat saved) -le $(cat listpure | wc -l) ]
	then
	  echo "> $(cat listpure | head -$(cat saved) | tail -1)" >> list
	else
	  echo "> Umad? No next episode available" >> list
	fi
	echo "" >> list

	# prints everything after the singled out episode
	savedVar=$(cat saved)
	savedUp=$(($savedVar + 1 ))
	cat listpure | tail -n +$savedUp >> list
	
	# do the actual printing from file, displayRange refines the outlook for large series
	displayRange="$(( $(cat saved) + 20 ))"
	cat list | head -$displayRange
	rm list listpure
}

# only used if ran from ~, seeks to the series seriesDir wanted
function chooseDirFromHome {
	# we have seriesDir and player variables available from loadConfig in main script
	if [ "$(pwd)" == "$HOME" ]
	then
		echo "Series available:"
		presentSeries;
		echo "Choose what to watch... "
		read choice;
		# a bit of input sanitizing, $seriesAmount was initialized in presentSeries()
		# the while loop checks if the choice is NOT a valid positive integer within permitted range
		while [[ ! $choice =~ ^[0-9]+$ ]] || [ $choice -lt 1 ] || [ $choice -gt $seriesAmount ] 
		do
			echo "-!- Choice not an valid integer (1-$seriesAmount). Pick again:"
			read choice
		done
		
		choice=$(( $choice - humanBit)) # the choice entered was with human numericals in mind, revert it for computer use
		echo "-=- ${dir[$choice]} decided!"
		cd "$seriesDir/${dir[$choice]}"
	# if the current seriesDir is a descendant of the series seriesDir, continue script, otherwise don't proceed as if it's a series seriesDir.
	elif [ "$(pwd | grep $seriesDir -o)" == "" ] || [ "$(pwd)" == "$seriesDir" ] 
	then
		echo "-!- Use from ~ (home) for main menu, use from a series seriesDir for direct play."
		kill -SIGINT $$ # exit doesn't work, as the script is called with source
	fi	
}
# gets the seriesDir path from the file, configure ~/.config/series/config
function configure {	
	# As the main script is called with source, exit would destroy the running shell, kill -SIGINT $$ is used instead.
	echo "-=- Configuration started."
	# we have $configFile available from main script definition
	if [ "$(grep 'alias series=' ~/.bashrc)" == "" ]
	then
		echo "alias series='source $(readlink -m "${BASH_SOURCE[0]}")'" >> ~/.bashrc
    	echo "-=- Alias appended to $HOME/.bashrc"
	else
		echo "-=- A series alias is already present in .bashrc, not adding anything"
	fi
	
	# Create the config directory if it's not there, so creating the file works
	configDir="$HOME/.config/series"
	if [ ! -e $configDir ]
	then
		mkdir $configDir
		echo "$configDir created."
	fi

	#Setting configuration for seriesDir
	echo "-?- Please specify the pathname of the series directory. Example: ~/videos/series. Press enter to keep current. [$seriesDir]"
	read seriesDirNew
	if [ "$seriesDirNew" == "" ]
	then
		echo "-=- No changes to $seriesDir"
	else
		# eval is used to expand ~ ($HOME) 
		eval seriesDir="$seriesDirNew"
		echo "Directory:$seriesDir" > $configFile
		echo "-=- Series directory changed to $seriesDir"
	fi

	#Setting configuration for mplayer
	echo "-?- Please specify the name of the player to be used. Example: mplayer. Press enter to keep current. [$player]"
	read playerNew
	if [ "$playerNew" == "" ]
	then
		echo "-=- No changes to $player"
	else
		eval player="$playerNew"
		echo "Player:$player" >> $configFile
		echo "-=- Player used changed to $player"
	fi
}
function populateList {
	find . -iregex ".*\.\($formats\)" | grep -vi sample | sort > listpure
}
# Continuous playback and countdown between plays, for when endless mode is specified
function loopPlaying {
	checkNextEpisode;
	while $nextEpisodeAvailable
	do
		# read is used as a echo+sleep+character suppress mechanism
		read -s -p "-=- Playing next episode in 3..." -t 1
		read -s -p "2..." -t 1
		read -s -p "1..." -t 1
		playNext;
		incrementSaved;
		checkNextEpisode;
	done
}
# having the details of the episode settled, play the desired file
function playNext {
	# ensure the saved file exists, if not, create one
	if [ ! -f saved ]
	then
	  echo 1 > saved
	fi
	epnumber=$(cat saved)
	checkNextEpisode;
	if $nextEpisodeAvailable # if there is at least one more episode
	then
	  # input is taken from /dev/null to make sure a nasty 'q' keystroke doesn't get queue up in between episodes
	  $player "$(cat listpure | head -$epnumber | tail -1)" < /dev/null
	fi
}
# after everything is completed, increment the next episode counter
function incrementSaved {
	if [ $(cat saved) -le $(cat listpure | wc -l) ]
	then
	  echo $(( $epnumber + 1 )) > saved
	fi
}

# Sets the next episode of the chosen series to one less.
function rewindEpisode {
	# ensure the saved file exists, if not, create one
	if [ ! -f saved ]
	then
		echo 1 > saved
	fi

	# Do the rewinding, only if not already at the start
	if [ $(cat saved) -le 1 ]
	then
		echo "-!- No previous episode to rewind to."
	else
		prev=$(( $(cat saved) - 1 ))
		echo $prev > saved
		echo "-=- Rewinded one episode."
	fi

	# Print a newline if the next episode(after possible rewinding) is not the first (the next episode surroundings have spacing)
	if [ $(cat saved) -gt 1 ]
	then
		echo ""
	fi
}
