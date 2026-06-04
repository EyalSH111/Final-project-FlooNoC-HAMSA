
// THIS FILE CONTAINS ADDITIONAL COMMON FUNCTIONS FOR GENERAL USE
// EACH ONE ADDING FUNCTION ***MUST*** INDICATE NAME+DATE AS FOLLOWS:
// Inserted: dd/mm/yyyy by <name>

// CONSTANT FUNCTIONS
// ==================
// CEILING LOG2 OF A NUMBER (may be used e.g. for parameter manipulations)
// Inserted: 01/12/2009 by Micha Stern
// *** Warning *** module support integers little than 2^31 !!!
function integer clog2;
  input integer value;
  integer value_next;
  begin
    value_next = value - 1;
    for (clog2 = 0; value_next > 0; clog2 = clog2 + 1)
      value_next = value_next >> 1;
  end
endfunction


//function  integer length_of_file;
//   input integer file_handle;
//   integer line_num;
//   integer status;
//   reg [8*200:0] str;  
//     
//     begin
//       length_of_file = 0;
//       while (!$feof(file_handle)) begin            
//      //      $display ("length_of_file = %d",length_of_file);
//            status = $fscanf(file_handle,"%S\n",  str);
//            length_of_file = length_of_file+1;
//       end
//     end
//endfunction


// NON-CONSTANT FUNCTIONS
// ======================

