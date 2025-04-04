process PANGOLIN_UPDATEDATA {
    tag "$dbname"
    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/bb/bb7bac48e43a9cd6274e1f99c761a5785b74f6d8a55313ee634aaffbe87c1869/data' :
        'community.wave.seqera.io/library/pangolin-data_pangolin_snakemake:5bbc297f7502ff33' }"

    input:
    val(dbname)

    output:
    path("${prefix}")   , emit: db
    path "versions.yml" , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    prefix = task.ext.prefix ?: "${dbname}"
    """
    export XDG_CACHE_HOME=/tmp/.cache
    mkdir -p ${prefix}

    pangolin \\
        $args \\
        --update-data \\
        --threads $task.cpus \\
        --datadir ${prefix}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        pangolin: \$(pangolin --version | sed "s/pangolin //g")
    END_VERSIONS
    """

    stub:
    prefix = task.ext.prefix ?: "${dbname}"
    """
    mkdir -p ${prefix}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        pangolin: \$(pangolin --version | sed "s/pangolin //g")
    END_VERSIONS
    """
}
