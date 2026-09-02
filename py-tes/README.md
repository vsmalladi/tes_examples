# py-tes Demonstration

License: this example is licensed under MIT. See [../LICENSE](../LICENSE).


## Client requirements

You can install all client dependencies using [UV](https://github.com/astral-sh/uv).

```bash
uv --version
uv venv .venv
source .venv/bin/activate
uv pip install -r requirements.txt
```


Next, you need to create a file of the TES instance in a
comma-separated file `.tes_instances`. Two fields/columns are required, a
description of the TES instance, and the URL pointing to it. Only the first
line is used by the script. You can use the following command to create such
a file, but make sure to replace the example contents and do not use commas
in the name/description field:

```bash
cat << "EOF" > .tes_instances
Azure/TES @ YourNode,https://tes.your-node.org/
EOF
```

Finally, you will need to create a secrets file `.env` with the following
command.  You can either set the environment variables in your shell or set the
actual values in the command below.

```bash
cat << EOF > .env
TES_SERVER_USER=$TES_SERVER_USER
TES_SERVER_PASSWORD=$TES_SERVER_PASSWORD
TES_OUTPUT_STORAGE_PATH=$TES_OUTPUT_STORAGE_PATH
EOF
```

TES_OUTPUT_STORAGE_PATH is a URL path prefix (e.g. `file:///path/to/output/dir`)
that the script appends `output.txt` to when building the task's output URL.

## Run demo

We have created two examples to test fundamentals and also a bioinformatics workflow;

1. Hello World example:

```bash
./.venv/bin/python hello-world.py
```

## Viewing Results

After the task completes, the output file will be written to the location
specified by TES_OUTPUT_STORAGE_PATH in `.env`.
