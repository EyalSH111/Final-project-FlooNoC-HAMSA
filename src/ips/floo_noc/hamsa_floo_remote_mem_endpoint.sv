// Minimal remote Floo endpoint for the HAMSA 2x2/full-integration demo.
// It receives Floo request flits, unpacks them through a second Chimney, and
// completes writes against a tiny AXI register slave.

import floo_hamsa_pkg::*;

module hamsa_floo_remote_mem_endpoint (
  input  logic      clk_i,
  input  logic      rst_ni,
  input  logic      test_enable_i,
  input  floo_req_t floo_req_i,
  input  floo_rsp_t floo_rsp_i,
  output logic      floo_req_valid_o,
  output floo_req_chan_t floo_req_o,
  input  logic      floo_req_ready_i,
  output logic      floo_rsp_valid_o,
  output floo_rsp_chan_t floo_rsp_o,
  input  logic      floo_rsp_ready_i
);

  axi_in_req_t  remote_mgr_req;
  axi_in_rsp_t  remote_mgr_rsp;
  axi_out_req_t remote_slv_req;
  axi_out_rsp_t remote_slv_rsp;
  floo_req_t    remote_floo_req_o;
  floo_rsp_t    remote_floo_rsp_o;

  logic [31:0] remote_reg_q;
  logic        remote_aw_seen_q;
  logic        remote_w_seen_q;
  logic        remote_b_pending_q;
  logic        remote_r_pending_q;
  axi_out_id_t remote_b_id_q;
  axi_out_id_t remote_r_id_q;
  int unsigned remote_write_count_q;
  int unsigned remote_req_flit_count_q;
  int unsigned remote_rsp_flit_count_q;

  assign remote_mgr_req = '0;

  hamsa_floo_chimney_wrap #(
    .AxiCfg        ( AxiCfg        ),
    .ChimneyCfg    ( ChimneyCfg    ),
    .RouteCfg      ( RouteCfg      ),
    .AtopSupport   ( AtopSupport   ),
    .MaxAtomicTxns ( MaxAtomicTxns ),
    .id_t          ( id_t          ),
    .hdr_t         ( hdr_t         ),
    .axi_in_req_t  ( axi_in_req_t  ),
    .axi_in_rsp_t  ( axi_in_rsp_t  ),
    .axi_out_req_t ( axi_out_req_t ),
    .axi_out_rsp_t ( axi_out_rsp_t ),
    .floo_req_t    ( floo_req_t    ),
    .floo_rsp_t    ( floo_rsp_t    )
  ) u_remote_chimney (
    .clk_i           ( clk_i          ),
    .rst_ni          ( rst_ni         ),
    .test_enable_i   ( test_enable_i  ),
    .axi_in_req_i    ( remote_mgr_req ),
    .axi_in_rsp_o    ( remote_mgr_rsp ),
    .axi_out_req_o   ( remote_slv_req ),
    .axi_out_rsp_i   ( remote_slv_rsp ),
    .id_i            ( RemoteTileId   ),
    .flit_req_out_o  ( remote_floo_req_o ),
    .flit_rsp_out_o  ( remote_floo_rsp_o ),
    .flit_req_in_i   ( floo_req_i     ),
    .flit_rsp_in_i   ( floo_rsp_i     )
  );

  assign floo_req_valid_o      = remote_floo_req_o.valid;
  assign floo_req_o            = remote_floo_req_o.req;

  assign floo_rsp_valid_o      = remote_floo_rsp_o.valid;
  assign floo_rsp_o            = remote_floo_rsp_o.rsp;

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      remote_reg_q            <= '0;
      remote_aw_seen_q        <= 1'b0;
      remote_w_seen_q         <= 1'b0;
      remote_b_pending_q      <= 1'b0;
      remote_r_pending_q      <= 1'b0;
      remote_b_id_q           <= '0;
      remote_r_id_q           <= '0;
      remote_write_count_q    <= 0;
      remote_req_flit_count_q <= 0;
      remote_rsp_flit_count_q <= 0;
    end else begin
      if (floo_req_i.valid && floo_req_i.ready) begin
        remote_req_flit_count_q <= remote_req_flit_count_q + 1;
        $display("[FLOO_2X2] remote endpoint accepted req flit_count=%0d @ time %0t",
                 remote_req_flit_count_q + 1, $time);
      end

      if (floo_rsp_valid_o && floo_rsp_ready_i) begin
        remote_rsp_flit_count_q <= remote_rsp_flit_count_q + 1;
        $display("[FLOO_2X2] remote endpoint emitted rsp flit_count=%0d @ time %0t",
                 remote_rsp_flit_count_q + 1, $time);
      end

      if (remote_slv_req.aw_valid && remote_slv_rsp.aw_ready) begin
        remote_aw_seen_q <= 1'b1;
        remote_b_id_q    <= remote_slv_req.aw.id;
        $display("[FLOO_2X2] remote AXI AW addr=0x%08x id=0x%0x @ time %0t",
                 remote_slv_req.aw.addr, remote_slv_req.aw.id, $time);
      end

      if (remote_slv_req.w_valid && remote_slv_rsp.w_ready && remote_slv_req.w.last) begin
        remote_reg_q     <= remote_slv_req.w.data;
        remote_w_seen_q  <= 1'b1;
        $display("[FLOO_2X2] remote AXI W data=0x%08x write_count=%0d @ time %0t",
                 remote_slv_req.w.data, remote_write_count_q + 1, $time);
      end

      if (!remote_b_pending_q && remote_aw_seen_q && remote_w_seen_q) begin
        remote_aw_seen_q     <= 1'b0;
        remote_w_seen_q      <= 1'b0;
        remote_b_pending_q   <= 1'b1;
        remote_write_count_q <= remote_write_count_q + 1;
        $display("[FLOO_2X2] remote AXI write complete -> B pending count=%0d @ time %0t",
                 remote_write_count_q + 1, $time);
      end

      if (remote_slv_rsp.b_valid && remote_slv_req.b_ready) begin
        remote_b_pending_q <= 1'b0;
        $display("[FLOO_2X2] remote AXI B response accepted @ time %0t", $time);
      end

      if (remote_slv_req.ar_valid && remote_slv_rsp.ar_ready) begin
        remote_r_pending_q <= 1'b1;
        remote_r_id_q      <= remote_slv_req.ar.id;
        $display("[FLOO_2X2] remote AXI AR addr=0x%08x id=0x%0x @ time %0t",
                 remote_slv_req.ar.addr, remote_slv_req.ar.id, $time);
      end

      if (remote_slv_rsp.r_valid && remote_slv_req.r_ready) begin
        remote_r_pending_q <= 1'b0;
        $display("[FLOO_2X2] remote AXI R response accepted @ time %0t", $time);
      end
    end
  end

  assign remote_slv_rsp.aw_ready = !remote_b_pending_q && !remote_aw_seen_q;
  assign remote_slv_rsp.w_ready  = !remote_b_pending_q && !remote_w_seen_q;
  assign remote_slv_rsp.ar_ready = !remote_r_pending_q;

  assign remote_slv_rsp.b_valid  = remote_b_pending_q;
  assign remote_slv_rsp.b.id     = remote_b_id_q;
  assign remote_slv_rsp.b.resp   = 2'b00;
  assign remote_slv_rsp.b.user   = '0;

  assign remote_slv_rsp.r_valid  = remote_r_pending_q;
  assign remote_slv_rsp.r.id     = remote_r_id_q;
  assign remote_slv_rsp.r.data   = remote_reg_q;
  assign remote_slv_rsp.r.resp   = 2'b00;
  assign remote_slv_rsp.r.last   = 1'b1;
  assign remote_slv_rsp.r.user   = '0;

endmodule
