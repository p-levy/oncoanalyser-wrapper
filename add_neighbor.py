import sys

def parse_variant_info(variant):
    parts = variant.split(":")
    if len(parts) >= 2:
        try:
            return parts[0], int(parts[1])
        except ValueError:
            return None, None
    return None, None

if len(sys.argv) != 4:
    print(f"Usage: {sys.argv[0]} <input.tsv> <output.tsv>")
    sys.exit(1)

input_file = sys.argv[1] 
output_file = sys.argv[2]
flanks_size = int(sys.argv[3])

with open(input_file) as fin, open(output_file, "w") as fout:
    lines = [line.rstrip("\n") for line in fin]
    header = lines[0]
    fout.write(header + "\tProximalVariant\n")
    data = [line.split("\t") for line in lines[1:]]

    for i, row in enumerate(data):
        curr_info = row[2]
        curr_chr, curr_pos = parse_variant_info(curr_info)
        neighbor = ""
        # Check previous row
        if i > 0:
            prev_info = data[i-1][2]
            prev_chr, prev_pos = parse_variant_info(prev_info)
            if (curr_chr == prev_chr and abs(curr_pos - prev_pos) <= flanks_size and prev_info != curr_info):
                neighbor = prev_info
        # Check next row
        if neighbor == "" and i < len(data) - 1:
            next_info = data[i+1][2]
            next_chr, next_pos = parse_variant_info(next_info)
            if (curr_chr == next_chr and abs(curr_pos - next_pos) <= flanks_size and next_info != curr_info):
                neighbor = next_info
        fout.write("\t".join(row) + "\t" + neighbor + "\n")