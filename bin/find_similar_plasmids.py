#!/usr/bin/env python3

import argparse
import csv
import json

def parse_distance_matrix(distance_matrix_path):
    matrix_by_ref_by_query = {}
    with open(distance_matrix_path, 'r') as f:
        reader = csv.DictReader(f, dialect='unix')
        for row in reader:
            ref_id = row[""]
            matrix_by_ref_by_query[ref_id] = {}
            for query_id, dist in row.items():
                if query_id == "":
                    pass
                else:
                    matrix_by_ref_by_query[ref_id][query_id] = float(dist)

    return matrix_by_ref_by_query

def main(args):
    distance_by_ref_by_query = parse_distance_matrix(args.matrix)
    for ref_plasmid_id, distances_by_query in distance_by_ref_by_query.items():
        # print(','.join(['query_plasmid_id', 'similar_plasmid_id', 'distance']))
        for query_plasmid_id, distance in distances_by_query.items():
            if distance < args.distance_threshold and query_plasmid_id != ref_plasmid_id:
                print(','.join([ref_plasmid_id, query_plasmid_id, str(distance)]))


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('-m', '--matrix')
    parser.add_argument('-d', '--distance-threshold', type=float, default=0.01)
    args = parser.parse_args()
    main(args)
