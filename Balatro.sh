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

source $controlfolder/control.txt

get_controls
[ -f "${controlfolder}/mod_${CFW_NAME}.txt" ] && source "${controlfolder}/mod_${CFW_NAME}.txt"

## TODO: Change to PortMaster/tty when Johnnyonflame merges the changes in,
$ESUDO chmod 666 /dev/tty0
printf "\033c" > /dev/tty0
echo "Loading... Please Wait." > /dev/tty0

PORTDIR=$(dirname "$0")
GAMEDIR="$PORTDIR/balatro"

export XDG_DATA_HOME="$GAMEDIR/saves" # allowing saving to the same path as the game
export XDG_CONFIG_HOME="$GAMEDIR/saves"
export LD_LIBRARY_PATH="$GAMEDIR/libs.aarch64:/usr/lib:/usr/lib32:$LD_LIBRARY_PATH"

mkdir -p "$XDG_DATA_HOME"
mkdir -p "$XDG_CONFIG_HOME"

## Uncomment the following file to log the output, for debugging purpose
# > "$GAMEDIR/log.txt" && exec > >(tee "$GAMEDIR/log.txt") 2>&1

cd $GAMEDIR

$ESUDO chmod a+x ./bin/*

if [ -f "Balatro.exe" ]; then
    GAMEFILE="Balatro.exe"
elif [ -f "balatro.exe" ]; then
    GAMEFILE="balatro.exe"
elif [ -f "Balatro.love" ]; then
    GAMEFILE="Balatro.love"
elif [ -f "balatro.love" ]; then
    GAMEFILE="balatro.love"
fi

if [ -f "$GAMEFILE" ]; then
  # Extract globals.lua
  ./bin/7za.aarch64 x "$GAMEFILE" globals.lua

  # Modify globals.lua

  # change some default settings
  sed -i 's/crt = 70,/crt = 0,/g' globals.lua
  sed -i 's/bloom = 1/bloom = 0/g' globals.lua
  sed -i 's/s/shadows = 'On'/shadows = 'Off'/g' globals.lua
  sed -i 's/self.F_HIDE_BG = false/self.F_HIDE_BG = true/g' globals.lua

  # change controller mapping (swap A/B,X/Y to match the physical buttons) for TSP
  if [ "${DEVICE_NAME}" = "TrimUI Smart Pro" ]; then
    sed -i 's/self.F_SWAP_AB_BUTTONS = false/self.F_SWAP_AB_BUTTONS = true/g' globals.lua
    sed -i 's/self.F_SWAP_XY_BUTTONS = false/self.F_SWAP_XY_BUTTONS = true/g' globals.lua
  fi

  if [ $DISPLAY_WIDTH -le 1279 ]; then # increase the scale for smaller screens
    sed -i 's/self.TILE_W = self.F_MOBILE_UI and 11.5 or 20/self.TILE_W = 18.25/g' globals.lua
    sed -i 's/self.TILE_H = self.F_MOBILE_UI and 20 or 11.5/self.TILE_H = 18.25/g' globals.lua
  fi

  if [ $DISPLAY_WIDTH -le 720 ]; then # switch out the font if the screen is too small; helping with readability
    cp resources/fonts/Nunito-Black.ttf resources/fonts/m6x11plus.ttf # change Nunito-Black to the in-game font file
    ./bin/7za.aarch64 u -aoa "$GAMEFILE" resources/fonts/m6x11plus.ttf
    rm resources/fonts/m6x11plus.ttf
  fi

  # Update the archive with the modified globals.lua
  ./bin/7za.aarch64 u -aoa "$GAMEFILE" globals.lua

  # CP the file to Patched Balatro location
  cp $GAMEFILE Balatro

  # RGB30 & Other 1x1 square ratio device specific changes
  if [ $DISPLAY_HEIGHT -eq $DISPLAY_WIDTH ]; then
    mkdir -p ./functions
    ./bin/7za.aarch64 x "$GAMEFILE" functions/common_events.lua
    # move the hands a bit to the right
    sed -i 's/G.hand.T.x = G.TILE_W - G.hand.T.w - 2.85/G.hand.T.x = G.TILE_W - G.hand.T.w - 1/g' functions/common_events.lua
    # then move the playing area up
    sed -i 's/G.play.T.y = G.hand.T.y - 3.6/G.play.T.y = G.hand.T.y - 4.5/g' functions/common_events.lua
    # move the decks to the right
    sed -i 's/G.deck.T.x = G.TILE_W - G.deck.T.w - 0.5/G.deck.T.x = G.TILE_W - G.deck.T.w + 0.85/g' functions/common_events.lua
    # move the jokers to the left
    sed -i 's/G.jokers.T.x = G.hand.T.x - 0.1/G.jokers.T.x = G.hand.T.x - 0.2/g' functions/common_events.lua

    # Update the archive with the modified common_events.lua
    ./bin/7za.aarch64 u -aoa "$GAMEFILE" functions/common_events.lua
    rm functions/common_events.lua
    cp $GAMEFILE Balatro_1x1
  fi

  rm $GAMEFILE
  rm globals.lua
fi

if [ "${DEVICE_NAME}" = "TrimUI Smart Pro" ]; then
  # These libs are no good.
  LIBDIR="$GAMEDIR/libs.aarch64"

  if [ -f "$LIBDIR/libfontconfig.so.1" ]; then
    $ESUDO rm -f "$LIBDIR/libfontconfig.so.1"
  fi

  if [ -f "$LIBDIR/libtheoradec.so.1" ]; then
    $ESUDO rm -f "$LIBDIR/libtheoradec.so.1"
  fi
fi

LAUNCH_GAME="Balatro"

if [ $DISPLAY_HEIGHT -eq $DISPLAY_WIDTH ]; then
  LAUNCH_GAME="Balatro_1x1"
fi

if [ -f "$LAUNCH_GAME" ]; then
  $GPTOKEYB "love.aarch64" &
	pm_platform_helper "./bin/love.aarch64"
  ./bin/love.aarch64 "$LAUNCH_GAME"
else
  echo "Balatro game file not found. Please drop in Balatro.exe or Balatro.love into the Balatro folder prior to starting the game."> $CUR_TTY
fi

pm_finish

# Disable console
printf "\033c" > $CUR_TTY