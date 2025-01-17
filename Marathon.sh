#!/bin/bash

export HOME=/root

if [ -d "/opt/system/Tools/PortMaster/" ]; then
  controlfolder="/opt/system/Tools/PortMaster"
elif [ -d "/opt/tools/PortMaster/" ]; then
  controlfolder="/opt/tools/PortMaster"
else
  controlfolder="/roms/ports/PortMaster"
fi

SHDIR="$(cd $(dirname "$0"); pwd)"

source $controlfolder/control.txt

get_controls

GAMEDIR="$SHDIR/alephone"

cd $GAMEDIR

$ESUDO rm -rf ~/.alephone
$ESUDO ln -s $GAMEDIR/conf/.alephone ~/

export LIBGL_ES=2
export LIBGL_GL=21
export LIBGL_FB=4

$ESUDO chmod 666 /dev/tty1
$ESUDO chmod 666 /dev/uinput
$GPTOKEYB "alephone" &
LD_LIBRARY_PATH="$GAMEDIR/libs:$LD_LIBRARY_PATH" SDL_GAMECONTROLLERCONFIG="$sdl_controllerconfig" ./alephone $GAMEDIR"/gamedata/Marathon" 2>&1 | tee $GAMEDIR/log.txt
$ESUDO kill -9 $(pidof gptokeyb)
