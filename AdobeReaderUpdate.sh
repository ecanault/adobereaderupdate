#!/bin/bash

#####################################################################################################
#
# ABOUT THIS PROGRAM
#
# NAME
#   AdobeReaderUpdate.sh -- Installs or updates Adobe Reader
#
# SYNOPSIS
#   sudo AdobeReaderUpdate.sh
#
# EXIT CODES
#   0 - Adobe Reader DC installed successfully or is current
#   3 - Adobe Reader DC NOT installed
#   4 - Adobe Reader DC update unsuccessful
#   5 - Adobe Reader (DC) is running or was attempted to be installed manually and user deferred install
#   6 - Not an Intel-based Mac
#
#
###
### Source: https://github.com/stevemillermac/adobereaderupdate/blob/master/AdobeReaderUpdate.sh
###
#
#
####################################################################################################
#
# HISTORY
#   Based on the threads:
#   https://jamfnation.jamfsoftware.com/viewProductFile.html?id=42&fid=761
#   https://jamfnation.jamfsoftware.com/discussion.html?id=12042
#   Version: 1.7 - Netopie 2018
#
#   - v.1.0 Joe Farage, 23.01.2015
#   - v.1.1 Joe Farage, 08.04.2015 : support for new Adobe Acrobat Reader DC
#   - v.1.2 Steve Miller, 15.12.2015
#   - v.1.3 Luis Lugo, 07.04.2016 : updates both Reader and Reader DC to the latest Reader DC
#   - v.1.4 Luis Lugo, 28.04.2016 : attempts an alternate download if the first one fails
#	- v.1.5	Steve Miller, 15.12.2016 : Adobe checking if installed is greater than online, exit code updated
#	- v.1.6	Steve Miller, 17.02.2017 : Fixed install when not installed, changed to touch command for log creation.
#	- v.1.7 Netopie, 01.03.2018 : Use the latest update installer if Reader DC is already installed
#								  Install the latest version if Reader DC is not installed
#								  Option to remove current installation
#
####################################################################################################
# Script to download and install Adobe Reader DC.
# Only works on Intel systems.

# Setting variables
readerProcRunning=0
currentUser=$(stat -f%Su /dev/console)

# Echo function
echoFunc () {
    # Date and Time function for the log file
    fDateTime () { echo $(date +"%a %b %d %T"); }

    # Title for beginning of line in log file
    Title="InstallLatestAdobeReader:"

    # Header string function
    fHeader () { echo $(fDateTime) $(hostname) $Title; }

    # Check for the log file
    if [ -e "/Library/Logs/AdobeReaderDCUpdateScript.log" ]; then
        echo $(fHeader) "$1" >> "/Library/Logs/AdobeReaderDCUpdateScript.log"
    else
        touch "/Library/Logs/AdobeReaderDCUpdateScript.log"
        if [ -e "/Library/Logs/AdobeReaderDCUpdateScript.log" ]; then
            echo $(fHeader) "$1" >> "/Library/Logs/AdobeReaderDCUpdateScript.log"
        else
            echo "Failed to create log file, writing to JAMF log"
            echo $(fHeader) "$1" >> "/var/log/jamf.log"
        fi
    fi

    # Echo out
    echo $(fDateTime) ": $1"
}

# Exit function
# Exit code examples: http://www.tldp.org/LDP/abs/html/exitcodes.html
exitFunc () {
    case $1 in
        0) exitCode="0 - SUCCESS: Adobe Reader up to date with version $2";;
        #1) exitCode="0 - INFO: Adobe Reader DC is current! Version: $2";;
        3) exitCode="3 - INFO: Adobe Reader DC NOT installed!";;
        4) exitCode="4 - ERROR: Adobe Reader DC update unsuccessful, version remains at $2";;
        5) exitCode="5 - ERROR: Adobe Reader (DC) is running or was attempted to be installed manually and user deferred install.";;
        6) exitCode="6 - ERROR: Not an Intel-based Mac.";;
        *) exitCode="$1";;
    esac
    echoFunc "Exit code: $exitCode"
    echoFunc "======================== Script Complete ========================"
    exit $1
}

# Check to see if Reader or Reader DC is running
readerRunningCheck () {
	sleep 10
    processNum=$(ps aux | grep "Adobe Acrobat Reader DC" | wc -l)
    if [ $processNum -gt 1 ]
    then
        # Reader is running, prompt the user to close it or defer the upgrade
        readerRunning
    else
        # Check if the older Adobe Reader is running
        processNum=$(ps aux | grep "Adobe Reader" | wc -l)
        if [ $processNum -gt 1 ]
        then
            # Reader is running, prompt the user to close it or defer the upgrade
            readerRunning
        else
            # Adobe Reader shouldn't be running, continue on
            echoFunc "Adobe Acrobat Reader (DC) doesn't appear to be running!"
        fi
    fi
}

# If Adobe Reader is running, prompt the user to close it
readerRunning () {
    echoFunc "Adobe Acrobat Reader (DC) appears to be running!"
    hudTitle="Mise à jour Adobe Acrobat Reader DC"
    hudDescription="Adobe Acrobat Reader doit être mis à jour, supprimé ou réinstallé. Veuillez quitter l'application et cliquer sur 'Continuer'. Cliquez sur 'Plus tard' pour effectuer cette opération ultérieurement.
Contactez le support Netopie pour plus d'informations."
	hudIcon="/Applications/Adobe Acrobat Reader DC.app/Contents/Resources/ACR_App.icns"

    jamfHelperPrompt=`/Library/Application\ Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfHelper -windowType hud -lockHUD -title "$hudTitle" -description "$hudDescription" -icon "$hudIcon" -button1 "Continuer" -button2 "Plus tard" -defaultButton 1`

    case $jamfHelperPrompt in
        0)
            echoFunc "Proceed selected"
            readerProcRunning=1
            readerRunningCheck
        ;;
        2)
            echoFunc "Deferment Selected"
            exitFunc 5
        ;;
        *)
            echoFunc "Selection: $?"
            exitFunc 3 "Unknown"
        ;;
    esac
}

# Let the user know we're installing Adobe Acrobat Reader DC manually
readerUpdateMan () {
    echoFunc "Letting the user know we're installing Adobe Acrobat Reader DC manually!"
    hudTitle="Mise à jour Adobe Acrobat Reader DC"
    hudDescription="Adobe Acrobat Reader doit être mis à jour, supprimé ou réinstallé. Veuillez cliquer sur 'Continuer' pour télécharger et installer l'application. Cliquez sur 'Plus tard' pour effectuer cette opération ultérieurement.
Contactez le support Netopie pour plus d'informations."
	hudIcon="/Applications/Adobe Acrobat Reader DC.app/Contents/Resources/ACR_App.icns"

    jamfHelperPrompt=`/Library/Application\ Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfHelper -windowType hud -lockHUD -title "$hudTitle" -description "$hudDescription" -icon "$hudIcon" -button1 "Plus tard" -button2 "Continuer" -defaultButton 1 -timeout 60 -countdown`

    case $jamfHelperPrompt in
        0)
            echoFunc "Deferment Selected or Window Timed Out"
            exitFunc 5
        ;;
        2)
            echoFunc "Proceed selected"
            readerRunningCheck
        ;;
        *)
            echoFunc "Selection: $?"
            exitFunc 3 "Unknown"
        ;;
    esac
}

# Download and installation function
installReader () {
	echoFunc "Current Reader DC version: ${currentinstalledapp} ${currentinstalledver}"
	echoFunc "Available Reader DC version: ${latestver} => ${ARCurrVersNormalized}"
	echoFunc "Downloading newer version."
	curl -s -o /tmp/${filename}.dmg ${url}
	case $? in
		0)
			echoFunc "Checking if the file exists after downloading."
			if [ -e "/tmp/${filename}.dmg" ]; then
				readerFileSize=$(du -k "/tmp/${filename}.dmg" | cut -f 1)
				echoFunc "Downloaded File Size: $readerFileSize kb"
			else
				echoFunc "File NOT downloaded!"
				return 3
			fi
			echoFunc "Checking if Reader is running one last time before we install"
			readerRunningCheck
			echoFunc "Mounting installer disk image."
			hdiutil attach /tmp/${filename}.dmg -nobrowse -quiet
			echoFunc "Installing..."
			installer -pkg /Volumes/${filename}/${filename}.pkg -target / > /dev/null

			sleep 10
			echoFunc "Unmounting installer disk image."
			umount "/Volumes/${filename}"
			sleep 10
			echoFunc "Deleting disk image."
			rm /tmp/${filename}.dmg

			# double check to see if the new version got updated
			if [ -e "/Applications/Adobe Acrobat Reader DC.app" ]; then
				newlyinstalledver=`/usr/bin/defaults read /Applications/Adobe\ Acrobat\ Reader\ DC.app/Contents/Info CFBundleShortVersionString`
				if [ "${latestvernorm}" = "${newlyinstalledver}" ]; then
					echoFunc "SUCCESS: Adobe Reader has been updated to version ${newlyinstalledver}"
#					echoFunc "SUCCESS: Adobe Reader has been updated to version ${newlyinstalledver}, issuing JAMF recon command"
#					jamf recon
					if [ $readerProcRunning -eq 1 ];
					then
						hudTitle="Adobe Reader DC mis à jour"
						hudDescription="Adobe Reader DC a été mis à jour en version ${newlyinstalledver}."
						hudIcon="/Applications/Adobe Acrobat Reader DC.app/Contents/Resources/ACR_App.icns"
						/Library/Application\ Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfHelper -windowType hud -lockHUD -title "$hudTitle" -description "$hudDescription" -icon "$hudIcon" -button1 "OK" -defaultButton 1
					fi
						return 0
				else
                       return 4
				fi
			else
				return 3
			fi
		;;
		*)
			echoFunc "Curl function failed on primary download! Error: $?. Review error codes here: https://curl.haxx.se/libcurl/c/libcurl-errors.html"
			echoFunc "Attempting alternate download from https://admdownload.adobe.com/bin/live/AdobeReader_dc_en_a_install.dmg"
			curl -s -o /tmp/AdobeReader_dc_en_a_install.dmg https://admdownload.adobe.com/bin/live/AdobeReader_dc_en_a_install.dmg
			case $? in
			0)
				echoFunc "Checking if the file exists after downloading."
				if [ -e "/tmp/AdobeReader_dc_en_a_install.dmg" ]; then
					readerFileSize=$(du -k "/tmp/AdobeReader_dc_en_a_install.dmg" | cut -f 1)
					echoFunc "Downloaded File Size: $readerFileSize kb"
				else
					echoFunc "File NOT downloaded!"
					return 4
				fi
				echoFunc "Checking if Reader is running one last time before we install"
				readerRunningCheck
				echoFunc "Checking with the user if we should proceed"
				readerUpdateMan
				echoFunc "Mounting installer disk image."
				hdiutil attach /tmp/AdobeReader_dc_en_a_install.dmg -nobrowse -quiet
				echoFunc "Installing..."
				/Volumes/Adobe\ Acrobat\ Reader\ DC\ Installer/Install\ Adobe\ Acrobat\ Reader\ DC.app/Contents/MacOS/Install\ Adobe\ Acrobat\ Reader\ DC
				sleep 10
				echoFunc "Unmounting installer disk image."
				umount "/Volumes/Adobe Acrobat Reader DC Installer"
				sleep 10
				echoFunc "Deleting disk image."
				rm /tmp/AdobeReader_dc_en_a_install.dmg

				# double check to see if the new version got updated
				if [ -e "/Applications/Adobe Acrobat Reader DC.app" ]; then
				newlyinstalledver=`/usr/bin/defaults read /Applications/Adobe\ Acrobat\ Reader\ DC.app/Contents/Info CFBundleShortVersionString`
					if [ "${latestvernorm}" = "${newlyinstalledver}" ]; then
						echoFunc "SUCCESS: Adobe Reader has been updated to version ${newlyinstalledver}"
#						echoFunc "SUCCESS: Adobe Reader has been updated to version ${newlyinstalledver}, issuing JAMF recon command"
#						jamf recon
						return 0
					else
						return 4
					fi
				else
					return 4
				fi
			;;
			*)
				echoFunc "Curl function failed on alternate download! Error: $?. Review error codes here: https://curl.haxx.se/libcurl/c/libcurl-errors.html"
				return 4
			;;
		esac
		;;
	esac
}

# Uninstallation function
removeReader () {
	hudTitle="Suppression Adobe Acrobat Reader DC"
    hudDescription="Adobe Acrobat Reader va être supprimé. Voulez-vous continuer ?
Contactez le support Netopie pour plus d'informations."
	hudIcon="/Applications/Adobe Acrobat Reader DC.app/Contents/Resources/ACR_App.icns"

    jamfHelperPrompt=`/Library/Application\ Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfHelper -windowType hud -lockHUD -title "$hudTitle" -description "$hudDescription" -icon "$hudIcon" -button1 "Oui" -button2 "Non" -defaultButton 1`

    case $jamfHelperPrompt in
        0)
            echoFunc "Proceed selected"
            readerRunningCheck
        ;;
        2)
            echoFunc "Deferment Selected"
            exitFunc 5
        ;;
        *)
            echoFunc "Selection: $?"
            exitFunc 3 "Unknown"
        ;;
    esac

	IFS=","
	launchAgent="com.adobe.ARMDCHelper.*.plist"
	launchDaemons="com.adobe.ARMDC.Communicator.plist,\
com.adobe.ARMDC.SMJobBlessHelper.plist"
	readerApp="/Applications/Adobe Acrobat Reader DC.app"
	readerRsc="/Library/Application Support/Adobe/ARMDC,\
/Library/Application Support/Adobe/ARMNext,\
/Library/Application Support/Adobe/HelpCfg,\
/Library/Application Support/Adobe/Reader/DC,\
/Library/Internet Plug-Ins/AdobePDFViewer.plugin,\
/Library/Internet Plug-Ins/AdobePDFViewerNPAPI.plugin,\
/Library/PrivilegedHelperTools/com.adobe.ARMDC.Communicator,\
/Library/PrivilegedHelperTools/com.adobe.ARMDC.SMJobBlessHelper,\
/Users/${currentUser}/Library/Application Support/Adobe/AcroCef,\
/Users/${currentUser}/Library/Application Support/Adobe/Acrobat/DC,\
/Users/${currentUser}/Library/Application Support/Adobe/Linguistics,\
/Users/${currentUser}/Library/Application Support/CEF"
	pkgRcpt="/private/var/db/receipts/com.adobe.RdrServicesUpdater.*,\
/private/var/db/receipts/com.adobe.acrobat.AcroRdrDCUpd*,\
/private/var/db/receipts/com.adobe.acrobat.DC.*,\
/private/var/db/receipts/com.adobe.armdc.*"
	userPrefs="/Users/${currentUser}/Library/Preferences/com.adobe.Acrobat-Customization-Wizard-DC.plist,\
/Users/${currentUser}/Library/Preferences/com.adobe.AdobeRdrCEFHelper.plist,\
/Users/${currentUser}/Library/Preferences/com.adobe.Reader.plist,\
/Users/${currentUser}/Library/Preferences/com.adobe.com.adobe.acrobat.AcroPatchInstall.plist"

	# Stop and remove daemons and agents
	echoFunc "Stop and remove launchd agents"
	sudo -u "${currentUser}" launchctl unload /Library/LaunchAgents/${launchAgent} 2>/dev/null
	rm -f /Library/LaunchAgents/${launchAgent}
	echoFunc "Stop and remove launchd daemons"
	for i in ${launchDaemons}; do
		launchctl unload /Library/LaunchDaemons/${i} 2>/dev/null
		rm -f /Library/LaunchDaemons/${i}
	done

	# Remove application
	echoFunc "Remove application"
	rm -rf "${readerApp}"

	# Remove ressources
	echoFunc "Remove ressources"
	for i in ${readerRsc}; do
		rm -rf "${i}"
	done

	# Remove packages receipts
	echoFunc "Remove packages receipts"
	for i in ${pkgRcpt}; do
		rm -rf "${i}"
	done
	
	# Remove user preferences
	if [ "${1}" = "fullremove" ]; then
		echoFunc "Remove user preferences"
		for i in ${userPrefs}; do
			rm -rf "${i}"
		done
	fi
}

echoFunc ""
echoFunc "======================== Starting Script ========================"

# Uninstall Reader DC
if [ "${1}" = "remove" ]; then
	echoFunc "Execution using option ${1}: will remove application and components"
	removeReader ${1}
	exitFunc 3 "Reader DC removed"
elif [ "${1}" = "fullremove" ]; then
	echoFunc "Execution using option ${1}: will remove application, components and user preferences"
	removeReader ${1}
	exitFunc 3 "Reader DC removed"
elif [ "${1}" = "reinstall" ]; then
	echoFunc "Execution using option ${1}: will remove application and components, and will reinstall the latest version"
	removeReader ${1}
fi

# Are we running on Intel?
if [ '`/usr/bin/uname -p`'="i386" -o '`/usr/bin/uname -p`'="x86_64" ]; then
    ## Get OS version and adjust for use with the URL string
    OSvers_URL=$( sw_vers -productVersion | sed 's/[.]/_/g' )

    ## Set the User Agent string for use with curl
    userAgent="Mozilla/5.0 (Macintosh; Intel Mac OS X ${OSvers_URL}) AppleWebKit/535.6.2 (KHTML, like Gecko) Version/5.2 Safari/535.6.2"

    # Get the latest version of Reader available from Adobe's About Reader page.
    latestverfull=``
    latestverupd=``
    while [ -z "$latestverfull" ] || [ -z "$latestverupd" ]
    do
        latestverfull=`curl -s -L -A "$userAgent" https://get.adobe.com/reader/ | grep "<strong>Version" | /usr/bin/sed -e 's/<[^>][^>]*>//g' | /usr/bin/awk '{print $2}' | cut -c 3-14`
    	latestverupd=`curl -s http://armmf.adobe.com/arm-manifests/mac/AcrobatDC/reader/current_version.txt`
    done

    echoFunc "Latest Adobe Reader DC Version is: $latestverfull (full installer)"
    echoFunc "Latest Adobe Reader DC Version is: $latestverupd (update installer)"

    # Get the version number of the currently-installed Adobe Reader, if any.
    if [ -e "/Applications/Adobe Acrobat Reader DC.app" ]; then
        currentinstalledapp="Reader DC"
        currentinstalledver=`/usr/bin/defaults read /Applications/Adobe\ Acrobat\ Reader\ DC.app/Contents/Info CFBundleShortVersionString`
        echoFunc "Current Reader DC installed version is: $currentinstalledver"
        if [ "${latestverupd}" \< "${currentinstalledver}" ] || [ "${latestverupd}" = "${currentinstalledver}" ]; then
            exitFunc 0 "${currentinstalledapp} ${currentinstalledver}"
        else
            # Not running the latest DC version, check if Reader is running
            readerRunningCheck
        fi
        latestvernorm=`echo ${latestverupd}`
    elif [ -e "/Applications/Adobe Reader.app" ]; then
        currentinstalledapp="Reader"
        currentinstalledver=`/usr/bin/defaults read /Applications/Adobe\ Reader.app/Contents/Info CFBundleShortVersionString`
        echoFunc "Current Reader installed version is: $currentinstalledver"
        processNum=$(ps aux | grep "Adobe Reader" | wc -l)
        if [ $processNum -gt 1 ]
        then
            readerRunning
        else
            echoFunc "Adobe Reader doesn't appear to be running!"
        fi
        latestvernorm=`echo ${latestverupd}`
    else
        currentinstalledapp="None"
        currentinstalledver="N/A"
        echoFunc "Adobe Reader (DC) Version is not installed, beginning install now..."
        latestvernorm=`echo ${latestverfull}`
    fi

	# Build URL and dmg file name
	if ([ -e "/Applications/Adobe Acrobat Reader DC.app" ] || [ -e "/Applications/Adobe Reader.app" ]) && [ ${latestverupd} != ${latestverfull} ]; then
		ARCurrVersNormalized=$(echo $latestverupd | sed -e 's/[.]//g' )
		echoFunc "ARCurrVersNormalized: $ARCurrVersNormalized (update installer)"
		url1="http://ardownload.adobe.com/pub/adobe/reader/mac/AcrobatDC/${ARCurrVersNormalized}/AcroRdrDCUpd${ARCurrVersNormalized}_MUI.dmg"
		url2=""
		url=`echo "${url1}${url2}"`
		echoFunc "Latest version of the URL is: $url (update installer)"
		filename="AcroRdrDCUpd${ARCurrVersNormalized}_MUI"
		latestver=`echo ${latestverupd}`
	else
		ARCurrVersNormalized=$(echo $latestverfull | sed -e 's/[.]//g' )
		echoFunc "ARCurrVersNormalized: $ARCurrVersNormalized (full installer)"
		url1="http://ardownload.adobe.com/pub/adobe/reader/mac/AcrobatDC/${ARCurrVersNormalized}/AcroRdrDC_${ARCurrVersNormalized}_MUI.dmg"
		url2=""
		url=`echo "${url1}${url2}"`
		echoFunc "Latest version of the URL is: $url (full installer)"
		filename="AcroRdrDC_${ARCurrVersNormalized}_MUI"
		latestver=`echo ${latestverfull}`
	fi

    # Compare the two versions, if they are different or Adobe Reader is not present then download and install the new version.
    if [ "${currentinstalledver}" != "${latestvernorm}" ]; then
		installReader
		returnvalue=$?
		if [ ${returnvalue} == 0 ]; then
			if [ ${latestverupd} != ${newlyinstalledver} ]; then
		        currentinstalledapp="Reader DC"
        		currentinstalledver=`/usr/bin/defaults read /Applications/Adobe\ Acrobat\ Reader\ DC.app/Contents/Info CFBundleShortVersionString`
        		latestvernorm=`echo ${latestverupd}`
				ARCurrVersNormalized=$(echo $latestverupd | sed -e 's/[.]//g' )
				echoFunc "ARCurrVersNormalized: $ARCurrVersNormalized (update installer)"
				url1="http://ardownload.adobe.com/pub/adobe/reader/mac/AcrobatDC/${ARCurrVersNormalized}/AcroRdrDCUpd${ARCurrVersNormalized}_MUI.dmg"
				url2=""
				url=`echo "${url1}${url2}"`
				echoFunc "Latest version of the URL is: $url (update installer)"
				filename="AcroRdrDCUpd${ARCurrVersNormalized}_MUI"
				latestver=`echo ${latestverupd}`
				installReader
				returnvalue=$?
				if [ ${returnvalue} == 0 ]; then
					exitFunc "${returnvalue}" "${newlyinstalledver}"
				else
					exitFunc "${returnvalue}" "${currentinstalledapp} ${currentinstalledver}"
				fi
			fi
			exitFunc "${returnvalue}" "${newlyinstalledver}"
		else
			exitFunc "${returnvalue}" "${currentinstalledapp} ${currentinstalledver}"
		fi
    else
        # If Adobe Reader DC is up to date already, just log it and exit.
        exitFunc 0 "${currentinstalledapp}" "${currentinstalledver}"
    fi
else
    # This script is for Intel Macs only.
    exitFunc 5
fi
