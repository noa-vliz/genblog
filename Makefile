linux: ./zig-linux
	./zig-linux/zig-linux-x86_64-0.15.0-dev.471+369177f0b/zig build

linux-release: ./zig-linux
	zig-linux/zig-linux-x86_64-0.15.0-dev.471+369177f0b/zig build -Doptimize=ReleaseFast

./zig-linux: 
	@echo "Downloading zig"
	curl https://ziglang.org/builds/zig-linux-x86_64-0.15.0-dev.471+369177f0b.tar.xz -o ./zig-linux.tar.xz
	@echo "Unpacking zig"
	mkdir ./zig-linux/
	tar -xvf ./zig-linux.tar.xz -C ./zig-linux/

