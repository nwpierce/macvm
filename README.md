# What?

A simple command line wrapper for Qemu on macOS.

# Features

* Defaults to native Qemu platform
	* Works on both x86_64 and arm64 macOS
* Attaches drives with TRIM/discard enabled for `fstrim`
	* Note that qcow drive images are sparse - logical size will not shrink
* Uses [socket_vmnet](https://github.com/lima-vm/socket_vmnet) for networking if installed
* Generates a unique ethernet MAC from provided disk image path(s)
* Defaults to serial console on stdio with no graphics - works with:
	* [Debian-nocloud](http://cloud.debian.org/images/cloud/bullseye/latest/)
	* [Alpine-virt](https://alpinelinux.org/downloads/)
* Bundles aarch64 QEMU_EFI.fd, as Homebrew Qemu does not
* Remaps VM monitor escape sequence from `ctrl-a` to `ctrl-g`
	* <sup><sub>Because I cannot remap my fingers</sub></sup>

# Dependencies

* Qemu - installable via [Homebrew](https://brew.sh):
	* `brew install qemu`
* [socket_vmnet](https://github.com/lima-vm/socket_vmnet) (optional)
	* lets virtual machines configure a virtual network interface without having to run the entire Qemu process as root\*
	* gives your VM(s) a real local IP address, making it easy to host network services

\* As of Qemu 7.1, either this:
* `-nic vmnet-bridged,mac=00:11:22:33:44:55,ifname=en0`

or this:
* `-device virtio-net-pci,netdev=vmnet0,mac=00:11:22:33:44:55`
* `-netdev vmnet-bridged,id=vmnet0,ifname=en0`

will work, but only via sudo, as the [com.apple.vm.networking](https://developer.apple.com/documentation/bundleresources/entitlements/com_apple_vm_networking) entitlement is currently restricted.

# Install

`make install`
* builds/installs to `/usr/local/bin/vm`

# Run

Run with no arguments for help, but in brief, supply it one or more qcow2 or ISO images:
* `vm disk.qcow2`

# Miscellaneous

### Commands
Within a VM, shut it down gracefully by running:
* `poweroff` (for Debian or Alpine)

Manually release blocks backing deleted files in your VM:
* `fstrim -va` (or `fstrim /` on Alpine)

### Clock shenanigans
On x86_64 linux you may get a lot of complaints about the clock on the console:
```
[   31.538691] clocksource: wd-tsc-wd read-back delay of 133000ns, clock-skew test skipped!
[   32.014140] clocksource: timekeeping watchdog on CPU0: hpet wd-wd read-back delay of 58000ns
[   32.020628] clocksource: wd-tsc-wd read-back delay of 156000ns, clock-skew test skipped!
[   34.030150] clocksource: timekeeping watchdog on CPU0: hpet wd-wd read-back delay of 58000ns
[   34.036468] clocksource: wd-tsc-wd read-back delay of 154000ns, clock-skew test skipped!
[   34.510992] clocksource: timekeeping watchdog on CPU0: hpet wd-wd read-back delay of 58000ns
[   34.517297] clocksource: wd-tsc-wd read-back delay of 158000ns, clock-skew test skipped!
[   36.526046] clocksource: timekeeping watchdog on CPU0: hpet wd-wd read-back delay of 54000ns
[   36.532508] clocksource: wd-tsc-wd read-back delay of 132000ns, clock-skew test skipped!
```

To remedy, try this:
```
sed -i '/^GRUB_CMDLINE_LINUX=/s/"$/ tsc=unstable"/' /etc/default/grub
update-grub
reboot
```

### Serial console
[This](https://github.com/lime45/serial) works great for automatically configuring serial console dimensions.

For Alpine, try:
```
apk add gcc curl musl-dev ncurses-dev
curl -LO https://raw.githubusercontent.com/lime45/serial/master/resize.c
sed -i 's/termio.h/sys\/ioctl.h/' resize.c
gcc -s -Os resize.c -o /usr/local/bin/resize
```

Or for Debian try:
```
apt update && apt install gcc curl ncurses-dev
curl -LO https://raw.githubusercontent.com/lime45/serial/master/resize.c
gcc -s -Os resize.c -o /usr/local/bin/resize
```

Run it anytime your terminal dimensions change.

To have it run once on serial console login, try:
```
cat << "EOF" > /etc/profile.d/resize.sh
#!/bin/sh
tty=`tty`
if [ "${tty::9}" = "/dev/ttyS" ]; then
	/usr/local/bin/resize
fi
EOF
```

# Thanks

I ran across the [macbian-linux macos-subsystem-for-linux project](https://github.com/macbian-linux/macos-subsystem-for-linux) on HN - it was super helpful and motivated me to give qemu on macOS a serious try.

[lima-vm's socket_vmnet project](https://github.com/lima-vm/socket_vmnet)

[lime45's serial project](https://github.com/lime45/serial)