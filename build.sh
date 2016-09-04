#!/bin/zsh
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
	local rw=""
	[[ $1 = '-w' ]] && rw="" || rw="-r"
	btrfs subvolume snapshot $rw "$container" "${work}/snapshots/$(date +%s)"
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
	sudo systemd-nspawn --directory "$container" --chdir="/root/repo" $@
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
	cp -rvfT "${here}/copied" "${container}/root"
	cp -rvT "$repo" "${container}/root/repo"
	nspawn ./container-setup.sh
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
	xnspawn "releng/fullbuild.sh"
}

###################################
$@ #execute command line parameters
###################################

fi
