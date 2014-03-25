# Supplementary file to series.sh, contains a majority of the functions used.

# Function level 1, lower level uses upper level functions
##########################################################
function presentSeries {
	# initialDir is already allocated, contains the directory the user specified as the directory, containing the series
	humanBit=1;
	entryCount=0;
	seriesAmount="$(ls $initialDir | wc -l)"
	while [ "$entryCount" -lt "$seriesAmount" ]
	do
	  nextToAdd="$(ls $initialDir | head -$(($entryCount+1)) | tail -1)"; # need to increase by one for getting 0 last files is not worth for first case
	  dir[$entryCount]=$nextToAdd;
	  entryCount=$(( $entryCount+1 ))
	done
	
	count=0;
	# the $entryCount variable is the amount of entries in $dir
	while [ "$count" -lt "$entryCount" ] 
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


# Function level 0
##################

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

# only used if ran from ~, seeks to the series directory wanted
function chooseDirFromHome {
	# eval is used so ~ is expanded
	eval initialDir=$(cat $scriptDir/config.seriesDir)
	player=$(cat $scriptDir/config.player)
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
		cd "$initialDir/${dir[$choice]}"
	# if the current directory is a descendant of the series directory, continue script, otherwise don't proceed as if it's a series directory.
	elif [ "$(pwd | grep $initialDir -o)" == "" ] || [ "$(pwd)" == "$initialDir" ] 
	then
		echo "-!- Use from ~ (home directory) for main menu, use from a series directory for direct play."
		kill -SIGINT $$ # exit doesn't work, as the script is called with source
	fi	
}
# gets the directory path from the file, asks user for first time setup if there it's not in the script's folder
function checkFirstRun {	
	# BASH_SOURCE[0] gets the script directory even if it was invoked with 'source <name>'
	if [ ! -f $scriptDir/config.seriesDir ] 
	then
		echo '-?- First time use detected. Please specify the pathname of the series directory. Example: ~/videos/series.'
		read initialDir
		# outputs to the a new file in the script's folder
		echo $initialDir > $scriptDir/config.seriesDir
		echo '-=- Series directory initialized.'
	fi
	if [ ! -f $scriptDir/config.player ]
	then
		echo '-?- Please specify the video player which you want to use. Example: mplayer'
		read player
		echo $player > $scriptDir/config.player
		echo '-=- $player selected.'
	fi
}
# create the file, containing the list of video files for that series
function populateList {
	find . -iregex ".*\.\($formats\)" | grep -vi sample | sort > listpure
}
# having the details of the episode settled, play the desired file
function playNext {
	# ensure the saved file exists, if not, create one
	if [ ! -f saved ]
	then
	  echo 1 > saved
	fi
	epnumber=$(cat saved)
	if [ "$(cat saved)" -le "$(cat listpure | wc -l)" ] # if there is at least one more episode
	then
	  #mplayer "$(cat listpure | head -$epnumber | tail -1)" -alang jpn,Japanese,eng,English -slang eng,English
	  $player "$(cat listpure | head -$epnumber | tail -1)" 
	fi
}
# after everything is completed, increment the next episode counter
function incrementSaved {
	if [ $(cat saved) -le $(cat listpure | wc -l) ]
	then
	  echo $(( $epnumber + 1 )) > saved
	fi
}
