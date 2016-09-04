#!/bin/bash
set -x
if [ ! $USER = tux ]; then
	#############
	#GLOBAL SETUP
	#############
	usermod -s /bin/zsh root #set zsh as default shell
	useradd -m -s /bin/zsh -U -G wheel,users tux #add unprivileged user
	
	mkdir -p tmp
	cd tmp
		echo '#!/bin/sh' >> editsudo.sh
		echo 'echo "%wheel ALL=(ALL) NOPASSWD: ALL" >> $2' >> editsudo.sh #allow unpriviliged user to run ANYTHING as root without a password
		chmod +x editsudo.sh
		VISUAL="$PWD/editsudo.sh" visudo
	cd ..
	cp "$0" /home/tux
	cd /home/tux
	su -c "/home/tux/$(basename "$0")" tux
else
	mkdir -p tmp
	cd tmp
		curl -O https://aur.archlinux.org/cgit/aur.git/snapshot/cower.tar.gz
		curl -O https://aur.archlinux.org/cgit/aur.git/snapshot/pacaur.tar.gz
		tar xvf cower.tar.gz
		tar xvf pacaur.tar.gz
		gpg --recv-keys --keyserver hkp://pgp.mit.edu 1EB2638FF56C0C53
		mkpkg="makepkg -sri --noconfirm"
		cd cower
			$mkpkg
		cd ..
		cd pacaur
			$mkpkg
		cd ..
	cd ..
fi

