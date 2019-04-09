#!/usr/bin/env bash
# 
#	This must run with `. configure.sh`, or else export won't work
# 

if  [ "$0" != "-bash" ]; then
	echo 'Warning: Please run this script using: ". configure.sh" to allow the enviornment variable ROKU_DEV_TARGET to be updated'
	echo ""
fi

touch .rokuTarget

targetip="$(head -1 .rokuTarget | cut -d\; -f1)"
targetmac="$(head -1 .rokuTarget | cut -d\; -f2)"
passwd="$(head -1 .rokuTarget | cut -d\; -f3)"

shouldUpdate=true;

# read args
shouldRunScript=true
shouldOpenTelnet=false
shouldOpenSG=false
shouldOpenWebInstaller=false
shouldShowHelp=false

while [ "$1" != "" ]; do
	if [ "$1" == "-t" ]; then shouldOpenTelnet=true; fi
	if [ "$1" == "-s" ]; then shouldOpenSG=true; fi
	if [ "$1" == "-w" ]; then shouldOpenWebInstaller=true; fi
	if [ "$1" == "-h" ]; then shouldShowHelp=true; fi
	if [ "$1" == "--help" ]; then shouldShowHelp=true; fi
	shift
done

# if it is help, then 
if [ "$shouldShowHelp" == "true" ]; then
	shouldRunScript=false
	echo "True[X] Roku Dev Helper"
	echo 'This must run with `. configure.sh`, or else export would not work'
	echo ""
	echo "Args:"
	echo "-t		Open BrightScript console"
	echo "-s		Open SceneGraph console"
	echo "-w		Open web Development Application Installer"
	echo "-h --help	Show current page"
fi

if [ "$shouldRunScript" == "true" ]; then
	if [ "$targetmac" == "" ]; then
		#first time set up, or trying to re-connect to another device
		echo "Add a Roku device"

		echo "Go to: Settings > Network > About"
		read -p 'IP Address: ' targetip
		
		echo ""
		echo "Roku's dev password, set as part of Developer Settings"
		read -sp 'Password: ' passwd

		echo ""
		echo "Looking up device mac address... This might take a second.";
		targetmac=$(arp -a | grep "$targetip" | head -1 | cut -d' ' -f4)

		echo "$targetip;$targetmac;$passwd" > .rokuTarget
		echo "Device Saved."
	else
		#ip not empty, try to connect
		echo "Updating device's IP Address..."

		arpResult=$(arp -a);

		targetip=$(echo "$arpResult" | grep -i "$targetmac" | head -1 | cut -d" " -f2 | sed "s/[^0-9.]//g")


		#check if we can ping to it
		echo "Pinging device..."
		ping -c1 -n -t1 "$targetip" > /dev/null 
		if [ $? -ne 0 ]; then
			targetip=""
		fi

		if [ "$targetip" == "" ]; then
			# roku's wired and wireless mac address seems to be off by 1
			macPrefix=$(echo $targetmac | cut -d':' -f1-5);
			macPostfix=$(echo $targetmac | cut -d':' -f6);
			
			macPostfixP1Dec=$(echo "ibase=16; $macPostfix + 1" | bc);
			macPostfixM1Dec=$(echo "ibase=16; $macPostfix - 1" | bc);
			
			macP1=$macPrefix:$(echo "obase=16; $macPostfixP1Dec" | bc);
			macM1=$macPrefix:$(echo "obase=16; $macPostfixM1Dec" | bc);

			targetmac=$macP1;
			targetip=$(echo "$arpResult" | grep -i "$targetmac" | cut -d" " -f2 | sed "s/[^0-9.]//g")


			if [ "$targetip" == "" ]; then
				targetmac=$macM1;
				targetip=$(echo "$arpResult" | grep -i "$targetmac" | cut -d" " -f2 | sed "s/[^0-9.]//g")
			fi


			# if ip address is still empty, probably the device is disconnected, exit with error
			if [ "$targetip" == "" ]; then
				echo "Error: device is not connected. Remove .rokuTarget file if you think this is an error."
				shouldUpdate=false;
			else 
			# ask user if it is really the right ip
				echo "Your device seems to have switched between wired and wireless connection";
				echo "Are you sure you want to use $targetip?";
				read -p  "(^C to exit, RETURN to continue)";
				if [ $? -ne 0 ]; then
		                        echo "Not saved. Remove .rokuTarget file if you need to redo the setup."
					shouldUpdate=false;
				fi
			fi

		fi

		if $shouldUpdate; then
			echo "$targetip;$targetmac;$passwd" > .rokuTarget
			echo "Updated"
		fi
	fi


	if [ "$shouldUpdate"=="true" ]; then
		echo "Updating ROKU_DEV_TARGET ($targetip) and DEVPASSWORD..."
		export ROKU_DEV_TARGET=$targetip
		export DEVPASSWORD=$passwd


		if [ "$shouldOpenTelnet" == "true" ]; then
			echo "opening BrightScript console"
			osascript -e 'tell application "Terminal" to do script "telnet '"$ROKU_DEV_TARGET"' 8085"'
		fi
		if [ "$shouldOpenSG" == "true" ]; then
			echo "opening SceneGraph console"
			osascript -e 'tell application "Terminal" to do script "telnet '"$ROKU_DEV_TARGET"' 8080"'
		fi
		if [ "$shouldOpenWebInstaller" == "true" ]; then
			echo "opening web Development Application Installer"
			open "http://$ROKU_DEV_TARGET"
		fi
	else
		echo "Updating ROKU_DEV_TARGET not updated"
	fi
fi




