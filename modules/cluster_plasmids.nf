process extract_individual_plasmids {
    executor 'local'
    
    input:
    path(plasmid_db)

    output:
    path("plasmids")
    
    script:
    """
    extract_individual_plasmids.py \
      ${plasmid_db} \
      -o plasmids
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


process pairwise_align {

    tag { plasmid_id_1 + ' / ' + plasmid_id_2 }

    publishDir "${params.outdir}/pairwise_alignments/${plasmid_id_1}", pattern: "*.aln.fa", mode: "copy"

    input:
    tuple val(plasmid_id_1), val(plasmid_id_2), path(all_plasmids)

    output:
    tuple val(plasmid_id_1), val(plasmid_id_2),  path("${plasmid_id_1}_vs_${plasmid_id_2}.aln.fa")
    
    script:
    """
    extract_plasmid_by_id.py --id ${plasmid_id_1} ${all_plasmids} -o . 
    extract_plasmid_by_id.py --id ${plasmid_id_2} ${all_plasmids} -o .
    cat ${plasmid_id_1}.fa ${plasmid_id_2}.fa > plasmids_to_align.fa

    mafft \
      --auto \
      --thread ${task.cpus} \
      plasmids_to_align.fa > ${plasmid_id_1}_vs_${plasmid_id_2}.aln.fa
    """
}

process evaluate_pairwise_alignment {

    tag { plasmid_id_1 + ' / ' + plasmid_id_2 }

    executor 'local'

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
