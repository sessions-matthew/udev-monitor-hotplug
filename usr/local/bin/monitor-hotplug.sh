#!/bin/bash
# sleep 10
#Adapt this script to your needs.

DEVICES=$(find /sys/class/drm/*/status)

#inspired by /etc/acpd/lid.sh and the function it sources

displaynum=`ls /tmp/.X11-unix/* | sed s#/tmp/.X11-unix/X##`
display=":$displaynum.0"
export DISPLAY=":$displaynum.0"

# from https://wiki.archlinux.org/index.php/Acpid#Laptop_Monitor_Power_Off
export XAUTHORITY=$(ps -C Xorg -f --no-header | sed -n 's/.*-auth //; s/ -[^ ].*//; p')


#this while loop declare the $HDMI1 $VGA1 $LVDS1 and others if they are plugged in
while read l
do
  dir=$(dirname $l);
  status=$(cat $l);
  dev=$(echo $dir | cut -d\- -f 2-);

  if [ $(expr match  $dev "HDMI") != "0" ]
  then
#REMOVE THE -X- part from HDMI-X-n
    dev=HDMI${dev#HDMI-?-}
  else
    dev=$(echo $dev | tr -d '-')
  fi

  if [ "connected" == "$status" ]
  then
    echo $dev "connected"
    declare $dev="yes";

  fi
done <<< "$DEVICES"

# extra call to xrandr, race condition?
xrandr

if [ ! -z "$HDMI1" -a ! -z "$DP1" ]
then
  echo "HDMI1 and DP1 are plugged in"
  #xrandr --output LVDS1 --off
  xrandr --output DP1 --auto
  xrandr --output HDMI1 --auto --right-of DP1
elif [ ! -z "$HDMI1" -a -z "$DP1" ]; then
  echo "HDMI1 is plugged in, but not DP1"
  #xrandr --output LVDS1 --off
  xrandr --output DP1 --off
  xrandr --output HDMI1 --auto
elif [ -z "$HDMI1" -a ! -z "$DP1" ]; then
  echo "DP1 is plugged in, but not HDMI1"
  #xrandr --output LVDS1 --off
  xrandr --output HDMI1 --off
  xrandr --output DP1 --auto --above eDP1
else
  echo "No external monitors are plugged in"
  #xrandr --output LVDS1 --off
  xrandr --output HDMI1 --off
  xrandr --output DP1 --off
  #xrandr --output LVDS1 --mode 1366x768 --primary
fi
