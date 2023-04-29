#!/usr/bin/env python3

import argparse
import csv

def main(args):
    plasmids_compared = {}
    with open(args.input, 'r') as f:
        reader = csv.DictReader(f, dialect='unix')
        for row in reader:
            plasmid_1 = row['query_plasmid_id']
            plasmid_2 = row['similar_plasmid_id']
            distance = row['distance']
            if plasmid_1 in plasmids_compared:
                if plasmid_2 in plasmids_compared[plasmid_1]:
                    pass
                else:
                    plasmids_compared[plasmid_1].add(plasmid_2)
                    print(','.join([plasmid_1, plasmid_2, distance]))
            elif plasmid_2 in plasmids_compared:
                if plasmid_1 in plasmids_compared[plasmid_2]:
                    pass
                else:
                    plasmids_compared[plasmid_2].add(plasmid_1)
                    print(','.join([plasmid_1, plasmid_2, distance]))
            else:
                plasmids_compared[plasmid_1] = set([plasmid_2])
                print(','.join([plasmid_1, plasmid_2, distance]))
            
    

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('input')
    args = parser.parse_args()
    main(args)
