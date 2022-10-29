DESTDIR=/usr/local
BIN=$(DESTDIR)/bin

edk2=https://mirrors.wikimedia.org/debian/pool/main/e/edk2/
deb=$(shell curl -fsSL $(edk2) | sed -nr 's/.*href="(qemu-efi-aarch64[^"]*)".*/\1/p' | tail -1)

vm: vm.pl QEMU_EFI.fd
	rm -f $@
	xz -ec9 < QEMU_EFI.fd | base64 -b 120 | cat $< - > $@
	chmod a+x,a-w $@

install: $(BIN)/vm

$(BIN)/vm: vm
	sudo mkdir -vp "$(BIN)"
	sudo install -o root -g wheel -m 0755 $^ "$(BIN)"

QEMU_EFI.fd: data.tar.xz
	tar xOf data.tar.xz --include \*/$@ > $@

data.tar.xz: qemu-efi-aarch64.deb
	ar x $< $@

qemu-efi-aarch64.deb:
	curl -fsSL $(edk2)$(deb) > $@

clean:
	@rm -fv QEMU_EFI.fd data.tar.xz qemu-efi-aarch64.deb vm
