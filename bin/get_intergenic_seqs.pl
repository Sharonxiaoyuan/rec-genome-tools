#!/usr/bin/perl -w
#  by Jason Stajic
use strict;
use Bio::SeqIO;
use Bio::DB::SeqFeature::Store;
use Getopt::Long;
use Env qw(HOME);
my $prefix;
my $debug = 0;
my $output;

GetOptions(
	   'v|verbose!'  => \$debug,
	   'db|dbname:s' => \$dbname,
	   
	   'o|output:s'  => \$output,
	   );

unless(  defined $dbname ) {
    die("no dbname provided\n");
}

my $ofh = Bio::SeqIO->new(-format => 'fasta',
		       -file   => ">$output");
my @names;

# my $iter = $dbh->get_seq_stream(-type => 'scaffold:chromosome');
while( my $chrom = $iter->next_seq ) {
    push @names, $chrom->seq_id;
}

for my $seqid ( @names ) {
    my $segment = $dbh->segment($seqid);
    my @genes = map { $_->[0] } 
    sort { $a->[1] <=> $b->[1] } 
    map { [$_, $_->start] } $segment->features(-type => $src);

    my $count = 0;
    my $lastgene;
    for my $gene ( @genes ) {
	my $gene_name = $gene->name;
	if( $gene->start > $gene->end ) {
	    die("start !< end for $gene_name\n");
	}
	if( $lastgene && $lastgene->name ne $gene_name ) {
	    my $l1 = $lastgene->location;
	    $l1->seq_id($seqid);
	    my $l2 = $gene->location;
	    $l2->seq_id($seqid);
	    if( $lastgene->end < $gene->start ) {
		my $intergenic = $dbh->segment($seqid,
					       $lastgene->end+1,
					       $gene->start-1);
		print join("\t", $lastgene->name,
			   $gene_name,$seqid, $lastgene->end+1,
			   $gene->start-1),"\n";
		$ofh->write_seq($intergenic->seq);
	    } elsif( $l1->overlaps($l2) ) {
		warn("overlapping genes $gene_name, ", $lastgene->name,"\n");
	    } else {
		warn("genes in weird order: $gene_name, ",
		     $lastgene->name,"\n");
		warn($lastgene->location->to_FTstring()," ",
		     $gene->location->to_FTstring(),"\n");
	    }
	}
	$lastgene = $gene;
	last if $debug && $count++ > 10;
    }
    
    last if $debug && $count > 10;
}


