#!/usr/bin/perl
use warnings;
use strict;

sub process_division 
{
    my ($division_path) = @_;
    open(my $division, '<', $division_path) or die;
    my %prefixToComponent;

    while (my $line = <$division>) {
        chomp $line;
        my @fields = split "," , $line;
        $prefixToComponent[@fields[1]] = @fields[0];
    }
}

# get user inputs
print "Enter factfolder path: ";
my $fact_folder_path = <>;
chomp($fact_folder_path);

print "Enter component division path: ";
my $division_path = <>;
chomp($division_path);

# Define output folder paths
my $cfg_node_path="${fact_folder_path}/cfg/nodes.csv";
my $cfg_edge_path="${fact_folder_path}/cfg/edges.csv";
my $cfg_comp_node_folder="${fact_folder_path}/cfg/nodes/";
my $cfg_comp_edge_folder="${fact_folder_path}/cfg/edges/";
my $all_CFG_node_path="${fact_folder_path}/cfg/allCompNodes.csv";
my $all_CFG_edge_path="${fact_folder_path}/cfg/allCompEdges.csv";

my $ncfg_node_path="${fact_folder_path}/ncfg/nodes.csv";
my $ncfg_edge_path="${fact_folder_path}/ncfg/edges.csv";
my $ncfg_comp_node_folder="${fact_folder_path}/ncfg/nodes/";
my $ncfg_comp_edge_folder="${fact_folder_path}/ncfg/edges/";
my $all_NCFG_node_path="${fact_folder_path}/ncfg/allCompNodes.csv";
my $all_NCFG_edge_path="${fact_folder_path}/ncfg/allCompEdges.csv";

# Remove previously created folders
if (-d $ncfg_comp_node_folder) {rmdir $ncfg_comp_node_folder;}
if (-d $ncfg_comp_edge_folder) {rmdir $ncfg_comp_edge_folder;}
if (-e $all_NCFG_node_path) {unlink $all_NCFG_node_path;}
if (-e $all_NCFG_edge_path) {unlink $all_NCFG_edge_path;}
if (-d $cfg_comp_node_folder) {rmdir $cfg_comp_node_folder;}
if (-d $cfg_comp_edge_folder) {rmdir $cfg_comp_edge_folder;}
if (-e $all_CFG_node_path) {unlink $all_CFG_node_path;}
if (-e $all_CFG_edge_path) {unlink $all_CFG_edge_path;}

# Create node and edges directories
mkdir $ncfg_comp_node_folder;
mkdir $ncfg_comp_edge_folder;
mkdir $cfg_comp_node_folder;
mkdir $cfg_comp_edge_folder;

open(my $cfg_node, '<', $cfg_node_path) or die;
open(my $cfg_edge, '<', $cfg_edge_path) or die;






