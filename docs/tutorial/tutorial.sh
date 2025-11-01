#!/usr/bin/env bash
shopt -sq expand_aliases
trap 'jobs -p | xargs -r kill' EXIT
check_and_output_long_running_output() {
    if [[ -n "$BASHTESTMD_LONG_RUNNING_OUTPUT" && -f "$BASHTESTMD_LONG_RUNNING_OUTPUT" ]]; then
        echo "Output of the long running task:"
        cat "$BASHTESTMD_LONG_RUNNING_OUTPUT"
    fi
}

echo 'Running: '\''cargo new basic --bin'\'''
cargo new basic --bin
exit_code=$?

if [ $exit_code -ne 0 ]; then
    echo "Expected exit code 0, got $exit_code"
    check_and_output_long_running_output
    exit 1
fi

echo 'Running: '\''cd basic'\'''
cd basic
exit_code=$?

if [ $exit_code -ne 0 ]; then
    echo "Expected exit code 0, got $exit_code"
    check_and_output_long_running_output
    exit 1
fi

echo 'Running: '\''cat >> Cargo.toml <<EOL

[workspace]
resolver = "3"
EOL'\'''
cat >> Cargo.toml <<EOL

[workspace]
resolver = "3"
EOL
exit_code=$?

if [ $exit_code -ne 0 ]; then
    echo "Expected exit code 0, got $exit_code"
    check_and_output_long_running_output
    exit 1
fi

echo 'Running: '\''cat > basic-os.md <<EOL
# basic-os

A minimal os to showcase the usage of bootloader.
EOL'\'''
cat > basic-os.md <<EOL
# basic-os

A minimal os to showcase the usage of bootloader.
EOL
exit_code=$?

if [ $exit_code -ne 0 ]; then
    echo "Expected exit code 0, got $exit_code"
    check_and_output_long_running_output
    exit 1
fi

echo 'Running: '\''cat > .gitignore <<EOL
/target/
**/*.rs.bk
EOL'\'''
cat > .gitignore <<EOL
/target/
**/*.rs.bk
EOL
exit_code=$?

if [ $exit_code -ne 0 ]; then
    echo "Expected exit code 0, got $exit_code"
    check_and_output_long_running_output
    exit 1
fi

echo 'Running: '\''cargo add --build bootloader'\'''
cargo add --build bootloader
exit_code=$?

if [ $exit_code -ne 0 ]; then
    echo "Expected exit code 0, got $exit_code"
    check_and_output_long_running_output
    exit 1
fi

echo 'Running: '\''cat > build.rs <<EOL
use std::path::PathBuf;

fn main() {
    // set by cargo, build scripts should use this directory for output files
    let out_dir = PathBuf::from(std::env::var_os("OUT_DIR").unwrap());
    // set by cargo'\''s artifact dependency feature, see
    // https://doc.rust-lang.org/nightly/cargo/reference/unstable.html#artifact-dependencies
    let kernel = PathBuf::from(std::env::var_os("CARGO_BIN_FILE_KERNEL_kernel").unwrap());

    // create an UEFI disk image (optional)
    let uefi_path = out_dir.join("uefi.img");
    bootloader::UefiBoot::new(&kernel)
        .create_disk_image(&uefi_path)
        .unwrap();

    // create a BIOS disk image
    let bios_path = out_dir.join("bios.img");
    bootloader::BiosBoot::new(&kernel)
        .create_disk_image(&bios_path)
        .unwrap();

    // pass the disk image paths as env variables to the
    println'\!'("cargo:rustc-env=UEFI_PATH={}", uefi_path.display());
    println'\!'("cargo:rustc-env=BIOS_PATH={}", bios_path.display());
}
EOL'\'''
cat > build.rs <<EOL
use std::path::PathBuf;

fn main() {
    // set by cargo, build scripts should use this directory for output files
    let out_dir = PathBuf::from(std::env::var_os("OUT_DIR").unwrap());
    // set by cargo's artifact dependency feature, see
    // https://doc.rust-lang.org/nightly/cargo/reference/unstable.html#artifact-dependencies
    let kernel = PathBuf::from(std::env::var_os("CARGO_BIN_FILE_KERNEL_kernel").unwrap());

    // create an UEFI disk image (optional)
    let uefi_path = out_dir.join("uefi.img");
    bootloader::UefiBoot::new(&kernel)
        .create_disk_image(&uefi_path)
        .unwrap();

    // create a BIOS disk image
    let bios_path = out_dir.join("bios.img");
    bootloader::BiosBoot::new(&kernel)
        .create_disk_image(&bios_path)
        .unwrap();

    // pass the disk image paths as env variables to the
    println!("cargo:rustc-env=UEFI_PATH={}", uefi_path.display());
    println!("cargo:rustc-env=BIOS_PATH={}", bios_path.display());
}
EOL
exit_code=$?

if [ $exit_code -ne 0 ]; then
    echo "Expected exit code 0, got $exit_code"
    check_and_output_long_running_output
    exit 1
fi

echo 'Running: '\''mkdir .cargo'\'''
mkdir .cargo
exit_code=$?

if [ $exit_code -ne 0 ]; then
    echo "Expected exit code 0, got $exit_code"
    check_and_output_long_running_output
    exit 1
fi

echo 'Running: '\''cat > .cargo/config.toml <<EOF
[unstable]
bindeps = true
EOF'\'''
cat > .cargo/config.toml <<EOF
[unstable]
bindeps = true
EOF
exit_code=$?

if [ $exit_code -ne 0 ]; then
    echo "Expected exit code 0, got $exit_code"
    check_and_output_long_running_output
    exit 1
fi

echo 'Running: '\''cat > rust-toolchain.toml <<EOF
[toolchain]
channel = "nightly"
components = ["rustfmt", "clippy"]
targets = ["x86_64-unknown-none"]
EOF'\'''
cat > rust-toolchain.toml <<EOF
[toolchain]
channel = "nightly"
components = ["rustfmt", "clippy"]
targets = ["x86_64-unknown-none"]
EOF
exit_code=$?

if [ $exit_code -ne 0 ]; then
    echo "Expected exit code 0, got $exit_code"
    check_and_output_long_running_output
    exit 1
fi

echo 'Running: '\''sed -i '\''/^\[build-dependencies\]$/r /dev/stdin'\'' Cargo.toml <<'\''EOF'\''
kernel = { path = "kernel", artifact = "bin", target = "x86_64-unknown-none" }
EOF'\'''
sed -i '/^\[build-dependencies\]$/r /dev/stdin' Cargo.toml <<'EOF'
kernel = { path = "kernel", artifact = "bin", target = "x86_64-unknown-none" }
EOF
exit_code=$?

if [ $exit_code -ne 0 ]; then
    echo "Expected exit code 0, got $exit_code"
    check_and_output_long_running_output
    exit 1
fi

echo 'Running: '\''cargo new kernel --bin'\'''
cargo new kernel --bin
exit_code=$?

if [ $exit_code -ne 0 ]; then
    echo "Expected exit code 0, got $exit_code"
    check_and_output_long_running_output
    exit 1
fi

echo 'Running: '\''cp .gitignore kernel/'\'''
cp .gitignore kernel/
exit_code=$?

if [ $exit_code -ne 0 ]; then
    echo "Expected exit code 0, got $exit_code"
    check_and_output_long_running_output
    exit 1
fi

echo 'Running: '\''cd kernel'\'''
cd kernel
exit_code=$?

if [ $exit_code -ne 0 ]; then
    echo "Expected exit code 0, got $exit_code"
    check_and_output_long_running_output
    exit 1
fi

echo 'Running: '\''cat > basic-kernel.md <<EOL
# basic-kernel

A minimal kernel to showcase the usage of bootloader.
EOL'\'''
cat > basic-kernel.md <<EOL
# basic-kernel

A minimal kernel to showcase the usage of bootloader.
EOL
exit_code=$?

if [ $exit_code -ne 0 ]; then
    echo "Expected exit code 0, got $exit_code"
    check_and_output_long_running_output
    exit 1
fi

echo 'Running: '\''cat > src/main.rs <<EOF
#'\!'[no_std] // don'\''t link the Rust standard library
#'\!'[no_main] // disable all Rust-level entry points

use bootloader_api::{BootInfo, entry_point};
use core::fmt::Write;

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
#[repr(u32)]
pub enum QemuExitCode {
    Success = 0x10,
    Failed = 0x11,
}

pub fn exit_qemu(exit_code: QemuExitCode) -> '\!' {
    use x86_64::instructions::{nop, port::Port};

    unsafe {
        let mut port = Port::new(0xf4);
        port.write(exit_code as u32);
    }

    loop {
        nop();
    }
}

pub fn serial() -> uart_16550::SerialPort {
    let mut port = unsafe { uart_16550::SerialPort::new(0x3F8) };
    port.init();
    port
}

entry_point'\!'(kernel_main);

fn kernel_main(boot_info: &'\''static mut BootInfo) -> '\!' {
    writeln'\!'(serial(), "Entered kernel with boot info: {boot_info:?}").unwrap();
    writeln'\!'(serial(), "\n=(^.^)= meow\n").unwrap();
    exit_qemu(QemuExitCode::Success);
}

/// This function is called on panic.
#[panic_handler]
#[cfg(not(test))]
fn panic(info: &core::panic::PanicInfo) -> '\!' {
    let _ = writeln'\!'(serial(), "PANIC: {info}");
    exit_qemu(QemuExitCode::Failed);
}
EOF'\'''
cat > src/main.rs <<EOF
#![no_std] // don't link the Rust standard library
#![no_main] // disable all Rust-level entry points

use bootloader_api::{BootInfo, entry_point};
use core::fmt::Write;

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
#[repr(u32)]
pub enum QemuExitCode {
    Success = 0x10,
    Failed = 0x11,
}

pub fn exit_qemu(exit_code: QemuExitCode) -> ! {
    use x86_64::instructions::{nop, port::Port};

    unsafe {
        let mut port = Port::new(0xf4);
        port.write(exit_code as u32);
    }

    loop {
        nop();
    }
}

pub fn serial() -> uart_16550::SerialPort {
    let mut port = unsafe { uart_16550::SerialPort::new(0x3F8) };
    port.init();
    port
}

entry_point!(kernel_main);

fn kernel_main(boot_info: &'static mut BootInfo) -> ! {
    writeln!(serial(), "Entered kernel with boot info: {boot_info:?}").unwrap();
    writeln!(serial(), "\n=(^.^)= meow\n").unwrap();
    exit_qemu(QemuExitCode::Success);
}

/// This function is called on panic.
#[panic_handler]
#[cfg(not(test))]
fn panic(info: &core::panic::PanicInfo) -> ! {
    let _ = writeln!(serial(), "PANIC: {info}");
    exit_qemu(QemuExitCode::Failed);
}
EOF
exit_code=$?

if [ $exit_code -ne 0 ]; then
    echo "Expected exit code 0, got $exit_code"
    check_and_output_long_running_output
    exit 1
fi

echo 'Running: '\''cargo add bootloader_api'\'''
cargo add bootloader_api
exit_code=$?

if [ $exit_code -ne 0 ]; then
    echo "Expected exit code 0, got $exit_code"
    check_and_output_long_running_output
    exit 1
fi

echo 'Running: '\''cargo add x86_64 --features instructions'\'''
cargo add x86_64 --features instructions
exit_code=$?

if [ $exit_code -ne 0 ]; then
    echo "Expected exit code 0, got $exit_code"
    check_and_output_long_running_output
    exit 1
fi

echo 'Running: '\''cargo add uart_16550'\'''
cargo add uart_16550
exit_code=$?

if [ $exit_code -ne 0 ]; then
    echo "Expected exit code 0, got $exit_code"
    check_and_output_long_running_output
    exit 1
fi

echo 'Running: '\''rustup target add x86_64-unknown-none'\'''
rustup target add x86_64-unknown-none
exit_code=$?

if [ $exit_code -ne 0 ]; then
    echo "Expected exit code 0, got $exit_code"
    check_and_output_long_running_output
    exit 1
fi

echo 'Running: '\''mkdir .cargo'\'''
mkdir .cargo
exit_code=$?

if [ $exit_code -ne 0 ]; then
    echo "Expected exit code 0, got $exit_code"
    check_and_output_long_running_output
    exit 1
fi

echo 'Running: '\''cat > .cargo/config.toml <<EOF
[build]
target = "x86_64-unknown-none"
EOF'\'''
cat > .cargo/config.toml <<EOF
[build]
target = "x86_64-unknown-none"
EOF
exit_code=$?

if [ $exit_code -ne 0 ]; then
    echo "Expected exit code 0, got $exit_code"
    check_and_output_long_running_output
    exit 1
fi

echo 'Running: '\''cargo build'\'''
cargo build
exit_code=$?

if [ $exit_code -ne 0 ]; then
    echo "Expected exit code 0, got $exit_code"
    check_and_output_long_running_output
    exit 1
fi

echo 'Running: '\''cd ..'\'''
cd ..
exit_code=$?

if [ $exit_code -ne 0 ]; then
    echo "Expected exit code 0, got $exit_code"
    check_and_output_long_running_output
    exit 1
fi

echo 'Running: '\''cargo build'\'''
cargo build
exit_code=$?

if [ $exit_code -ne 0 ]; then
    echo "Expected exit code 0, got $exit_code"
    check_and_output_long_running_output
    exit 1
fi

echo 'Running: '\''cargo add ovmf-prebuilt'\'''
cargo add ovmf-prebuilt
exit_code=$?

if [ $exit_code -ne 0 ]; then
    echo "Expected exit code 0, got $exit_code"
    check_and_output_long_running_output
    exit 1
fi

echo 'Running: '\''cat > src/main.rs <<EOF
use ovmf_prebuilt::{Arch, FileType, Prebuilt, Source};
use std::env;
use std::process::{Command, exit};

fn main() {
    // read env variables that were set in build script
    let uefi_path = env'\!'("UEFI_PATH");
    let bios_path = env'\!'("BIOS_PATH");

    // parse mode from CLI
    let args: Vec<String> = env::args().collect();
    let prog = &args[0];

    // choose whether to start the UEFI or BIOS image
    let uefi = match args.get(1).map(|s| s.to_lowercase()) {
        Some(ref s) if s == "uefi" => true,
        Some(ref s) if s == "bios" => false,
        Some(ref s) if s == "-h" || s == "--help" => {
            println'\!'("Usage: {prog} [uefi|bios]");
            println'\!'("  uefi  - boot using OVMF (UEFI)");
            println'\!'("  bios  - boot using legacy BIOS");
            exit(0);
        }
        _ => {
            eprintln'\!'("Usage: {prog} [uefi|bios]");
            exit(1);
        }
    };

    let mut cmd = Command::new("qemu-system-x86_64");
    cmd.arg("-serial").arg("mon:stdio");
    cmd.arg("-device")
        .arg("isa-debug-exit,iobase=0xf4,iosize=0x04");
    cmd.arg("-display").arg("none");

    if uefi {
        let prebuilt =
            Prebuilt::fetch(Source::LATEST, "target/ovmf").expect("failed to update prebuilt");

        let code = prebuilt.get_file(Arch::X64, FileType::Code);
        let vars = prebuilt.get_file(Arch::X64, FileType::Vars);

        cmd.arg("-drive")
            .arg(format'\!'("format=raw,file={uefi_path}"));
        cmd.arg("-drive").arg(format'\!'(
            "if=pflash,format=raw,unit=0,file={},readonly=on",
            code.display()
        ));
        cmd.arg("-drive").arg(format'\!'(
            "if=pflash,format=raw,unit=1,file={},snapshot=on",
            vars.display()
        ));
    } else {
        cmd.arg("-drive")
            .arg(format'\!'("format=raw,file={bios_path}"));
    }

    let mut child = cmd.spawn().expect("failed to start qemu-system-x86_64");
    let status = child.wait().expect("failed to wait on qemu");
    if '\!'status.success() {
        exit(status.code().unwrap_or(1));
    }
}
EOF'\'''
cat > src/main.rs <<EOF
use ovmf_prebuilt::{Arch, FileType, Prebuilt, Source};
use std::env;
use std::process::{Command, exit};

fn main() {
    // read env variables that were set in build script
    let uefi_path = env!("UEFI_PATH");
    let bios_path = env!("BIOS_PATH");

    // parse mode from CLI
    let args: Vec<String> = env::args().collect();
    let prog = &args[0];

    // choose whether to start the UEFI or BIOS image
    let uefi = match args.get(1).map(|s| s.to_lowercase()) {
        Some(ref s) if s == "uefi" => true,
        Some(ref s) if s == "bios" => false,
        Some(ref s) if s == "-h" || s == "--help" => {
            println!("Usage: {prog} [uefi|bios]");
            println!("  uefi  - boot using OVMF (UEFI)");
            println!("  bios  - boot using legacy BIOS");
            exit(0);
        }
        _ => {
            eprintln!("Usage: {prog} [uefi|bios]");
            exit(1);
        }
    };

    let mut cmd = Command::new("qemu-system-x86_64");
    cmd.arg("-serial").arg("mon:stdio");
    cmd.arg("-device")
        .arg("isa-debug-exit,iobase=0xf4,iosize=0x04");
    cmd.arg("-display").arg("none");

    if uefi {
        let prebuilt =
            Prebuilt::fetch(Source::LATEST, "target/ovmf").expect("failed to update prebuilt");

        let code = prebuilt.get_file(Arch::X64, FileType::Code);
        let vars = prebuilt.get_file(Arch::X64, FileType::Vars);

        cmd.arg("-drive")
            .arg(format!("format=raw,file={uefi_path}"));
        cmd.arg("-drive").arg(format!(
            "if=pflash,format=raw,unit=0,file={},readonly=on",
            code.display()
        ));
        cmd.arg("-drive").arg(format!(
            "if=pflash,format=raw,unit=1,file={},snapshot=on",
            vars.display()
        ));
    } else {
        cmd.arg("-drive")
            .arg(format!("format=raw,file={bios_path}"));
    }

    let mut child = cmd.spawn().expect("failed to start qemu-system-x86_64");
    let status = child.wait().expect("failed to wait on qemu");
    if !status.success() {
        exit(status.code().unwrap_or(1));
    }
}
EOF
exit_code=$?

if [ $exit_code -ne 0 ]; then
    echo "Expected exit code 0, got $exit_code"
    check_and_output_long_running_output
    exit 1
fi

echo 'Running: '\''cargo run -- bios || [ $? -eq 33 ]'\'''
cargo run -- bios || [ $? -eq 33 ]
exit_code=$?

if [ $exit_code -ne 0 ]; then
    echo "Expected exit code 0, got $exit_code"
    check_and_output_long_running_output
    exit 1
fi

echo 'Running: '\''cargo run -- uefi || [ $? -eq 33 ]'\'''
cargo run -- uefi || [ $? -eq 33 ]
exit_code=$?

if [ $exit_code -ne 0 ]; then
    echo "Expected exit code 0, got $exit_code"
    check_and_output_long_running_output
    exit 1
fi

echo "All tests passed!"; exit 0
