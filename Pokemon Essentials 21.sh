#!/bin/bash

export HOME=/root

if [ -d "/opt/system/Tools/PortMaster/" ]; then
  controlfolder="/opt/system/Tools/PortMaster"
elif [ -d "/opt/tools/PortMaster/" ]; then
  controlfolder="/opt/tools/PortMaster"
elif [ -d "/roms/ports" ]; then
  controlfolder="/roms/ports/PortMaster"
 elif [ -d "/roms2/ports" ]; then
  controlfolder="/roms2/ports/PortMaster"
else
  controlfolder="/storage/roms/ports/PortMaster"
fi


# Source the controls and device info
source $controlfolder/control.txt

# Source custom mod files from the portmaster folder
[ -f "${controlfolder}/mod_${CFW_NAME}.txt" ] && source "${controlfolder}/mod_${CFW_NAME}.txt"
# Pull the controller configs for native controls
get_controls

# Directory setup
PORTDIR=$(dirname "$0")
GAMEDIR="$PORTDIR/essentials21"
CONFDIR="$GAMEDIR/conf/"
mkdir -p "$GAMEDIR/conf"

## TODO: Change to PortMaster/tty when Johnnyonflame merges the changes in,
$ESUDO chmod 666 /dev/tty0
printf "\033c" > /dev/tty0
echo "Loading... Please Wait." > /dev/tty0

# Exports
export LD_LIBRARY_PATH="$GAMEDIR/libs.aarch64:/usr/lib:/usr/lib32:$LD_LIBRARY_PATH"
export SDL_GAMECONTROLLERCONFIG="$sdl_controllerconfig"
export TEXTINPUTINTERACTIVE="Y"
export XDG_DATA_HOME="$CONFDIR"

export PATCHER_FILE="$GAMEDIR/patch/patchscript"
export PATCHER_GAME="Pokemon Essentials"
export PATCHER_TIME="around 1 minute"
export PATCHDIR=$GAMEDIR

cd $GAMEDIR

# Check if patchlog.txt exists to skip patching
if [ ! -f patchlog.txt ]; then
    source "$controlfolder/utils/patcher.txt"
fi

# Move the mkxp.json preset
mv preset/mkxp.json ./mkxp.json

# Gptk and run port
$GPTOKEYB "mkxp-z.aarch64" -c "./Essentials21.gptk" &
pm_platform_helper $GAMEDIR/mkxp-z.aarch64
./mkxp-z.aarch64

# Cleanup
pm_finish