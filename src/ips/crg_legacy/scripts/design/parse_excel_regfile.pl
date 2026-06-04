#!/usr/local/bin/perl -w

#    use strict;
use Spreadsheet::ParseExcel;
use Spreadsheet::XLSX;
use Data::Dumper qw(Dumper);

sub get_options {
    my $arg ;
    $opt{extra_space} = 0;
    while (@_) {
        $arg = shift ;

        $arg =~ /-block_name=/ && do {$arg =~ s/-block_name=(\w+)/$1/s;   $opt{block_name}=$arg; next};
        $arg =~ /-excel_path=/ && do {$arg =~ s/-excel_path=([\w+\/+])/$1/s;   $opt{excel_path}=$arg; next};
        $arg =~ /-sheet_name=/ && do {$arg =~ s/-sheet_name=(\w+)/$1/s;   $opt{sheet_name}=$arg; next};
        $arg =~ /-out_file_name=/ && do {$arg =~ s/-out_file_name=([\w+\/+\.+])/$1/s;   $opt{out_file_name}=$arg; next};
        $arg =~ /-address_width=/ && do {$arg =~ s/-address_width=(\w+)/$1/s;   $opt{address_width}=$arg; next};
        $arg =~ /-cdc=/ && do {$arg =~ s/-cdc=(\w+)/$1/s;   $opt{cdc}=$arg; next};
    } #end while(@_)
}#end get_options

$opt{block_name}="";
$opt{excel_path}="";
$opt{sheet_name}="";
$opt{out_file_name}="";
$opt{address_width}=8;
$opt{cdc}=0;

&get_options (@ARGV);           # fills global hash %opt

my $block_name = $opt{block_name};
my $excel_path = $opt{excel_path};
my $sheet_name = $opt{sheet_name};
my $out_file_name = $opt{out_file_name};
my $address_width = $opt{address_width};
my $cdc = $opt{cdc};

#    print "~cdc = ~$cdc \n";
print "sheet = $sheet_name \n";

my $address_width_msb = $address_width-1;

#ben my $FileName = "$DB_DIR/negev/common/address_map/Negev_register_file.xls";
#my $FileName = "$DB_DIR/negev/$root/$block_name/work/".$rf_file.".xlsx";
if ( !-e $excel_path ) {
    print "error opening file $excel_path \n";
    exit 255;
}
# save original settings. this is done because the XLSX->new line prints a lot of warnings to stderr
*OLD_STDOUT = *STDOUT;
*OLD_STDERR = *STDERR;
open my $log_fh, '>>', '/dev/null';
*STDOUT = $log_fh;
*STDERR = $log_fh;

my $workbook = Spreadsheet::XLSX->new($excel_path);
if ( !defined $workbook ) {
    print "error opening file $excel_path \n";
    exit 255;
}
*STDOUT = *OLD_STDOUT;
*STDERR = *OLD_STDERR;



# Following block is used to Iterate through all worksheets
# in the workbook and print the worksheet content

#different from VBA because row/col start at 0
my $int_vars_first_data_row = 3;



my $worksheet = $workbook->worksheet($sheet_name);
#die "error opening worksheet with name $sheet_name \n" if ( !defined $worksheet );
if ( !defined $worksheet ) {
    print "error opening worksheet with name $sheet_name \n";
    exit 255;
}

#    my @ColsNames = ("Reg. Name", "Address", "Field name", "Bit Field", "mask", "R / W", "(reset)", "Shadow", "False Path", "Signed", "Valid vals", "Clock Name", "Coverage Type", "Coverage Enable", "Special Function", "Path");
#we dont have shadow regs in negev
my @ColsNames = ("Reg. Name", "Address", "Field name", "Bit Field", "mask", "R / W", "(reset)", "False Path", "Signed", "Valid vals", "Async Reset", "Clock Name", "Coverage Type", "Coverage Enable", "Special Function", "Path");

my $n_captions_row = FindInCol("cell_name" => "Reg. Name", "col_num" => "1");

my @SelectedCols;
for my $i (0 .. $#ColsNames) {
    if(($ColsNames[$i] ne "mask") && !($ColsNames[$i] eq "Clock Name" && !$cdc)) {
        #           print "ColsNames[i] = $ColsNames[$i] \n";
        $SelectedCols[$i] = FindInRow("cell_name" => $ColsNames[$i], "row_num" => $n_captions_row);
    }
}
# we are not using modification type in Negev
#
#    my $modification_type_col = FindInRow("cell_name" => "Modification Type", "row_num" => $n_captions_row);

my $end_row_num = $int_vars_first_data_row;
my $cell_data = "";
my $cell_data_value = "";

do{
    $end_row_num = $end_row_num + 1;
    $cell_data = $worksheet->{Cells}[$end_row_num][0];
    $cell_data_value = defined $cell_data->{Val} ? $cell_data->{Val} : 0;
} until ($cell_data_value eq "END");

open(FILE, "> $out_file_name") || die "problem opening $out_file_name\n";

my $row_counter = $int_vars_first_data_row;

my $cell = "";
my $value = "";
my $text_line = "";
my $bit_field = "";
my $mask = "";
my $field_name="";
my $reg_index = "";

while($row_counter < $end_row_num) {
    $text_line = "";
    $reg_index = $worksheet->{Cells}[$row_counter][0]                  ;

    if (defined $reg_index) {
        for my $col_counter ( 0 .. $#ColsNames) {
            if($ColsNames[$col_counter] eq "mask") {
                $value = $mask;
            } elsif(($ColsNames[$col_counter] eq "Clock Name") && !$cdc) {
            } else {
                $cell = $worksheet->{Cells}[$row_counter][$SelectedCols[$col_counter]];
                if (defined $cell) {
                    $value = $cell->{Val};
                    if($ColsNames[$col_counter] eq "Bit Field") {
                        $bit_field = $value;
                        $mask = calcMask("bit_field" => $bit_field);
                    } elsif($ColsNames[$col_counter] eq "Field name") {
                        $field_name = $value;
                    }
                } else {
                    $value = "";
                }
            }
            if($col_counter == 0) {
                $text_line = $value;
            } else {
                $text_line = $text_line." ".$value;
            }
        }
    }



    #MAKES SURE THAT BIT FIELD IN EXCEL IS CONSISTENT WITH ADDRESS WIDTH PARAMETER
    if(((uc($field_name) eq uc($block_name)."_BAD_RD_ADDR") or (uc($field_name) eq uc($block_name)."_BAD_WR_ADDR")) and ($bit_field ne "[$address_width_msb:0]")) {
        print "ERROR: BIT FIELD FOR $field_name IS INCONSISTENT WITH \$ADDRESS_WIDTH IN run_gen_regfile_hdl\.sh\n";
        exit 255;
    }

    if($text_line ne "") {
        print FILE $text_line."\n";
    }
    $row_counter = $row_counter + 1;
}
close(FILE);

#
#args: cell_name, col_num
#
sub FindInCol {
    my %hash = @_;

    my $find_in_col = -1;
    my $i = -1;
    my $curr = "";
    my $curr_cell = "";
    do{
        $i = $i + 1;
        $curr_cell = $worksheet->{Cells}[$i][$hash{"col_num"}];
        if (defined $curr_cell) {
            $curr = $curr_cell->{Val};
            if ($curr eq $hash{"cell_name"}) {
                $find_in_col = $i;
                $curr = "END";
            }
        }
    } until (($curr eq "END") or ($i > 10000));

    if($find_in_col > 10000) {
        die ("reg name not in col 1 \n");
    }
    return $find_in_col;
}

#
#args: cell_name, row_num
#
sub FindInRow {
    my %hash = @_;
    my $find_in_row = -1;
    my $i = -1;
    my $curr = "";
    my $curr_cell = "";
    do{
        $i = $i + 1;
        $curr_cell = $worksheet->{Cells}[$hash{"row_num"}][$i];
        if (defined $curr_cell) {
            $curr = $curr_cell->{Val};
            if ($curr eq $hash{"cell_name"}) {
                $find_in_row = $i;
                $curr = "END";
            }
        }
        if ($i > 100) {
            die "Can't find caption @{[%hash]} in worksheet \n";
        }
    } until ($curr eq "END");
    return $find_in_row;
}

#
#args: bit_field
#
sub calcMask {
    my %hash = @_;
    my $bit_field = $hash{"bit_field"};
    my $mask = "";
    my $mask_bin = "";
    my $mask_hex = "";
    my @bits = split /:/, $bit_field;
    #   print Dumper \@bits;
    #   print "\n";
    my $msb = substr($bits[0],1);
    my $lsb = substr($bits[1],0,-1);
    #   print "msb = $msb   lsb = $lsb \n";

    my $num_leading_zeros = 31-$msb;
    #num trailing zeros = $lsb

    my $field_size = $msb - $lsb + 1;
    #   print "field_size = $field_size \n";

    for my $leading_zero_index ( 1 .. $num_leading_zeros ) {
        $mask_bin = $mask_bin."0";
    }

    #   print "mask_bin = $mask_bin \n";

    for my $field_index ( 1 .. $field_size ) {
        $mask_bin = $mask_bin."1";
    }

    #   print "mask_bin = $mask_bin \n";

    for my $trailing_zero_index ( 1 .. $lsb ) {
        $mask_bin = $mask_bin."0";
    }

    #   print "mask_bin = $mask_bin \n";

    $mask_hex = sprintf('%X', oct("0b$mask_bin"));

    #   print "mask_hex = $mask_hex \n";

    my $num_trailing_zero_bytes = 8-length($mask_hex);

    for my $trailing_zero_index ( 1 .. $num_trailing_zero_bytes ) {
        $mask = $mask."0";
    }

    $mask=$mask.$mask_hex;
    #   print "mask = $mask \n";
    return $mask;
}
