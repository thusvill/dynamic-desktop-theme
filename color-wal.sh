#!/bin/bash

# Generate pywal colors
wal -i "$(gsettings get org.gnome.desktop.background picture-uri-dark | sed "s/'file:\/\///;s/'//")"

# Check if the pywal output file exists
pywal_file="/home/bios/.cache/wal/colors"
if [[ ! -f "$pywal_file" ]]; then
  echo "Error: The pywal output file '$pywal_file' does not exist."
  exit 1
fi

# Extract the accent color hex code
accent_color_hex=$(awk 'NR==3 {print $1}' "$pywal_file")

# Convert hex to RGB
hex_to_rgb() {
  hex=$1
  r=$(printf "%d" 0x${hex:1:2})
  g=$(printf "%d" 0x${hex:3:2})
  b=$(printf "%d" 0x${hex:5:2})
  echo "$r $g $b"
}

# Extract individual RGB values
rgb_values=$(hex_to_rgb "$accent_color_hex")

# Extract individual RGB values
red=$(echo "$rgb_values" | awk '{print $1}')
green=$(echo "$rgb_values" | awk '{print $2}')
blue=$(echo "$rgb_values" | awk '{print $3}')

echo "Accent color hex code: $accent_color_hex"
echo "RGB values: $rgb_values"

# Determine the two highest RGB values
max1=0
max2=0
for value in "$red" "$green" "$blue"; do
  if ((value >= max1)); then
    max2=$max1
    max1=$value
  elif ((value > max2)); then
    max2=$value
  fi
done

# Determine the least similar theme based on the two highest RGB values
least_similar_color=""
min_difference=999999

check_difference() {
  local value1=$1
  local value2=$2
  local difference=$((value1 - value2))
  if ((difference < 0)); then
    difference=$((difference * -1))
  fi
  echo "$difference"
}

compare_and_update() {
  local candidate_color=$1
  local candidate_red=$2
  local candidate_green=$3
  local candidate_blue=$4

  local difference_red=$(check_difference "$red" "$candidate_red")
  local difference_green=$(check_difference "$green" "$candidate_green")
  local difference_blue=$(check_difference "$blue" "$candidate_blue")

  local total_difference=$((difference_red + difference_green + difference_blue))

  if ((total_difference < min_difference)); then
    least_similar_color="$candidate_color"
    min_difference=$total_difference
  fi
}

compare_and_update "purple" 128 0 128
compare_and_update "pink" 255 192 203
compare_and_update "green" 0 128 0
compare_and_update "blue" 0 0 255
compare_and_update "red" 255 0 0

# Apply the GNOME Shell theme
if [ -n "$least_similar_color" ]; then
  shell_theme="Marble-$least_similar_color-dark"
  gsettings set org.gnome.shell.extensions.user-theme name "$shell_theme"
  echo "Applied GNOME Shell theme: $shell_theme"

  # Apply the application themes
  app_theme="Graphite-$least_similar_color-Dark-nord"
  gsettings set org.gnome.desktop.interface gtk-theme "$app_theme"
  gsettings set org.gnome.desktop.interface icon-theme "Reversal-$least_similar_color-dark"  # Set your preferred icon theme
  echo "Applied application themes: $app_theme"
else
  echo "No specific theme condition met. Exiting without applying themes."
  exit 0
fi

