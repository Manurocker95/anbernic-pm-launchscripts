#!/bin/bash

export HOME=/root

XDG_DATA_HOME=${XDG_DATA_HOME:-$HOME/.local/share}

if [ -d "/opt/system/Tools/PortMaster/" ]; then
  controlfolder="/opt/system/Tools/PortMaster"
elif [ -d "/opt/tools/PortMaster/" ]; then
  controlfolder="/opt/tools/PortMaster"
elif [ -d "$XDG_DATA_HOME/PortMaster/" ]; then
  controlfolder="$XDG_DATA_HOME/PortMaster"
else
  controlfolder="/roms/ports/PortMaster"
fi
 
SHDIR=$(dirname "$0")

source $controlfolder/control.txt
source $controlfolder/device_info.txt
[ -f "${controlfolder}/mod_${CFW_NAME}.txt" ] && source "${controlfolder}/mod_${CFW_NAME}.txt"

get_controls

$ESUDO chmod 666 /dev/tty0

GAMEDIR="$SHDIR/JediAcademy"

> "$GAMEDIR/log.txt" && exec > >(tee "$GAMEDIR/log.txt") 2>&1
printf "\033c" > /dev/tty0

sed -i "s/seta r_customheight \".*\"/seta r_customheight \"$DISPLAY_HEIGHT\"/" "$GAMEDIR/conf/openjk/base/openjk_sp.cfg"
sed -i "s/seta r_customwidth \".*\"/seta r_customwidth \"$DISPLAY_WIDTH\"/" "$GAMEDIR/conf/openjk/base/openjk_sp.cfg"

cd $GAMEDIR

$ESUDO rm -rf ~/.local/share/openjk
ln -sfv $GAMEDIR/conf/openjk/ ~/.local/share/

export DEVICE_ARCH="${DEVICE_ARCH:-aarch64}"

if [ -f "${controlfolder}/libgl_${CFW_NAME}.txt" ]; then 
  source "${controlfolder}/libgl_${CFW_NAME}.txt"
fi

if [ "$LIBGL_FB" != "" ]; then
export SDL_VIDEO_GL_DRIVER="$GAMEDIR/gl4es.aarch64/libGL.so.1"
fi 

export LD_LIBRARY_PATH="/usr/lib32:$GAMEDIR/libs:/usr/lib":$LD_LIBRARY_PATH
export SDL_GAMECONTROLLERCONFIG="$sdl_controllerconfig"

whichos=$(grep "title=" "/usr/share/plymouth/themes/text.plymouth")
if [[ $whichos == *"RetroOZ"* ]]; then
  APP_TO_KILL="."
  execute_perf=0
else
  APP_TO_KILL="openjk_sp.aarch64"
  execute_perf=1
fi

((execute_perf)) && maxperf

$ESUDO chmod 666 /dev/tty1
$ESUDO chmod 666 /dev/uinput

$GPTOKEYB $APP_TO_KILL -c "openjk_sp.aarch64.gptk" &
./openjk_sp.aarch64
$ESUDO kill -9 $(pidof gptokeyb)
((execute_perf)) && normperf
unset LD_LIBRARY_PATH

$ESUDO systemctl restart oga_events & 
printf "\033c" >> /dev/tty1
