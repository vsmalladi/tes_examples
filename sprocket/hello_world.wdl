version 1.3

task hello_world {
    meta {
        description: "Minimal hello world task for Sprocket using WDL 1.3"
        author: "Venkat Malladi"
    }

    command <<<
        set -euo pipefail
        echo "Hello World from Sprocket" > output.txt
    >>>

    requirements {
        container: "ubuntu:22.04"
        cpu: 1
    }

    hints {
        preemptible: 1
    }
}

workflow hello_world_workflow {
    meta {
        description: "Hello world workflow for Sprocket"
    }

    call hello_world

}
