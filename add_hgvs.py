#!/usr/bin/env python3
"""
Add HGVS p. (protein change) annotation to neoepitope file from pave VCF.

Usage:
    python add_hgvs.py <neoepitope.tsv> <pave.vcf.gz> <output.tsv>

Matches variants in the neoepitope file (via VariantInfo chr:pos:ref:alt)
to entries in the pave VCF. For each neoepitope, the transcript(s) listed
in the TranscriptsUp column are looked up against the IMPACT field
(canonical transcript) and PAVE_TI field (all transcripts) to find the
corresponding p. HGVS protein change notation.
"""

import sys
import gzip
import re

AA3_TO_1 = {
    'Ala': 'A', 'Arg': 'R', 'Asn': 'N', 'Asp': 'D', 'Cys': 'C',
    'Gln': 'Q', 'Glu': 'E', 'Gly': 'G', 'His': 'H', 'Ile': 'I',
    'Leu': 'L', 'Lys': 'K', 'Met': 'M', 'Phe': 'F', 'Pro': 'P',
    'Ser': 'S', 'Thr': 'T', 'Trp': 'W', 'Tyr': 'Y', 'Val': 'V',
    'Ter': '*',
}


def hgvs_3to1(hgvs_3):
    """Convert HGVS p. notation from 3-letter to 1-letter AA codes.

    e.g. p.Gly23Val -> p.G23V, p.Ter130Glnfs*9 -> p.*130Qfs*9
    """
    if not hgvs_3:
        return ""
    return re.sub(
        r'(?:' + '|'.join(AA3_TO_1.keys()) + r')',
        lambda m: AA3_TO_1[m.group()],
        hgvs_3,
    )


def parse_impact_canonical(info_field):
    """Extract (transcript_id, p.HGVS) from the IMPACT field (canonical transcript).

    IMPACT format: GeneName,TranscriptID,Consequence,Impact,bool,c.notation,p.notation,,Type,Number
    """
    match = re.search(r'IMPACT=([^;]+)', info_field)
    if not match:
        return None
    parts = match.group(1).split(',')
    if len(parts) >= 7:
        transcript_id = parts[1]
        p_hgvs = parts[6]  # may be empty
        if p_hgvs and p_hgvs.startswith('p.'):
            return (transcript_id, p_hgvs)
    return None


def parse_pave_ti(info_field):
    """Extract list of (transcript_id, p.HGVS) from the PAVE_TI field.

    PAVE_TI entries are comma-separated, each pipe-delimited:
    GeneID|GeneName|TranscriptID|Consequence|bool|c.notation|p.notation|RefSeqID|ExonRank|CodonIndex
    """
    match = re.search(r'PAVE_TI=([^;]+)', info_field)
    if not match:
        return []
    results = []
    for entry in match.group(1).split(','):
        fields = entry.split('|')
        if len(fields) >= 7:
            transcript_id = fields[2]
            p_hgvs = fields[6]
            if p_hgvs and p_hgvs.startswith('p.'):
                results.append((transcript_id, p_hgvs))
    return results


def build_vcf_lookup(vcf_path):
    """Build a dictionary mapping (chrom, pos, ref, alt, transcript_id) -> p.HGVS.

    Parses both IMPACT (canonical transcript) and PAVE_TI (all transcripts).
    """
    lookup = {}
    opener = gzip.open if vcf_path.endswith('.gz') else open
    with opener(vcf_path, 'rt') as f:
        for line in f:
            if line.startswith('#'):
                continue
            fields = line.strip().split('\t')
            if len(fields) < 8:
                continue
            chrom = fields[0]
            pos = fields[1]
            ref = fields[3]
            alt = fields[4]
            info = fields[7]

            var_key = (chrom, pos, ref, alt)

            # Canonical transcript from IMPACT
            canonical = parse_impact_canonical(info)
            if canonical:
                tid, hgvs = canonical
                lookup[(var_key, tid)] = hgvs

            # All transcripts from PAVE_TI
            for tid, hgvs in parse_pave_ti(info):
                lookup[(var_key, tid)] = hgvs
    return lookup


def parse_variant_info(variant_info):
    """Parse VariantInfo 'chr:pos:ref:alt' into a lookup key tuple."""
    parts = variant_info.split(':')
    if len(parts) >= 4:
        return (parts[0], parts[1], parts[2], parts[3])
    return None


def main():
    if len(sys.argv) != 4:
        print(f"Usage: {sys.argv[0]} <neoepitope.tsv> <pave.vcf.gz> <output.tsv>")
        sys.exit(1)

    neoepitope_file = sys.argv[1]
    vcf_file = sys.argv[2]
    output_file = sys.argv[3]

    # Build VCF lookup
    print(f"Parsing VCF: {vcf_file}")
    lookup = build_vcf_lookup(vcf_file)
    print(f"Found {len(lookup)} (variant, transcript) entries with p. HGVS annotation")

    # Process neoepitope file
    matched = 0
    total = 0
    with open(neoepitope_file) as fin, open(output_file, 'w') as fout:
        lines = [line.rstrip('\n') for line in fin]
        header = lines[0]
        cols = header.split('\t')
        tx_up_idx = cols.index('TranscriptsUp')  # column index for TranscriptsUp
        fout.write(header + '\tHGVS_p\tHGVS_p1\n')

        for line in lines[1:]:
            total += 1
            row = line.split('\t')
            variant_info = row[2]  # VariantInfo column
            var_key = parse_variant_info(variant_info)
            transcripts_up = row[tx_up_idx].split(';') if row[tx_up_idx] else []

            hgvs = ""
            if var_key:
                # Try each transcript in TranscriptsUp
                for tid in transcripts_up:
                    tid = tid.strip()
                    hgvs = lookup.get((var_key, tid), "")
                    if hgvs:
                        break
            if hgvs:
                matched += 1
            fout.write(line + '\t' + hgvs + '\t' + hgvs_3to1(hgvs) + '\n')

    print(f"Annotated {matched}/{total} neoepitopes with HGVS_p")
    print(f"Output written to: {output_file}")


if __name__ == '__main__':
    main()
