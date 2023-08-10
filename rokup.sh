#!/bin/bash

# Destination directory for the backup
backup_dir="$BACKUP_DIR"

if [ -z "$backup_dir" ]; then
  backup_dir="$HOME/rokup"
fi

# Create the backup directory if it doesn't exist
if ! mkdir -p "$backup_dir"; then
    echo "Error: Unable to create the directory $backup_dir"
    exit 1
fi

# Create subdirectories for different types of files
if ! mkdir -p "$backup_dir/packages"; then
	echo "Error: Unable to create the directory $backup_dir/packages"
fi

function show_loading_animation() {
  local -a spin_chars=("|" "/" "-" "\\")
  local i=0

  while :; do
    echo -ne "\r[${spin_chars[i]}] Working... "
    sleep 0.1
    ((i = (i + 1) % 4))
  done
}

echo "=== Starting backup ==="
echo ""
echo "[*] Backing up local files to $backup_dir/local_share"
show_loading_animation &
# Exclude list for rsync

exclude_list=()

# Get the value of the DONT_BACKUP environment variable
dont_backup="$DONT_BACKUP"

# Check if DONT_BACKUP is empty
if [ -z "$dont_backup" ]; then
  echo "[SKIP] Variable DONT_BACKUP is not set or empty"

else
	# Iterate over the values in DONT_BACKUP
	IFS=',' read -ra exclude_dirs <<< "$dont_backup"

	for dir in "${exclude_dirs[@]}"; do
	  # check if has a space and remove it
	  dir=$(echo "$dir" | sed 's/ //g')
	  formatted_option="--exclude=${dir}/"
	  exclude_list+=("$formatted_option")
	done
fi

# Copy ~/.local/share, excluding specified folders
rsync -a "${exclude_list[@]}" "$HOME/.local/share/" "$backup_dir/local_share"
kill $!
echo -e "\r                "

echo "[*] Backing up dotfiles to $backup_dir/dotfiles"
show_loading_animation &
rsync -a "${exclude_list[@]}" "$HOME/.config" "$backup_dir/dotfiles"
kill $!
echo -e "\r                "

echo "[*] Backing up fonts to $backup_dir/fonts"
show_loading_animation &
# Save all fonts from system locations
rsync -a "${exclude_list[@]}" /usr/share/fonts "$backup_dir/fonts" &> /dev/null
rsync -a "${exclude_list[@]}" /usr/local/share/fonts "$backup_dir/fonts" &> /dev/null
rsync -a "${exclude_list[@]}" /usr/share/X11/fonts "$backup_dir/fonts" &> /dev/null
kill $!
echo -e "\r                "

# Function to list installed packages using the detected package manager
list_installed_packages() {
    local manager="$1"

    case "$manager" in
        "apt")
            apt list --installed > "$backup_dir/packages/installed_packages.txt"
            ;;
        "dnf")
            dnf list installed > "$backup_dir/packages/installed_packages.txt"
            ;;
        "yum")
            yum list installed > "$backup_dir/packages/installed_packages.txt"
            ;;
        "pacman")
            pacman -Q > "$backup_dir/packages/installed_packages.txt"
            ;;
        "zypper")
            zypper se --installed-only > "$backup_dir/packages/installed_packages.txt"
            ;;
        "apk")
            apk info > "$backup_dir/packages/installed_packages.txt"
            ;;
        *)
            echo "Unsupported package manager: $manager" 
            ;;
    esac
}

echo "[*] Backing up installed packages to $backup_dir/packages"
show_loading_animation &
# Detect the package manager in use
if which apt &> /dev/null; then
    list_installed_packages "apt"
elif which dnf &> /dev/null; then
    list_installed_packages "dnf"
elif which yum &> /dev/null; then
    list_installed_packages "yum"
elif which pacman &> /dev/null; then
    list_installed_packages "pacman"
elif which zypper &> /dev/null; then
    list_installed_packages "zypper"
elif which apk &> /dev/null; then
    list_installed_packages "apk"
else
    echo "No supported package manager found."
    exit 1
fi
echo -e "\r                "

# Get a list of installed Python packages
pip list --format=freeze > "$backup_dir/packages/python_packages.txt"

# Get a list of globally installed npm packages
npm ls -g --depth=0 --parseable --quiet | sed 's/.*node_modules\///' > "$backup_dir/packages/npm_packages.txt"

# Get a list of installed Ruby gems
gem list > "$backup_dir/packages/ruby_gems.txt"

kill $!
echo -e "\r                "
echo "=== Backup completed and stored in $backup_dir ===    "
echo ""
echo "--- Backup statistics ---"
echo "Total size: $(du -sh $backup_dir | cut -f1)"
echo "-------------------------"
