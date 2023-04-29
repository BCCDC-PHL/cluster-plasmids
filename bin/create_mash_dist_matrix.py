#!/usr/bin/env python3

import argparse
import json
import os
import subprocess

def main(args):
    seq_ids = []
    for seq_filename in os.listdir(args.input_dir):
        seq_filename_split = seq_filename.split('.')
        seq_id = '.'.join(seq_filename_split[0:-1])
        seq_ids.append(seq_id)

    print(',' + ','.join(seq_ids))

    for query_seq_id in seq_ids:
        print(query_seq_id, end='')
        query_seq_path = os.path.join(args.input_dir, query_seq_id + '.fa')
        mash_command = [
            'mash',
            'dist',
            args.sketch,
            query_seq_path,
        ]
        try:
            mash_process = subprocess.Popen(' '.join(mash_command), universal_newlines=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True, shell=True)

            while (line := mash_process.stdout.readline()) != "":
                line = line.strip().split()
                ref_seq_path = line[0]
                query_seq_path = line[1]
                mash_distance = float(line[2])
                p_value = float(line[3])
                matching_hashes_numerator = int(line[4].split('/')[0])
                matching_hashes_denominator = int(line[4].split('/')[1])
                print(',' + str(mash_distance), end='')

            mash_returncode = mash_process.wait()
        except subprocess.CalledProcessError as e:
                print("ERROR", e)
                exit(-1)
        print(flush=True)

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('input_dir')
    parser.add_argument('-s', '--sketch')
    args = parser.parse_args()
    main(args)
