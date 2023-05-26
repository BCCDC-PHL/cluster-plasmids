#!/usr/bin/env nextflow

nextflow.enable.dsl = 2

include { identify_resistance_genes }   from './modules/cluster_plasmids.nf'
include { identify_replicons }          from './modules/cluster_plasmids.nf'
include { extract_individual_plasmids } from './modules/cluster_plasmids.nf'
include { sketch_plasmid_db }           from './modules/cluster_plasmids.nf'
include { create_mash_distance_matrix } from './modules/cluster_plasmids.nf'
include { find_similar_plasmids }       from './modules/cluster_plasmids.nf'
include { remove_duplicates }           from './modules/cluster_plasmids.nf'
include { extract_plasmid_pair }        from './modules/cluster_plasmids.nf'
include { pairwise_align }              from './modules/cluster_plasmids.nf'
include { dotpath }                     from './modules/cluster_plasmids.nf'
include { dotmatcher }                  from './modules/cluster_plasmids.nf'
include { evaluate_pairwise_alignment } from './modules/cluster_plasmids.nf'

workflow {
  ch_db = Channel.fromPath(params.db)

  main:
    identify_resistance_genes(ch_db)
    identify_replicons(ch_db)
    extract_individual_plasmids(ch_db)
    sketch_plasmid_db(ch_db)
    create_mash_distance_matrix(sketch_plasmid_db.out.combine(extract_individual_plasmids.out))
    find_similar_plasmids(create_mash_distance_matrix.out)
    remove_duplicates(find_similar_plasmids.out)
    extract_plasmid_pair(remove_duplicates.out.splitCsv().map{ it -> [it[0], it[1]] }.combine(ch_db))
    pairwise_align(extract_plasmid_pair.out)
    dotpath(extract_plasmid_pair.out)
    dotmatcher(extract_plasmid_pair.out)
    evaluate_pairwise_alignment(pairwise_align.out).collectFile(name: "pairwise_alignment_metrics.csv", storeDir: params.outdir, keepHeader: true)
}
