use std::process::Output;
use tokio::process::Command as TokioCommand;
use futures::future::join_all;

async fn run_command(command: &str, args: &[&str]) -> std::io::Result<Output> {
    let mut cmd = TokioCommand::new(command);
    cmd.args(args);
    cmd.output().await
}

#[tokio::main]
async fn main() -> std::io::Result<()> {
    let sm_manager_path = r"C:\Users\dansh\OneDrive\Dokumenty\HONOURS PROJECT\Implementations\multi-party-ecdsa-master-dan\multi-party-ecdsa-master\target\release\examples\gg20_sm_manager.exe";
    let keygen_path = r"C:\Users\dansh\OneDrive\Dokumenty\HONOURS PROJECT\Implementations\multi-party-ecdsa-master-dan\multi-party-ecdsa-master\target\release\examples\gg20_keygen.exe";
    let signing_path = r"C:\Users\dansh\OneDrive\Dokumenty\HONOURS PROJECT\Implementations\multi-party-ecdsa-master-dan\multi-party-ecdsa-master\target\release\examples\gg20_signing.exe";

    let command = sm_manager_path;
    let args = ["-p", "8000", "-t", "keygen", "-n", "3", "-s", "3"];
    println!("Starting SM manager...");
    let sm_manager_future = tokio::spawn(async move { run_command(&command, &args).await });

    tokio::time::sleep(tokio::time::Duration::from_secs(5)).await;

    let keygen_commands = vec![
        (keygen_path, &["-t", "2", "-n", "5", "-i", "1", "--output", "local-share1.json"]),
        (keygen_path, &["-t", "2", "-n", "5", "-i", "2", "--output", "local-share2.json"]),
        (keygen_path, &["-t", "2", "-n", "5", "-i", "3", "--output", "local-share3.json"]),
        (keygen_path, &["-t", "2", "-n", "5", "-i", "4", "--output", "local-share4.json"]),
        (keygen_path, &["-t", "2", "-n", "5", "-i", "5", "--output", "local-share5.json"])
    ];

    println!("Starting keygen tasks...");
    let keygen_futures = keygen_commands
        .into_iter()
        .map(|(command, args)| tokio::spawn(async move { run_command(command, &args[..]).await }));

    let results = join_all(keygen_futures).await;
    for result in results {
        let output = result??;
        if output.status.success() {
            println!(
                "Keygen exited with status code {}",
                output.status.code().unwrap_or(-1)
            );
        } else {
            eprintln!("Keygen task failed with status code {:?}", output.status.code());
        }
    }

    println!("Starting signing tasks...");
    let signing_commands = vec![
        (signing_path, &["-p", "1,2,3", "-d", "hello", "-l", "local-share1.json"]),
        (signing_path, &["-p", "1,2,3", "-d", "hello", "-l", "local-share2.json"]),
        (signing_path, &["-p", "1,2,3", "-d", "hello", "-l", "local-share3.json"])
    ];

    let signing_futures = signing_commands
        .into_iter()
        .map(|(command, args)| run_command(command, &args[..]));

        let results = futures::future::join_all(signing_futures).await;
        for result in results {
            let output = result?;
            if output.status.success() {
                println!(
                    "Signing exited with status code {}",
                    output.status.code().unwrap_or(-1)
                );
            } else {
                eprintln!("Signing task failed with status code {:?}", output.status.code());
            }
        }
    
        println!("Terminating SM server...");
        let sm_manager_output = sm_manager_future.await??;
        if sm_manager_output.status.success() {
            println!(
                "SM manager exited with status code {}",
                sm_manager_output.status.code().unwrap_or(-1)
            );
        } else {
            eprintln!("SM manager task failed with status code {:?}", sm_manager_output.status.code());
        }
    
        Ok(())
    }
    
