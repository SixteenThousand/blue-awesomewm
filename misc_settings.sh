# This script just sets up stuff for awesome that are easier to set from a shell script

# map Caps Lock to Escape
setxkbmap -option caps:escape

# compositor
picom --daemon --backend glx --vsync

# set wallpaper
$HOME/.fehbg

# Change default cursor size
echo 'Xcursor.size: 48' | xrdb -
xsetroot -xcf /usr/share/icons/Adwaita/cursors/default 48

# turn off screen saving
xset -dpms
xset s off
