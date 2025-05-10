ZIG_VERSION=0.15.0-dev.471+369177f0b

.PHONY: linux linux-release mac mac-release windows windows-release

# Linux
linux: ./zig-linux
	./zig-linux/zig-linux-x86_64-$(ZIG_VERSION)/zig build

linux-release: ./zig-linux
	./zig-linux/zig-linux-x86_64-$(ZIG_VERSION)/zig build -Doptimize=ReleaseFast

./zig-linux:
	@echo "Downloading Zig for Linux"
	curl -L https://ziglang.org/builds/zig-linux-x86_64-$(ZIG_VERSION).tar.xz -o zig-linux.tar.xz
	@echo "Unpacking"
	mkdir -p zig-linux
	tar -xf zig-linux.tar.xz -C zig-linux/

# macOS
mac: ./zig-macos
	./zig-macos/zig-macos-x86_64-$(ZIG_VERSION)/zig build

mac-release: ./zig-macos
	./zig-macos/zig-macos-x86_64-$(ZIG_VERSION)/zig build -Doptimize=ReleaseFast

./zig-macos:
	@echo "Downloading Zig for macOS"
	curl -L https://ziglang.org/builds/zig-macos-x86_64-$(ZIG_VERSION).tar.xz -o zig-macos.tar.xz
	@echo "Unpacking"
	mkdir -p zig-macos
	tar -xf zig-macos.tar.xz -C zig-macos/

# Windows (MinGW or MSVC)
windows: ./zig-windows
	./zig-windows/zig-windows-x86_64-$(ZIG_VERSION)/zig build

windows-release: ./zig-windows
	./zig-windows/zig-windows-x86_64-$(ZIG_VERSION)/zig build -Doptimize=ReleaseFast

./zig-windows:
	@echo "Downloading Zig for Windows"
	curl -L https://ziglang.org/builds/zig-windows-x86_64-$(ZIG_VERSION).zip -o zig-windows.zip
	@echo "Unpacking"
	mkdir -p zig-windows
	unzip -q zig-windows.zip -d zig-windows/