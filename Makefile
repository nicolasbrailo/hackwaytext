.PHONY: clean deploytgt

all: hackswaytext

clean:
	rm -rf build hackswaytext

deploytgt: hackswaytext
	scp ./hackswaytext batman@10.0.0.146:/home/batman/hackswaytext

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
	-fdiagnostics-color=always \
	-ffunction-sections -fdata-sections \
	-ggdb -O3 \
	-std=gnu99 \
	-Wall -Werror -Wextra -Wpedantic \
	-Wendif-labels \
	-Wfloat-equal \
	-Wformat=2 \
	-Wimplicit-fallthrough \
	-Winit-self \
	-Winvalid-pch \
	-Wmissing-field-initializers \
	-Wmissing-include-dirs \
	-Wno-strict-prototypes \
	-Wno-unused-function \
	-Wno-unused-parameter \
	-Woverflow \
	-Wpointer-arith \
	-Wredundant-decls \
	-Wstrict-aliasing=2 \
	-Wundef \
	-Wuninitialized \
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

hackswaytext:\
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

