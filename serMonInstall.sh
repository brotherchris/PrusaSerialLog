#!/bin/bash
USER="$(whoami)"

echo "Are you connecting to your Prusa via USB[1] or GPIO[2]:"
read -p "Enter 1 or 2 " var

if [ -z "$var" ]
then
   echo "Input cannot be blank."
   exit 0
fi

if ! [[ "$var" =~ [1-2] ]]
     then
         echo "Input has to be a 1 or 2."
     exit 0
fi

if [ $var = "1" ] ; then
   logger "We are using USB, do we need to fix up the files?"
   if grep -q pi3-miniuart-bt /boot/config.txt ; then
      logger "Files need updated for USB"
      sudo sed -i '1s/^/console=serial0,115200 /' /boot/cmdline.txt
      sudo sed -i 's/dtoverlay=pi3-miniuart-bt//g' /boot/config.txt
   fi
fi

if [ $var = "2" ] ; then
   logger "We have a Pi zero, do we need to fix up the files?"
   if grep -q pi3-miniuart-bt /boot/config.txt ; then
      logger "Files already updated for Pi zero"
   else
      sudo systemctl disable hciuart.service
      sudo systemctl disable bluetooth.service
      echo 'dtoverlay=pi3-miniuart-bt' | sudo tee -a /boot/config.txt
      sudo sed -i 's/console=serial0,115200 //g' /boot/cmdline.txt
   fi
fi

cron_bkp="/home/"$USER"/cron_bkp"
sudo apt update
sudo apt -y upgrade
sudo apt -y install python3-pip
sudo pip install pyserial
sudo apt -y install tmux
sudo wget -O seriallog.sh https://github.com/brotherchris/PrusaSerialLog/raw/main/seriallog.sh
sudo chmod 755 seriallog.sh
if [ $var = "1" ] ; then
   sed -i 's/SERIALDEV=""/SERIALDEV="\/dev\/ttyACM0"/g' seriallog.sh
fi

if [ $var = "2" ] ; then
   sed -i 's/SERIALDEV=""/SERIALDEV="\/dev\/ttyAMA0"/g' seriallog.sh
fi


crontab -l > cron_bkp
if grep -q serial "$cron_bkp"; then
echo "Crontab up to date"
rm "$cron_bkp"
else
echo "MAILTO=\"\"" >> "$cron_bkp"
echo "@reboot /home/"$USER"/seriallog.sh >> outboot.txt 2>&1" >> "$cron_bkp"
echo "0 * * * * /home/"$USER"/seriallog.sh >> outhour.txt 2>&1" >> "$cron_bkp"
echo "* * * * * date >> ~/log/serial.csv" >> "$cron_bkp"
echo "* * * * * sleep 15; date >> ~/log/serial.csv" >> "$cron_bkp"
echo "* * * * * sleep 30; date >> ~/log/serial.csv" >> "$cron_bkp"
echo "* * * * * sleep 45; date >> ~/log/serial.csv" >> "$cron_bkp"
crontab "$cron_bkp"
rm "$cron_bkp"
fi
if [ $var = "1" ] ; then
   echo "Install complete!!!"
   echo "Please plug in your Prusa to your Pi via USB"
   echo "Please reboot to start serial logging. Enter sudo reboot now"
fi

if [ $var = "2" ] ; then
   echo "Install complete!!!"
   echo "Please set your Prusa Rpi port to on from the LCD > Settings."
   echo "Please reboot to start serial logging. Enter sudo reboot now"
fi
