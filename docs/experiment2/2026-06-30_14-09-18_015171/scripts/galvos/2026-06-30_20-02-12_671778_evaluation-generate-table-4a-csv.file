#!/usr/bin/env python3
import csv
import os
import re
import glob
import subprocess
import yaml

# Directory where the generated csv file is stored
OUTPUT_DIR = '/root/evaluation-table-4a'

IDENTIFIER = 'table-4a'

# The library only accepts the long OpenSSL curve names, but the table
# displays the short forms.
kem_display = {
    'prime256v1': 'p256',
    'secp384r1': 'p384',
    'secp521r1': 'p521',
}

# Mapping from tc in JSON to output column prefix
tc_map = {
    'loss 0%': 'None',
    'loss 10%': 'highLoss',
    'delay 500ms': 'highDelay',
    'rate 1mbit': 'lowBandwidth',
    'loss 10% delay 100ms rate 1mbit': 'LTEM',
    'loss 4% delay 22ms rate 880mbit': 'fiveG'
}

alg_levels = {
    'rsa:2048': 0,
    'X25519': 1,
    'prime256v1': 1,
    'bikel1': 1,
    'hqc128': 1,
    'kyber512': 1,
    'kyber90s512': 1,
    'p256_bikel1': 1,
    'p256_hqc128': 1,
    'p256_kyber512': 1,
    'secp384r1': 3,
    'bikel3': 3,
    'hqc192': 3,
    'kyber768': 3,
    'kyber90s768': 3,
    'p384_bikel3': 3,
    'p384_hqc192': 3,
    'p384_kyber768': 3,
    'secp521r1': 5,
    'hqc256': 5,
    'kyber1024': 5,
    'kyber90s1024': 5,
    'p521_hqc256': 5,
    'p521_kyber1024': 5,
}


def main():
    # One loop file per captured sniffer run
    loop_files = glob.glob('/root/sniffer-raw/run-files/**/*measurement-sniffer-*.loop', recursive=True)
    if not loop_files:
        print("Warning: No sniffer loop files found in /root/sniffer-raw/run-files/")

    # Each sniffer loop file corresponds to one captured run; link it to the
    # pcap by the run iteration (runNNN) that pos appends to both names.
    runs = {}
    for loop_file in loop_files:
        match = re.search(r'run\d+', os.path.basename(loop_file))
        if not match:
            continue
        run = match.group(0)
        with open(loop_file, 'r') as f:
            run_vars = yaml.safe_load(f)
        tc = run_vars.get('tc')
        sig_alg = run_vars.get('sig_alg')
        kem_alg = run_vars.get('kem_alg')
        if not (tc and sig_alg and kem_alg):
            continue

        level = max(alg_levels.get(kem_alg, 0), alg_levels.get(sig_alg, 0))
        # Classical baseline: force this combination to level 0
        if (kem_alg, sig_alg) == ('X25519', 'rsa:2048'):
            level = 0
        runs[run] = {
            'tc': tc,
            'kem': kem_display.get(kem_alg, kem_alg),
            'sig': sig_alg,
            'level': level,
        }

    # Read the median latency for each run and group by (kem, sig).
    data = {}
    for run, run_info in runs.items():
        pattern = f'/root/sniffer-results/latencies-pre_{run}.pcap.zst.*.client_hello_change_cipher.median.csv'
        files = glob.glob(pattern)
        if not files:
            continue
        with open(files[0], 'r') as f:
            reader = csv.DictReader(f)
            for row in reader:
                ns = int(float(row['latency_median']))
                key = (run_info['kem'], run_info['sig'])
                if key not in data:
                    data[key] = {'level': run_info['level'], 'kem': run_info['kem'], 'sig': run_info['sig']}
                data[key][tc_map[run_info['tc']]] = ns

    if not data:
        print("Warning: No latency data found")
        return

    # Find the maximum latency for each column to use as the baseline
    max_ns_per_column = {}
    for prefix in tc_map.values():
        max_val = 0
        for row_data in data.values():
            if prefix in row_data:
                max_val = max(max_val, row_data[prefix])
        max_ns_per_column[prefix] = float(max_val) if max_val > 0 else 1.0

    # Format the data
    output_rows = []
    for row_data in data.values():
        out_row = {
            'level': row_data['level'],
            'kem': row_data['kem'].replace('_', r'\_'),
            'sig': row_data['sig'].replace('_', r'\_'),
        }
        for prefix in tc_map.values():
            if prefix in row_data:
                ns = row_data[prefix]
                table_val = ns / 1000000.0
                rel_val = (ns / max_ns_per_column[prefix]) * 2.05
                out_row[prefix] = str(ns)
                out_row[f'{prefix}Table'] = f'{table_val:.2f}'
                out_row[f'{prefix}Rel'] = f'{rel_val:.4f}'
            else:
                out_row[prefix] = ''
                out_row[f'{prefix}Table'] = ''
                out_row[f'{prefix}Rel'] = ''
        output_rows.append(out_row)

    # Sort by level, then KEM, then SIG
    output_rows.sort(key=lambda x: (x['level'], x['kem'], x['sig']))

    # Write to CSV
    columns = ['level', 'kem', 'sig']
    for prefix in tc_map.values():
        columns.extend([prefix, f'{prefix}Table', f'{prefix}Rel'])

    output_filename = os.path.join(OUTPUT_DIR, f'data_{IDENTIFIER}.csv')
    with open(output_filename, 'w', newline='') as f:
        writer = csv.DictWriter(f, fieldnames=columns)
        writer.writeheader()
        writer.writerows(output_rows)

    print(f"Table generated successfully at {output_filename}")

    # pos_upload is a shell function, so invoke it through a login shell
    subprocess.run(
        ["bash", "-lc", f"pos_upload {os.path.basename(output_filename)}"],
        cwd=OUTPUT_DIR, check=True,
    )

if __name__ == '__main__':
    main()
