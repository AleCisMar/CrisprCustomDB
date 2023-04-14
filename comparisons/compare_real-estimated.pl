#!/usr/bin/perl
use strict;
use warnings;

#   Usage: perl compare_real-estimated.pl real_acc-genera.txt estimated_acc-genera.txt > real-estimated_comparison.tsv
#
#   real_acc-genera.txt must be tab delimited with virus accessions (e. g. NC_042137) on the first column and the name of its known host 
#at genus level (e. g. Acinetobacter) on the second column.
#
#   estimated_acc-genera.txt should have the same format but must contain the virus-host estimates of the evaluated prediction tool.
#
#   real-estimated_comparison.tsv will add a third column telling if the estimation is True, False or absent (NA).

my $real_pairs=$ARGV[0];
my $estimated_pairs=$ARGV[1];

# Open file for reading
open (REAL_PAIRS, '<', $real_pairs) or die "Could not open file '$real_pairs' $!";
open (ESTIMATED_PAIRS, '<', $estimated_pairs) or die "Could not open file '$estimated_pairs' $!";

# Create array of real pairs
my @RP = <REAL_PAIRS>;
my @EP = <ESTIMATED_PAIRS>;

# Create 2d array of @RP
chomp @RP;
chomp @EP;
my @RP2d = map { [ split /\t/ ] } @RP;
my @EP2d = map { [ split /\t/ ] } @EP;

# Create array of hashes of @RP2d
my @RP2d_hash = map { { 'accession' => $_->[0], 'genus' => $_->[1] } } @RP2d;
my @EP2d_hash = map { { 'accession' => $_->[0], 'genus' => $_->[1] } } @EP2d;

# print keys and values of @RP2d_hash
#for my $hash (@RP2d_hash) {
#    print "$hash->{accession} => $hash->{genus}\n";
#}

# If accession of @RP2d_hash exists in @EP2d_hash, print "Exists" else print "Does not exist"
for my $hash (@RP2d_hash) {
    if (grep { $_->{accession} eq $hash->{accession} } @EP2d_hash) {
        # If accession and genus of @RP2d_hash exists in @EP2d_hash, print "True" else print "False"
        if (grep { $_->{accession} eq $hash->{accession} && $_->{genus} eq $hash->{genus} } @EP2d_hash) {
            print "$hash->{accession}\t$hash->{genus}\tTrue\n";
        } else {
            print "$hash->{accession}\t$hash->{genus}\tFalse\n";
        }
    } else {
        print "$hash->{accession}\t$hash->{genus}\tNA\n";
    }
}
