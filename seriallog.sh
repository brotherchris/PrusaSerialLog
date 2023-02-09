#!/bin/bash
USER="$(whoami)"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
LOGDIR="/home/"$USER"/log"  #log directory
LOGNAME="serial.csv"   #log file name
MAXSIZE="5000000"      #log file size in K (5MB)
TMUXSESSION="MINI"     #name on TMUX session
SERIALDEV=""
BAUD="115200"          #baud rate
OLDLOG=${LOGNAME}_${TIMESTAMP}

#if there is no LOGDIR create it.
if [ -e "$LOGDIR" ] ; then
   logger "LOGDIR exists"
else
#Make LOG dir
mkdir $LOGDIR
fi

cd $LOGDIR      #change to log directory

LOGNAME_SIZE=$(ls -l $LOGNAME | awk '{print $5}')  #find log file size using awk

logger "Current serial log size $LOGNAME_SIZE"    # report log size
if ((LOGNAME_SIZE >= MAXSIZE)); #if log is over max size (5MB)

then
logger "Serial $LOGNAME exceeds max threshold"   #report it's over the limit
if [ $SERIALDEV = "/dev/ttyACM0" ] ; then
echo -e ";C32u2_RMD">/dev/ttyACM0   #stop Prusa from resetting
fi
tmux ls #list TMUX sessions
tmux kill-session -t $TMUXSESSION #kill TMUX session
mv $LOGNAME $OLDLOG #rename log file with date
#Start new TMUX session to continue logging
tmux new-session -d -s $TMUXSESSION "/bin/python -m serial.tools.miniterm -q "$SERIALDEV" "$BAUD" >> "$LOGNAME""
if [ $SERIALDEV = "/dev/ttyACM0" ] ; then
sleep 30 #wait 30 seconds
echo -e ";C32u2_RME">/dev/ttyACM0   #start Prusa back to default
fi
else
logger "Serial $LOGNAME is below max threshold"  #report it's not over the limit
fi

find /home/$USER/log* -mtime +10 -exec rm {} \;  # remove any file in log over 10 days old

#if there is no TMUX session start one.
STATUS=$(tmux ls) #list TMUX sessions
if [ -z "$STATUS" ] ; then
   logger "Start new TMUX session"
   #start a session
mv $LOGNAME $OLDLOG #rename log file with date
tmux new-session -d -s $TMUXSESSION "/bin/python -m serial.tools.miniterm -q "$SERIALDEV" "$BAUD" >> "$LOGNAME""
else
    #if there is one, do nothing.
   logger "Session "$TMUXSESSION" running , do nothing"
fi
