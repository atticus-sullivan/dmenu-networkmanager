.PHONY: install pkg clean pkg-dev pkg-release install-dev install-release

install: install-dev

install-dev: pkg-dev
	f="$$(find . -iname "dmenu-networkmanager-dev-[a-f0-9.]*-x86_64.pkg.tar.zst" | grep -v "debug" | head -n 1)" && sudo pacman -U "$$f"

install-release: pkg-release
	f="$$(find . -iname "dmenu-networkmanager-[0-9.]*-x86_64.pkg.tar.zst" | grep -v "debug" | head -n 1)" && sudo pacman -U "$$f"

pkg: pkg-dev

pkg-release:
	makepkg -D pkg-release -c
	mv pkg-release/*.tar.zst .

pkg-dev:
	makepkg -D pkg-dev -c
	mv pkg-dev/*.tar.zst .

clean:
	-$(RM) *.tar.gz *.tar.zst
