#!/usr/bin/env nextflow

nextflow.enable.dsl = 2

include { extract_individual_plasmids } from './modules/cluster_plasmids.nf'
include { sketch_plasmid_db }           from './modules/cluster_plasmids.nf'
include { create_mash_distance_matrix } from './modules/cluster_plasmids.nf'
include { find_similar_plasmids }       from './modules/cluster_plasmids.nf'
include { remove_duplicates }           from './modules/cluster_plasmids.nf'
include { mafft }                       from './modules/cluster_plasmids.nf'

workflow {
  ch_db = Channel.fromPath(params.db)

  main:
    extract_individual_plasmids(ch_db)
    sketch_plasmid_db(ch_db)
    create_mash_distance_matrix(sketch_plasmid_db.out.combine(extract_individual_plasmids.out))
    find_similar_plasmids(create_mash_distance_matrix.out)
    remove_duplicates(find_similar_plasmids.out)
}
