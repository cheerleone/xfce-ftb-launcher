#!/bin/bash

# XFCE - FTB Artifact Fix (XFart.f?)
# Copyright 2014 RWM.
# License: GPL-V2.0

# This script disables XFCE compositing prior to executing the FTB Launcher,
# we redirect the launcher output to a logfile and parse for a string that
# indicates the launcher has fully loaded, then wm compositing is re-enabled.

# This addresses a recent bug between the FTB Launcher and XFCE that would leave
# an artifact on the upper left corner of the screen until FTB is closed.

# It was considered to respect the compositor off/false state prior to running,
# however, it was not fathomable why someone would use this script when
# their choice was to have compositing off.

# -- Globals -------------------------------------------------------------------

    launcherLoaded=false # launcher state tracking.

# -- Constants -----------------------------------------------------------------

    readonly version="1.1.0.beta" # major.minor.point.stage
    readonly workingDir=$HOME/Games/ftb # FTB Launcher Location
    readonly ftbFileName=FTB_Launcher.jar # FTB jar file to launch
    readonly launcherLogFile=launcher.log # FTB Launcher - per launch log
    
    # note, advanced optoins for the minecraft client are set in the Launcher.
    
# -- Functions -----------------------------------------------------------------

function compositorOn() {
    # enable xfce compositing.
    xfconf-query -c xfwm4 -p /general/use_compositing -s true
}

function compositorOff() {
    # disable xfce compositing.
    xfconf-query -c xfwm4 -p /general/use_compositing -s false
}

function deleteOldLog() {
    # delete previous launcher logfile if it exists.
    if [ -f $workingDir/$launcherLogFile ]; then
        echo "[$0] deleting log"
        rm $workingDir/$launcherLogFile > /dev/null
    fi
}

function checkLog() {
    # wait for logfile to exist.
    until [ -f $workingDir/$launcherLogFile ]; do
        sleep 0.5;
    done    

    # check if logfile contains specified text that indicates the launcher
    # has loaded.
    cat $workingDir/$launcherLogFile | grep "Launcher Startup took" > /dev/null
    if [ "$?" = "0" ]; then
        launcherLoaded=true
    fi
}

function enableCompositorOnLoad() {    
    # check once per 0.5 seconds if FTB Launcher has loaded.
    echo "[$0] waiting for launcher to fully load"
    echo -n "[$0] "
    while [ $launcherLoaded = false ]; do        
        checkLog;
        echo -n .
        sleep 0.5;
    done
    
    # Now that FTB is running, notify user, then re-enable compositor.
    echo -e "\n[$0] launcher loaded"

    # re-enable compositing
    echo "[$0] enabling compositor"
    compositorOn;
}

# -- Main Function -------------------------------------------------------------

function main() {  
    # delete old launcher logfile.
    deleteOldLog;
    
    # disable xfce compositing.
    echo "[$0] disabling compositor"
    compositorOff;
    
    # fork into backdround, disable, then re-enable xfce compositing when FTB
    # is detected as running.
    enableCompositorOnLoad &
    
    # set working directory for FTB.
    cd $workingDir
    
    # start FTB launcher.
    echo "[$0] starting launcher"
    java -jar $ftbFileName > $workingDir/$launcherLogFile
    
    # force compositor on. State could exist if Launcher failed to fully load.
    echo "[$0] force enabling compositor ;P"
    compositorOn;

    # clean up orphaned process.
    pkill -P $$

    echo -e "[$0] exit\n"
}

# -- Main Call -----------------------------------------------------------------

main;
exit 0;
