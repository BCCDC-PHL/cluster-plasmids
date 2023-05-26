process extract_individual_plasmids {

    executor 'local'

    publishDir "${params.outdir}", pattern: "individual_plasmids", mode: "copy"

    input:
    path(plasmid_db)

    output:
    path("individual_plasmids")
    
    script:
    """
    extract_individual_plasmids.py \
      ${plasmid_db} \
      -o individual_plasmids
    """
}


process identify_resistance_genes {

    publishDir "${params.outdir}", pattern: "plasmid_resistance_genes.tsv", mode: "copy"

    input:
    path(plasmid_db)

    output:
    path("plasmid_resistance_genes.tsv")

    script:
    """
    abricate \
      --db ncbi \
      ${plasmid_db} \
      > plasmid_resistance_genes.tsv
    """
}


process identify_replicons {

    publishDir "${params.outdir}", pattern: "plasmid_replicons.tsv", mode: "copy"

    input:
    path(plasmid_db)

    output:
    path("plasmid_replicons.tsv")

    script:
    """
    abricate \
      --db plasmidfinder \
      ${plasmid_db} \
      > plasmid_replicons.tsv
    """
}



process sketch_plasmid_db {

    input:
    path(plasmid_db)

    output:
    path("plasmid_db.msh")
    
    script:
    """
    mash sketch -i \
      -p ${task.cpus} \
      ${plasmid_db} \
      -o plasmid_db
    """
}

process create_mash_distance_matrix {

    executor 'local'
    
    publishDir "${params.outdir}", pattern: "mash_distance_matrix.csv", mode: "copy"

    input:
    tuple path(plasmid_db_sketch), path(plasmids)

    output:
    path("mash_distance_matrix.csv")
    
    script:
    """
    create_mash_dist_matrix.py \
      -s ${plasmid_db_sketch} \
      ${plasmids} \
      > mash_distance_matrix.csv
    """
}


process find_similar_plasmids {

    executor 'local'

    input:
    path(mash_distance_matrix)

    output:
    path("similar_plasmids.csv")
    
    script:
    """
    echo "query_plasmid_id,similar_plasmid_id,distance" > similar_plasmids.csv
 
    find_similar_plasmids.py \
      -m ${mash_distance_matrix} \
      -d ${params.mash_distance_threshold} \
      >> similar_plasmids.csv
    """
}

process remove_duplicates {

    executor 'local'
    
    input:
    path(similar_plasmids)

    output:
    path("similar_plasmids_deduplicated.csv")
    
    script:
    """
    echo "query_plasmid_id,similar_plasmid_id,distance" > similar_plasmids_deduplicated.csv
    remove_duplicates.py ${similar_plasmids} > similar_plasmids_deduplicated.csv
    """
}

process extract_plasmid_pair {

    executor 'local'

    tag { plasmid_id_1 + ' / ' + plasmid_id_2 }

    input:
    tuple val(plasmid_id_1), val(plasmid_id_2), path(all_plasmids)

    output:
    tuple val(plasmid_id_1), val(plasmid_id_2),  path("${plasmid_id_1}.fa"), path("${plasmid_id_2}.fa")
    
    script:
    """
    extract_plasmid_by_id.py --id ${plasmid_id_1} ${all_plasmids} -o .
    extract_plasmid_by_id.py --id ${plasmid_id_2} ${all_plasmids} -o .
    """
}


process pairwise_align {

    tag { plasmid_id_1 + ' / ' + plasmid_id_2 }

    publishDir "${params.outdir}/pairwise_alignments/${plasmid_id_1}", pattern: "*.aln.fa", mode: "copy"
    publishDir "${params.outdir}/pairwise_alignments/${plasmid_id_2}", pattern: "*.aln.fa", mode: "copy"
    publishDir "${params.outdir}/pairwise_alignments/${plasmid_id_1}", pattern: "{plasmid_id_1}.fa", mode: "copy"
    publishDir "${params.outdir}/pairwise_alignments/${plasmid_id_1}", pattern: "{plasmid_id_2}.fa", mode: "copy"
    publishDir "${params.outdir}/pairwise_alignments/${plasmid_id_2}", pattern: "{plasmid_id_1}.fa", mode: "copy"
    publishDir "${params.outdir}/pairwise_alignments/${plasmid_id_2}", pattern: "{plasmid_id_2}.fa", mode: "copy"


    input:
    tuple val(plasmid_id_1), val(plasmid_id_2), path(plasmid_1), path(plasmid_2)

    output:
    tuple val(plasmid_id_1), val(plasmid_id_2),  path("${plasmid_id_1}_vs_${plasmid_id_2}.aln.fa")
    
    script:
    """
    cat ${plasmid_1} ${plasmid_2} > plasmids_to_align.fa

    mafft \
      --auto \
      --thread ${task.cpus} \
      plasmids_to_align.fa > ${plasmid_id_1}_vs_${plasmid_id_2}.aln.fa
    """
}

process dotpath {

    tag { plasmid_id_1 + ' / ' + plasmid_id_2 }

    publishDir "${params.outdir}/pairwise_alignments/${plasmid_id_1}", pattern: "${plasmid_id_1}_vs_${plasmid_id_2}_dotpath.png", mode: "copy"
    publishDir "${params.outdir}/pairwise_alignments/${plasmid_id_2}", pattern: "${plasmid_id_1}_vs_${plasmid_id_2}_dotpath.png", mode: "copy"

    input:
    tuple val(plasmid_id_1), val(plasmid_id_2), path(plasmid_1), path(plasmid_2)

    output:
    tuple val(plasmid_id_1), val(plasmid_id_2),  path("${plasmid_id_1}_vs_${plasmid_id_2}_dotpath.png")
    
    script:
    """
    dotpath ${plasmid_1} ${plasmid_2} -word ${params.dotpath_wordsize} -graph png -gtitle "${plasmid_id_1} Vs. ${plasmid_id_2}"
    mv dotpath.1.png ${plasmid_id_1}_vs_${plasmid_id_2}_dotpath.png
    """
}

process dotmatcher {

    tag { plasmid_id_1 + ' / ' + plasmid_id_2 }

    publishDir "${params.outdir}/pairwise_alignments/${plasmid_id_1}", pattern: "${plasmid_id_1}_vs_${plasmid_id_2}_dotmatcher.png", mode: "copy"
    publishDir "${params.outdir}/pairwise_alignments/${plasmid_id_2}", pattern: "${plasmid_id_1}_vs_${plasmid_id_2}_dotmatcher.png", mode: "copy"

    input:
    tuple val(plasmid_id_1), val(plasmid_id_2), path(plasmid_1), path(plasmid_2)

    output:
    tuple val(plasmid_id_1), val(plasmid_id_2),  path("${plasmid_id_1}_vs_${plasmid_id_2}_dotmatcher.png")
    
    script:
    """
    dotmatcher ${plasmid_1} ${plasmid_2} -windowsize ${params.dotmatcher_windowsize} -graph png -gtitle "${plasmid_id_1} Vs. ${plasmid_id_2}"
    mv dotmatcher.1.png ${plasmid_id_1}_vs_${plasmid_id_2}_dotmatcher.png
    """
}

process evaluate_pairwise_alignment {

    tag { plasmid_id_1 + ' / ' + plasmid_id_2 }

    publishDir "${params.outdir}/pairwise_alignments/${plasmid_id_1}", pattern: "*_alignment_metrics.csv", mode: "copy"
    
    input:
    tuple val(plasmid_id_1), val(plasmid_id_2), path(alignment)

    output:
    path("${plasmid_id_1}_vs_${plasmid_id_2}_alignment_metrics.csv")
    
    script:
    """
    evaluate_pairwise_alignment.py ${alignment} > ${plasmid_id_1}_vs_${plasmid_id_2}_alignment_metrics.csv
    """
}

