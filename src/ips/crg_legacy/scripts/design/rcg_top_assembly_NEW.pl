#!/usr/local/bin/perl -w

##########################  USED packages  ##########################
use strict;
use warnings;
use Switch;

use Spreadsheet::ParseExcel;
use Spreadsheet::XLSX;
use Data::Dumper;
use Text::ParseWords;
use Cwd;
use POSIX qw/strftime/;
#####################################################################


##################### Script input arguments ########################
my $sub_sys_label    = $ARGV[0];
my $excel_source_dir = $ARGV[1]."/";
my $hdl_dir          = $ARGV[2]."/";
my $excel_filename   = $ARGV[3];
#####################################################################

chdir $excel_source_dir;

#################### Variables definitions ##########################
my $now_string          = strftime "%d.%m.%Y (%H:%M:%S)", localtime;

my $PLL_SENSE_EN_NAME   = "pll_sense_div_en";
my $PLL_SENSE_CLK_NAME  = "pll_sense_clk";

my $RF_RCG_pair         = "rcg_rf_pair";
my $rcg_suffix          = "_rcg_cfg";
my $rf_suffix           = $rcg_suffix.'_rf';

my $rf_verilog_filename = $sub_sys_label.$rf_suffix.".v";
my $rcg_sheetname       = "DESIGN_product";
my $summary_sheetname   = "Summary";

my $result_dir          = $hdl_dir;

my $top_modulename      = $sub_sys_label."_".$RF_RCG_pair;
my $top_filename        = $top_modulename.".v";
my $result_file         = $result_dir.$top_filename;
#####################################################################

chdir $excel_source_dir;

################## Read the EXCEL file and define handlers for relevant workbooks ####################

# save original settings. This is done because the XLSX->new line prints a lot of warnings to stderr
*OLD_STDOUT    = *STDOUT;
*OLD_STDERR    = *STDERR;
open my $log_fh, '>>', '/dev/null';
*STDOUT        = $log_fh;
*STDERR        = $log_fh;

my $excel      = Spreadsheet::XLSX->new($excel_filename);

*STDOUT        = *OLD_STDOUT;
*STDERR        = *OLD_STDERR;

my $rcg_info_sheet = $excel->worksheet($rcg_sheetname);
my $summary_sheet  = $excel->worksheet($summary_sheetname);

######################################################################################################


################################ Get the PLL sense parameters for instantiation ######################
# Save the flag of PLL clock sense instantiation
my $pll_sense_word      = $summary_sheet->{Cells} [0] [1]->{Val};
my $pll_sense_freq_str  = $summary_sheet->{Cells} [0] [2]->{Val};
my $pll_sense           = ($pll_sense_word eq "YES") ? 1 : 0;
my $clk_name_from_pll   = $rcg_info_sheet->{Cells} [22] [6]->{Val};

# Save the required divider value
my $pll_sense_div_ratio = $summary_sheet->{Cells} [0] [3]->{Val};

# FOR DEBUG: print Dumper($summary_sheet);
######################################################################################################

chdir $hdl_dir;

###################################### START of MAIN routine #########################################

open (my $fh_rf, '<', $rf_verilog_filename) or die "Could not open the RegFile file!";

#-------------------------------- Data collection & processing block --------------------------------#

# Define a hash of arrays (HoA), where:
#    (a) Each port represented by a {key}
#    (b) The {value} represents a list of port attributes, like direction & data_width
my %rf_ports_HoA;
my $rf_portname_str_len = 0;

# [1] collect_rf_ports_data function constructs a hash of ports with their attributes as values.
# Note that, the function treats several arguments by reference (not by value)
# The main product is the %rf_ports_HoA
my %rf_param_hash = collect_rf_ports_data (\$fh_rf, \%rf_ports_HoA, \$rf_portname_str_len, $sub_sys_label);

# FOR DEBUG: print Dumper(\%rf_ports_HoA);

my @rcg_param_block;
my %rcg_ports_hash;
my @rcg_ports_info;

my $AW_param_val = ();

# [2] collect_rcg_data function constructs:
#       (a) Text block of RCG parameters (rcg_param_block) for future print to file.
#       (b) hash table of the rcg ports, where {key} is the port_name and {val} is its excel file row index.
#           This index is used to retrieve the port INFO (stored in rcg_ports_info array)
# Note that, the function treats several arguments by reference (not by value)
my $rcg_portname_str_len = collect_rcg_data (\$rcg_info_sheet, \@rcg_param_block, \%rcg_ports_hash, \@rcg_ports_info, \$AW_param_val);

# FOR DEBUG: print Dumper(\%rcg_ports_hash);
# FOR DEBUG: print Dumper(\@rcg_ports_info);

my $max_portname_str_len = ($rcg_portname_str_len, $rf_portname_str_len)[$rcg_portname_str_len < $rf_portname_str_len];

my %outbound_ports = ();
my %internal_ports = ();

# The function creates two sets of ports: (1) Outbound ports, (2) Internally bounded ports
sort_port_sets (\%rcg_ports_hash, \@rcg_ports_info, \%rf_ports_HoA, \%outbound_ports, \%internal_ports);

# Hashes clones to prevent referencing surprises:
my %outbound_ports_copy = clone(%outbound_ports);
my %internal_ports_copy = clone(%internal_ports);

# FOR DEBUG: print Dumper(\%outbound_ports);

#---------------------------------------------------------------------------------------------------#

open(my $fh_top, '>', $result_file) or die "Could not open file $result_file!";


#################### Generate an integrated rcg_rf_pair.v of RCG and RF modules #####################

print $fh_top <<BLOCK_1;

//-----------------------------------------------------------------------------
// Title         : Sansa Reset Clock Generator and RegFile pair
// Project       : Sansa
//-----------------------------------------------------------------------------
// File          : $top_filename
// Author        : <shoshay7\@biu.ac.il>
// Created       : 05.03.2015
// Last modified : $now_string
//-----------------------------------------------------------------------------
// Description :
// A block which embodies an RCG module and corresponding configuration RegFile
// with an APB interface.
//-----------------------------------------------------------------------------
// Copyright (c) 2015 by EnICS. This model is the confidential and
// proprietary property of EnICS. The possession or use of this
// file requires a written license from EnICS.
//------------------------------------------------------------------------------
// Modification history :
// 05.03.2015 : Created
// 09.05.2015 : Linked with Ceragon RegFile generation script & RCG XLSX db
// 21.05.2015 : 1st stable version
// 08.07.2015 : Adjustments after DEMO review action items
// 30.07.2015 : Inclusion of optional PLL clock sense unit for debug
// 13.08.2015 : Bypass parameter added to distinguish special bootstrap RCCs
// 01.12.2015 : Optional PLL clock sense unit changed to be generic_clk_div.v
//------------------------------------------------------------------------------

BLOCK_1


# print the top level port mapping
print_top_module (\$fh_top, $top_modulename, \%outbound_ports_copy, $max_portname_str_len, $AW_param_val, $sub_sys_label."_".$PLL_SENSE_EN_NAME, $sub_sys_label."_".$PLL_SENSE_CLK_NAME, $pll_sense);

# print internal parameters of the top level
print_top_params (\$fh_top, \@rcg_param_block, \$summary_sheet);

# print top level external ports
print_top_ext_ports (\$fh_top, \%outbound_ports_copy, $AW_param_val, $sub_sys_label."_".$PLL_SENSE_EN_NAME, $sub_sys_label."_".$PLL_SENSE_CLK_NAME, $pll_sense, \%rf_ports_HoA);

# print internal wires
print_internal_wires (\$fh_top, \%internal_ports_copy, $pll_sense);

# print internal register file instantiation
print_RegFile_module (\$fh_top, \%rf_ports_HoA, $sub_sys_label, $rf_portname_str_len, $AW_param_val);

# print internal RCG instantiation
print_RCG_module (\$fh_top, \%rcg_ports_hash, \@rcg_ports_info, \@rcg_param_block, $sub_sys_label, $rcg_portname_str_len);

# print internal PLL sense divider instantiation
if ($pll_sense eq 1) { &print_pll_sense (\$fh_top, $PLL_SENSE_EN_NAME, $PLL_SENSE_CLK_NAME, $pll_sense_div_ratio, $pll_sense_freq_str, $clk_name_from_pll, $sub_sys_label); }

print $fh_top "\nendmodule // $top_modulename\n";

close ($fh_rf);
close ($fh_top);

print "\n\n";
print "RCG integration script parameters summary:\n";
print "  > EXCEL path @ RCG integration level is: $excel_source_dir\n";
print "  > HDL path @ RCG integration level is: $hdl_dir$top_filename\n";

###################################### END of MAIN routine #########################################

sub clone {
    map { ! ref() ? $_ : ref eq 'HASH' ? {clone(%$_)} : ref eq 'ARRAY' ? [clone(@$_)] : die "$_ not supported" } @_;
}

#################################### collect_rcg_data() function ###################################
# Description: The function reads the excel tab of the RCG port mapping (DESIGN_product worksheet) #
#              and constructs:                                                                     #
#                (a) An rcg_param_block text block of parameters for future print to file.         #
#                (b) A hash table of the rcg ports, where {key} is the port_name and {val} is its  #
#                    excel file row index. This index might be used to retrieve the port INFO,     #
#                    such as:                                                                      #
#                         [1] port_direction                                                       #
#                         [2] bind_type                                                            #
#                         [3] data_element_width                                                   #
#                         [4] inst_num                                                             #
#                         [5] const_tie                                                            #
#                         [6] connectivity                                                         #
#                   This can be done with the help of rcg_ports_info_tab 2D array, where row and   #
#                   column indexes match their relative excel indexes.                             #
#--------------------------------------------------------------------------------------------------#
sub collect_rcg_data {
    my $worksheet_ref       = shift; # scalar
    my $rcg_param_block_ref = shift; # list
    my $rcg_ports_hash_ref  = shift; # hash
    my $rcg_port_info_ref   = shift; # list
    my $AW_param_val_ref    = shift; # integer

    my $worksheet       = $$worksheet_ref;
    my @rcg_param_block = @$rcg_param_block_ref;
    my %rcg_ports_hash  = %$rcg_ports_hash_ref;

    # Save the value of the required AW parameter
    $$AW_param_val_ref = $worksheet->{Cells} [1] [2]->{Val};

    #----------------------------- Read out the parameter definition block ----------------------------#
    my $cell;
    my $param_line;

    # --------- Determine the length of the param_block ----------#
    my $PARAM_block_len = 0;
    my $row = 0;
    while ($PARAM_block_len == $row) {
        $cell = $worksheet->{Cells} [$row] [0]->{Val};
        if ($cell =~ /param/) {
            $PARAM_block_len++;
            $row++;
        } else { $row++; }
    }
    #------------------------------------------------------------#

    #----------------- Construct the param_block ----------------#
    for ($row=1; $row<$PARAM_block_len; $row++) {
        $param_line = "";
        for (my $col=0; $col<3; $col++) {
            $cell = $worksheet->{Cells} [$row] [$col]->{Val};
            switch ($col) {
                case 0 { $param_line = $param_line.$cell."\t"; }
                case 1 { $param_line = $param_line.$cell." = "; }
                case 2 { $param_line = $param_line.$cell.";"; }
                else { $param_line = $param_line.""; }
            }
        }
        push(@rcg_param_block, $param_line);
        @$rcg_param_block_ref = @rcg_param_block;
    }
    #------------------------------------------------------------#

    my $rcg_tab_start_row = 0;
    while ($cell ne "port_name") {
        $cell = $worksheet->{Cells} [$row] [0]->{Val};
        $row++;
    }
    $rcg_tab_start_row = $row;

    #-------- Construct the port mapping data of the RCG --------#
    my $end_of_rcg_tab_row = $worksheet->{MaxRow};
    my $end_of_rcg_tab_col = $worksheet->{MaxCol};
    my $tmp;
    my @rcg_ports_info_tab;
    my $allign_str_len = 0;

    while ($row <= $end_of_rcg_tab_row) {
        $cell = $worksheet->{Cells} [$row] [0]->{Val};
        $allign_str_len = (length($cell) > $allign_str_len) ? length($cell) : $allign_str_len;
        $rcg_ports_hash{$cell} = $row-$rcg_tab_start_row;
        my @rcg_ports_line;
        for (my $i=1; $i<=$end_of_rcg_tab_col; $i++) {
            $tmp = $worksheet->{Cells} [$row] [$i]->{Val};
            push(@rcg_ports_line,$tmp);
        }
        push(@rcg_ports_info_tab,\@rcg_ports_line);
        $row++;
    }
    #-----------------------------------------------------------#

    @$rcg_port_info_ref = @rcg_ports_info_tab;
    %$rcg_ports_hash_ref = %rcg_ports_hash;
    return $allign_str_len;
}
####################################################################################################

################################# collect_rf_ports_data() function #################################
# Description: The function reads the verilog file of a particular RegFile and constructs a hash   #
#              of ports with their attributes (direction & width)                                  #
#--------------------------------------------------------------------------------------------------#
sub  collect_rf_ports_data {
  my ($fh_ref)           = shift; # scalar
  my $fh                 = $$fh_ref;
  my $rf_ports_HoA_ref   = shift; # hash of lists
  my $allign_str_len_ref = shift; # scalar
  my $sub_sys_label      = shift; # string

  my $port_name  = "";
  my $port_width = "";
  my $port_dir   = "";
  my %param_hash   = ();

  while ( my $line = <$fh>) {
    # match port direction patterns: output, input or inout
    next unless $line =~ /^\s*(output|input|inout)\s*/;
    $port_dir = ($1);

    # Note: Enclose the match pattern with () in order to use $1.. operators
    # Match any port_name; string and then remove the ";"
    if ($line =~ /(\w+\s*;)/ ) {
      $port_name = $1;
      $port_name =~ s/\s*;//;
    }

    # Match the data width for the port_name according [..] pattern & evaluate parameters
    $line =~ /(\[[^\[|\]]+\])/;
    $port_width = $1;
    if ($port_width =~ /\[\s*([^\[|\]]+)\]/) {
      $port_width = $1;
      $port_width =~ s/(\s*[\w|\(|\)]\s*):\s*0/$1/;
    } else { $port_width = "0"; }

    # ensure arithmetic context ==> evaluate (security)
    unless( $port_width =~ /[^\d\(\)\+\-\*\/]/ ) {
      $port_width = eval($port_width) + 1;
    }

    if (length($port_dir) > 0) {
      $$rf_ports_HoA_ref{$port_name} = [$port_dir,$port_width]; # Add port to the hash
      $$allign_str_len_ref = (length($port_name) > $$allign_str_len_ref) ? length($port_name) : $$allign_str_len_ref;
    }
  }
  return %param_hash;
}
####################################################################################################

################################### print_top_module() function ##############$$$###################
# Description: The function gets the RCG and RF data bases and print the top module port mapping   #
#              after some data filtering. Internal connections are omitted.                        #
#--------------------------------------------------------------------------------------------------#
sub print_top_module {
    my $fh_ref             = shift;
    my $top_module_name    = shift;
    my $outbound_ports_ref = shift; # hash of lists
    my $max_str_len        = shift;
    my $AW_param_val       = shift; # integer
    my $PLL_SENSE_EN_NAME  = shift;
    my $PLL_SENSE_CLK_NAME = shift;
    my $PLL_SENSE_INST     = shift; # 0 or 1

    my $allign_str    = ();
    my $ext_ports_num = keys %$outbound_ports_ref;
    # each hash{key} = val = @port_attributes_list is {
    #                              [0] direction,
    #                              [1] bind_type,
    #                              [2] wd,
    #                              [3] inst_num,
    #                              [4] tie,
    #                              [5] inst_type
    #                        }

    my $out_port_cnt = 0;
    my $in_port_cnt  = 0;

    print $$fh_ref "module $top_module_name (\n";
    print $$fh_ref "    // Outputs\n";

    # Addition of optional PLL sense ports for debug
    $allign_str = ' ' x ($max_str_len - length($PLL_SENSE_CLK_NAME));
    if ($PLL_SENSE_INST) {
        print $$fh_ref "    $PLL_SENSE_CLK_NAME, $allign_str// [OUT] 1 bit\n";
    }

    # Note that outbound_ports_ref is a reference to a hash of lists (arrays), thus its content retrieved by: $$outbound_ports_ref{port_name}[list_index]
    foreach my $port (sort keys %$outbound_ports_ref) {
        my $s_str = ();

        # Outbound output?
        if ($$outbound_ports_ref{$port}[0] eq "output" and $$outbound_ports_ref{$port}[1] ne "INT") {
            $port =~ s/(\w+)\s*\[.*\]\s*/$1/; # remove bus notation
            $allign_str = ' ' x ($max_str_len - length($port));
            print $$fh_ref "    $port, $allign_str// [OUT] ";

            # Multi-bit?
            if ($$outbound_ports_ref{$port}[2] * $$outbound_ports_ref{$port}[3] > 1) {
                $s_str = "s";
                if ($$outbound_ports_ref{$port}[5] eq "CLONE") {
                    if ($$outbound_ports_ref{$port}[2] == 1) { $s_str = ""; }
                    print $$fh_ref "$$outbound_ports_ref{$port}[2] bit".$s_str." (replicated x ".$$outbound_ports_ref{$port}[3].")\n";
                } else {
                    if ($$outbound_ports_ref{$port}[5] ne "CONCAT") {
                        if ($$outbound_ports_ref{$port}[3] > 1) { print $$fh_ref "$$outbound_ports_ref{$port}[3] x "; }
                    } else {
                        if ($$outbound_ports_ref{$port}[2] == 1) {
                            $s_str = "";
                        }
                    }
                }
                print $$fh_ref "$$outbound_ports_ref{$port}[2] bit";
                print $$fh_ref "$s_str\n";
            } else { print $$fh_ref "1 bit\n"; }
            $out_port_cnt++;
        }
    }

    $in_port_cnt = $ext_ports_num - $out_port_cnt;

    print $$fh_ref "\n    // Inputs\n";

    # Addition of optional PLL sense ports for debug
    $allign_str = ' ' x ($max_str_len - length($PLL_SENSE_EN_NAME));
    if ($PLL_SENSE_INST) {
        print $$fh_ref "    $PLL_SENSE_EN_NAME, $allign_str// [IN] 1 bit\n";
    }

    foreach my $port (sort keys %$outbound_ports_ref) {

        # Outbound input?
        if ($$outbound_ports_ref{$port}[0] eq "input" and $$outbound_ports_ref{$port}[1] ne "INT") {
            $in_port_cnt--;
            $port =~ s/(\w+)\s*\[.*\]\s*/$1/; # remove bus notation
            $allign_str = ' ' x ($max_str_len - length($port));
            my $comma_str = ($in_port_cnt > 0) ? "," : " " ;
            print $$fh_ref "    $port$comma_str $allign_str// [IN] ";
            my $dw_val = ($$outbound_ports_ref{$port}[2] =~ /[A-Z_]+/) ? $AW_param_val : $$outbound_ports_ref{$port}[2];

            # Multi-bit?
            if ($dw_val * $$outbound_ports_ref{$port}[3] > 1) {
                if ($$outbound_ports_ref{$port}[5] eq "CLONE") {
                    my $s_str = ($$outbound_ports_ref{$port}[2] > 1) ? "s" : "";
                    print $$fh_ref "$$outbound_ports_ref{$port}[2] bit".$s_str." (replicated x ".$$outbound_ports_ref{$port}[3].")\n";
                } else {
                    if ($$outbound_ports_ref{$port}[3] > 1) { print $$fh_ref "$$outbound_ports_ref{$port}[3] x "; }
                    print $$fh_ref "$dw_val bits\n";
                }
            } else { print $$fh_ref "1 bit\n"; }
        }
    }

    print $$fh_ref "   );\n\n";
}

####################################################################################################

################################## print_top_ext_ports() function ##################################
# Description: The function gets the RCG and RF data bases and print the top module external ports #
#              after some data filtering.                                                          #
#--------------------------------------------------------------------------------------------------#
sub print_top_ext_ports {
  my $fh_ref             = shift; # scalar
  my $outbound_ports_ref = shift; # hash of lists
  my $AW_param_val       = shift; # integer
  my $PLL_SENSE_EN_NAME  = shift;
  my $PLL_SENSE_CLK_NAME = shift;
  my $PLL_SENSE_INST     = shift; # 0 or 1
  my $rf_ports_HoA_ref   = shift;

   # each hash{key} = val = @port_attributes_list is {
   #                              [0] direction,
   #                              [1] bind_type,
   #                              [2] wd,
   #                              [3] inst_num,
   #                              [4] tie,
   #                              [5] inst_type
   #                        }

  my $fh = $$fh_ref;

  print $fh <<BLOCK_2;

//-----------------------------------------------------------------------------
//                     External ports of the RCG-RF pair
//-----------------------------------------------------------------------------

BLOCK_2

  if ($PLL_SENSE_INST) { print $$fh_ref "    input $PLL_SENSE_EN_NAME;\n"; }

  foreach my $port (sort keys %$outbound_ports_ref) {
    my $width_str = ();

    # Input?
    if($$outbound_ports_ref{$port}[0] eq "input") {
      my $dw_val = ($$outbound_ports_ref{$port}[2] =~ /[A-Z_]+/) ? $AW_param_val : $$outbound_ports_ref{$port}[2];

      # Multi-bit?
      if ($dw_val * $$outbound_ports_ref{$port}[3] > 1) {
   switch ($$outbound_ports_ref{$port}[5]) {
     case "CLONE" {
         $width_str = ($$outbound_ports_ref{$port}[2]>1) ? "[".eval($$outbound_ports_ref{$port}[2]-1).":0] " : "";
     }
     case "CONCAT" {
         $width_str = ($$outbound_ports_ref{$port}[2]>1) ? "[".eval($$outbound_ports_ref{$port}[2]*$$outbound_ports_ref{$port}[3]-1).":0] " : "" ;
     }
     else {
        my $MSB_index_str = ($$outbound_ports_ref{$port}[2] =~ /[A-Z_]+/) ? $$outbound_ports_ref{$port}[2]."-1" : eval($$outbound_ports_ref{$port}[2]*$$outbound_ports_ref{$port}[3]-1) ;
        $width_str = "[".$MSB_index_str.":0] ";
          }
   }
      }
      print $$fh_ref "    input $width_str$port;\n";
    }
  }

  print $$fh_ref "\n";

  if ($PLL_SENSE_INST) { print $$fh_ref "    output $PLL_SENSE_CLK_NAME;\n"; }

  foreach my $port (sort keys %$outbound_ports_ref) {
    my $width_str = ();

    # Output?
    if($$outbound_ports_ref{$port}[0] eq "output") {

      # Multi-bit?
      if ($$outbound_ports_ref{$port}[2] * $$outbound_ports_ref{$port}[3] > 1) {
   switch ($$outbound_ports_ref{$port}[5]) {
     case "CLONE" {
         $width_str = ($$outbound_ports_ref{$port}[2]>1) ? "[".eval($$outbound_ports_ref{$port}[2]-1).":0] " : "";
     }
     case "CONCAT" {
         $width_str = ($$outbound_ports_ref{$port}[2]>1) ? "[".eval($$outbound_ports_ref{$port}[2]*$$outbound_ports_ref{$port}[3]-1).":0] " : "" ;
         if (exists($$rf_ports_HoA_ref{$port}) and $$rf_ports_HoA_ref{$port}[0] eq "output")  {
             $width_str = "[" . eval($$outbound_ports_ref{$port}[2]-1) . ":0] ";
         }
     }
     else { $width_str = "[".eval($$outbound_ports_ref{$port}[2]*$$outbound_ports_ref{$port}[3]-1).":0] "; }
   }
      }
      print $$fh_ref "    output $width_str$port;\n";
    }
  }
}
####################################################################################################

################################## print_internal_wires() function #################################
# Description: The function gets the RCG and RF data bases and print the internal wires of the top #
#              module after some data filtering.                                                   #
#--------------------------------------------------------------------------------------------------#
sub print_internal_wires {
  my $fh_ref             = shift; # scalar
  my $internal_ports_ref = shift; # hash of lists
  my $PLL_SENSE_INST     = shift; # 0 or 1

  # each hash{key} = val = @port_attributes_list is {
  #                              [0] direction,
  #                              [1] bind_type,
  #                              [2] wd,
  #                              [3] inst_num,
  #                              [4] tie,
  #                              [5] inst_type
  #                        }

  my $fh = $$fh_ref;

  print $fh <<BLOCK_3;

   //----------------------------------------------------------------------------
   // Internal Wires Definitions
   //----------------------------------------------------------------------------

BLOCK_3

  if($PLL_SENSE_INST) {
    print $$fh_ref "    wire clk_out_cg_net;\n";
    print $$fh_ref "    wire rst_n_to_pll_sense_div_sync_net;\n";
  }

  foreach my $port (sort keys %$internal_ports_ref) {
    if($$internal_ports_ref{$port}[1] ne "EXT") {
      my $width = ();

      if ($$internal_ports_ref{$port}[5] eq "BUS") {
        $width = "[".eval($$internal_ports_ref{$port}[2]*$$internal_ports_ref{$port}[3]-1).":0] ";
      } else {
          $width = ($$internal_ports_ref{$port}[2]>1) ? "[".eval($$internal_ports_ref{$port}[2]-1).":0] " : "" ;
      }
      print $$fh_ref "    wire $width$port;\n";
    }
  }
}
####################################################################################################


################################## print_RegFile_module() function #################################
# Description: The function prints the internal instantiation of the RegFile module and its port   #
#              mapping.                                                                            #
#--------------------------------------------------------------------------------------------------#
sub print_RegFile_module {
  my $fh_ref           = shift; # scalar
  my $rf_ports_HoA_ref = shift; # hash of lists
  my $SSL              = shift; # string
  my $max_str_len      = shift; # scalar
  my $AW_param_val     = shift; # integer

  my $fh         = $$fh_ref;
  my $hash_size  = keys %$rf_ports_HoA_ref;
  my $allign_str = ();

  print $fh <<BLOCK_4;

   //----------------------------------------------------------------------------
   // Register file instantiation
   //----------------------------------------------------------------------------

   $SSL\_rcg_cfg_rf I_$SSL\_rcg_cfg_rf (
        // Outputs
BLOCK_4

  my $cnt = 0;
  foreach my $rf_port (sort keys %$rf_ports_HoA_ref) {
    my $port_arr = $$rf_ports_HoA_ref{$rf_port};

    # Output?
    if(@$port_arr[0] eq "output") {
      $allign_str = ' ' x ($max_str_len + 1 - length($rf_port));
      $cnt++;
      my $wd_str = ();

      if (@$port_arr[1] =~ /\s*(\D+)\s*/) { $wd_str = "[".@$port_arr[1].":0]"; } # preserve non-numeric parameters
      else { $wd_str = (@$port_arr[1] > 1) ? "[".eval(@$port_arr[1]-1).":0]" : ""; }
      print $fh "        .$rf_port$allign_str($rf_port$wd_str),\n";
    }
  }

  print $fh "\n        // Inputs\n";

  my $num_of_inputs = $hash_size - $cnt;

  $cnt = 0;
  my $comma_str = ();

  foreach my $rf_port (sort keys %$rf_ports_HoA_ref) {
    my $port_arr = $$rf_ports_HoA_ref{$rf_port};

    # Input?
    if(@$port_arr[0] eq "input") {
      $allign_str = ' ' x ($max_str_len + 1 - length($rf_port));
      $cnt++;
      $comma_str = ($cnt < $num_of_inputs) ? "," : "";
      my $dw_str = ();
      my $tail_str = ();
      if (@$port_arr[1] =~ /\s*(\D+)\s*/) { # preserve non-numeric parameters
        $dw_str = "[".@$port_arr[1];
        $dw_str = (@$port_arr[1] =~ /[A-Z_]+/) ? $dw_str."-1" : $dw_str;
      }
      else { $dw_str = (@$port_arr[1] > 1) ? "[".eval(@$port_arr[1]-1) : ""; }

      # Find port with "addr" substring and omit its 2 LSB bits
      if($rf_port =~ /\w*addr.*/) { $tail_str = ":0]"; }
      else { $tail_str = (@$port_arr[1] > 1) ? ":0]" : ""; }

      print $fh "        .$rf_port$allign_str($rf_port$dw_str$tail_str)$comma_str\n";
    }
  }
  print $fh "    );\n";
}
####################################################################################################

################################## print_top_params() function #####################################
# Description: The function prints the internal parameters of the top module.                      #
#--------------------------------------------------------------------------------------------------#

sub print_top_params {
  my $fh_ref              = shift; # scalar
  my $rcg_param_block_ref = shift; # list
  my $worksheet_ref       = shift; # scalar

  my $fh = $$fh_ref;

  print $fh <<BLOCK_4;

   //----------------------------------------------------------------------------
   // Local parameters
   //----------------------------------------------------------------------------

BLOCK_4

  my $col_limit    = $$worksheet_ref -> {MaxCol};

  my $rcc_name_col = 0;
  my $type_col     = 0;
  my $verbose_col1 = 0;
  my $verbose_col2 = 0;
  my $verbose_col3 = 0;
  my $verbose_col4 = 0;
  my $cell;
  my $col_i        = 0;

  #-------------------- Locate verbose columns in the EXCEL "Summary" worksheet ---------------------#
  while ($col_i < $col_limit) {
    $cell = $$worksheet_ref -> {Cells} [2] [$col_i]->{Val};
    switch($cell) {
      case "rcc_name"   { $rcc_name_col = $col_i; }
      case "clock_mode" { $type_col     = $col_i; }
      case "init_state" { $verbose_col1 = $col_i; }
      case "duty_cycle" { $verbose_col2 = $col_i; }
      case "force_en"   { $verbose_col3 = $col_i; }
      case "bypass"     { $verbose_col4 = $col_i; }
    }
    $col_i++;
  }
  #--------------------------------------------------------------------------------------------------#

  #---------------------- Determine the depth of the EXCEL "Summary" worksheet ----------------------#
  my $row_i = 3;
  my $row_limit = 0;

  while (length($cell)>0) {
    $cell = $$worksheet_ref -> {Cells} [$row_i] [$rcc_name_col]->{Val};
    $row_i++;
  }
  my $row_limit = $row_i - 1;
  #--------------------------------------------------------------------------------------------------#

  my $param_index = 0;
  my $param_line = ();
  foreach $param_line (@$rcg_param_block_ref) {
    ($param_index == 1) ? print $fh "\n" : print $fh "";
    print $fh "    $param_line\n";

    $param_index++;

    #-------------- Verbose particular parameters for better RCG configuration readability ------------#
    switch($param_index) {
      case 9  { verbose_param($worksheet_ref, $fh_ref, $param_line, $rcc_name_col, $type_col, $verbose_col1, $row_limit); }
      case 10 { verbose_param($worksheet_ref, $fh_ref, $param_line, $rcc_name_col, $type_col, $verbose_col2, $row_limit); }
      case 11 { verbose_param($worksheet_ref, $fh_ref, $param_line, $rcc_name_col, $type_col, $verbose_col3, $row_limit); }
      case 12 { verbose_param($worksheet_ref, $fh_ref, $param_line, $rcc_name_col, $type_col, $verbose_col4, $row_limit); }
    }
  }
}
#--------------------------------------------------------------------------------------------------#


################################## print_RCG_module() function #####################################
# Description: The function prints the internal instantiation of the RCG module with its parameter #
#              definitions block and port mapping.                                                 #
#--------------------------------------------------------------------------------------------------#

sub print_RCG_module {
  my $fh_ref              = shift; # scalar
  my $rcg_ports_hash_ref  = shift; # hash
  my $rcg_ports_info_ref  = shift; # list
  my $rcg_param_block_ref = shift; # list
  my $ssl_lc              = shift; # string
  my $max_str_len         = shift; # scalar

  my $fh         = $$fh_ref;
  my $hash_size  = keys %$rcg_ports_hash_ref;
  my $allign_str = ();
  my $SSL        = uc($ssl_lc);

  print $fh <<BLOCK_5;

    //----------------------------------------------------------------------------
    // Reset Clock Generator instantiation
    //----------------------------------------------------------------------------

    rcg_ctrl_top #(
        .DIV_WIDTH($SSL\_RCG_DIV_WIDTH),
        .DIV_NUM_PULSE($SSL\_RCG_DIV_NUM_PULSE),
        .DIV_NUM_HALFDC($SSL\_RCG_DIV_NUM_HALFDC),
        .RCC_NUM_ARRAY($SSL\_RCC_NUM_ARRAY),
        .RCC_OFFST_ARRAY($SSL\_RCC_OFFST_ARRAY),
        .RCC_NUM($SSL\_RCC_NUM),
        .HALFDC_UP($SSL\_RCG_DIV_HALFDC_UP),
   .RCC_BYP_VEC($SSL\_RCC_BYP_VEC)
   )

    I_$ssl_lc\_rcg_ctrl_top (
        // Outputs
BLOCK_5

  my $cnt = 0;
  foreach my $rcg_port (sort keys %$rcg_ports_hash_ref) {
    my $row_index        = $$rcg_ports_hash_ref{$rcg_port};
    my $port_dir         = $$rcg_ports_info_ref[$row_index][0];
    my $element_width    = $$rcg_ports_info_ref[$row_index][2];
    my $connectivity_str = ($element_width ne 0) ? $$rcg_ports_info_ref[$row_index][5] : "";

    if (($port_dir eq "output")) {
      $allign_str = ' ' x ($max_str_len + 1 - length($rcg_port));
      $cnt++;
      print $fh "        .$rcg_port$allign_str($connectivity_str),\n";
    }
  }

  print $fh "\n        // Inputs\n";

  my $num_of_inputs = $hash_size - $cnt;

  $cnt = 0;
  my $EoL_str = ();             # End of line string
  foreach my $rcg_port (sort keys %$rcg_ports_hash_ref) {
    my $row_index        = $$rcg_ports_hash_ref{$rcg_port};
    my $port_dir         = $$rcg_ports_info_ref[$row_index][0];
    my $element_width    = $$rcg_ports_info_ref[$row_index][2];
    my $connectivity_str = ($element_width ne 0) ? $$rcg_ports_info_ref[$row_index][5] : "";

    if(($port_dir eq "input")) {
      $allign_str = ' ' x ($max_str_len + 1 - length($rcg_port));
      $cnt++;
      $EoL_str = ($cnt < $num_of_inputs) ? "," : "";
      print $fh "        .$rcg_port$allign_str($connectivity_str)$EoL_str\n";
    }
  }
  print $fh "    );\n";
}
####################################################################################################


#################################### sort_port_sets() function #####################################
# Description: The function creates two sets of ports:                                             #
#                  (1) Outbound ports                                                              #
#                  (2) Internally bounded ports                                                    #
# Note: These two sets may have common elements in case of dual binding (internal & external)      #
#--------------------------------------------------------------------------------------------------#




sub sort_port_sets {
    my $rcg_ports_hash_ref = shift; # hash
    my $rcg_ports_info_ref = shift; # list
    my $rf_ports_HoA_ref   = shift; # hash of arrays
    my $outbound_ports_ref = shift; # hash
    my $internal_ports_ref = shift; # hash

    foreach my $port (keys %$rcg_ports_hash_ref) {
        my $row_index        = $$rcg_ports_hash_ref{$port};
        my $port_dir         = $$rcg_ports_info_ref[$row_index][0];
        my $port_type        = $$rcg_ports_info_ref[$row_index][1];
        my $element_dw       = $$rcg_ports_info_ref[$row_index][2];
        my $inst_num         = $$rcg_ports_info_ref[$row_index][3];
        my $const_tie        = $$rcg_ports_info_ref[$row_index][4];
        my $connectivity_str = ($inst_num ne 0) ? $$rcg_ports_info_ref[$row_index][5] : "";
        my $mult_inst_type   = $$rcg_ports_info_ref[$row_index][6];
        my @port_attributes  = ($port_dir, $port_type, $element_dw, $inst_num, $const_tie, $mult_inst_type);

        if ($port_type ne "INT") {
            switch($inst_num) {
                case 0 {  }
                case 1 {
                    $connectivity_str =~ s/(\w+)\s*\[.*\]\s*/$1/; # remove bus notation
                    if ($port_type eq "BOTH") {
                        $connectivity_str =~ s/(\w+)\s*\[.*\]\s*/$1/; # remove bus notation

                        # Extract the RF output port out of the rcg_rf_pair as output, despite being an input port of the RCG module:
                        if (exists($$rf_ports_HoA_ref{$connectivity_str}) and $$rf_ports_HoA_ref{$connectivity_str}[0] eq "output")  {
                            $port_attributes[0] = "output";
                        }
                        $$internal_ports_ref{$connectivity_str} = \@port_attributes;
                    }
                    $$outbound_ports_ref{$connectivity_str} = \@port_attributes;
                } else {
                    if ($mult_inst_type eq "CONCAT" or $mult_inst_type eq "CLONE") {
                        my @port_inst_list;
                        $connectivity_str =~ s/\s*\{(.*)\}\s*/$1/;
                        if ($mult_inst_type eq "CLONE") { $connectivity_str =~ s/\s*\d+\{(.*)\}\s*/$1/; }

                        # Split connectivity string by "," delimiter and produce a list
                        @port_inst_list = quotewords(",", 0, $connectivity_str);

                        foreach my $port_inst (@port_inst_list) {
                            my @local_port_attributes = ($port_dir, $port_type, $element_dw, $inst_num, $const_tie, $mult_inst_type);
                            $port_inst =~ s/(\w+)\s*\[.*\]\s*/$1/; # remove bus notation
                            if ($port_type eq "BOTH") {
                                # Extract the RF output port out of the rcg_rf_pair as output, despite being an input port of the RCG module:
                                if (exists($$rf_ports_HoA_ref{$port_inst}) and $$rf_ports_HoA_ref{$port_inst}[0] eq "output")  {
                                    $local_port_attributes[0] = "output";
                                }
                                $$internal_ports_ref{$port_inst} = \@local_port_attributes;
                            }
                            $$outbound_ports_ref{$port_inst} = \@local_port_attributes;
                        }
                    } else {
                        $connectivity_str =~ s/(\w+)\s*\[.*\]\s*/$1/; # remove bus notation
                        if ($port_type eq "BOTH") {
                            # Extract the RF output port out of the rcg_rf_pair as output, despite being an input port of the RCG module:
                            if (exists($$rf_ports_HoA_ref{$connectivity_str}) and $$rf_ports_HoA_ref{$connectivity_str}[0] eq "output")  {
                                $port_attributes[0] = "output";
                            }
                            $$internal_ports_ref{$connectivity_str} = \@port_attributes;
                        }
                        $$outbound_ports_ref{$connectivity_str} = \@port_attributes;
                    }
                }
            }

        } else {
            if (not($const_tie)) {
                switch($inst_num) {
                    case 0 { }
                    case 1 {
                        $connectivity_str =~ s/(\w+)\s*\[.*\]\s*/$1/; # remove bus notation
                        $$internal_ports_ref{$connectivity_str} = \@port_attributes;
                    } else {
                        my @port_inst_list;
                        $connectivity_str =~ s/\s*\{(.*)\}\s*/$1/;

                        # Split connectivity string by "," delimiter and produce a list
                        @port_inst_list = quotewords(",", 0, $connectivity_str);
                        foreach my $port_inst (@port_inst_list) {
                            my @local_port_attributes = ($port_dir, $port_type, $element_dw, $inst_num, $const_tie, $mult_inst_type);
                            $port_inst =~ s/(\w+)\s*\[.*\]\s*/$1/; # remove bus notation
                            $$internal_ports_ref{$port_inst} = \@local_port_attributes;
                        }
                    }
                }
            }
        }
    }

    foreach my $port (keys %$rf_ports_HoA_ref) {
        $port =~ s/(\w+)\s*\[.*\]\s*/$1/; # remove bus notation
        if (not(exists($$internal_ports_ref{$port}))) {
            # Artificially fit the structure of the RegFile port attributes list as in RCG: [direction,type,dw,inst,inst_type]
            # Convert the textual ADDRESS WIDTH parameter of the RegFile to the top level AW parameter
            $$rf_ports_HoA_ref{$port}[1] =~ s/\s*[(A-Z|_)]+-1\s*/AW/;
            my @port_attributes = ($$rf_ports_HoA_ref{$port}[0], "EXT", $$rf_ports_HoA_ref{$port}[1], 1, "FALSE", "X", "BUS");
            $$outbound_ports_ref{$port} = \@port_attributes;
        }
    }
}

####################################################################################################


#################################### verbose_param() function ######################################
# Description: The function transverses the CONSTANT parameters values per RCC from EXCEL data.    #
#--------------------------------------------------------------------------------------------------#

sub verbose_param() {

  my $worksheet_ref = shift; # scalar
  my $fh_ref        = shift; # scalar
  my $param_line    = shift; # list
  my $rcc_name_col  = shift; # integer
  my $type_col      = shift; # integer
  my $verbose_col   = shift; # integer
  my $row_limit     = shift; # integer

  my $worksheet     = $$worksheet_ref;

  my $row         = 3;
  my $name        = ();
  my $type        = ();
  my $verbose     = ();
  my $max_str_len = 0;
  my $feature     = $worksheet->{Cells} [2] [$verbose_col]->{Val};

  # Determine alignment string
  while ($row < $row_limit) {
    $name = $worksheet->{Cells} [$row] [$rcc_name_col]->{Val};
    $type = ucfirst(lc($worksheet->{Cells} [$row] [$type_col]->{Val}));
    $max_str_len = (eval(length($name) + length($type) + 8) > $max_str_len) ? eval(length($name) + length($type) + 8) : $max_str_len;
    $row++;
  }

  my $allign_str = ();
  my $row = 3;
  while ($row < $row_limit) {
    $name = $worksheet->{Cells} [$row] [$rcc_name_col]->{Val};
    $type = ucfirst(lc($worksheet->{Cells} [$row] [$type_col]->{Val}));
    $allign_str = ' ' x (eval($max_str_len - length($name) - length($type) - 8));
    $verbose = $worksheet->{Cells} [$row] [$verbose_col]->{Val};
    FixXML(\$verbose);
    print $$fh_ref "    // $type <$name> RCC $allign_str has $feature of $verbose\n";
    $row++;
  }
  print $$fh_ref "\n";
}

####################################################################################################

######################################## print_pll_sense() function ################################
# Description: The function adds instance of the div_by_n counter and also generates a .v file     #
#--------------------------------------------------------------------------------------------------#

sub print_pll_sense() {
  my $top_fh_ref         = shift; # scalar
  my $PLL_SENSE_EN_NAME  = shift;
  my $PLL_SENSE_CLK_NAME = shift;
  my $div_ratio          = shift;
  my $pll_sense_freq_str = shift; # string
  my $clk_name_from_pll  = shift; # string
  my $sub_sys_label      = shift;

  my $top_fh             = $$top_fh_ref;

  print $top_fh <<TOP1;

    //----------------------------------------------------------------------------
    // PLL reference sense $pll_sense_freq_str\ clock generation for debug
    //----------------------------------------------------------------------------

TOP1

   print $top_fh "    crg_sync2_arst I_".$sub_sys_label."_rst_n_sync (\n";

   print $top_fh <<TOP2;
        // Outputs
        .q          (rst_n_to_pll_sense_div_sync_net),
        // Inputs
        .clr_n      (hgrst_n),
        .d          (1'b1),
        .clk        ($clk_name_from_pll\)
    );

TOP2

   print $top_fh "    generic_clk_div #(.DIV_N($div_ratio)) I_generic_clk_div (\n";

   print $top_fh <<TOP3;
        // Outputs
        .clk_out    (clk_out_cg_net),
        // Inputs
        .reset_n    (rst_n_to_pll_sense_div_sync_net),
        .clk_in     ($clk_name_from_pll\)
    );

    crg_clk_clockgate I_crg_clk_clockgate (
        // Output
        .out_clk    ($sub_sys_label\_$PLL_SENSE_CLK_NAME\),
        // Inputs
        .clk        (clk_out_cg_net),
        .en         ($sub_sys_label\_$PLL_SENSE_EN_NAME\),
        .ten        (1'b0)
    );
TOP3
}

####################################################################################################

######################################## FixXML() function #########################################
# Description: The function converts XML special characters to regular symbols                     #
#--------------------------------------------------------------------------------------------------#

sub FixXML() {
  my $text_ref = shift;         # reference to string

  $$text_ref =~ s/&amp;/&/g;
  $$text_ref =~ s/&gt;/>/g;
  $$text_ref =~ s/&lt;/</g;
  $$text_ref =~ s/&quot;/"/g;
  $$text_ref =~ s/&apos;/'/g;
  $$text_ref =~ s/&#xA;/\n/g;
  $$text_ref =~ s/&#xa;/\n/g;
  $$text_ref =~ s/&#xD;/\r/g;
  $$text_ref =~ s/&#xd;/\r/g;
  $$text_ref =~ s/&#x9;/\t/g;
}

####################################################################################################
