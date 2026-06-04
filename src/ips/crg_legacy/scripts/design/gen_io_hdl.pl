#!/usr/bin/perl -w
#use strict;
#use warnings;

use Switch;
use Cwd qw(realpath);

sub usage {
  my $help = <<EOM;

gen_rio_hdl.pl

Usage:

     $0  <PATH_TO_IO_CFG_CSV_FILE> <HDL_GEN_DIR> <SDC_GEN_DIR> <LOGFILE_NAME>

     The input arguments are:

        -h                             Show help info.
        -csv=<PATH_TO_IO_CFG_CSV_FILE> Path to the CSV file, generated from the <project>_PADs.xlsm. (required)
        -hdl=<HDL_GEN_DIR>             Path to the library, where the RTL is generated.              (required)
        -sdc=<SDC_GEN_DIR>             Path to the library, where the SDC is generated.              (required)
        -log=<LOGFILE_NAME>            Name of the log file to dump some generation INFO.

Description:
        This script generates RTL components of the PIN_MUX and an SDC file for I/O driving strength case analysis.
        Generated files:
        (1) func_pin_mux.v      - PIN_MUX logic
        (2) dig_io_bank.v       - Instantiation of TSMC I/O cells
        (3) dft_pin_mux.v       - DFT related RTL (inaplicable)
        (4) <case_analysis>.sdc - SDC file for case analysis of the I/O driving strength inputs
        (5) <logfile>           - Optional log file

EOM

  print $help;
}

sub get_options {
  my $arg ;
  $opt{extra_space} = 0;
  while (@_) {
    $arg = shift;
    $arg =~ /^-h$/ && do { &usage; exit 1;};
    $arg =~ /-csv\s*=/ && do {$arg =~ s/-csv\s*=\s*(\S+)/$1/s; $opt{csv}=$arg; next};
    $arg =~ /-hdl\s*=/ && do {$arg =~ s/-hdl\s*=\s*(\S+)/$1/s; $opt{hdl}=$arg; next};
    $arg =~ /-sdc\s*=/ && do {$arg =~ s/-sdc\s*=\s*(\S+)/$1/s; $opt{sdc}=$arg; next};
    $arg =~ /-log\s*=/ && do {$arg =~ s/-log\s*=\s*(\w+)/$1/s; $opt{log}=$arg; next};

    print ($opt{hdl});
    print ($opt{hdl});
    print ($opt{sdc});
  }
  die ("Missing arguments ...\nType $0 -h to get help\n\n") unless ($opt{csv} && $opt{hdl} && $opt{sdc});
}


sub colname2index {
    # Auxiliary function to retrieve column number by name - more readable for debug.
    $line_ref   = $_[0];
    @line_split = split /\,/,$line_ref;
    $i          = 0;
    %data_index       = ();
    foreach (@line_split) {
        my $tmp = $_;
        $tmp =~ s/\v//g;        # Due weird bug in last column due to ghost newline character
        $data_index{$tmp} = $i;
        $i++;
    }
}

sub instantiate_reten_cell {

    my($args) = @_;

    my $is_sim               = defined ($$args{sim})     ? $$args{sim}     : 1; # RTL_SIM is a default
    my $inst_default_name    = ($is_sim == 1)            ? "buf"           : "PCBRTE_V";
    my $reten_cell           = defined ($$args{io_cell}) ? $$args{io_cell} : "buf";
    my $reten_inst_name      = defined ($$args{inst})    ? $$args{inst}    : "I_PAD_RTE_WEST";
    my $is_ret               = defined ($$args{is_ret})  ? $$args{is_ret}  : 0; # No retention is a default
    my $reten_domain_signal  = defined ($$args{en})      ? $$args{en}      : "west_retention_latch_en";

    if (!($is_sim) && $reten_cell =~ m/^([A-Z0-9_]+)$/) {
        if ($1) {$reten_cell = $1;} # Is it a word?
    }

    my $ports = "";
    if ($is_sim) {
        $ports = "(" . $reten_domain_signal . "_io_int, " . ($is_ret ? $reten_domain_signal : "1'b0") . ")";
    } else {
        $ports = "(.IRTE(" . ($is_ret ? $reten_domain_signal : "1'b0") . "), .RTE($reten_domain_signal" . "_io_int))";
    }

    my $inst_str = "	" . $reten_cell . " " . $reten_inst_name . " " . $ports . ";\n";

    return $inst_str;
}

sub wire_hash_table_update {

    $line_split_ref          = $_[0];
    $line_split_indx         = $_[1];
    $module_wires_hash_ref   = $_[2];
    $module_wires_hash_entry = 0;

    if ($line_split_ref->[$line_split_indx] =~ m/(^[A-Za-z0-9_]+[A-Za-z0-9]+$)|(?:^([A-Za-z0-9_]+[A-Za-z0-9]+)\[([0-9]+)\]$)|(?:^([A-Za-z0-9_]+[A-Za-z0-9]+)\[([0-9]+):([0-9]+)\]$)/) {
        # Scalar pad.
        if ($1) {
            #@print ("scalar port $1\n");
            # Check if PAD is already declared, in case it is, assert error.
            if (exists $module_wires_hash_ref->{$1}) {
                print "Error!! Pad=\"$1\" already exists!!\n";
                exit 1;
            } else {
                # If not already exist, add it to the hash table with range fields forces to "scalar" strings.
                $module_wires_hash_ref->{$1} = [($1, "scalar")];
            }
        }
        # BUS pad (single bit).
        if ($2) {
            #@print ("vector port $2,$3\n");
            # Check if BUS PAD is already declared,
            if (exists $module_wires_hash_ref->{$2}) {
                # extract entry from hash
                $module_wires_hash_entry = $module_wires_hash_ref->{$2};
                # Check if already declared as "scalar",
                if ($module_wires_hash_entry->[1] eq "scalar") {
                    print "Error!! Pad=\"$2\" already declared as scalar port\n";
                    exit 1;
                } else {
                    push(@{$module_wires_hash_entry->[1]}, $3);
                    @{$module_wires_hash_entry->[1]} = sort {$a <=> $b} @{$module_wires_hash_entry->[1]};
                }
            } else {
                # We push the index value into array refenece. The array reference and added to the ports hash at the third location.
                $module_wires_hash_ref->{$2} = [($2, [($3)])];
            }
            #
            if (@{$module_wires_hash_ref->{$2}->[1]} > 1) {
                for ($range_check_indx=0 ; $range_check_indx <= (@{$module_wires_hash_ref->{$2}->[1]}-2) ; $range_check_indx++) {
                    if ($module_wires_hash_ref->{$2}->[1]->[$range_check_indx+1] == $module_wires_hash_ref->{$2}->[1]->[$range_check_indx]) {
                        print ("Error!! Bus=\"$2\[$3\]\", bus range conflict(s)\n");
                        exit 1;
                    }
                }
            }
        }
        # BUS pad (range of bits).
        if ($4) {
            #@print ("vector port $4,$5,$6\n");
            # Check if BUS PAD is already declared,
            if (exists $module_wires_hash_ref->{$4}) {
                # extract entry from hash
                $module_wires_hash_entry = $module_wires_hash_ref->{$4};
                # Check if already declared as "scalar",
                if ($module_wires_hash_entry->[1] eq "scalar") {
                    print "Error!! Pad=\"$2\", already declared as scalar port\n";
                    exit 1;
                } else {
                    if ($5 <= $6) {
                        print ("Error!! Bus=\"$4\[$5:$6\]\", incorrect range msb should be greater then lsb\n");
                        exit 1;
                    } else {
                        $bus_range_msb = $5;
                        $bus_range_lsb = $6;
                        for (; $bus_range_msb >= $bus_range_lsb ; $bus_range_lsb++) {
                            push(@{$module_wires_hash_entry->[1]}, $bus_range_lsb);
                        }
                        @{$module_wires_hash_entry->[1]} = sort {$a <=> $b} @{$module_wires_hash_entry->[1]};
                    }
                }
            } else {
                # We push the index value into array refenece. The array reference and added to the ports hash at the third location.
                if ($5 <= $6) {
                    print ("Error!! Bus=\"$4\[$5:$6\]\", incorrect range msb should be greater then lsb\n");
                    exit 1;
                } else {
                    $module_wires_hash_ref->{$4} = [($4, [()])];
                    $bus_range_msb = $5;
                    $bus_range_lsb = $6;
                    for (; $bus_range_msb >= $bus_range_lsb ; $bus_range_lsb++) {
                        push(@{$module_wires_hash_ref->{$4}->[1]}, $bus_range_lsb);
                    }
                    @{$module_wires_hash_ref->{$4}->[1]} = sort {$a <=> $b} @{$module_wires_hash_ref->{$4}->[1]};
                }
            }
            # Check for bus range conflicts.
            for ($range_check_indx=0 ; $range_check_indx <= (@{$module_wires_hash_ref->{$4}->[1]}-2) ; $range_check_indx++) {
                # In case of mux. selector (index=36), we allow connection of a single selector input to more then one pin-mux instance.
                if (($module_wires_hash_ref->{$4}->[1]->[$range_check_indx+1] == $module_wires_hash_ref->{$4}->[1]->[$range_check_indx]) && $line_split_indx != 36) {
                    print ("Error!! Bus=\"$4\[$5:$6\]\", bus range conflict(s)\n");
                    exit 1;
                }
            }
        }
    } else {
        print ("Error!! Pad=$line_split_ref->[1], col\[$line_split_indx\]=$line_split_ref->[$line_split_indx], bad format or empty\n");
        exit 1;
    }
}

sub port_hash_table_update {

    $line_split_ref          = $_[0];
    $line_split_indx         = $_[1];
    $module_pad_dir          = $_[2];
    $module_ports_hash_ref   = $_[3];
    $module_ports_hash_entry = 0;

    if ($line_split_ref->[$line_split_indx] =~ m/(^[A-Za-z0-9_]+[A-Za-z0-9]+$)|(?:^([A-Za-z0-9_]+[A-Za-z0-9]+)\[([0-9]+)\]$)|(?:^([A-Za-z0-9_]+[A-Za-z0-9]+)\[([0-9]+):([0-9]+)\]$)/) {
        # Scalar pad.
        if ($1) {
            #@print ("scalar port $1\n");
            # Check if PAD is already declared, in case it is, assert error.
            if (exists $module_ports_hash_ref->{$1}) {
                print "Error!! Pad=\"$1\" already exists!!\n";
                exit 1;
            } else {
                # If not already exist, add it to the hash table with range fields forces to "scalar" strings.
                $module_ports_hash_ref->{$1} = [($1, $module_pad_dir, "scalar")];
            }
        }
        # BUS pad.
        if ($2) {
            #@print ("vector port $2,$3\n");
            # Check if BUS PAD is already declared,
            if (exists $module_ports_hash_ref->{$2}) {
                # extract entry from hash
                $module_ports_hash_entry = $module_ports_hash_ref->{$2};
                # Check if already declared as "scalar",
                if ($module_ports_hash_entry->[2] eq "scalar") {
                    print "Error!! Pad=\"$2\" already declared as scalar port\n";
                    exit 1;
                } else {
                    push(@{$module_ports_hash_entry->[2]}, $3);
                    @{$module_ports_hash_entry->[2]} = sort {$a <=> $b} @{$module_ports_hash_entry->[2]};
                }
            } else {
                # We push the index value into array refenece. The array reference and added to the ports hash at the third location.
                $module_ports_hash_ref->{$2} = [($2, $module_pad_dir, [($3)])];
            }
            # Check for bus range conflicts.
            if (@{$module_ports_hash_ref->{$2}->[2]} > 1) {
                for ($range_check_indx=0 ; $range_check_indx <= (@{$module_ports_hash_ref->{$2}->[2]}-2) ; $range_check_indx++) {
                    if ($module_ports_hash_ref->{$2}->[2]->[$range_check_indx+1] == $module_ports_hash_ref->{$2}->[2]->[$range_check_indx]) {
                        print ("Error!! Bit=\"$2\[$3\]\", bus range conflict(s)\n");
                        exit 1;
                    }
                }
            }
        }
        # BUS pad (range of bits).
        if ($4) {
            #@print ("vector port $4,$5,$6\n");
            # Check if BUS PAD is already declared,
            if (exists $module_ports_hash_ref->{$4}) {
                # extract entry from hash
                $module_ports_hash_entry = $module_ports_hash_ref->{$4};
                # Check if already declared as "scalar",
                if ($module_ports_hash_entry->[2] eq "scalar") {
                    print "Error!! Pad=\"$2\", already declared as scalar port\n";
                    exit 1;
                } else {
                    if ($5 <= $6) {
                        print ("Error!! Bus=\"$4\[$5:$6\]\", incorrect range msb should be greater then lsb\n");
                        exit 1;
                    } else {
                        $bus_range_msb = $5;
                        $bus_range_lsb = $6;
                        for (; $bus_range_msb >= $bus_range_lsb ; $bus_range_lsb++) {
                            push(@{$module_ports_hash_entry->[2]}, $bus_range_lsb);
                        }
                        @{$module_ports_hash_entry->[2]} = sort {$a <=> $b} @{$module_ports_hash_entry->[2]};
                    }
                }
            } else {
                # We push the index value into array refenece. The array reference and added to the ports hash at the third location.
                if ($5 <= $6) {
                    print ("Error!! Bus=\"$4\[$5:$6\]\", incorrect range msb should be greater then lsb\n");
                    exit 1;
                } else {
                    $module_ports_hash_ref->{$4} = [($4, $module_pad_dir, [()])];
                    $bus_range_msb = $5;
                    $bus_range_lsb = $6;
                    for (; $bus_range_msb >= $bus_range_lsb ; $bus_range_lsb++) {
                        push(@{$module_ports_hash_ref->{$4}->[2]}, $bus_range_lsb);
                    }
                    @{$module_ports_hash_ref->{$4}->[2]} = sort {$a <=> $b} @{$module_ports_hash_ref->{$4}->[2]};
                }
            }
            # Check for bus range conflicts.
            for ($range_check_indx=0 ; $range_check_indx <= (@{$module_ports_hash_ref->{$4}->[2]}-2) ; $range_check_indx++) {
                # In case of mux. selector (index=36), we allow connection of a single selector input to more then one pin-mux instance.
                if (($module_ports_hash_ref->{$4}->[2]->[$range_check_indx+1] == $module_ports_hash_ref->{$4}->[2]->[$range_check_indx]) && $line_split_indx != 36) {
                    print ("Error!! Bus=\"$4\[$5:$6\]\", bus range conflict(s)\n");
                    exit 1;
                }
            }
        }
    } else {
        print ("Error!! Pad=$line_split_ref->[1], col\[$line_split_indx\]=$line_split_ref->[$line_split_indx], bad format or empty\n");
        exit 1;
    }
}

sub trim {
    my @out = @_;
    for (@out) {
        s/^\s+//;
        s/\s+$//;
    }
    return wantarray ? @out : $out[0];
}

my @now = localtime();
my $timestamp = sprintf("%04d%02d%02d%02d%02d%02d",
                        $now[5]+1900, $now[4]+1, $now[3],
                        $now[2],      $now[1],   $now[0]);

my $datetime = sprintf("%02d:%02d:%02d %02d/%02d/%04d",
                       $now[2],      $now[1],   $now[0],
                       $now[4]+1, $now[3], $now[5]+1900);


&get_options (@ARGV);  # fills global hash %opt

$dig_io_bank_module  = "dig_io_bank";
$func_pin_mux_module = "func_pin_mux";
$dft_pin_mux_module  = "dft_pin_mux";

my $script_fullpath = realpath($0);

$io_bank_module_hdl_file  = $opt{hdl} . "/" . $dig_io_bank_module . ".v";
$func_mux_module_hdl_file = $opt{hdl} . "/" . $func_pin_mux_module . ".v";
$dft_tpm_module_hdl_file  = $opt{hdl} . "/" . $dft_pin_mux_module . ".v";

open(IO_CFG_IN_FILE, $opt{csv});
if ($opt{log}) { open(RPT_OUT_FILE, '>', $opt{log} . ".log"); }
open(CASE_ANALYSIS_IO_DRV_STRENGTH, '>', $opt{sdc} . "/io_drv_strength_case_analysis.sdc");

@io_cfg_in_file_array = ();
$column_headers_line =  <IO_CFG_IN_FILE>;

while ($line = <IO_CFG_IN_FILE>) {
    chomp($line);
    # dos2unix equivalent
    $line =~ s/\r//;
    push(@io_cfg_in_file_array, $line);
}

close(IO_CFG_IN_FILE);

$script_version = "3.0 - (TSMC 16FFC + configurable I/O control)";
$state = 0;
$io_cfg_file_indx = 0;
%io_bank_module_ports_hash = ();
%io_bank_module_wires_hash = ();
%io_bank_module_insts_hash = ();
%io_bank_module_analog_insts_hash = ();
$io_bank_module_muxs_ports_hash = ();
$port_name = 0;
%io_func_module_ports_hash = ();
%io_func_module_wires_hash = ();
%io_func_module_insts_hash = ();
%dft_tpm_module_ports_hash = ();
%dft_tpm_module_wires_hash = ();
%dft_tpm_module_insts_hash = ();

colname2index( $column_headers_line );

# read each line in the file
foreach $line (@io_cfg_in_file_array) {
    if (defined($line)) {
        @line_split = split /\,/,$line;
        # Check pad index validity.
        if ($line_split[$data_index{'Index'}] != $io_cfg_file_indx) {
            print ("Error!! Pad=\"$line_split[$data_index{'Pad Name'}]\", Index=$line_split[$data_index{'Index'}] \(current= $io_cfg_file_indx\)\n");
            exit 1;
        }
        # Check pad type (digital or analog).
        if ($line_split[$data_index{'Dig/Ana'}] eq "1") {
            # Digital pad selected.
            $state = 1;
        } elsif ($line_split[$data_index{'Dig/Ana'}] eq "0") {
            # Analog pad selected.
            $state = 2;
        } else {
            print ("Error!! Pad=\"$line_split[$data_index{'Pad Name'}]\", Dig/Ana should be \"1\" or \"0\" \(current=$line_split[$data_index{'Dig/Ana'}]\)\n");
            exit 1;
        }

        # Digital pad
        if ($state == 1) {
            # Check pad direction.
            if ($line_split[$data_index{'Direction'}] =~ m/(^input$)|(^output$)|(^inout$)/ ) {
            } else {
                print ("Error!! Pad=\"$line_split[$data_index{'Pad Name'}]\", \"Direction\" should be input/output/input \(current=$line_split[$data_index{'Direction'}]\)\n");
                exit 1;
            }
            # Update module ports hash table
            port_hash_table_update(\@line_split, $data_index{'Pad Name'}, "inout", \%io_bank_module_ports_hash); # For bidir only cell, PAD is always inout port type
            # Add module ports into wires hash table
            wire_hash_table_update(\@line_split, $data_index{'Pad Name'}, \%io_bank_module_wires_hash);
        }
        $io_cfg_file_indx++;
    }
}

#################################################################################
# io-bank module database creation
#################################################################################

# read each line in the file
foreach $line (@io_cfg_in_file_array) {

    if (defined($line)) {
        @line_split = split /\,/,$line;
        # Check pad type (digital or analog).
        if ($line_split[$data_index{'Dig/Ana'}] eq "1") {
            # Digital pad selected.
            $state = 1;
        } elsif ($line_split[$data_index{'Dig/Ana'}] eq "0") {
            # Analog pad selected.
            $state = 2;
        } else {
            print ("Error!! Pad=\"$line_split[$data_index{'Pad Name'}]\", Dig/Ana should be \"1\" or \"0\" \(current=$line_split[$data_index{'Dig/Ana'}]\)\n");
            exit 1;
        }

        # -------------------------------------------------------------------------------------------------#
        # Boot critical digital I/O --> all inputs tied to constants instead of configurable registers     #
        # -------------------------------------------------------------------------------------------------#
        $is_boot_crit = 0;
        if ($line_split[$data_index{'Muxed'}] eq "0" && $line_split[$data_index{'Pull direction'}] eq "FLOAT") { $is_boot_crit = 1; }


        # ------------------------------------------------------------------------------------------------ #
        # Driving strength control:                                                                        #
        # ------------------------------------------------------------------------------------------------ #
        $driving_val = ($line_split[$data_index{'Drv_cfg'}] ne 1) ? "CONSTANT" : $line_split[$data_index{'IO DS configuration signal'}];
        $driving_val =~ s/\[.*//;

        $driving_num = $line_split[$data_index{'Drive strength'}];
        if ( $driving_num =~ /^[0-9]+.*$/ ) {
            $bin_val     = sprintf("%04b", $driving_num);
        } else {
            $bin_val = "NONE";
        }
        my @drv_default_bits = split("", $bin_val); # New copy of array reference is required (my)
        $is_constant = $line_split[$data_index{'Drv_cfg'}];

        # ------------------------------------------------------------------------------------------------ #
        # Configuration signals:                                                                           #
        # ------------------------------------------------------------------------------------------------ #
        $driving_sel_0 = (($is_boot_crit eq 1) || ($is_constant ne 1)) ? "1'b" . $drv_default_bits[3] : $driving_val . "[0]";
        $driving_sel_1 = (($is_boot_crit eq 1) || ($is_constant ne 1)) ? "1'b" . $drv_default_bits[2] : $driving_val . "[1]";
        $driving_sel_2 = (($is_boot_crit eq 1) || ($is_constant ne 1)) ? "1'b" . $drv_default_bits[1] : $driving_val . "[2]";
        $driving_sel_3 = (($is_boot_crit eq 1) || ($is_constant ne 1)) ? "1'b" . $drv_default_bits[0] : $driving_val . "[3]";

        # ------------------------------------------------------------------------------------------------ #
        # Loopback control:                                                                                #
        # ------------------------------------------------------------------------------------------------ #
        $force_ie = ($line_split[$data_index{'Force cfg LB'}] ne 1) ? "1'b0" : $line_split[$data_index{'IO force IE signal'}];

        # ------------------------------------------------------------------------------------------------ #
        # Retention enable control:                                                                        #
        # ------------------------------------------------------------------------------------------------ #
        # $rte_val = $line_split[$data_index{'IO RTE configuration signal'}];

        # TODO - degenerated version with only one enable signal
        $rte_val = "west_retention_latch_en";
        $rte = ($rte_val ne "") ? $rte_val : "UNKNOWN";


        # ------------------------------------------------------------------------------------------------ #
        # Schmitt trigger of the input control:                                                            #
        # ------------------------------------------------------------------------------------------------ #
        $st = "1'b1";

        # ------------------------------------------------------------------------------------------------ #
        # Pull control:                                                                                    #
        # ------------------------------------------------------------------------------------------------ #
        if ($line_split[$data_index{'Pull_cfg'}] eq 1) {
            $pullup  = $line_split[$data_index{'IO PS configuration signal'}];
            $pull_en = $line_split[$data_index{'IO PE configuration signal'}];
        } elsif ( $is_boot_crit eq 1 ) {
            $pullup = "1'b1";
            $pull_en = "1'b0";
        } else {
            # print ("HERE CONSTANTS\n")
            # switch ($line_split[$data_index{'Pull direction'}]) {
            #     UP {
            #         $pullup = "1'b1";
            #         $pull_en = "1'b1";
            #     }
            #     DOWN {
            #         $pullup = "1'b0";
            #         $pull_en = "1'b1";
            #     }
            #     else {
            #         $pullup = "1'b1";
            #         $pull_en = "1'b0";
            #     }
            # }
        }

        # Check if digital PAD is muxed.
        if ($state == 1) {

            # Check pad type (digital or analog).
            if ($line_split[$data_index{'Muxed'}] eq "0") {
                # Non-Muxed PAD.
                $state = 3;
            } elsif ($line_split[$data_index{'Muxed'}] eq "1") {
                # Muxed PAD.
                # Load PAD name, change upper-case to lower-case and remove pad_ prefix, if exists.
                $port_name = $line_split[$data_index{'Pad Name'}];
                $port_name =~ tr/[A-Z]/[a-z]/;
                $port_name =~ s/\[|\]|pad_//g;
                # Add prefix/sufix to $port_name and load it into $line_split[7,8,9].
                $line_split[$data_index{'1st from pad'}] = "to_mux_".$port_name;
                $line_split[$data_index{'1st from core'}] = "frm_mux_".$port_name;
                $line_split[$data_index{'1st oen'}] = "frm_mux_".$port_name."_oe_n";
                $io_bank_module_muxs_ports_hash{$line_split[$data_index{'Pad Name'}]} = [($line_split[$data_index{'1st from pad'}], $line_split[$data_index{'1st from core'}], $line_split[$data_index{'1st oen'}])];
                $state = 3;
            } else {
                print ("Error!! Pad=\"$line_split[$data_index{'Pad Name'}]\", Muxed should be \"1\" or \"0\" \(current=$line_split[$data_index{'Muxed'}]\)\n");
                exit 1;
            }
        } else {
            # Analog pads:
            if ($line_split[$data_index{'Pad instance name'}] =~ m/(^I_[A-Z0-9_]+$)/) {
                $io_bank_module_analog_insts_hash{$1} = [$1, $line_split[$data_index{'Pad Cell'}]];
            }
        }

        # Digital Muxed & Non-Muxed PAD
        if ($state == 3) {
            # Check PAD instance naming.
            if ($line_split[$data_index{'Pad instance name'}] =~ m/(^I_[A-Z0-9_]+[A-Z0-9]+$)/) {
                # Scalar pad.
                if ($1) {
                    # Check if PAD instance is already declared, in case it is, assert error.
                    if (exists $io_bank_module_insts_hash{$1}) {
                        print "Error!! Instance=\"$1\" already exists!!\n";
                        exit 1;
                    } else {
                        # --------------------------------------------------------------------------------------------------- #
                        # Extract the I/O configuration inputs outside the dig_io_bank, for potential external configuration: #
                        # --------------------------------------------------------------------------------------------------- #

                        if ($line_split[$data_index{'Pull_cfg'}] eq 1)     {
                            port_hash_table_update(\@line_split, $data_index{'IO PE configuration signal'}, "input", \%io_bank_module_ports_hash);
                            port_hash_table_update(\@line_split, $data_index{'IO PS configuration signal'}, "input", \%io_bank_module_ports_hash);
                        }
                        if ($line_split[$data_index{'Drv_cfg'}] eq 1)      {
                            port_hash_table_update(\@line_split, $data_index{'IO DS configuration signal'}, "input", \%io_bank_module_ports_hash);
                        }
                        if ($line_split[$data_index{'Force cfg LB'}] eq 1) { port_hash_table_update(\@line_split, $data_index{'IO force IE signal'}, "input", \%io_bank_module_ports_hash); }

                        if ($line_split[$data_index{'Direction'}] eq "inout") {
                            # Update module instances hash table for "inout" ports.
                            $io_bank_module_insts_hash{$1} = [($1, $line_split[$data_index{'Pad Cell'}], $line_split[$data_index{'Pad Name'}], $line_split[$data_index{'1st from pad'}], $line_split[$data_index{'1st from core'}], $line_split[$data_index{'1st oen'}], $pull_en , $line_split[$data_index{'Direction'}], $st, $pullup, $rte, $driving_sel_0, $driving_sel_1, $driving_sel_2, $driving_sel_3),$force_ie, \@drv_default_bits];
                            # Update module wire hash table for non-muxed and muxed bidi PAD's #RINAT
                            wire_hash_table_update(\@line_split, $data_index{'1st from pad'}, \%io_bank_module_wires_hash);
                            wire_hash_table_update(\@line_split, $data_index{'1st from core'}, \%io_bank_module_wires_hash);
                            wire_hash_table_update(\@line_split, $data_index{'1st oen'}, \%io_bank_module_wires_hash);
                            # Update module port hash table for non-muxed and muxed bidi PAD's #RINAT
                            port_hash_table_update(\@line_split, $data_index{'1st from pad'}, "output", \%io_bank_module_ports_hash);
                            port_hash_table_update(\@line_split, $data_index{'1st from core'}, "input", \%io_bank_module_ports_hash);
                            port_hash_table_update(\@line_split, $data_index{'1st oen'}, "input", \%io_bank_module_ports_hash);
                        } elsif ($line_split[$data_index{'Direction'}] eq "input") {
                            # Update module instances hash table for "input" ports.
                            $io_bank_module_insts_hash{$1} = [($1, $line_split[$data_index{'Pad Cell'}], $line_split[$data_index{'Pad Name'}], $line_split[$data_index{'1st from pad'}], "1'b1", "1'b1", $pull_en, $line_split[$data_index{'Direction'}], $st, $pullup, $rte, $driving_sel_0, $driving_sel_1, $driving_sel_2, $driving_sel_3),$force_ie, \@drv_default_bits];
                            # Update module wire hash table for non-muxed and muxed input PAD's
                            wire_hash_table_update(\@line_split, $data_index{'1st from pad'}, \%io_bank_module_wires_hash);
                            # Update module port hash table for non-muxed and muxed input PAD's
                            port_hash_table_update(\@line_split, $data_index{'1st from pad'}, "output", \%io_bank_module_ports_hash);
                        } elsif ($line_split[$data_index{'Direction'}] eq "output") {
                            # Update module instances hash table for "output" ports.
                            $io_bank_module_insts_hash{$1} = [($1, $line_split[$data_index{'Pad Cell'}], $line_split[$data_index{'Pad Name'}], $line_split[$data_index{'1st from pad'}], $line_split[$data_index{'1st from core'}], $line_split[$data_index{'1st oen'}], $pull_en , $line_split[$data_index{'Direction'}], $st, $pullup, $rte, $driving_sel_0, $driving_sel_1, $driving_sel_2, $driving_sel_3),$force_ie, \@drv_default_bits];
                            # Update module wire hash table for non-muxed and muxed output PAD's
                            wire_hash_table_update(\@line_split, $data_index{'1st from core'}, \%io_bank_module_wires_hash);
                            wire_hash_table_update(\@line_split, $data_index{'1st oen'}, \%io_bank_module_wires_hash);
                            # Update module port hash table for non-muxed and muxed output PAD's
                            port_hash_table_update(\@line_split, $data_index{'1st from core'}, "input", \%io_bank_module_ports_hash);
                            port_hash_table_update(\@line_split, $data_index{'1st oen'}, "input", \%io_bank_module_ports_hash);
                        }
                    }
                }
            } else {
                print ("Error!! Pad=\"$line_split[$data_index{'Pad instance name'}]\", \"Instance\" should in sturcture of: I_XXX_YYYYnn \(current=$line_split[$data_index{'Pad instance name'}]\)\n");
                exit 1;
            }
        }
        $io_cfg_file_indx++;
    }
}

#################################################################################
# Functional mux. module database creation
#################################################################################

# Add test_mode net into functional mux module.
@test_mode_net = ("test_mode");
port_hash_table_update(\@test_mode_net, 0, "input", \%io_func_module_ports_hash);
wire_hash_table_update(\@test_mode_net, 0, \%io_func_module_wires_hash);
# Add pad_highz net into functional mux module.
@pad_highz_net = ("pad_highz");
port_hash_table_update(\@pad_highz_net, 0, "input", \%io_func_module_ports_hash);
wire_hash_table_update(\@pad_highz_net, 0, \%io_func_module_wires_hash);

# read each line in the file
foreach $line (@io_cfg_in_file_array) {
    if (defined($line)) {
        @line_split = split /\,/,$line;
        # Check pad type (digital or analog).
        if ($line_split[$data_index{'Dig/Ana'}] eq "1") {
            # Digital pad selected.
            $state = 1;
        } elsif ($line_split[$data_index{'Dig/Ana'}] eq "0") {
            # Analog pad selected.
            $state = 2;
        } else {
            print ("Error!! Pad=\"$line_split[$data_index{'Pad Name'}]\", Dig/Ana should be \"1\" or \"0\" \(current=$line_split[$data_index{'Dig/Ana'}]\)\n");
            exit 1;
        }
        # Check if digital PAD is muxed.
        if ($state == 1) {
            # Check pad type (digital or analog).
            if ($line_split[$data_index{'Muxed'}] eq "0") {
                # Non-Muxed PAD.
                $state = 4;
            } elsif ($line_split[$data_index{'Muxed'}] eq "1") {
                # Muxed PAD.
                $state = 3;
            } else {
                print ("Error!! Pad=\"$line_split[$data_index{'Pad Name'}]\", Muxed should be \"1\" or \"0\" \(current=$line_split[$data_index{'Muxed'}]\)\n");
                exit 1;
            }
        }
        # Digital Muxed & Non-Muxed PAD
        if ($state == 3) {
            # Load functional mux instance name.
            $func_mux_inst_name = $line_split[$data_index{'Pad instance name'}]."_mux";
            if (exists $io_func_module_insts_hash{$func_mux_inst_name}) {
                print "Error!! Instance=\"$func_mux_inst_name\" already exists!!\n";
                exit 1;
            } else {
                if ($line_split[$data_index{'Direction'}] eq "inout") {
                    # Load functional mux ports to IO PAD instance.
                    $io_bank_module_mux_port_ref = $io_bank_module_muxs_ports_hash{$line_split[$data_index{'Pad Name'}]};
                    # Add functional mux ports into functional mux ports hash table.
                    port_hash_table_update($io_bank_module_mux_port_ref, 0, "input", \%io_func_module_ports_hash);
                    port_hash_table_update($io_bank_module_mux_port_ref, 1, "output", \%io_func_module_ports_hash);
                    port_hash_table_update($io_bank_module_mux_port_ref, 2, "output", \%io_func_module_ports_hash);
                    # Add functional mux ports into functional mux wires hash table.
                    wire_hash_table_update($io_bank_module_mux_port_ref, 0, \%io_func_module_wires_hash);
                    wire_hash_table_update($io_bank_module_mux_port_ref, 1, \%io_func_module_wires_hash);
                    wire_hash_table_update($io_bank_module_mux_port_ref, 2, \%io_func_module_wires_hash);

                    # Add functional mux port0 (from-pad) into functional mux ports and wires hash table. Port is added if not defined as "()".
                    if (!($line_split[$data_index{'1st from pad'}] =~ m/^\(\)$/)) {
                        port_hash_table_update(\@line_split, $data_index{'1st from pad'}, "output", \%io_func_module_ports_hash);
                        wire_hash_table_update(\@line_split, $data_index{'1st from pad'}, \%io_func_module_wires_hash);
                    } else {
                        $line_split[$data_index{'1st from pad'}] =~ s/^\(\)$//;
                    }
                    # Add functional mux port0 (from-core) into functional mux ports and wires hash table. Port is added if not defined as "1'b0".
                    if (!($line_split[$data_index{'1st from core'}] =~ m/^1'b0$/)) {
                        port_hash_table_update(\@line_split, $data_index{'1st from core'}, "input", \%io_func_module_ports_hash);
                        wire_hash_table_update(\@line_split, $data_index{'1st from core'}, \%io_func_module_wires_hash);
                    }
                    # Add functional mux port0 (output en) into functional mux ports and wires hash table. Port is added if not defined as "set_as_input" or "set_as_output".
                    if (!($line_split[$data_index{'1st oen'}] =~ m/(^set_as_input$)|(^set_as_output$)/)) {
                        port_hash_table_update(\@line_split, $data_index{'1st oen'}, "input", \%io_func_module_ports_hash);
                        wire_hash_table_update(\@line_split, $data_index{'1st oen'}, \%io_func_module_wires_hash);
                    }

                    # Add functional mux port1 (from-pad) into functional mux ports and wires hash table. Port is added if not defined as "()".
                    if (!($line_split[$data_index{'2nd from pad'}] =~ m/^\(\)$/)) {
                        port_hash_table_update(\@line_split, $data_index{'2nd from pad'}, "output", \%io_func_module_ports_hash);
                        wire_hash_table_update(\@line_split, $data_index{'2nd from pad'}, \%io_func_module_wires_hash);
                    } else {
                        $line_split[$data_index{'2nd from pad'}] =~ s/^\(\)$//;
                    }
                    # Add functional mux port1 (from-core) into functional mux ports and wires hash table. Port is added if not defined as "1'b0".
                    if (!($line_split[$data_index{'2nd from core'}] =~ m/^1'b0$/)) {
                        port_hash_table_update(\@line_split, $data_index{'2nd from core'}, "input", \%io_func_module_ports_hash);
                        wire_hash_table_update(\@line_split, $data_index{'2nd from core'}, \%io_func_module_wires_hash);
                    }
                    # Add functional mux port1 (output en) into functional mux ports and wires hash table. Port is added if not defined as "set_as_input" or "set_as_output".
                    if (!($line_split[$data_index{'2nd oen'}] =~ m/(^set_as_input$)|(^set_as_output$)/)) {
                        port_hash_table_update(\@line_split, $data_index{'2nd oen'}, "input", \%io_func_module_ports_hash);
                        wire_hash_table_update(\@line_split, $data_index{'2nd oen'}, \%io_func_module_wires_hash);
                    }

                    # Add functional mux port2 (from-pad) into functional mux ports and wires hash table. Port is added if not defined as "()".
                    if (!($line_split[$data_index{'3rd from pad'}] =~ m/^\(\)$/)) {
                        port_hash_table_update(\@line_split, $data_index{'3rd from pad'}, "output", \%io_func_module_ports_hash);
                        wire_hash_table_update(\@line_split, $data_index{'3rd from pad'}, \%io_func_module_wires_hash);
                    } else {
                        $line_split[$data_index{'3rd from pad'}] =~ s/^\(\)$//;
                    }
                    # Add functional mux port2 (from core) into functional mux ports and wires hash table. Port is added if not defined as "1'b0".
                    if (!($line_split[$data_index{'3rd from core'}] =~ m/^1'b0$/)) {
                        port_hash_table_update(\@line_split, $data_index{'3rd from core'}, "input", \%io_func_module_ports_hash);
                        wire_hash_table_update(\@line_split, $data_index{'3rd from core'}, \%io_func_module_wires_hash);
                    }
                    # Add functional mux port2 (output en) into functional mux ports and wires hash table. Port is added if not defined as "set_as_input" or "set_as_output".
                    if (!($line_split[$data_index{'3rd oen'}] =~ m/(^set_as_input$)|(^set_as_output$)/)) {
                        port_hash_table_update(\@line_split, $data_index{'3rd oen'}, "input", \%io_func_module_ports_hash);
                        wire_hash_table_update(\@line_split, $data_index{'3rd oen'}, \%io_func_module_wires_hash);
                    }

                    # Add functional mux port3 into (from-pad) functional mux ports and wires hash table. Port is added if not defined as "()".
                    if (!($line_split[$data_index{'DFT from pad'}] =~ m/^\(\)$/)) {
                        port_hash_table_update(\@line_split, $data_index{'DFT from pad'}, "output", \%io_func_module_ports_hash);
                        wire_hash_table_update(\@line_split, $data_index{'DFT from pad'}, \%io_func_module_wires_hash);
                    } else {
                        $line_split[$data_index{'DFT from pad'}] =~ s/^\(\)$//;
                    }
                    # Add functional mux port3 into (from-core) functional mux ports and wires hash table. Port is added if not defined as "1'b0".
                    if (!($line_split[$data_index{'DFT from core'}] =~ m/^1'b0$/)) {
                        port_hash_table_update(\@line_split, $data_index{'DFT from core'}, "input", \%io_func_module_ports_hash);
                        wire_hash_table_update(\@line_split, $data_index{'DFT from core'}, \%io_func_module_wires_hash);
                    }
                    # Add functional mux port3 into (output en) functional mux ports and wires hash table. Port is added if not defined as "set_as_input" or "set_as_output".
                    if (!($line_split[$data_index{'DFT oen'}] =~ m/(^set_as_input$)|(^set_as_output$)/)) {
                        port_hash_table_update(\@line_split, $data_index{'DFT oen'}, "input", \%io_func_module_ports_hash);
                        wire_hash_table_update(\@line_split, $data_index{'DFT oen'}, \%io_func_module_wires_hash);
                    }

                    # Add functional mux port selector into functional mux ports and wires hash table.
                    if (!($line_split[$data_index{'Mux Selector'}] =~ m/^2'b00$/)) {
                        port_hash_table_update(\@line_split, $data_index{'Mux Selector'}, "input", \%io_func_module_ports_hash);
                        wire_hash_table_update(\@line_split, $data_index{'Mux Selector'}, \%io_func_module_wires_hash);
                    }

                    $io_func_module_insts_hash{$func_mux_inst_name} = [($func_mux_inst_name, $io_bank_module_mux_port_ref->[0], $io_bank_module_mux_port_ref->[1],
                                                                        $io_bank_module_mux_port_ref->[2], $pad_highz_net[0],
                                                                        $line_split[$data_index{'1st from pad'}], $line_split[$data_index{'1st from core'}], $line_split[$data_index{'1st oen'}],
                                                                        $line_split[$data_index{'2nd from pad'}], $line_split[$data_index{'2nd from core'}], $line_split[$data_index{'2nd oen'}],
                                                                        $line_split[$data_index{'3rd from pad'}], $line_split[$data_index{'3rd from core'}], $line_split[$data_index{'3rd oen'}],
                                                                        $line_split[$data_index{'DFT from pad'}], $line_split[$data_index{'DFT from core'}], $line_split[$data_index{'DFT oen'}]),
                                                                       $line_split[$data_index{'Mux Selector'}], $test_mode_net[0] ];
                } elsif ($line_split[$data_index{'Direction'}] eq "input") {
                    print ("Error!! Muxed PAD must defined as \"inout\", currently defined as \"$line_split[$data_index{'Direction'}]\"");
                    exit 1;
                } elsif ($line_split[$data_index{'Direction'}] eq "output") {
                    print ("Error!! Muxed PAD must defined as \"inout\", currently defined as \"$line_split[$data_index{'Direction'}]\"");
                    exit 1;
                }
            }
        }
        $io_cfg_file_indx++;
    }
}

## DFT test pin mux Begin
#################################################################################
# DFT test-pin-mux module database creation
#################################################################################

# Add test_mode net into functional mux module.
@test_mode_net = ("test_mode");
port_hash_table_update(\@test_mode_net, 0, "input", \%dft_tpm_module_ports_hash);
wire_hash_table_update(\@test_mode_net, 0, \%dft_tpm_module_wires_hash);

# read each line in the file
foreach $line (@io_cfg_in_file_array) {
    if (defined($line)) {
        @line_split = split /\,/,$line;
        # Check pad type (digital or analog).
        if ($line_split[$data_index{'Dig/Ana'}] eq "1") {
            # Digital pad selected.
            $state = 1;
        } elsif ($line_split[$data_index{'Dig/Ana'}] eq "0") {
            # Analog pad selected.
            $state = 2;
        } else {
            print ("Error!! Pad=\"$line_split[$data_index{'Pad Name'}]\", Dig/Ana should be \"1\" or \"0\" \(current=$line_split[$data_index{'Dig/Ana'}]\)\n");
            exit 1;
        }
        # Check if digital PAD is muxed.
        if ($state == 1) {
            # Check pad type (digital or analog).
            if ($line_split[$data_index{'Muxed'}] eq "0") {
                # Non-Muxed PAD.
                $state = 4;
            } elsif ($line_split[$data_index{'Muxed'}] eq "1") {
                # Muxed PAD. Also Check if "DFT from pad" has been allocated.
                if ($line_split[$data_index{'DFT from pad'}] =~ m/^\(\)$/) {
                    $state = 4;
                } else {
                    $state = 3;
                }
            } else {
                print ("Error!! Pad=\"$line_split[$data_index{'Pad Name'}]\", Muxed should be \"1\" or \"0\" \(current=$line_split[$data_index{'Muxed'}]\)\n");
                exit 1;
            }
        }
        # Digital Muxed & Non-Muxed PAD
        if ($state == 3) {
            # Load DFT cell instance name.
            $dft_cell_inst_name = "I_".$line_split[$data_index{'DFT function'}];
            $dft_cell_inst_name =~ s/\[/_/;
            $dft_cell_inst_name =~ s/\]//;
            if (exists $dft_tpm_module_insts_hash{$dft_cell_inst_name}) {
                print "Error!! Instance=\"$dft_cell_inst_name\" already exists!!\n";
                exit 1;
            } else {
                if ($line_split[$data_index{'Direction'}] eq "inout") {
                    # Add functional mux port3 into (from-pad) functional mux ports and wires hash table. Port is added if not defined as "()".
                    if (!($line_split[$data_index{'DFT from pad'}] =~ m/^\(\)$/)) {
                        port_hash_table_update(\@line_split, $data_index{'DFT from pad'}, "input", \%dft_tpm_module_ports_hash);
                        wire_hash_table_update(\@line_split, $data_index{'DFT from pad'}, \%dft_tpm_module_wires_hash);
                    } else {
                        $line_split[$data_index{'DFT from pad'}] =~ s/^\(\)$//;
                    }
                    # Add functional mux port3 into (from-core) functional mux ports and wires hash table. Port is added if not defined as "1'b0".
                    if (!($line_split[$data_index{'DFT from core'}] =~ m/^1'b0$/)) {
                        port_hash_table_update(\@line_split, $data_index{'DFT from core'}, "output", \%dft_tpm_module_ports_hash);
                        wire_hash_table_update(\@line_split, $data_index{'DFT from core'}, \%dft_tpm_module_wires_hash);
                    }
                    # Add functional mux port3 into (output en) functional mux ports and wires hash table. Port is added if not defined as "set_as_input" or "set_as_output".
                    if (!($line_split[$data_index{'DFT oen'}] =~ m/(^set_as_input$)|(^set_as_output$)/)) {
                        port_hash_table_update(\@line_split, $data_index{'DFT oen'}, "output", \%dft_tpm_module_ports_hash);
                        wire_hash_table_update(\@line_split, $data_index{'DFT oen'}, \%dft_tpm_module_wires_hash);
                    }

                    # Check hook-up type. In case of non "hookup-only" cell, the DFT function net is also added to the module ports table. Otherwise, we only declare it as "wire".
                    if (!($line_split[$data_index{'DFT cell'}] =~ m/^\(\)$/)) {
                        if ($line_split[$data_index{'DFT hookup only'}] eq "0") {
                            wire_hash_table_update(\@line_split, $data_index{'DFT function'}, \%dft_tpm_module_wires_hash);
                            if      ($line_split[$data_index{'DFT direction'}] eq "input") {
                                port_hash_table_update(\@line_split, $data_index{'DFT function'}, "output", \%dft_tpm_module_ports_hash);
                            } elsif ($line_split[$data_index{'DFT direction'}] eq "output") {
                                port_hash_table_update(\@line_split, $data_index{'DFT function'}, "input", \%dft_tpm_module_ports_hash);
                            } else {
                                print ("Error!! Pad=\"$line_split[$data_index{'Pad Name'}]\", DFT direction  should be \"inout\" or \"output\" \(current=$line_split[$data_index{'DFT direction'}]\)\n");
                                exit 1;
                            }
                        } else {
                            wire_hash_table_update(\@line_split, $data_index{'DFT function'}, \%dft_tpm_module_wires_hash);
                        }

                        # Check if DFT gate signal is inverted.
                        if ($line_split[$data_index{'DFT gate'}] =~ m/^\~/) {
                            $dft_tpm_gate_invert = "1";
                            # Removed the leading "~" char.
                            $line_split[$data_index{'DFT gate'}] =~ s/^\~//;
                        } else {
                            $dft_tpm_gate_invert = "0";
                        }

                        $dft_tpm_module_insts_hash{$dft_cell_inst_name} = [($dft_cell_inst_name,
                                                                            $line_split[$data_index{'DFT from pad'}], $line_split[$data_index{'DFT from core'}], $line_split[$data_index{'DFT oen'}],
                                                                            $line_split[$data_index{'DFT function'}], $line_split[$data_index{'DFT cell'}], $line_split[$data_index{'DFT direction'}],
                                                                            $line_split[$data_index{'DFT gate'}], $line_split[$data_index{'DFT hookup only'}], $dft_tpm_gate_invert, $line_split[$data_index{'Pad Name'}])];
                    } else {

                        $dft_tpm_module_insts_hash{$line_split[$data_index{'Pad instance name'}]} = [($line_split[$data_index{'Pad instance name'}],
                                                                                                $line_split[$data_index{'DFT from pad'}], $line_split[$data_index{'DFT from core'}], $line_split[$data_index{'DFT oen'}],
                                                                                                $line_split[$data_index{'DFT function'}], $line_split[$data_index{'DFT cell'}], $line_split[$data_index{'DFT direction'}],
                                                                                                $line_split[$data_index{'DFT gate'}], $line_split[$data_index{'DFT hookup only'}], $dft_tpm_gate_invert, $line_split[$data_index{'Pad Name'}])];
                    }
                } elsif ($line_split[$data_index{'Direction'}] eq "input") {
                    print ("Error!! Muxed PAD must defined as \"inout\", currently defined as \"$line_split[$data_index{'Direction'}]\"");
                    exit 1;
                } elsif ($line_split[$data_index{'Direction'}] eq "output") {
                    print ("Error!! Muxed PAD must defined as \"inout\", currently defined as \"$line_split[$data_index{'Direction'}]\"");
                    exit 1;
                }
            }
        }
        $io_cfg_file_indx++;
    }
}

## DFT test pin mux End

# Functional Mux's HDL file generation
open (IO_HDL_FILE,  '>', $io_bank_module_hdl_file);
open (MUX_HDL_FILE, '>', $func_mux_module_hdl_file);
open (DFT_HDL_FILE, '>', $dft_tpm_module_hdl_file);

$total_number_pad_insts = keys %io_bank_module_insts_hash;

print IO_HDL_FILE ("\n");
print IO_HDL_FILE ("//----------------------------------------------------------------------------\n");
print IO_HDL_FILE ("// Time-Date $datetime\n");
print IO_HDL_FILE ("// Total number of instantiated PADs is $total_number_pad_insts\n");
print IO_HDL_FILE ("// Legacy file from Ceragon Networks LTD. (modified by EnICS)\n");
print IO_HDL_FILE ("// $script_fullpath script version $script_version\n");
print IO_HDL_FILE ("// Auto-Generated file - Do not modify manually !!!!!\n");
print IO_HDL_FILE ("// Generated by $ENV{'USER'}\n");
print IO_HDL_FILE ("//----------------------------------------------------------------------------\n\n");

# Generate module name
$io_bank_module_hdl = $io_bank_module_hdl_file;
$io_bank_module_hdl =~ s/\.v//;
# Print module name.
print IO_HDL_FILE ("module $dig_io_bank_module \(\n");
# Load number of keys into counter.
$num_of_hash_keys = (keys %io_bank_module_ports_hash);
# Clear ports per line counter.
$num_of_ports_per_line = 0;

print IO_HDL_FILE ("	west_retention_latch_en, south_retention_latch_en, east_retention_latch_en, north_retention_latch_en,\n");

# Handle all entries in hash-table.
foreach $k (sort keys %io_bank_module_ports_hash) {
    # Decrement hash key counter.
    $num_of_hash_keys--;
    $port_name = @{$io_bank_module_ports_hash{$k}}[0];
    # Insert tab at the beginning of each line.
    if ($num_of_ports_per_line == 0) {
        print IO_HDL_FILE ("\t");
    }
    # Print port.
    print IO_HDL_FILE ("$port_name");
    # Print "," or ");" according to the number of keys left.
    if ($num_of_hash_keys != 0) {
        print IO_HDL_FILE (", ");
    } else {
        print IO_HDL_FILE ("\);\n");
    }
    # Print "\n" if third port reached and more then one key left.
    if ($num_of_ports_per_line == 3 && $num_of_hash_keys != 0) {
        print IO_HDL_FILE ("\n");
        $num_of_ports_per_line = 0;
    } else {
        $num_of_ports_per_line++;
    }
}

print IO_HDL_FILE ("\n");
print IO_HDL_FILE ("//----------------------------------------------------------------------------\n");
print IO_HDL_FILE ("// Ports\n");
print IO_HDL_FILE ("//----------------------------------------------------------------------------\n");

print IO_HDL_FILE ("input west_retention_latch_en;\n");
print IO_HDL_FILE ("input south_retention_latch_en;\n");
print IO_HDL_FILE ("input east_retention_latch_en;\n");
print IO_HDL_FILE ("input north_retention_latch_en;\n\n");


# Print port section.
foreach $k (sort keys %io_bank_module_ports_hash) {
    if (@{$io_bank_module_ports_hash{$k}}[2] ne "scalar") {
        $array_ref = @{$io_bank_module_ports_hash{$k}}[2];
        $port_name = @{$io_bank_module_ports_hash{$k}}[0];
        $port_dir  = @{$io_bank_module_ports_hash{$k}}[1];
        print IO_HDL_FILE ("$port_dir \[${$array_ref}[$#{$array_ref}]:${$array_ref}[0]\] $port_name;\n");
    } else {
        $port_name = @{$io_bank_module_ports_hash{$k}}[0];
        $port_dir  = @{$io_bank_module_ports_hash{$k}}[1];
        print IO_HDL_FILE ("$port_dir $port_name;\n");
    }
}

print IO_HDL_FILE ("\n");
print IO_HDL_FILE ("//----------------------------------------------------------------------------\n");
print IO_HDL_FILE ("// Wires\n");
print IO_HDL_FILE ("//----------------------------------------------------------------------------\n");

print IO_HDL_FILE ("wire west_retention_latch_en_io_int;\n");
print IO_HDL_FILE ("wire south_retention_latch_en_io_int;\n");
print IO_HDL_FILE ("wire east_retention_latch_en_io_int;\n");
print IO_HDL_FILE ("wire north_retention_latch_en_io_int;\n\n");

foreach $k (sort keys %io_bank_module_wires_hash) {
    if (@{$io_bank_module_wires_hash{$k}}[1] ne "scalar") {
        $array_ref = @{$io_bank_module_wires_hash{$k}}[1];
        $wire_name = @{$io_bank_module_wires_hash{$k}}[0];
        print IO_HDL_FILE ("wire \[${$array_ref}[$#{$array_ref}]:${$array_ref}[0]\] $wire_name;\n");
    } else {
        $wire_name = @{$io_bank_module_wires_hash{$k}}[0];
        print IO_HDL_FILE ("wire $wire_name;\n");
    }
}

print IO_HDL_FILE ("\n");
print IO_HDL_FILE ("//----------------------------------------------------------------------------\n");
print IO_HDL_FILE ("// Analog PAD's\n");
print IO_HDL_FILE ("//----------------------------------------------------------------------------\n");

foreach $k (sort keys %io_bank_module_analog_insts_hash) {
    $inst_name          = $io_bank_module_analog_insts_hash{$k}->[0];
    $pad_type           = $io_bank_module_analog_insts_hash{$k}->[1];

    # TODO - degenerated version with only one retention enable signal:
    print IO_HDL_FILE ("`ifdef RTL_SIM\n");
    print IO_HDL_FILE (instantiate_reten_cell({sim => 1, inst => $inst_name, en => "west_retention_latch_en"}));
    print IO_HDL_FILE ("`else\n");
    print IO_HDL_FILE (instantiate_reten_cell({sim => 0, io_cell => $pad_type, inst => $inst_name, en => "west_retention_latch_en"}));
    print IO_HDL_FILE ("`endif\n");
}


print IO_HDL_FILE ("\n");
print IO_HDL_FILE ("//----------------------------------------------------------------------------\n");
print IO_HDL_FILE ("// PAD's\n");
print IO_HDL_FILE ("//----------------------------------------------------------------------------\n");

if ($opt{log}) {print RPT_OUT_FILE ("DEBUG: Hash of the I/O digital bank\n");}
foreach $k (sort keys %io_bank_module_insts_hash) {

    if ($opt{log}) {
        print RPT_OUT_FILE "$k => \n";
        foreach $el (@{$io_bank_module_insts_hash{$k}}) {print RPT_OUT_FILE "\t> $el\n";}
        print RPT_OUT_FILE "\n";
    }

    $inst_name          = $io_bank_module_insts_hash{$k}->[0];
    $pad_type           = $io_bank_module_insts_hash{$k}->[1];
    $pullup_pad         = $io_bank_module_insts_hash{$k}->[9];
    $sch_en_port        = $io_bank_module_insts_hash{$k}->[8];
    $pad_port           = $io_bank_module_insts_hash{$k}->[2];
    $c_port             = $io_bank_module_insts_hash{$k}->[3];
    $i_port             = $io_bank_module_insts_hash{$k}->[4];
    $oen_port           = $io_bank_module_insts_hash{$k}->[5];
    $pull_en_port       = $io_bank_module_insts_hash{$k}->[6];
    $port_dir           = $io_bank_module_insts_hash{$k}->[7];
    $retention_bus      = $io_bank_module_insts_hash{$k}->[10];
    $driving_selector_0 = $io_bank_module_insts_hash{$k}->[11];
    $driving_selector_1 = $io_bank_module_insts_hash{$k}->[12];
    $driving_selector_2 = $io_bank_module_insts_hash{$k}->[13];
    $driving_selector_3 = $io_bank_module_insts_hash{$k}->[14];
    $force_ie           = $io_bank_module_insts_hash{$k}->[15];
    @drv_default_bits   = @{$io_bank_module_insts_hash{$k}->[16]};

    $ie_port            = $oen_port;
    $ie_port            =~ s/oe_n/ie/;

    ############################################################################################################
    # Produce case analysis constants for the driving strength configuration bits of the I/O:                  #
    ############################################################################################################
    if ($port_dir ne "input") {
        print CASE_ANALYSIS_IO_DRV_STRENGTH "\n#--------------------------------------------------------------------------------\n";
        print CASE_ANALYSIS_IO_DRV_STRENGTH "# Minimal driving strength of $inst_name I/O:\n";
        print CASE_ANALYSIS_IO_DRV_STRENGTH "#--------------------------------------------------------------------------------\n";
        for ($bit=0 ; $bit < 4 ; $bit++) {
            print CASE_ANALYSIS_IO_DRV_STRENGTH "set_case_analysis $drv_default_bits[$bit] [get_pins -hierarchical ${inst_name}/DS${bit}]\n"
        }
    }
    ############################################################################################################

    # -------------------------------------------------------------------------------------------------------- #
    # IMPORTANT: The END_IN_PORTS multi-line string must be enclosed with "" and not '', otherwise internal    #
    # variables won't be evaluated.                                                                            #
    # -------------------------------------------------------------------------------------------------------- #
    $io_in_ports_str = <<"END_IN_PORTS";
    // Inouts
    .PAD			($pad_port\),
    // Inputs
    .PE        ($pull_en_port\),
    .PS        ($pullup_pad\),
    .I         ($i_port\),
    .IE        ($ie_port\),   // Active HIGH
    .OEN			($oen_port\),  // Active LOW
    .DS0			($driving_selector_0\),
    .DS1			($driving_selector_1\),
    .DS2			($driving_selector_2\),
    .DS3			($driving_selector_3\),
    .ST        ($sch_en_port\),
    .RTE			(west_retention_latch_en_io_int)\n   );

END_IN_PORTS

    # NOTE: Currently the RTE signal is degenerated to a single "west" signal --> TODO: Deduce the correct RTE
    # domain from the CSV

    if ($ie_port =~ "_ie") {
        print IO_HDL_FILE ("wire   $ie_port;\n");
        print IO_HDL_FILE ("assign $ie_port = $force_ie || $oen_port;\n\n");
    }

    print IO_HDL_FILE ("`ifdef RTL_SIM\n");
    print IO_HDL_FILE ("\tpad_behave $inst_name\n");

    # Output pad
    if ($port_dir eq "output") {
        print IO_HDL_FILE ("\t\(\n");
        print IO_HDL_FILE ("    // Outputs\n");
        if ($c_port =~ m/^\(\)$/) {
            print IO_HDL_FILE ("    .C  \t\t\t\(\),\n");
        } else {
            print IO_HDL_FILE ("    .C  \t\t\t\($c_port\),\n");
        }
        print IO_HDL_FILE ($io_in_ports_str);

        print IO_HDL_FILE ("`else\n");

        print IO_HDL_FILE ("\t$pad_type $inst_name\n");
        print IO_HDL_FILE ("\t\(\n");
        print IO_HDL_FILE ("    // Outputs\n");
        if ($c_port =~ m/^\(\)$/) {
            print IO_HDL_FILE ("    .C  \t\t\t\(\),\n");
        } else {
            print IO_HDL_FILE ("    .C  \t\t\t\($c_port\),\n");
        }
        print IO_HDL_FILE ($io_in_ports_str);
    }
    # Input pad
    elsif ($port_dir eq "input") {
        print IO_HDL_FILE ("\t\(\n");
        print IO_HDL_FILE ("    // Outputs\n");
        print IO_HDL_FILE ("    .C  \t\t\t\($c_port\),\n");
        print IO_HDL_FILE ($io_in_ports_str);

        print IO_HDL_FILE ("`else\n");

        print IO_HDL_FILE ("\t$pad_type $inst_name\n");
        print IO_HDL_FILE ("\t(\n");
        print IO_HDL_FILE ("    // Outputs\n");
        print IO_HDL_FILE ("    .C  \t\t\t\($c_port\),\n");
        print IO_HDL_FILE ($io_in_ports_str);
    }
    else {
        print IO_HDL_FILE ("\t(\n");
        print IO_HDL_FILE ("    // Outputs\n");
        print IO_HDL_FILE ("    .C  \t\t\t\($c_port\),\n");
        print IO_HDL_FILE ($io_in_ports_str);

        print IO_HDL_FILE ("`else\n");

        print IO_HDL_FILE ("\t$pad_type $inst_name\n");
        print IO_HDL_FILE ("\t(\n");
        print IO_HDL_FILE ("    // Outputs\n");
        print IO_HDL_FILE ("    .C  \t\t\t\($c_port\),\n");
        print IO_HDL_FILE ($io_in_ports_str);
    }

    print IO_HDL_FILE ("`endif\n\n");
}
print IO_HDL_FILE ("endmodule\n");
print IO_HDL_FILE ("\n");
print IO_HDL_FILE ("// verilog-library-directories\:\(\"\.\"\)\n");
print IO_HDL_FILE ("// verilog-library-files\:\(\)\n");
print IO_HDL_FILE ("// verilog-library-extensions\:\(\"\.v\" \"\.h\" \"\.sv\"\)\n");
print IO_HDL_FILE ("// End:\n");

$total_number_muxs_insts = keys %io_func_module_insts_hash;

# Functional Mux's HDL file generation
print MUX_HDL_FILE ("\n");
print MUX_HDL_FILE ("//----------------------------------------------------------------------------\n");
print MUX_HDL_FILE ("// Time-Date $datetime\n");
print MUX_HDL_FILE ("// Total number of generated Mux's $total_number_muxs_insts\n");
print MUX_HDL_FILE ("// Ceragon Networks LTD.\n");
print MUX_HDL_FILE ("// $script_fullpath script version $script_version\n");
print MUX_HDL_FILE ("// Auto-Generated file - Do not modify manually !!!!!\n");
print MUX_HDL_FILE ("//----------------------------------------------------------------------------\n\n");

# Generate module name
$func_mux_module_hdl = $func_mux_module_hdl_file;
$func_mux_module_hdl =~ s/\.v//;
# Print module name.
print MUX_HDL_FILE ("module $func_pin_mux_module \(\n");
# Load number of keys into counter.
$num_of_hash_keys = (keys %io_func_module_ports_hash);
# Clear ports per line counter.
$num_of_ports_per_line = 0;
# Handle all entries in hash-table.
foreach $k (sort keys %io_func_module_ports_hash) {
    # Decrement hash key counter.
    $num_of_hash_keys--;
    $port_name = @{$io_func_module_ports_hash{$k}}[0];
    # Insert tab at the beginning of each line.
    if ($num_of_ports_per_line == 0) {
        print MUX_HDL_FILE ("\t");
    }
    # Print port.
    print MUX_HDL_FILE ("$port_name");
    # Print "," or ");" according to the number of keys left.
    if ($num_of_hash_keys != 0) {
        print MUX_HDL_FILE (", ");
    } else {
        print MUX_HDL_FILE ("\);\n");
    }
    # Print "\n" if third port reached and more then one key left.
    if ($num_of_ports_per_line == 3 && $num_of_hash_keys != 0) {
        print MUX_HDL_FILE ("\n");
        $num_of_ports_per_line = 0;
    } else {
        $num_of_ports_per_line++;
    }
}

print MUX_HDL_FILE ("\n");
print MUX_HDL_FILE ("//----------------------------------------------------------------------------\n");
print MUX_HDL_FILE ("// Ports\n");
print MUX_HDL_FILE ("//----------------------------------------------------------------------------\n");

# Print port section.
foreach $k (sort keys %io_func_module_ports_hash) {
    if (@{$io_func_module_ports_hash{$k}}[2] ne "scalar") {
        $array_ref = @{$io_func_module_ports_hash{$k}}[2];
        $port_name = @{$io_func_module_ports_hash{$k}}[0];
        $port_dir  = @{$io_func_module_ports_hash{$k}}[1];
        print MUX_HDL_FILE ("$port_dir \[${$array_ref}[$#{$array_ref}]:${$array_ref}[0]\] $port_name;\n");
    } else {
        $port_name = @{$io_func_module_ports_hash{$k}}[0];
        $port_dir  = @{$io_func_module_ports_hash{$k}}[1];
        print MUX_HDL_FILE ("$port_dir $port_name;\n");
    }
}

print MUX_HDL_FILE ("\n");
print MUX_HDL_FILE ("//----------------------------------------------------------------------------\n");
print MUX_HDL_FILE ("// Wires\n");
print MUX_HDL_FILE ("//----------------------------------------------------------------------------\n");

$set_as_input_tieoff  = "1'b1";
$set_as_output_tieoff = "1'b0";

foreach $k (sort keys %io_func_module_wires_hash) {
    if (@{$io_func_module_wires_hash{$k}}[1] ne "scalar") {
        $array_ref = @{$io_func_module_wires_hash{$k}}[1];
        $wire_name = @{$io_func_module_wires_hash{$k}}[0];
        print MUX_HDL_FILE ("wire \[${$array_ref}[$#{$array_ref}]:${$array_ref}[0]\] $wire_name;\n");
    } else {
        $wire_name = @{$io_func_module_wires_hash{$k}}[0];
        print MUX_HDL_FILE ("wire $wire_name;\n");
    }
}
print MUX_HDL_FILE ("wire set_as_input=$set_as_input_tieoff;\n");
print MUX_HDL_FILE ("wire set_as_output=$set_as_output_tieoff;\n");

print MUX_HDL_FILE ("\n");
print MUX_HDL_FILE ("//----------------------------------------------------------------------------\n");
print MUX_HDL_FILE ("// PAD MUX's\n");
print MUX_HDL_FILE ("//----------------------------------------------------------------------------\n");

foreach $k (sort keys %io_func_module_insts_hash) {
    $pad_type         = "pin_mux_cell";
    $inst_name        = $io_func_module_insts_hash{$k}->[0];

    $pad_out          = $io_func_module_insts_hash{$k}->[2];
    $pad_oe_n         = $io_func_module_insts_hash{$k}->[3];
    $pad_in_primary   = $io_func_module_insts_hash{$k}->[5];
    $pad_in_second    = $io_func_module_insts_hash{$k}->[8];
    $pad_in_third     = $io_func_module_insts_hash{$k}->[11];
    $pad_in_fourth    = $io_func_module_insts_hash{$k}->[14];

    $pad_in           = $io_func_module_insts_hash{$k}->[1];
    $pad_highz        = $io_func_module_insts_hash{$k}->[4];
    $pad_primary      = $io_func_module_insts_hash{$k}->[6];
    $pad_second       = $io_func_module_insts_hash{$k}->[9];
    $pad_third        = $io_func_module_insts_hash{$k}->[12];
    $pad_fourth       = $io_func_module_insts_hash{$k}->[15];
    $pad_primary_oe_n = $io_func_module_insts_hash{$k}->[7];
    $pad_second_oe_n  = $io_func_module_insts_hash{$k}->[10];
    $pad_third_oe_n   = $io_func_module_insts_hash{$k}->[13];
    $pad_fourth_oe_n  = $io_func_module_insts_hash{$k}->[16];
    $mux_sel          = $io_func_module_insts_hash{$k}->[17];
    $test_mode        = $io_func_module_insts_hash{$k}->[18];

    print MUX_HDL_FILE ("$pad_type $inst_name\n");
    print MUX_HDL_FILE ("\(\n");
    print MUX_HDL_FILE (" // Outputs\n");
    print MUX_HDL_FILE (" .pad_out\t\t\t\($pad_out\),\n");
    print MUX_HDL_FILE (" .pad_oe_n\t\t\t\($pad_oe_n\),\n");
    print MUX_HDL_FILE (" .pad_in_primary\t\t\($pad_in_primary\),\n");
    print MUX_HDL_FILE (" .pad_in_second\t\t\t\($pad_in_second\),\n");
    print MUX_HDL_FILE (" .pad_in_third\t\t\t\($pad_in_third\),\n");
    print MUX_HDL_FILE (" .pad_in_fourth\t\t\t\($pad_in_fourth\),\n");
    print MUX_HDL_FILE (" // Inputs\n");
    print MUX_HDL_FILE (" .pad_in\t\t\t\($pad_in\),\n");
    print MUX_HDL_FILE (" .pad_highz\t\t\t\($pad_highz\),\n");
    print MUX_HDL_FILE (" .pad_primary\t\t\t\($pad_primary\),\n");
    print MUX_HDL_FILE (" .pad_second\t\t\t\($pad_second\),\n");
    print MUX_HDL_FILE (" .pad_third\t\t\t\($pad_third\),\n");
    print MUX_HDL_FILE (" .pad_fourth\t\t\t\($pad_fourth\),\n");
    print MUX_HDL_FILE (" .pad_primary_oe_n\t\t\($pad_primary_oe_n\),\n");
    print MUX_HDL_FILE (" .pad_second_oe_n\t\t\($pad_second_oe_n\),\n");
    print MUX_HDL_FILE (" .pad_third_oe_n\t\t\($pad_third_oe_n\),\n");
    print MUX_HDL_FILE (" .pad_fourth_oe_n\t\t\($pad_fourth_oe_n\),\n");
    print MUX_HDL_FILE (" .mux_sel\t\t\t\($mux_sel\),\n");
    print MUX_HDL_FILE (" .test_mode\t\t\t\($test_mode\) \n");
    print MUX_HDL_FILE ("\);\n");
    print MUX_HDL_FILE ("\n\n");
}
print MUX_HDL_FILE ("endmodule\n");
print MUX_HDL_FILE ("\n");
print MUX_HDL_FILE ("// verilog-library-directories\:\(\"\.\"\)\n");
print MUX_HDL_FILE ("// verilog-library-files\:\(\)\n");
print MUX_HDL_FILE ("// verilog-library-extensions\:\(\"\.v\" \"\.h\" \"\.sv\"\)\n");
print MUX_HDL_FILE ("// End:\n");

## DFT Begin
$total_number_dft_tpm_insts = keys %dft_tpm_module_insts_hash;

# Functional Mux's HDL file generation
print DFT_HDL_FILE ("\n");
print DFT_HDL_FILE ("//----------------------------------------------------------------------------\n");
print DFT_HDL_FILE ("// Time-Date $datetime\n");
print DFT_HDL_FILE ("// Total number of generated DFT cells $total_number_dft_tpm_insts\n");
print DFT_HDL_FILE ("// Ceragon Networks LTD.\n");
print DFT_HDL_FILE ("// $script_fullpath script version $script_version\n");
print DFT_HDL_FILE ("// Auto-Generated file - Do not modify manually !!!!!\n");
print DFT_HDL_FILE ("//----------------------------------------------------------------------------\n\n");

# Generate module name
$dft_tpm_module_hdl = $dft_tpm_module_hdl_file;
$dft_tpm_module_hdl =~ s/\.v//;
# Print module name.
print DFT_HDL_FILE ("module $dft_pin_mux_module \(\n");
# Load number of keys into counter.
$num_of_hash_keys = (keys %dft_tpm_module_ports_hash);
# Clear ports per line counter.
$num_of_ports_per_line = 0;
# Handle all entries in hash-table.
foreach $k (sort keys %dft_tpm_module_ports_hash) {
    # Decrement hash key counter.
    $num_of_hash_keys--;
    $port_name = @{$dft_tpm_module_ports_hash{$k}}[0];
    # Insert tab at the beginning of each line.
    if ($num_of_ports_per_line == 0) {
        print DFT_HDL_FILE ("\t");
    }
    # Print port.
    print DFT_HDL_FILE ("$port_name");
    # Print "," or ");" according to the number of keys left.
    if ($num_of_hash_keys != 0) {
        print DFT_HDL_FILE (", ");
    } else {
        print DFT_HDL_FILE ("\);\n");
    }
    # Print "\n" if third port reached and more then one key left.
    if ($num_of_ports_per_line == 3 && $num_of_hash_keys != 0) {
        print DFT_HDL_FILE ("\n");
        $num_of_ports_per_line = 0;
    } else {
        $num_of_ports_per_line++;
    }
}

print DFT_HDL_FILE ("\n");
print DFT_HDL_FILE ("//----------------------------------------------------------------------------\n");
print DFT_HDL_FILE ("// Ports\n");
print DFT_HDL_FILE ("//----------------------------------------------------------------------------\n");

# Print port section.
foreach $k (sort keys %dft_tpm_module_ports_hash) {
    if (@{$dft_tpm_module_ports_hash{$k}}[2] ne "scalar") {
        $array_ref = @{$dft_tpm_module_ports_hash{$k}}[2];
        $port_name = @{$dft_tpm_module_ports_hash{$k}}[0];
        $port_dir  = @{$dft_tpm_module_ports_hash{$k}}[1];
        print DFT_HDL_FILE ("$port_dir \[${$array_ref}[$#{$array_ref}]:${$array_ref}[0]\] $port_name;\n");
    } else {
        $port_name = @{$dft_tpm_module_ports_hash{$k}}[0];
        $port_dir  = @{$dft_tpm_module_ports_hash{$k}}[1];
        print DFT_HDL_FILE ("$port_dir $port_name;\n");
    }
}

print DFT_HDL_FILE ("\n");
print DFT_HDL_FILE ("//----------------------------------------------------------------------------\n");
print DFT_HDL_FILE ("// Wires\n");
print DFT_HDL_FILE ("//----------------------------------------------------------------------------\n");

$set_as_input_tieoff = "1'b1";
$set_as_output_tieoff = "1'b0";

foreach $k (sort keys %dft_tpm_module_wires_hash) {
    if (@{$dft_tpm_module_wires_hash{$k}}[1] ne "scalar") {
        $array_ref = @{$dft_tpm_module_wires_hash{$k}}[1];
        $wire_name = @{$dft_tpm_module_wires_hash{$k}}[0];
        print DFT_HDL_FILE ("wire \[${$array_ref}[$#{$array_ref}]:${$array_ref}[0]\] $wire_name;\n");
    } else {
        $wire_name = @{$dft_tpm_module_wires_hash{$k}}[0];
        print DFT_HDL_FILE ("wire $wire_name;\n");
    }
}
print DFT_HDL_FILE ("wire set_as_input=$set_as_input_tieoff;\n");
print DFT_HDL_FILE ("wire set_as_output=$set_as_output_tieoff;\n");

print DFT_HDL_FILE ("\n");
print DFT_HDL_FILE ("//----------------------------------------------------------------------------\n");
print DFT_HDL_FILE ("// DFT Cells\n");
print DFT_HDL_FILE ("//----------------------------------------------------------------------------\n");

foreach $k (sort keys %dft_tpm_module_insts_hash) {
    $dft_src_pad     = $dft_tpm_module_insts_hash{$k}->[10];
    $dft_cell_type   = $dft_tpm_module_insts_hash{$k}->[5];
    $inst_name       = $dft_tpm_module_insts_hash{$k}->[0];

    $dft_from_pad    = $dft_tpm_module_insts_hash{$k}->[1];
    $dft_from_core   = $dft_tpm_module_insts_hash{$k}->[2];
    $dft_oe          = $dft_tpm_module_insts_hash{$k}->[3];
    $dft_func        = $dft_tpm_module_insts_hash{$k}->[4];
    $dft_dir         = $dft_tpm_module_insts_hash{$k}->[6];
    $dft_gate        = $dft_tpm_module_insts_hash{$k}->[7];
    $dft_gate_invert = $dft_tpm_module_insts_hash{$k}->[9];

    if (!($dft_cell_type =~ m/^\(\)$/)) {
        if (!(exists $dft_tpm_module_wires_hash{$dft_gate})) {
            print "Error!!! gate signal \"$dft_gate\" does not exists!!!\n";
            exit 1;
        }

        if ($dft_gate_invert eq "1") {
            $dft_gate = "~".$dft_gate;
        }
    }
    print DFT_HDL_FILE ("\n");
    print DFT_HDL_FILE ("//----------------------------------------------------------------------------\n");
    print DFT_HDL_FILE ("// Source: $dft_src_pad\n");
    print DFT_HDL_FILE ("//----------------------------------------------------------------------------\n");

    if (!($dft_cell_type =~ m/^\(\)$/)) {
        print DFT_HDL_FILE ("$dft_cell_type $inst_name\n");
        #
        if      ($dft_dir eq "input") {
            print DFT_HDL_FILE ("\(\n");
            print DFT_HDL_FILE (" // Outputs\n");
            print DFT_HDL_FILE (" .y\t\t\t\($dft_func\),\n");
            print DFT_HDL_FILE (" // Inputs\n");
            print DFT_HDL_FILE (" .a\t\t\t\($dft_gate\),\n");
            print DFT_HDL_FILE (" .b\t\t\t\($dft_from_pad\) \n");
            print DFT_HDL_FILE ("\);\n");
            print DFT_HDL_FILE ("assign $dft_from_core = 1'b0;\n");
            print DFT_HDL_FILE ("assign $dft_oe = set_as_input;\n");
        } elsif ($dft_dir eq "output") {
            print DFT_HDL_FILE ("\(\n");
            print DFT_HDL_FILE (" // Outputs\n");
            print DFT_HDL_FILE (" .y\t\t\t\($dft_from_core\),\n");
            print DFT_HDL_FILE (" // Inputs\n");
            print DFT_HDL_FILE (" .a\t\t\t\($dft_gate\),\n");
            print DFT_HDL_FILE (" .b\t\t\t\($dft_func\) \n");
            print DFT_HDL_FILE ("\);\n");
            print DFT_HDL_FILE ("assign $dft_oe = set_as_output;\n");
        }
    } else {
        print DFT_HDL_FILE ("// Un-allocated DFT pad\n");
        print DFT_HDL_FILE ("assign $dft_from_core = 1'b0;\n");
        print DFT_HDL_FILE ("assign $dft_oe = set_as_input;\n");
    }
}
print DFT_HDL_FILE ("\n");
print DFT_HDL_FILE ("endmodule\n");
print DFT_HDL_FILE ("\n");
print DFT_HDL_FILE ("// verilog-library-directories\:\(\"\.\"\)\n");
print DFT_HDL_FILE ("// verilog-library-files\:\(\)\n");
print DFT_HDL_FILE ("// verilog-library-extensions\:\(\"\.v\" \"\.h\" \"\.sv\"\)\n");
print DFT_HDL_FILE ("// End:\n");

if ($opt{log}) {
    print RPT_OUT_FILE ("****************************************************************************\n");
    print RPT_OUT_FILE ("*   $script_fullpath script version $script_version Time/Date $datetime    *\n");
    print RPT_OUT_FILE ("****************************************************************************\n");
    print RPT_OUT_FILE ("Total number of generated PADs $total_number_pad_insts\n");
    print RPT_OUT_FILE ("Total number of generated Mux's $total_number_muxs_insts\n");
    print RPT_OUT_FILE ("Total number of generated DFT cells $total_number_dft_tpm_insts\n");
}

## DFT End

close(IO_HDL_FILE);
close(MUX_HDL_FILE);
if ($opt{log}) { close(RPT_OUT_FILE); }
close(DFT_HDL_FILE);

exit 0;
