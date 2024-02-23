build: cairo blockifier scarb starknet-devnet-rs

clean:
	cd cairo && cargo clean
	cd blockifier && cargo clean
	cd scarb && cargo clean
	cd starknet-devnet-rs && cargo clean

cairo:
	cd cairo && cargo build

blockifier:
	cd blockifier/crates/blockifier/ && cargo build

scarb:
	cd scarb && cargo build

starknet-devnet-rs:
	cd starknet-devnet-rs && cargo build

submodules:
	git submodule update --init --recursive

submodules-reset-hard:
	git clean -xfdf
	git submodule foreach --recursive git clean -xfdf
	git reset --hard
	git submodule foreach --recursive git reset --hard
	git submodule update --init --recursive

.PHONY: build clean cairo blockifier scarb starknet-devnet-rs
