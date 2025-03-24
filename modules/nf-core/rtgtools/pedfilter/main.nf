// Function to validate and return the compression level option
def compressionLevelOption(level) {
    if (!(level instanceof Integer)) {
        throw new IllegalArgumentException("Compression level must be an integer.")
    }
    if (level < 1 || level > 9) {
        throw new IllegalArgumentException("Compression level must be between 1 and 9.")
    }
    return "--compression-level=${level}"
}

// Function to process the --keep-family option.
// Accepts either a comma-separated String or a Collection of strings.
def processKeepFamilyString(input) {
    if (input == null) {
        return []
    }
    def values
    if (input instanceof String) {
        values = input.split(',').collect { it.trim() }.findAll { it }
    } else if (input instanceof Collection) {
        values = input.collect { it.toString().trim() }.findAll { it }
    } else {
        throw new IllegalArgumentException("The --keep-family option must be a string or a list of strings.")
    }
    return values.collect { "--keep-family=${it}" }
}

// Function to process the --keep-ids option.
// Accepts either a comma-separated String or a Collection of strings.
def processKeepIdString(input) {
    if (input == null) {
        return []
    }
    def values
    if (input instanceof String) {
        values = input.split(',').collect { it.trim() }.findAll { it }
    } else if (input instanceof Collection) {
        values = input.collect { it.toString().trim() }.findAll { it }
    } else {
        throw new IllegalArgumentException("The --keep-ids option must be a string or a list of strings.")
    }
    return values.collect { "--keep-ids=${it}" }
}


def familyLevelOption(level) {
    if (!(str instanceof String)) {
        throw new IllegalArgumentException("Compression level must be a String.")
    }

process RTGTOOLS_PEDFILTER {
    tag "$meta.id"
    label 'process_low'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/rtg-tools:3.12.1--hdfd78af_0':
        'biocontainers/rtg-tools:3.12.1--hdfd78af_0' }"

    input:
    tuple val(meta), path(input)

    output:
    tuple val(meta), path("*.{vcf.gz,ped}") , emit: output
    path "versions.yml"                     , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def args2 = task.ext.args2 ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"

    def keep_family=processKeepFamilyString(task.ext.keepFamily)
    def keep_ids=processKeepIdString(task.ext.keepIds)
    def keep_primary = task.ext.keep_primary == true ? '--keep-primary' : ''
    def remove_parentage = task.ext.remove_parentage == true ? '--remove-parentage' : ''


    def compressionLevel = compressionLevelOption(task.ext.compressionLevel) 

    def decompress   = task.ext.decompress   == true ? '--decompress' : ''
    def force        = task.ext.force        == true ? '--force' : ''
    def no_terminate = task.ext.no_terminate == true ? '--no-terminate' : ''
    def stdout       = task.ext.stdout       == true ? '--stdout' : ''


    def extension = args.contains("--vcf") ? "vcf.gz" : "ped"

    if( "${prefix}.${extension}" == "${input}" ) {
        error "The input and output file have the same name, please use another ext.prefix."
    }

    def postprocess = extension == "vcf.gz" ? "| rtg bgzip ${args2} ${compressionLevel} ${decompress} ${force} ${no_terminate} ${stdout} -" : ""

    """
    rtg pedfilter \\
        ${args} \\
        ${keep_family} \\
        ${keep_ids}\\
        ${keep_primary} \\
        ${remove_parentage}
        ${input} \\
    ${postprocess} > ${prefix}.${extension}


    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        rtgtools: \$(echo \$(rtg version | head -n 1 | awk '{print \$4}'))
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"

    def extension = args.contains("--vcf") ? "vcf.gz" : "ped"

    if( "${prefix}.${extension}" == "${input}" ) {
        error "The input and output file have the same name, please use another ext.prefix."
    }

    """
    touch ${prefix}.${extension}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        rtgtools: \$(echo \$(rtg version | head -n 1 | awk '{print \$4}'))
    END_VERSIONS
    """
}
