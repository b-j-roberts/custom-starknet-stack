build: cairo blockifier scarb starknet-devnet-rs

clean:
	cd cairo && cargo clean
	cd blockifier && cargo clean
	cd scarb && cargo clean
	cd scarb && rm -rf bin/
	cd starknet-devnet-rs && cargo clean

cairo:
	cd cairo && cargo build

blockifier:
	cd blockifier/crates/blockifier/ && cargo build

scarb:
	cd scarb && cargo build
	mkdir -p scarb/bin
	cp scarb/target/debug/scarb scarb/bin/
	cp scarb/target/debug/scarb-cairo-language-server scarb/bin/
	cp scarb/target/debug/scarb-cairo-run scarb/bin/
	cp scarb/target/debug/scarb-cairo-test scarb/bin/
	cp scarb/target/debug/scarb-snforge-test-collector scarb/bin/
	cp scarb/target/debug/scarb-test-support scarb/bin/


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
