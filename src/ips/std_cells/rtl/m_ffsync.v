`undef STD_DEFINED

//////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Special flip-flop intended to be used as 1st FF in a synchronizer:                                       //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////
module m_ffsync
  #(
    parameter X_SIZE  = 1
    )
   ( input CK, input D,
`ifdef STD_SIM
     output reg Q);
`else
   output       Q);
`endif

`ifdef STD_SIM
 `define STD_DEFINED
   always @(posedge CK)
     Q <= D;

`elsif TSMC_65
   // /data/tsmc/65LP//dig_libs/ARM_FEONLY/arm/tsmc/cln65lp/sc9_base_rvt/r0p0/verilog/sc9_cln65lp_base_rvt.v
   // /data/tsmc/65LP//dig_libs/ARM_FEONLY/arm/tsmc/cln65lp/sc9_base_rvt/r0p0/doc/sc9_cln65lp_base_rvt_databook.pdf
    generate
      case(X_SIZE)
          0 : begin : x0
            `define STD_DEFINED              
            DFFQ_X0P5M_A9TR i_ff (.Q(Q), .CK(CK), .D(D));
        end
          1 : begin : x1
            `define STD_DEFINED              
            DFFQ_X1M_A9TR i_ff (.Q(Q), .CK(CK), .D(D));
        end
          2 : begin : x2
            `define STD_DEFINED              
            DFFQ_X2M_A9TR i_ff (.Q(Q), .CK(CK), .D(D));
        end
          3 : begin : x3
            `define STD_DEFINED              
            DFFQ_X3M_A9TR i_ff (.Q(Q), .CK(CK), .D(D));
        end
          4 : begin : x4
            `define STD_DEFINED              
            DFFQ_X4M_A9TR i_ff (.Q(Q), .CK(CK), .D(D));
        end
        endcase
    endgenerate


`elsif TSMC16
   // /data/tsmc/16FF/dig_libs/TSMCHOME/digital/Front_End/verilog/tcbn16ffcllbwp16p90cpd_100a/tcbn16ffcllbwp16p90cpd.v
   // /data/tsmc/16FF/dig_libs/doc/DB_TCBN16FFCLLBWP16P90CPD_TT0P8V25C.pdf
   generate
      case(X_SIZE)
         1 : begin : x1
             `define STD_DEFINED
             `ifdef ULVT_ONLY
                SDFSYNQD1BWP16P90CPDULVT I_ff (.CP(CK), .D(D), .SE(1'b0), .SI(1'b0), .Q(Q));
               `else
                SDFSYNQD1BWP16P90CPD     I_ff (.CP(CK), .D(D), .SE(1'b0), .SI(1'b0), .Q(Q));
             `endif
         end
         2 : begin : x2
             `define STD_DEFINED
             `ifdef ULVT_ONLY
                SDFSYNQD2BWP16P90CPDULVT I_ff (.CP(CK), .D(D), .SE(1'b0), .SI(1'b0), .Q(Q));
             `else
                SDFSYNQD2BWP16P90CPD     I_ff (.CP(CK), .D(D), .SE(1'b0), .SI(1'b0), .Q(Q));
             `endif
         end
      endcase
   endgenerate

`endif // !`elsif TSMC16


endmodule
`ifndef STD_DEFINED
    ERROR NO STD_X TECHNOLOGY FOUND
`endif
