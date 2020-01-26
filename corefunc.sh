#!/bin/bash
#
# Script: corefunc.sh
# Desc: Supplementary file to series.sh, contains a majority of the functions used.
#
# Author: Mario Staykov

##########################################################

function presentSeries {
	# $seriesDir is already allocated
	humanBit=1;
	entryCount=0;
	# Evaluate the folder only once for performance
	ls $seriesDir > /tmp/series/seriesDirContents

	# Use the folder contents that are were fetched earlier
	seriesAmount="$(cat /tmp/series/seriesDirContents | wc -l)"
	while [ "$entryCount" -lt "$seriesAmount" ]
	do
	  nextToAdd="$(cat /tmp/series/seriesDirContents | head -$(($entryCount+1)) | tail -1)"; # need to increase by one for getting 0 last files is not worth for first case
	  dir[$entryCount]=$nextToAdd;
	  entryCount=$(( $entryCount+1 ))
	done

	count=0;
	# the $entryCount variable is the amount of entries in $dir
	echo "-=- Total: $entryCount series detected. Beginning parsing..."
	while [ "$count" -lt "$entryCount" ]
	do
		echo -n "$count "
		saved=$( cat "$seriesDir/${dir[$count]}/saved" 2>/dev/null )
		if [ "$saved" == "" ]
		then
			# File has proven to be empty, assume we're not watched anything
			saved=1
		# Verify value is a valid integer (comparable) and not a sneaky string (previously caused unintended behaviour and crash within the loop)
		elif [ "$saved" -gt 0 ] 2>/dev/null
		then
			:
		else
			echo -e "\n-!- Saved file for series ${dir[$count]} is not valid or present. File must contain only one integer larger than 0."
			echo "-?- Would you like to set it to the first episode? Press enter to keep do so now, otherwise re-run script after fixing it yourself."
			read "resetDecision"
			if [ "$resetDecision" == "" ]
			then
				saved=1
				echo "$saved" > "$seriesDir/${dir[$count]}/saved"
				echo "-=- Saved file reset."
			else
				echo "-!- Reset of saved file not chosen, exiting as file is currently non-valid (needs integer >=1)."
				exit 1
			fi
		fi
		saved=$(( $saved - 1 )) # make it be the number of episodes watched, instead of next
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
		echo "$(($count + $humanBit)). ${dir[$count]} [$saved/$total]" >> /tmp/series/presentableSeries # present the uncomfortable to press 0 into a 1
		count=$(( $count + 1 ));
	done
	echo -e "\n";
	cat /tmp/series/presentableSeries
}
function checkNextEpisode {
	if	[ "$(cat saved)" -le "$(cat /tmp/series/listpure | wc -l)" ]
	then
		nextEpisodeAvailable=true;
	else
		nextEpisodeAvailable=false;
	fi
}

##########################################################

function loadConfig {
	# loads variables needed from the config file
	if [ -f $configFile ]
	then
		# TODO: Add if conditions for getting DirectoryWatched when "-x" is supplied; also add it above for creating the config file
		seriesDir="$(grep 'Directory:' $configFile | cut -f2 -d ':')"
		player="$(grep 'Player:' $configFile | cut -f2 -d ':')"
	else
		echo "-!- No config file to load!"
	fi

	# Verify /tmp is writable and make a tmp folder there available
	openCleanTemp;

}
function openCleanTemp {
	# Clean the temp folder we use if there is one, create otherwise. This way works better as placing traps on exit doesn't work well with sourcing scripts.
	if [ -e /tmp/series ]
	then
		rm -rf /tmp/series/*
	else
		mkdir /tmp/series
	fi

	# Error handling
	if [ $? != 0 ]
	then
		echo "-!- Error: Please make sure /tmp is writeable."
		kill -SIGINT $$ # exit doesn't work, as the script is called with source
	fi
}
# it prepares a "/tmp/series/list" file in advance, then prints its contents
function showGuide {
	# prints everything up to the next episode
	lastDone=$(( $(cat saved) - 1 )) # gets the next episode to watch from saved, then subtracts one for last ep watched
	cat /tmp/series/listpure | head -$lastDone > /tmp/series/list

	# prints the structure surrounding and the name of the next episode
	echo "" >> /tmp/series/list # literally makes a new line, better outlook
	if [ $(cat saved) -le $(cat /tmp/series/listpure | wc -l) ]
	then
	  echo "> $(cat /tmp/series/listpure | head -$(cat saved) | tail -1)" >> /tmp/series/list
	else
	  echo "> Umad? No next episode available" >> /tmp/series/list
	fi
	echo "" >> /tmp/series/list

	# prints everything after the singled out episode
	savedVar=$(cat saved)
	savedUp=$(($savedVar + 1 ))
	cat /tmp/series/listpure | tail -n +$savedUp >> /tmp/series/list

	# do the actual printing from file, displayRange refines the outlook for large series
	displayRange="$(( $(cat saved) + 20 ))"
	cat /tmp/series/list | head -$displayRange
	rm /tmp/series/list /tmp/series/listpure
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
		echo "-!- Use from ~ (home) for main menu, use from a series in $seriesDir for direct play."
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
		#Fix needed to add ./series to alias and not ./corefunc. Should be fine unless someone goes around changing the name of corefunc.sh!
		mainScriptName=$(readlink -m "${BASH_SOURCE[0]}" | sed s/corefunc/series/)
		echo "alias series='source $mainScriptName'" >> ~/.bashrc
    	echo "-=- Alias appended to $HOME/.bashrc"
	else
		echo "-=- A series alias is already present in .bashrc, not adding anything"
	fi

	# Create the config directory if it's not there, so creating the file works. Create even ~/.config if not there (check first).
	configDir="$HOME/.config/series"
	if [ ! -e "$HOME/.config" ]; then
		mkdir "$HOME/.config"
		echo "-=- .config directory created under home."
	fi
	if [ ! -e $configDir ];then
		mkdir $configDir
		echo "-=- $configDir created."
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
	find . -iregex ".*\.\($formats\)" | grep -vi sample | sort > /tmp/series/listpure
	# ensure the saved file exists, if not, create one
	if [ ! -f saved ]
	then
	  echo 1 > saved
	  echo "-=- Initialized new series from episode 1."
	fi
}
# Continuous playback and countdown between plays, for when endless mode is specified
function loopPlaying {
	# TODO: Make an improvised do while loop, like...
	# TODO: i=0; while $i -le 2 ; echo gg && ((i++)); do :; done
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
# interpret user flags given into parameters to pass to player
function fillParams {
	if [ $volmax ]; then
		params="-softvol-max 600 -softvol"
	fi
}
# having the details of the episode settled, play the desired file
function playNext {
	epnumber=$(cat saved)
	checkNextEpisode;
	fillParams;
	if $nextEpisodeAvailable # if there is at least one more episode
	then
	  # input is taken from /dev/null to make sure a nasty 'q' keystroke doesn't get queue up in between episodes
	  $player "$(cat /tmp/series/listpure | head -$epnumber | tail -1)" $params < /dev/null
	fi
}
# Select a random episode only from those not watched in the current batch
function selectRankedRandomEpisode {
	# Roll a random number out of the total
	function rollRandomEpisode {
		echo "-Debug- Rerolling $epnumber";
		epnumber="$(( $RANDOM % $totalEpisodesAvailable +1 ))"
	}
	# Episodes that are not eligible for next playtime
	function getSpentEpisodeList {
		# Create/reset an empty indexed array
		spentEpisodes=()
		# Create the file if not there
		if [ ! -e 'rr-spent-episodes' ]; then
			touch rr-spent-episodes
			echo "-=- Initializing spent episode list."
		fi

		# Blacklist every episode noted down in the file
		for line in $(cat rr-spent-episodes); do
			spentEpisodes+=($line)
		done

		# If all the episodes are spent, start over
		if [ ${#spentEpisodes[@]} -ge $totalEpisodesAvailable ]; then
			rm rr-spent-episodes
			getSpentEpisodeList;
		fi
	}
	function markEpisodeAsSpent {
		epToInvalidate=$1
		echo "$epToInvalidate" >> rr-spent-episodes
	}

 	function checkIfEpisodeIsFresh {
		# Assume episode is fresh then prove it's not by matching to the list
		episodeIsFresh= True
		suspectEpisode=$1
		for s in $spentEpisodes; do
			if [ $suspectEpisode -eq $s ]; then
				episodeIsFresh= False
				break
			fi
	  done
	}
	function obtainUnseenEpisode {
		# As long as the episode rolled is matched on the list of spent ones, reroll again
		until $episodeIsFresh; do
			rollRandomEpisode;
			checkIfEpisodeIsSpent $epnumber;
		done
	}

	# Gather how many we have in total
	totalEpisodesAvailable="$(cat /tmp/series/listpure | wc -l)"

	# Get info about which episodes are to be ignored
	getSpentEpisodeList;

	# Get an episode we haven't seen in this batch
	obtainUnseenEpisode;

	# Mark episode as spent now that we're going to see it
	markEpisodeAsSpent $epnumber;

}
function playRankedRandom {
	# Pick and play a rankedRandom episode
	fillParams;
	selectRankedRandomEpisode;
	$player "$(cat /tmp/series/listpure | head -$epnumber | tail -1)" $params < /dev/null
}
# after everything is completed, increment the next episode counter
function incrementSaved {
	if [ $(cat saved) -le $(cat /tmp/series/listpure | wc -l) ]
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
# Verify that there are no missing episodes from a regular E09,E10,E11, etc. sequence
function sequentialConsistencyCheck {

	regex='(?<=S..E)..'
	episodeExpected=1
	cat /tmp/series/listpure | while read line; do
	#for line in $(cat /tmp/series/listpure); do
		episodeCurrent="$(echo "$line" | grep -oP $regex)"
		# Sanity check that episodes can be found, by checking if value is integer
		if ! [[ "$episodeCurrent" =~ ^[0-9]+$ ]]
		then
			echo "-!- Series doesn't seem to follow the standard S01E01 structure - quitting. Disable option with -q."
			quit
			break
		fi

		if [ ! $episodeCurrent -eq $episodeExpected ]; then
			echo "-!- Inconsistency in episode sequence found! Expected E$episodeExpected but found $line! Correct or disable with -q."
			quit
			break
		fi
		episodeExpected=$(( episodeExpected + 1 ))
	done
	echo "-=- Sequential consistency check passed."
}
