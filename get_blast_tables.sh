#!/bin/bash

usage () {
        echo
        echo "This script takes CRISPRDetect .gff file as input and a nucleotide multi-fasta file with viral genomes"
	echo "It exctracts spacers from .gff file and creates a blast database"
	echo "Viral genomes are searched against the spacer database"
	echo "The script outputs blast results in tabular format"
	echo
        echo "Usage: bash script.sh arrays.gff viruses.fasta"
        echo
}

if [[ $# -eq 0 ]] ; then
        echo "ERROR: no arguments provided"
        usage
        exit 0
fi

while :; do
        case $1 in
                -h)
                        echo "-h help requested"
                        echo "Printing help..."
                        usage
                        exit 1
                        ;;
                *)
                        break
                        ;;
        esac
done

# Create spacers.gff from CRISPRDetect arrays.gff
grep 'binding_site' $1 | 
sed 's/=/	/g' | 
sed 's/_/	/g' | 
sed 's/;/	/g' | 
sed 's/	/_/' | 
awk '{print $1"\t"$21"\t"$22"\t"$23"\t"$12"\t"$13"\t"$14"\t"$7"\t"$25}' | 
gsed '1s/^/tmp\n/' | 
awk '(NR>1) && ($8 > 27)' | 
gsed '1s/^/tmp\n/' | 
awk '(NR>1) && ($8 < 44)' > "${1%arrays.gff}spacers.gff"

# Create spacers.fasta
mkdir db
awk '{print ">"$1"_"$2"_"$3"_"$4"_"$5"_"$6"_"$7"_"$8"\n"$9}' "${1%arrays.gff}spacers.gff" > db/"${1%arrays.gff}spacers.fasta"
makeblastdb -in db/"${1%arrays.gff}spacers.fasta" -dbtype nucl

# Create blast tables
blastn -query $2 -db db/"${1%arrays.gff}spacers.fasta" -outfmt '6 qacc qlen qstart qend sacc slen sstart send length mismatch gaps' | 
gsed '1s/^/tmp\n/' | 
awk '(NR>1) && ($11 < 1 )' | 
awk -F'\t' 'function abs(x){return ((x < 0.0) ? -x : x)} {print $0"\t"abs($6-$9)+$10}' | 
gsed '1s/^/tmp\n/' | 
awk '(NR>1) && ($12 < 3)' > "${2%.fasta}_blast.txt"
