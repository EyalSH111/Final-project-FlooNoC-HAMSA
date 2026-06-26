// Minimal remote Floo endpoint for the HAMSA 2x2/full-integration demo.
// It receives Floo request flits, unpacks them through a second Chimney, and
// completes writes against a small memory-mapped set of remote AXI slaves.

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

  localparam int unsigned SmallRegWords  = 16;
  localparam int unsigned MediumRamWords = 256;
  localparam int unsigned LargeRamWords  = 1024;

  typedef enum logic [1:0] {
    RemoteTargetSmallReg  = 2'd0,
    RemoteTargetMediumRam = 2'd1,
    RemoteTargetLargeRam  = 2'd2,
    RemoteTargetInvalid   = 2'd3
  } remote_target_e;

  logic [31:0] small_reg_q  [0:SmallRegWords-1];
  logic [31:0] medium_ram_q [0:MediumRamWords-1];
  logic [31:0] large_ram_q  [0:LargeRamWords-1];
  remote_target_e remote_aw_target_q;
  remote_target_e remote_ar_target_q;
  logic [3:0]  remote_aw_small_idx_q;
  logic [3:0]  remote_ar_small_idx_q;
  logic [7:0]  remote_aw_medium_idx_q;
  logic [7:0]  remote_ar_medium_idx_q;
  logic [9:0]  remote_aw_large_idx_q;
  logic [9:0]  remote_ar_large_idx_q;
  logic [31:0] remote_w_data_q;
  logic [3:0]  remote_w_strb_q;
  logic        remote_aw_seen_q;
  logic        remote_w_seen_q;
  logic        remote_b_pending_q;
  logic        remote_r_pending_q;
  axi_out_id_t remote_b_id_q;
  axi_out_id_t remote_r_id_q;
  logic [1:0]  remote_b_resp_q;
  logic [1:0]  remote_r_resp_q;
  int unsigned remote_write_count_q;
  int unsigned remote_req_flit_count_q;
  int unsigned remote_rsp_flit_count_q;
  int unsigned remote_clear_idx;

  function automatic remote_target_e decode_target(input logic [31:0] addr);
    unique case (addr[13:12])
      2'b00: decode_target = RemoteTargetSmallReg;
      2'b01: decode_target = RemoteTargetMediumRam;
      2'b10: decode_target = RemoteTargetLargeRam;
      default: decode_target = RemoteTargetInvalid;
    endcase
  endfunction

  function automatic string target_name(input remote_target_e target);
    unique case (target)
      RemoteTargetSmallReg:  target_name = "small_reg";
      RemoteTargetMediumRam: target_name = "medium_ram";
      RemoteTargetLargeRam:  target_name = "large_ram";
      default:               target_name = "invalid";
    endcase
  endfunction

  function automatic logic [31:0] apply_wstrb(
    input logic [31:0] old_data,
    input logic [31:0] new_data,
    input logic [3:0]  strb
  );
    apply_wstrb = old_data;
    if (strb[0]) apply_wstrb[7:0]   = new_data[7:0];
    if (strb[1]) apply_wstrb[15:8]  = new_data[15:8];
    if (strb[2]) apply_wstrb[23:16] = new_data[23:16];
    if (strb[3]) apply_wstrb[31:24] = new_data[31:24];
  endfunction

  function automatic logic [31:0] read_target_data(
    input remote_target_e target,
    input logic [3:0] small_idx,
    input logic [7:0] medium_idx,
    input logic [9:0] large_idx
  );
    unique case (target)
      RemoteTargetSmallReg:  read_target_data = small_reg_q[small_idx];
      RemoteTargetMediumRam: read_target_data = medium_ram_q[medium_idx];
      RemoteTargetLargeRam:  read_target_data = large_ram_q[large_idx];
      default:               read_target_data = 32'hBAD0_BAD0;
    endcase
  endfunction

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
      for (remote_clear_idx = 0; remote_clear_idx < LargeRamWords; remote_clear_idx++) begin
        if (remote_clear_idx < SmallRegWords) begin
          small_reg_q[remote_clear_idx] <= '0;
        end
        if (remote_clear_idx < MediumRamWords) begin
          medium_ram_q[remote_clear_idx] <= '0;
        end
        large_ram_q[remote_clear_idx] <= '0;
      end
      remote_aw_target_q      <= RemoteTargetSmallReg;
      remote_ar_target_q      <= RemoteTargetSmallReg;
      remote_aw_small_idx_q   <= '0;
      remote_ar_small_idx_q   <= '0;
      remote_aw_medium_idx_q  <= '0;
      remote_ar_medium_idx_q  <= '0;
      remote_aw_large_idx_q   <= '0;
      remote_ar_large_idx_q   <= '0;
      remote_w_data_q         <= '0;
      remote_w_strb_q         <= '0;
      remote_aw_seen_q        <= 1'b0;
      remote_w_seen_q         <= 1'b0;
      remote_b_pending_q      <= 1'b0;
      remote_r_pending_q      <= 1'b0;
      remote_b_id_q           <= '0;
      remote_r_id_q           <= '0;
      remote_b_resp_q         <= 2'b00;
      remote_r_resp_q         <= 2'b00;
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
        remote_aw_seen_q       <= 1'b1;
        remote_aw_target_q     <= decode_target(remote_slv_req.aw.addr);
        remote_aw_small_idx_q  <= remote_slv_req.aw.addr[5:2];
        remote_aw_medium_idx_q <= remote_slv_req.aw.addr[9:2];
        remote_aw_large_idx_q  <= remote_slv_req.aw.addr[11:2];
        remote_b_id_q          <= remote_slv_req.aw.id;
        remote_b_resp_q        <= (decode_target(remote_slv_req.aw.addr) == RemoteTargetInvalid) ? 2'b10 : 2'b00;
        $display("[FLOO_2X2] remote AXI slave AW addr=0x%08x slave=%s small_word=%0d medium_word=%0d large_word=%0d id=0x%0x @ time %0t",
                 remote_slv_req.aw.addr, target_name(decode_target(remote_slv_req.aw.addr)),
                 remote_slv_req.aw.addr[5:2], remote_slv_req.aw.addr[9:2], remote_slv_req.aw.addr[11:2],
                 remote_slv_req.aw.id, $time);
      end

      if (remote_slv_req.w_valid && remote_slv_rsp.w_ready && remote_slv_req.w.last) begin
        remote_w_data_q  <= remote_slv_req.w.data;
        remote_w_strb_q  <= remote_slv_req.w.strb;
        remote_w_seen_q  <= 1'b1;
        $display("[FLOO_2X2] remote AXI RAM W data=0x%08x strb=0x%0x write_count=%0d @ time %0t",
                 remote_slv_req.w.data, remote_slv_req.w.strb, remote_write_count_q + 1, $time);
      end

      if (!remote_b_pending_q && remote_aw_seen_q && remote_w_seen_q) begin
        unique case (remote_aw_target_q)
          RemoteTargetSmallReg: begin
            small_reg_q[remote_aw_small_idx_q] <= apply_wstrb(
              small_reg_q[remote_aw_small_idx_q], remote_w_data_q, remote_w_strb_q
            );
          end
          RemoteTargetMediumRam: begin
            medium_ram_q[remote_aw_medium_idx_q] <= apply_wstrb(
              medium_ram_q[remote_aw_medium_idx_q], remote_w_data_q, remote_w_strb_q
            );
          end
          RemoteTargetLargeRam: begin
            large_ram_q[remote_aw_large_idx_q] <= apply_wstrb(
              large_ram_q[remote_aw_large_idx_q], remote_w_data_q, remote_w_strb_q
            );
          end
          default: ;
        endcase
        remote_aw_seen_q     <= 1'b0;
        remote_w_seen_q      <= 1'b0;
        remote_b_pending_q   <= 1'b1;
        remote_write_count_q <= remote_write_count_q + 1;
        $display("[FLOO_2X2] remote AXI slave write complete slave=%s small_word=%0d medium_word=%0d large_word=%0d data=0x%08x -> B pending count=%0d @ time %0t",
                 target_name(remote_aw_target_q), remote_aw_small_idx_q, remote_aw_medium_idx_q, remote_aw_large_idx_q,
                 apply_wstrb(
                   read_target_data(remote_aw_target_q, remote_aw_small_idx_q, remote_aw_medium_idx_q, remote_aw_large_idx_q),
                   remote_w_data_q, remote_w_strb_q
                 ),
                 remote_write_count_q + 1, $time);
      end

      if (remote_slv_rsp.b_valid && remote_slv_req.b_ready) begin
        remote_b_pending_q <= 1'b0;
        $display("[FLOO_2X2] remote AXI B response accepted @ time %0t", $time);
      end

      if (remote_slv_req.ar_valid && remote_slv_rsp.ar_ready) begin
        remote_r_pending_q      <= 1'b1;
        remote_r_id_q           <= remote_slv_req.ar.id;
        remote_ar_target_q      <= decode_target(remote_slv_req.ar.addr);
        remote_ar_small_idx_q   <= remote_slv_req.ar.addr[5:2];
        remote_ar_medium_idx_q  <= remote_slv_req.ar.addr[9:2];
        remote_ar_large_idx_q   <= remote_slv_req.ar.addr[11:2];
        remote_r_resp_q         <= (decode_target(remote_slv_req.ar.addr) == RemoteTargetInvalid) ? 2'b10 : 2'b00;
        $display("[FLOO_2X2] remote AXI slave AR addr=0x%08x slave=%s small_word=%0d medium_word=%0d large_word=%0d id=0x%0x @ time %0t",
                 remote_slv_req.ar.addr, target_name(decode_target(remote_slv_req.ar.addr)),
                 remote_slv_req.ar.addr[5:2], remote_slv_req.ar.addr[9:2], remote_slv_req.ar.addr[11:2],
                 remote_slv_req.ar.id, $time);
      end

      if (remote_slv_rsp.r_valid && remote_slv_req.r_ready) begin
        remote_r_pending_q <= 1'b0;
        $display("[FLOO_2X2] remote AXI slave R response accepted slave=%s small_word=%0d medium_word=%0d large_word=%0d data=0x%08x @ time %0t",
                 target_name(remote_ar_target_q), remote_ar_small_idx_q, remote_ar_medium_idx_q, remote_ar_large_idx_q,
                 read_target_data(remote_ar_target_q, remote_ar_small_idx_q, remote_ar_medium_idx_q, remote_ar_large_idx_q),
                 $time);
      end
    end
  end

  assign remote_slv_rsp.aw_ready = !remote_b_pending_q && !remote_aw_seen_q;
  assign remote_slv_rsp.w_ready  = !remote_b_pending_q && !remote_w_seen_q;
  assign remote_slv_rsp.ar_ready = !remote_r_pending_q;

  assign remote_slv_rsp.b_valid  = remote_b_pending_q;
  assign remote_slv_rsp.b.id     = remote_b_id_q;
  assign remote_slv_rsp.b.resp   = remote_b_resp_q;
  assign remote_slv_rsp.b.user   = '0;

  assign remote_slv_rsp.r_valid  = remote_r_pending_q;
  assign remote_slv_rsp.r.id     = remote_r_id_q;
  assign remote_slv_rsp.r.data   = read_target_data(
    remote_ar_target_q, remote_ar_small_idx_q, remote_ar_medium_idx_q, remote_ar_large_idx_q
  );
  assign remote_slv_rsp.r.resp   = remote_r_resp_q;
  assign remote_slv_rsp.r.last   = 1'b1;
  assign remote_slv_rsp.r.user   = '0;

endmodule
