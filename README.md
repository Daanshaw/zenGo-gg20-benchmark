ZenGo-GG20-ECDSA-Benchmark This repository contains a PowerShell script that benchmarks the performance of ZenGo's multi-party ECDSA GG20 protocol implementation. The script measures the time required for key generation and signing operations for a specified threshold and number of parties.

How to run the benchmark?

You need Rust and GMP library (optionally) to be installed on your computer.

Run cargo build --release --examples Don't have GMP installed? Use this command instead: cargo build --release --examples --no-default-features --features curv-kzen/num-bigint

Either of commands will produce binaries into ./target/release/examples/ folder.

Run gg20_demo.ps1. Input the number of parties and threshold.

After every run the files (local-sharex) created in ./target/release/examples/ folder must be deleted before running the program again.  
