#!/usr/bin/env python3

import argparse
import json
import os

def parse_fasta(fasta_path):
    seqs_by_id = {}
    current_seq_id = None
    with open(fasta_path, 'r') as f:
        for line in f:
            line = line.strip()
            if line.startswith('>'):
                current_seq_id = line.lstrip('>').split()[0]
                seqs_by_id[current_seq_id] = ""
            else:
                seqs_by_id[current_seq_id] += line

    return seqs_by_id

def main(args):
    seqs_by_id = parse_fasta(args.input)
    if not os.path.exists(args.outdir):
        os.makedirs(args.outdir)
    for seq_id, seq in seqs_by_id.items():
        output_filename = seq_id + '.fa'
        output_path = os.path.join(args.outdir, output_filename)
        with open(output_path, 'w') as f:
            f.write('>' + seq_id + '\n')
            f.write(seq + '\n')
    

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('input')
    parser.add_argument('-o', '--outdir')
    args = parser.parse_args()
    main(args)
    
