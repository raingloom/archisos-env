#!/bin/zsh
set -x -e
if [ "$EUID" -ne 0 ]
then
#not running as root, re-run with sudo
	sudo $0 $@
else
###################
#Main section
#Should be root now
###################

#assign defaults
here="$(dirname $0)"
#get absolute path of this script
if [ ${here[1]} != '/' ]
then
	here="${PWD}/${here}"
fi
work="${here}/work"
container="${here}/container"
repo="${here}/repo"

snap() {
	if [ ! -z $1 ]; then
		#$1 is an optional suffix
		1="-${1}"
	fi
	btrfs subvolume snapshot -r "$container" "${work}/snapshots/$(date +%s)${1}"
}

run-once() {
	local f="${work}/ran-${1}"
	if [ -f "$f" ]
	then
		$@
	else
		touch "$f"
		$@
	fi
}

nspawn() {
	sudo systemd-nspawn --directory "$container" --chdir="/root" $@
}

init() {
	mkdir "$work"
	mkdir "${work}/snapshots"
}

root-base() {
	btrfs subvolume create "$container"
	pacstrap -d "$container" base base-devel zsh grml-zsh-config --ignore linux
}

root-setup() {
	cp -rvfuT "${here}/copied" "$container"
	cp -rvT "$repo" "${container}/home/tux/repo"
	nspawn /root/container-setup.sh
	nspawn chown tux:tux --recursive --verbose "/home/tux"
}

mkautologin() {
	autologin="${container}/etc/systemd/system/getty@tty.service.d/override.conf"
	mkdir -p "$(dirname $autologin)"
	echo '
	[Service]
	ExecStart=
	ExecStart=-/usr/bin/agetty --autologin username --noclear %I $TERM' > "$autologin"
}

cleanup() {
	rm -r "$work"
}

buildiso() {
	nspawn "/home/tux/buildiso.sh"
}

run-then-snap() {
	$@
	snap "$@"
}

rollback() {
	if btrfs subvolume show "$1" &> /dev/null; then
		btrfs subvolume delete "$container" || true
		btrfs subvolume snapshot "$1" "$container"
	else
		echo "$1 is not a valid btrfs subvolume" 1>&2
	fi
}

###################################
$@ #execute command line parameters
###################################

fi
