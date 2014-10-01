function __static__SummarizeDirectoryContents(){

	#TODO: USE VARIABLE PREFIXES FOR FILES TO BE SEARCHED FOR!!

	echo "Directory $WORK_DIR_WITH_BETAFOLDERS"/b"$BETA contains:"
	echo "conf files:"
	ls $WORK_DIR_WITH_BETAFOLDERS"/b"$BETA/conf* | wc -l
	echo "rlxd files:"
	ls $WORK_DIR_WITH_BETAFOLDERS"/b"$BETA/rlxd* | wc -l
	echo "others:"
	ls $WORK_DIR_WITH_BETAFOLDERS"/b"$BETA/* | egrep -v "conf\.[[:digit:]]{4}|rlxd\.[[:digit:]]{4}"

	echo ""

	echo "Directory $HOME_DIR_WITH_BETAFOLDERS"/b"$BETA contains:"
	echo "muiPiT_*.out files:"
	ls $HOME_DIR_WITH_BETAFOLDERS"/b"$BETA/muiPiT_*.out | wc -l
	echo "output.data.* files:"
	ls $HOME_DIR_WITH_BETAFOLDERS"/b"$BETA/output.data.* | wc -l
	echo "polykovloop_dir0.* files:"
	ls $HOME_DIR_WITH_BETAFOLDERS"/b"$BETA/polykovloop_dir0.* | wc -l
	echo "others:"
	ls $HOME_DIR_WITH_BETAFOLDERS"/b"$BETA/* | egrep -v "output\.data\..*|muiPiT_.*\.out|polykovloop_dir0\..*"
}

function __static__EmptyBeta(){

	echo "rm $HOME_DIR_WITH_BETAFOLDERS"/b"$BETA/*"
	rm $HOME_DIR_WITH_BETAFOLDERS"/b"$BETA/*
	echo "rm $WORK_DIR_WITH_BETAFOLDERS"/b"$BETA/*"
	rm $WORK_DIR_WITH_BETAFOLDERS"/b"$BETA/*
	rm $WORK_DIR_WITH_BETAFOLDERS"/b"$BETA"/.nstore_counter"
}

function EmptyBetaDirectories(){

	for BETA in ${BETAVALUES[@]}; do

		echo ""
		echo "--------------------------------------------------------------------------------"
		echo ""
		__static__SummarizeDirectoryContents

		echo "Are you sure you want to empty the directory b$BETA?"
		echo "This deletion cannot be undone!"
		echo "Please enter: YES or NO"

		while read CONFIRM; do

			if [ $CONFIRM = "YES" ]; then

				echo ""
				echo "emptying $BETA..."
				echo ""
				__static__EmptyBeta
				break

			elif [ $CONFIRM = "NO" ]; then

				echo ""
				echo "Maintaining $BETA..."
				echo ""
				break
			else
				echo "Please enter: YES or NO"
			fi
		done
		echo ""
		echo "--------------------------------------------------------------------------------"
		echo ""
	done		
}
