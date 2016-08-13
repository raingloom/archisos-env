#!/bin/bash
if [ ! $USER = tux ]; then
	pacman -S zsh grml-zsh-config
	usermod -s /bin/zsh root
	useradd -m -s /bin/zsh -U -G wheel,users tux
	
	mkdir -p tmp
	cd tmp
		echo '#!/bin/sh' >> editsudo.sh
		echo 'echo "%wheel ALL=(ALL) NOPASSWD: ALL" >> $2' >> editsudo.sh
		chmod +x editsudo.sh
		VISUAL="$PWD/editsudo.sh" visudo
	cd ..
	cp $0 /home/tux
	cd /home/tux
	su -c /home/tux/$0 tux
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

