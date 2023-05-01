#!/usr/bin/env python3

import argparse
import csv
import json
import sys


def parse_alignment(alignment_path):
    """
    """
    seqs_by_id = {}
    with open(alignment_path, 'r') as f:
        current_seq_id = None
        for line in f:
            line = line.strip()
            if line.startswith('>'):
                current_seq_id = line.strip('>').split()[0]
                seqs_by_id[current_seq_id] = ""
            else:
                seqs_by_id[current_seq_id] += line

    return seqs_by_id


def evaluate_alignment(alignment):
    """
    """
    evaluation = []
    plasmid_id_1, plasmid_id_2 = alignment.keys()
    
    seq_1 = alignment[plasmid_id_1]
    seq_2 = alignment[plasmid_id_2]
    
    num_gap_positions = 0
    num_seq_positions = 0
    num_aligned_positions = 0
    num_matching_positions = 0
    for pos, base in enumerate(seq_1):
        if base == '-':
            num_gap_positions += 1
        else:
            num_seq_positions += 1
            if seq_2[pos] != '-':
                num_aligned_positions += 1
            if seq_2[pos] == base:
                num_matching_positions += 1
    for pos, base in enumerate(seq_2):
        if base == '-':
            num_gap_positions += 1
        

    proportion_aligned_positions = num_aligned_positions / len(seq_1)
    proportion_matching_positions = num_matching_positions / len(seq_1)
    proportion_of_aligned_positions_matching = num_matching_positions / num_aligned_positions


    alignment_eval = {
        "plasmid_id_1": plasmid_id_1,
        "plasmid_id_2": plasmid_id_2,
        "total_alignment_length": len(seq_1),
        "num_aligned_positions": num_aligned_positions,
        "num_gap_positions": num_gap_positions,
        "num_matching_positions": num_matching_positions,
        "proportion_of_full_alignment_aligned": proportion_aligned_positions,
        "proportion_of_full_alignment_matching": proportion_matching_positions,
        "proportion_of_aligned_regions_matching": proportion_of_aligned_positions_matching,
    }

    return alignment_eval
    
    

def main(args):
    alignment = parse_alignment(args.input)
    evaluation = evaluate_alignment(alignment)
    output_fieldnames = [
        "plasmid_id_1",
        "plasmid_id_2",
        "total_alignment_length",
        "num_gap_positions",
        "num_aligned_positions",
        "num_matching_positions",
        "proportion_of_full_alignment_aligned",
        "proportion_of_full_alignment_matching",
        "proportion_of_aligned_regions_matching",
        
    ]
    writer = csv.DictWriter(sys.stdout, fieldnames=output_fieldnames, dialect='unix', quoting=csv.QUOTE_MINIMAL)
    writer.writeheader()
    writer.writerow(evaluation)
    

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('input')
    args = parser.parse_args()
    main(args)
