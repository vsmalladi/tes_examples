# St. Jude Sprocket + TES Demonstration

Demonstration of using **Sprocket** (the WDL 1.3 workflow engine from St. Jude Rust Labs) with a **TES (Task Execution Service) backend** to execute scientific workflows.

License: this example is licensed under MIT. See [../LICENSE](../LICENSE).


## Client Requirements

### Install Rust

Sprocket is written in Rust. You will need a recent Rust toolchain.

We recommend using [rustup](https://rustup.rs/) to accomplish this. 


Verify installation:
```bash
rustc --version
cargo --version
```

### Install Sprocket

Install the Sprocket CLI:
```bash
cargo install sprocket

# Verify
sprocket --version

```


## Sprocket Configuration (`sprocket.toml`)

Sprocket is configured using a `sprocket.toml` file. 


*   `inputs` and `outputs` typically reference Azure Blob Storage, S3, or GCS.
*   TES authentication is configured **once** in `sprocket.toml`, not inside workflows.
*   WDL workflows must not hard‑code storage URLs.

### Azure Storage 

For [Azure Storage](https://sprocket.bio/configuration/storage/azure.html#authentication) the recomended way in Sprocket is 

Use the `AZURE_ACCOUNT_NAME` and `AZURE_ACCESS_KEY` environment variables to configure Azure Blob Storage authentication in Sprocket.

This overrides any Azure Blob Storage authentication settings in `sprocket.toml`.

Use the `--azure-account-name` and `--azure-access-key` options to the sprocket run command to configure Azure Storage authentication in Sprocket.

## Run Sprocket Demos

All examples are written in **WDL 1.3** and executed using the Sprocket CLI.

You will need to set the environment variables in your shell.
```bash
export AZURE_ACCOUNT_NAME='<your-storage-account-name>'
export AZURE_ACCESS_KEY='<your-storage-access-key>'
```

### Hello World Example

This validates that Sprocket, Docker, and TES are wired correctly.
```bash
sprocket run hello_world.wdl --azure-account-name $AZURE_ACCOUNT_NAME --azure-access-key $AZURE_ACCESS_KEY
```

Expected behavior:

*   A container is launched
*   “Hello World from Sprocket” is written to stdout
*   Logs and metadata are saved in the Sprocket run directory

```
