module crg_tieoff (hi,lo);
   output  lo;   // low output
   output  hi;   // high output.

   m_tie_lo i_tie_lo (.LO (lo));
   m_tie_hi i_tie_hi (.HI (hi));

endmodule // crg_tieoff
