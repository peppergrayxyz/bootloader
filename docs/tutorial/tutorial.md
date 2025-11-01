# Tutorial: create and boot a minimal OS

A step by step guide to setup bootloader with your kernel.

### 1. Create a new os crate at the top level that defines a workspace

```sh,tutorial
$ cargo new basic --bin
$ cd basic
```
```sh,tutorial,bashtestmd:raw
$ cat >> Cargo.toml <<EOL

[workspace]
resolver = "3"
EOL
```
```sh,tutorial,bashtestmd:raw
$ cat > basic-os.md <<EOL
# basic-os

A minimal os to showcase the usage of bootloader.
EOL
```
```sh,tutorial,bashtestmd:raw
$ cat > .gitignore <<EOL
/target/
**/*.rs.bk
EOL
```

### 2. Add bootloader to the workspace

#### 2.1 Add a build-dependencies on the bootloader crate

```sh,tutorial
$ cargo add --build bootloader
```

#### 2.2 Create a [build.rs](https://doc.rust-lang.org/cargo/reference/build-scripts.html) build script

```sh,tutorial,bashtestmd:raw
$ cat > build.rs <<EOL
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
```

#### 2.3 Set up an [artifact dependency](https://doc.rust-lang.org/nightly/cargo/reference/unstable.html#artifact-dependencies) to add your kernel crate as a build-dependency: 

Enable the unstable artifact-dependencies feature:
```sh,tutorial,bashtestmd:raw
$ mkdir .cargo
$ cat > .cargo/config.toml <<EOF
[unstable]
bindeps = true
EOF
$ cat > rust-toolchain.toml <<EOF
[toolchain]
channel = "nightly"
components = ["rustfmt", "clippy"]
targets = ["x86_64-unknown-none"]
EOF
```

Add your kernel crate as a build-dependency:

```sh,tutorial,bashtestmd:raw
$ sed -i '/^\[build-dependencies\]$/r /dev/stdin' Cargo.toml <<'EOF'
kernel = { path = "kernel", artifact = "bin", target = "x86_64-unknown-none" }
EOF
```

### 3. Move your full kernel code into a kernel subdirectory

#### 3.1 Copy your existing kernel or create a new one

Here we re-use `basic_boot` from default-settings test kernels to create a new kernel:

```sh,tutorial
$ cargo new kernel --bin
$ cp .gitignore kernel/
$ cd kernel
```
```sh,tutorial,bashtestmd:raw
$ cat > basic-kernel.md <<EOL
# basic-kernel

A minimal kernel to showcase the usage of bootloader.
EOL
```
```sh,tutorial,bashtestmd:raw
$ cat > src/main.rs <<EOF
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
```
Add dependencies:

```sh,tutorial
$ cargo add bootloader_api
$ cargo add x86_64 --features instructions
$ cargo add uart_16550
```

Check [README.md#kernel](/README.md#kernel) how to make your kernel compatible with bootloader.

#### 3.2 Compile your kernel 

Compile your kernel to an ELF executable by running cargo build --target x86_64-unknown-none. You might need to run rustup target add x86_64-unknown-none before to download precompiled versions of the core and alloc crates.

```sh,tutorial
$ rustup target add x86_64-unknown-none
```

```sh,tutorial,bashtestmd:raw
$ mkdir .cargo
$ cat > .cargo/config.toml <<EOF
[build]
target = "x86_64-unknown-none"
EOF
```
```sh,tutorial
$ cargo build
```

#### 3.3 Compile the workspace

```sh,tutorial
$ cd ..
$ cargo build
```

### 4. Do something with the bootable disk images

For example, run them with QEMU

#### 4.1 Create a qemu launcher

```sh,tutorial,bashtestmd:raw
$ cargo add ovmf-prebuilt
$ cat > src/main.rs <<EOF
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
```

#### 4.1 Run the kernel

Check for return code 33 (0x10) for success:

```sh,tutorial
$ cargo run -- bios || [ $? -eq 33 ]
```
```sh,tutorial
$ cargo run -- uefi || [ $? -eq 33 ]
```

## Generate basic example

The [basic example](/examples/basic) is generated from this tutorial. 

Convert `tutorial.md` to `tutorial.sh`:
```sh
$ cargo make convert
```
Create [basic example](/examples/basic) from `tutorial.sh`:
```sh
$ cargo make create
```

The tutorial can be used as a boilerplate for your project, by calling `tutorial.sh` from an arbitrary directory.
