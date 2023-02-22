#!/usr/bin/perl
use strict;
use warnings;
use List::Util qw( min max );

# This script takes blast table as input and outputs a list of virus-host according to criterion 1 (Host with max mismatches = 2), criterion 2 (Host matching more regions) and criterion 3 (Host with spacer closest to the 5' end)
# USAGE: perl get_host_id.pl bacteria_viruses_blast.txt > bacteria_viruses_blast_host_id.txt

my $blast = $ARGV[0];

open (BLAST, $blast) or die "Can't open $blast: $!";

my @blast = <BLAST>; # Create array of $blast file

my @blast2d = map { [ split /\t/ ] } @blast; # Create 2d array of @blast

my %blast2d_h = map { $_->[0] => $_->[1] } @blast2d; # Create hash of @blast2d with keys of 1st column and values of 2nd column

foreach my $key (keys %blast2d_h) { # Loop through hash
    my @array; # Create array to store values
    #print "prueba\n";
    for (my $i = 0; $i < @blast2d; $i++) { # Loop through blast2d array
        if ($key eq $blast2d[$i][0]) { # If key is equal to 1st column of blast2d array
            push @array, $blast2d[$i][2]; # Push 3rd column of blast2d array to array
            push @array, $blast2d[$i][3]; # Push 4th column of blast2d array to array
            push @array, (split /_C/, $blast2d[$i][4])[0]; # Push 5th column of blast2d array to array
            #push @array, (split /_/, $blast2d[$i][4])[3];
            #push @array, (split /_/, $blast2d[$i][4])[6];
        }
    }
    # Create 2d array of array
    #my @array2d = map { [ splice @array, 0, 5 ] } 1 .. @array/5;
    my @array2d = map { [ splice @array, 0, 3 ] } 1..@array/3; # Create 2d array of array

    if (@array2d == 1) { # If length of array2d is 1
        print "$key\t$array2d[0][2]\tCriterion 1: One match to a single host\n"; # Print key and 3rd column of array2d. One match to a single host
    } else { # If length of array2d is not 1
        my %array2dh = map { $_->[2] => $_->[1] } @array2d; # Crete hash of array2d with keys of 3rd column and values of 2nd column
        my @array4;
        foreach my $key2 (keys %array2dh) {
            my @array3;
            #print "test\n";
            if (keys %array2dh == 1) {
                print "$key\t$key2\tCriterion 1: Multiple matches to a single host\n"; # Multiple matches to a single host
            } else {
                for (my $i = 0; $i < @array2d; $i++) { # Loop through array2d
                    if ($key2 eq $array2d[$i][2]) {
                        push @array3, $array2d[$i][0];
                        push @array3, $array2d[$i][1];
                        push @array3, $array2d[$i][2];
                    } 
                }
                my @array3_2d = map { [ splice @array3, 0, 3 ] } 1..@array3/3;
                my @sorted = sort { $a->[0] <=> $b->[0] } @array3_2d;
                if (@sorted == 1) {
                    ###print "$key\t$sorted[0][2]\t1\tMultiple hosts. Only one match to this posible host\n"; # Multiple hosts. Only one match to this posible host
                    push @array4, $key;
                    push @array4, $sorted[0][2];
                    push @array4, "1";
                } else {
                    my $net_count = 0;
                    my $count = 0;
                    my $regions;
                    for (my $i = 0; $i < @sorted-1; $i++) {
                        for (my $j = $i+1; $j < @sorted; $j++) {
                            $net_count++;
                            if ($sorted[$j][0] == $sorted[$i][0] || $sorted[$j][0] == $sorted[$i][1]) {
                                next;
                            } elsif ($sorted[$j][0] > $sorted[$i][0] && $sorted[$j][0] < $sorted[$i][1]) {
                                next;
                            } else {
                                $count++;                            
                            }
                        }
                    }
                    if ($count == $net_count) {
                        $regions=sqrt(((8*$count)+1)/4)+0.5;
                    } else {
                        $regions=int(sqrt(((8*$count)+1)/4)+0.5);
                    }
                    ###print "$key\t$sorted[0][2]\t$regions\n";
                    push @array4, $key;
                    push @array4, $sorted[0][2];
                    push @array4, $regions;
                } 
            }
        }
        my @array4_2d = map { [ splice @array4, 0, 3 ] } 1..@array4/3;
        my @sorted2 = sort { $a->[2] <=> $b->[2] } @array4_2d;
        my $max = max map { $_->[2] } @sorted2;
        my @array5;
        for (my $i = 0; $i < @sorted2; $i++) {
            if ($sorted2[$i][2] == $max) {
                push @array5, $sorted2[$i][1];
            }
        }
        if (@array5 == 1) {
            print "$key\t$array5[0]\tCriterion 2: Multiple matches to multiple hosts. Host matching more regions\n";
        } 
        if (@array5 > 1) {
            #print "$key\t";
            #print join (", ", @array5);
            #print "\tMultiple matches to multiple hosts. More than one host with maximum number of matches\n";
            my @array6;
            for (my $i = 0; $i < @array5; $i++) {
                for (my $j = 0; $j < @blast2d; $j++) {
                    # If key is equal to 1st column of blast2d and array5 matches first element of 4th column spliteed by "_" of blast2d
                    if ($key eq $blast2d[$j][0] && $array5[$i] eq (split /_C/, $blast2d[$j][4])[0]) {
                        # print blast2d first element of 4th column splited by "_"
                        push @array6, $blast2d[$j][0];
                        push @array6, (split /_C/, $blast2d[$j][4])[0];
                        #my $split1 = (split /_C/, $blast2d[$j][4])[0];
                        my $split2 = (split /_/, $blast2d[$j][4])[3];
                        my $split3 = (split /_/, $blast2d[$j][4])[6];
                        my $split4 = (split /_/, $blast2d[$j][4])[4];
                        my $relative_position = ($split3 - $split2)/($split4 - $split2);
                        push @array6, $relative_position;
                        #print "$blast2d[$j][0]\t$split1\t$split2\t$split3\t$relative_position\n";
                    }
                }
            }
            my @array6_2d = map { [ splice @array6, 0, 3 ] } 1..@array6/3;
            my $min = min map { $_->[2] } @array6_2d;
            my @array7;
            for (my $i = 0; $i < @array6_2d; $i++) {
                if ($array6_2d[$i][2] == $min) {
                    push @array7, $array6_2d[$i][1];
                    #print "$array6_2d[$i][2]\n";
                }
            }
            if (@array7 == 1) {
                print "$key\t$array7[0]\tCriterion 3: Multiple hosts matching same number of regions. Host with spacer closest to the 5' end\n";
            } else {
                print "$key\t";
                print join (", ", @array7);
                print "\tMultiple hosts matching same number of regions. More than one host with minimum relative position\n";
            }
        }
    }
}
