#!/bin/bash

# XFCE - FTB Artifact Fix (XFart.f?)
# Copyright 2014 CheerLeone.
# License: GPL-V2.0

# This script disables XFCE compositing prior to executing the FTB Launcher,
# then when FTB minecraft JVM is running, compositing is enabled.

# This addresses a recent bug between the FTB Launcher and XFCE that would leave
# an artifact on the upper left corner of the screen until FTB is closed.

# Testing is done on the minecraft JVM and not the launcher due to the GUI delay
# between detectecting the launcher, and the launcher fully loading.

# It was considered to respect the compositor off/false state prior to running,
# however, it was not fathomable why someone would use this script when
# their choice was to have compositing off.

# Instances where this script does not apply:
#   Running multiple concurrent FTB sessions.

# -- Globals -------------------------------------------------------------------

    jvmIsRunning=false # (Java Virtual Macine is running - minecraft client)
    compositorState=true # on/off state tracking.

# -- Constants -----------------------------------------------------------------

    readonly version="1.0.3.beta" # major.minor.point.stage
    readonly workingDir=$HOME/Games/ftb # FTB Launcher Location
    readonly ftbFileName=FTB_Launcher.jar # FTB jar file to launch
    
    # note, advanced optoins for the JVM are set in the Launcher.
    
# -- Functions -----------------------------------------------------------------

function compositorOn() {
    # enable xfce compositing.
    xfconf-query -c xfwm4 -p /general/use_compositing -s true
    compositorState=true
}

function compositorOff() {
    # disable xfce compositing.
    xfconf-query -c xfwm4 -p /general/use_compositing -s false
    compositorState=false
}

function checkJVM() {
    # quetly test if both JVM is running and that JVM is FTB via grep exit code
    # this identifies the minecraft client and not the launcher.
    ps ax | grep "/usr/lib/jvm/java" | grep "ftb" | grep -v grep > /dev/null
    if [ "$?" = "0" ]; then
        jvmIsRunning=true
    fi
}

function enableCompositorOnJVM() {    
    # check once per second if the JVM is running.
    while [ $jvmIsRunning = false ]; do        
        checkJVM;
        sleep 1;
    done
    
    # when JVM is running re-enable compositor.
    compositorOn;
}

# -- Main Function -------------------------------------------------------------

function main() {  
    # disable xfce compositing
    compositorOff;
    
    # fork into backdround, disable, then re-enable xfce compositing when JVM
    # is detected as running.
    enableCompositorOnJVM &
    
    # set working directory for FTB
    cd $workingDir
    
    # start FTB launcher
    java -jar $ftbFileName > /dev/null

    # test if compositor is off, re-enable if off. This state exists when the
    # launcher is terminated by the user, leaving the forked process running.
    if [ $compositorState = false ]; then
        compositorOn;
        # clean up orphaned process
        pkill -P $$
    fi
}

# -- Main Call -----------------------------------------------------------------

main;
exit 0;
