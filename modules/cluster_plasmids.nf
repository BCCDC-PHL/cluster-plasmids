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





process mafft {

    tag { plasmid_id_1 + ' / ' + plasmid_id_2 }

    input:
    tuple val(plasmid_id_1), val(plasmid_id_2),  path(input)

    output:
    tuple val(plasmid_id_1), val(plasmid_id_2),  path("${plasmid_id_1}_vs_${plasmid_id_2}.aln.fa")
    
    script:
    """
    mafft \
      --auto \
      --thread ${task.cpus} \
      --input ${input} > ${plasmid_id_1}_vs_${plasmid_id_2}.aln.fa
    """
}
