.PHONY: clean deploytgt

all: hackwaytext

clean:
	rm -rf build hackimg

deploytgt: hackwaytext
	scp ./hackwaytext batman@10.0.0.146:/home/batman/hackwaytext

SYSROOT=/home/batman/src/xcomp-rpiz-env/mnt/
XCOMPILE=\
	 -target arm-linux-gnueabihf \
	 -mcpu=arm1176jzf-s \
	 --sysroot $(SYSROOT)

# Use SYSROOT=/ for local build includes
#SYSROOT=/
#XCOMPILE=

CFLAGS= \
       $(XCOMPILE) \
       -I./src/ \
       -isystem ./build/wayland_protos \
       -Wall -Werror -Wextra -Wpedantic \
       -Wno-unused-parameter \
       -Wundef \
       -Wmissing-include-dirs \
       -Wpointer-arith \
       -Winit-self \
       -Wfloat-equal \
       -Wredundant-decls \
       -Wimplicit-fallthrough \
       -Wendif-labels \
       -Wstrict-aliasing=2 \
       -Woverflow \
       -Wformat=2 \
       -Winvalid-pch \
       -ggdb -O0 \
       -std=c99 \
       -fdiagnostics-color=always \
       -D_FILE_OFFSET_BITS=64 \
       -D_POSIX_C_SOURCE=200809 \
       -pthread \

LDFLAGS=\
	  -lwayland-client \
	  -lwayland-cursor \
		-lcairo \

build/src/%.o: src/%.c $(wildcard src/%.h)
	mkdir -p build/src
	clang $(CFLAGS) $< -c -o $@

wayland_protos/wlr-layer-shell-unstable-v1.xml:
	mkdir -p wayland_protos
	wget --directory-prefix="wayland_protos" https://raw.githubusercontent.com/swaywm/wlr-protocols/refs/heads/master/unstable/wlr-layer-shell-unstable-v1.xml

wayland_protos/xdg-output-unstable-v1.xml:
	mkdir -p wayland_protos
	wget --directory-prefix="wayland_protos" https://gitlab.freedesktop.org/wayland/wayland-protocols/-/raw/main/unstable/xdg-output/xdg-output-unstable-v1.xml

wayland_protos/xdg-shell.xml:
	mkdir -p wayland_protos
	wget --directory-prefix="wayland_protos" https://gitlab.freedesktop.org/wayland/wayland-protocols/-/raw/main/stable/xdg-shell/xdg-shell.xml

build/wayland_protos/%.o build/wayland_protos/%.c build/wayland_protos/%.h: wayland_protos/%.xml
	mkdir -p build/wayland_protos
	wayland-scanner private-code $< $(patsubst %.o, %.c, $@)
	wayland-scanner client-header $< $(patsubst %.o, %.h, $@)
	clang $(CFLAGS) $(patsubst %.o, %.c, $@) -c -o $@

hackwaytext:\
		build/wayland_protos/xdg-shell.o \
		build/wayland_protos/wlr-layer-shell-unstable-v1.o \
		build/wayland_protos/xdg-output-unstable-v1.o \
		build/src/main.o \
		build/src/pool-buffer.o \
		build/src/render.o
	clang $(CFLAGS) -o $@ $^ $(LDFLAGS)


.PHONY: xcompile-start xcompile-end xcompile-rebuild-sysrootdeps

xcompile-start:
	./rpiz-xcompile/mount_rpy_root.sh ~/src/xcomp-rpiz-env

xcompile-end:
	./rpiz-xcompile/umount_rpy_root.sh ~/src/xcomp-rpiz-env

install_sysroot_deps:
	./rpiz-xcompile/add_sysroot_pkg.sh ~/src/xcomp-rpiz-env http://archive.raspberrypi.com/debian/pool/main/c/cairo/libcairo2-dev_1.16.0-7+rpt1_armhf.deb

