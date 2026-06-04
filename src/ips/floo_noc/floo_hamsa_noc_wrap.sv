// HAMSA SoC interconnect: 2x2 FlooNoC mesh + local axi_node mux/demux per tile.
`include "axi_bus.sv"

`ifdef USE_FLOO_NOC

module floo_hamsa_noc_wrap #(
  parameter int unsigned NB_MASTER      = 5,
  parameter int unsigned NB_SLAVE       = 6,
  parameter int unsigned AXI_ADDR_WIDTH = 32,
  parameter int unsigned AXI_DATA_WIDTH = 32,
  parameter int unsigned AXI_INITIATOR_ID_WIDTH = 2,
  parameter int unsigned AXI_TARGET_ID_WIDTH    = 5,
  parameter int unsigned AXI_USER_WIDTH = 1
) (
  input  logic clk,
  input  logic rst_n,
  input  logic test_en_i,
  // Port parameters come from msystem connection (initiator=2b, target=5b IDs).
  AXI_BUS.Slave   slave[NB_SLAVE-1:0],
  AXI_BUS.Master  master[NB_MASTER-1:0],
  input  logic [NB_MASTER-1:0][AXI_ADDR_WIDTH-1:0] start_addr_i,
  input  logic [NB_MASTER-1:0][AXI_ADDR_WIDTH-1:0] end_addr_i
);

  import floo_pkg::*;
  import floo_axi_mesh_noc_pkg::*;

  axi_in_req_t  [1:0][1:0] cluster_in_req;
  axi_in_rsp_t  [1:0][1:0] cluster_in_rsp;
  axi_out_req_t [1:0][1:0] cluster_out_req;
  axi_out_rsp_t [1:0][1:0] cluster_out_rsp;

  axi_out_req_t [1:0] hbm_out_req;
  axi_out_rsp_t [1:0] hbm_out_rsp;

  // Tile (0,0): core + debug masters -> Floo mgr port
  AXI_BUS #(
    .AXI_ADDR_WIDTH (AXI_ADDR_WIDTH),
    .AXI_DATA_WIDTH (AXI_DATA_WIDTH),
    .AXI_ID_WIDTH   (AXI_INITIATOR_ID_WIDTH),
    .AXI_USER_WIDTH (AXI_USER_WIDTH)
  ) tile00_mux_m[0:0] ();
  AXI_BUS #(
    .AXI_ADDR_WIDTH (AXI_ADDR_WIDTH),
    .AXI_DATA_WIDTH (AXI_DATA_WIDTH),
    .AXI_ID_WIDTH   (AXI_INITIATOR_ID_WIDTH),
    .AXI_USER_WIDTH (AXI_USER_WIDTH)
  ) tile00_floo_s ();
  AXI_BUS #(
    .AXI_ADDR_WIDTH (AXI_ADDR_WIDTH),
    .AXI_DATA_WIDTH (AXI_DATA_WIDTH),
    .AXI_ID_WIDTH   (AXI_INITIATOR_ID_WIDTH),
    .AXI_USER_WIDTH (AXI_USER_WIDTH)
  ) tile00_slv[1:0] ();

  axi_node_intf_wrap #(
    .NB_MASTER      (1),
    .NB_SLAVE       (2),
    .AXI_ADDR_WIDTH (AXI_ADDR_WIDTH),
    .AXI_DATA_WIDTH (AXI_DATA_WIDTH),
    .AXI_ID_WIDTH   (AXI_INITIATOR_ID_WIDTH),
    .AXI_USER_WIDTH (AXI_USER_WIDTH)
  ) tile00_mux_i (
    .clk          (clk),
    .rst_n        (rst_n),
    .test_en_i    (test_en_i),
    .slave        (tile00_slv),
    .master       (tile00_mux_m),
    .start_addr_i ('0),
    .end_addr_i   ('0)
  );

  hamsa_floo_axi_bridge #(
    .HAMSA_ID_WIDTH   (AXI_INITIATOR_ID_WIDTH),
    .HAMSA_USER_WIDTH (AXI_USER_WIDTH),
    .floo_req_t       (axi_in_req_t),
    .floo_rsp_t       (axi_in_rsp_t)
  ) tile00_mgr_bridge (
    .hamsa      (tile00_mux_m[0]),
    .floo_req_o (cluster_in_req[0][0]),
    .floo_rsp_i (cluster_in_rsp[0][0])
  );
  `AXI_ASSIGN_SLAVE(tile00_slv[0], slave[0]);
  `AXI_ASSIGN_SLAVE(tile00_slv[1], slave[1]);

  assign cluster_out_req[0][0] = '0;
  assign cluster_out_rsp[0][0] = '0;

  // Tile (0,1): Floo -> instr/data slaves
  AXI_BUS #(
    .AXI_ADDR_WIDTH (AXI_ADDR_WIDTH),
    .AXI_DATA_WIDTH (AXI_DATA_WIDTH),
    .AXI_ID_WIDTH   (AXI_TARGET_ID_WIDTH),
    .AXI_USER_WIDTH (AXI_USER_WIDTH)
  ) tile01_floo_s[0:0] ();
  AXI_BUS #(
    .AXI_ADDR_WIDTH (AXI_ADDR_WIDTH),
    .AXI_DATA_WIDTH (AXI_DATA_WIDTH),
    .AXI_ID_WIDTH   (AXI_TARGET_ID_WIDTH),
    .AXI_USER_WIDTH (AXI_USER_WIDTH)
  ) tile01_floo_bridge_m ();
  AXI_BUS #(
    .AXI_ADDR_WIDTH (AXI_ADDR_WIDTH),
    .AXI_DATA_WIDTH (AXI_DATA_WIDTH),
    .AXI_ID_WIDTH   (AXI_TARGET_ID_WIDTH),
    .AXI_USER_WIDTH (AXI_USER_WIDTH)
  ) tile01_ram_m[1:0] ();

  hamsa_floo_axi_bridge_noc_init #(
    .HAMSA_ID_WIDTH   (AXI_TARGET_ID_WIDTH),
    .HAMSA_USER_WIDTH (AXI_USER_WIDTH)
  ) tile01_noc_init_bridge (
    .hamsa      (tile01_floo_bridge_m),
    .floo_req_i (cluster_out_req[0][1]),
    .floo_rsp_o (cluster_out_rsp[0][1])
  );
  `AXI_ASSIGN_SLAVE(tile01_floo_s[0], tile01_floo_bridge_m);

  axi_node_intf_wrap #(
    .NB_MASTER      (2),
    .NB_SLAVE       (1),
    .AXI_ADDR_WIDTH (AXI_ADDR_WIDTH),
    .AXI_DATA_WIDTH (AXI_DATA_WIDTH),
    .AXI_ID_WIDTH   (AXI_TARGET_ID_WIDTH),
    .AXI_USER_WIDTH (AXI_USER_WIDTH)
  ) tile01_demux_i (
    .clk          (clk),
    .rst_n        (rst_n),
    .test_en_i    (test_en_i),
    .slave        (tile01_floo_s),
    .master       (tile01_ram_m),
    .start_addr_i ({32'h0010_0000, 32'h0000_0000}),
    .end_addr_i   ({32'h001F_FFFF, 32'h000F_FFFF})
  );

  `AXI_ASSIGN_SLAVE (master[0], tile01_ram_m[0]);
  `AXI_ASSIGN_SLAVE (master[1], tile01_ram_m[1]);

  assign cluster_in_req[0][1] = '0;
  assign cluster_in_rsp[0][1] = '0;

  // Tile (1,0): DMA + UART masters, peripherals slave
  AXI_BUS #(
    .AXI_ADDR_WIDTH (AXI_ADDR_WIDTH),
    .AXI_DATA_WIDTH (AXI_DATA_WIDTH),
    .AXI_ID_WIDTH   (AXI_INITIATOR_ID_WIDTH),
    .AXI_USER_WIDTH (AXI_USER_WIDTH)
  ) tile10_mux_m[0:0] ();
  AXI_BUS #(
    .AXI_ADDR_WIDTH (AXI_ADDR_WIDTH),
    .AXI_DATA_WIDTH (AXI_DATA_WIDTH),
    .AXI_ID_WIDTH   (AXI_INITIATOR_ID_WIDTH),
    .AXI_USER_WIDTH (AXI_USER_WIDTH)
  ) tile10_slv[1:0] ();
  axi_node_intf_wrap #(
    .NB_MASTER      (1),
    .NB_SLAVE       (2),
    .AXI_ADDR_WIDTH (AXI_ADDR_WIDTH),
    .AXI_DATA_WIDTH (AXI_DATA_WIDTH),
    .AXI_ID_WIDTH   (AXI_INITIATOR_ID_WIDTH),
    .AXI_USER_WIDTH (AXI_USER_WIDTH)
  ) tile10_mux_i (
    .clk          (clk),
    .rst_n        (rst_n),
    .test_en_i    (test_en_i),
    .slave        (tile10_slv),
    .master       (tile10_mux_m),
    .start_addr_i ('0),
    .end_addr_i   ('0)
  );

  hamsa_floo_axi_bridge #(
    .HAMSA_ID_WIDTH   (AXI_INITIATOR_ID_WIDTH),
    .HAMSA_USER_WIDTH (AXI_USER_WIDTH),
    .floo_req_t       (axi_in_req_t),
    .floo_rsp_t       (axi_in_rsp_t)
  ) tile10_mgr_bridge (
    .hamsa      (tile10_mux_m[0]),
    .floo_req_o (cluster_in_req[1][0]),
    .floo_rsp_i (cluster_in_rsp[1][0])
  );
  `AXI_ASSIGN_SLAVE(tile10_slv[0], slave[3]);
  `AXI_ASSIGN_SLAVE(tile10_slv[1], slave[5]);

  // Local 5-bit-ID bus: Cadence needs explicit width for mem_tgt bridge (not master[2] direct).
  AXI_BUS #(
    .AXI_ADDR_WIDTH (AXI_ADDR_WIDTH),
    .AXI_DATA_WIDTH (AXI_DATA_WIDTH),
    .AXI_ID_WIDTH   (AXI_TARGET_ID_WIDTH),
    .AXI_USER_WIDTH (AXI_USER_WIDTH)
  ) tile10_periph_axi ();

  `AXI_ASSIGN_SLAVE (master[2], tile10_periph_axi);

  hamsa_floo_axi_bridge_noc_init #(
    .HAMSA_ID_WIDTH   (AXI_TARGET_ID_WIDTH),
    .HAMSA_USER_WIDTH (AXI_USER_WIDTH)
  ) tile10_periph_bridge (
    .hamsa      (tile10_periph_axi),
    .floo_req_i (cluster_out_req[1][0]),
    .floo_rsp_o (cluster_out_rsp[1][0])
  );

  // Tile (1,1): SPI + external slave masters; MMSPI + xtrn slaves
  AXI_BUS #(
    .AXI_ADDR_WIDTH (AXI_ADDR_WIDTH),
    .AXI_DATA_WIDTH (AXI_DATA_WIDTH),
    .AXI_ID_WIDTH   (AXI_INITIATOR_ID_WIDTH),
    .AXI_USER_WIDTH (AXI_USER_WIDTH)
  ) tile11_mux_m[0:0] ();
  AXI_BUS #(
    .AXI_ADDR_WIDTH (AXI_ADDR_WIDTH),
    .AXI_DATA_WIDTH (AXI_DATA_WIDTH),
    .AXI_ID_WIDTH   (AXI_TARGET_ID_WIDTH),
    .AXI_USER_WIDTH (AXI_USER_WIDTH)
  ) tile11_floo_s[0:0] ();
  AXI_BUS #(
    .AXI_ADDR_WIDTH (AXI_ADDR_WIDTH),
    .AXI_DATA_WIDTH (AXI_DATA_WIDTH),
    .AXI_ID_WIDTH   (AXI_TARGET_ID_WIDTH),
    .AXI_USER_WIDTH (AXI_USER_WIDTH)
  ) tile11_floo_bridge_m ();
  AXI_BUS #(
    .AXI_ADDR_WIDTH (AXI_ADDR_WIDTH),
    .AXI_DATA_WIDTH (AXI_DATA_WIDTH),
    .AXI_ID_WIDTH   (AXI_TARGET_ID_WIDTH),
    .AXI_USER_WIDTH (AXI_USER_WIDTH)
  ) tile11_io_m[1:0] ();
  AXI_BUS #(
    .AXI_ADDR_WIDTH (AXI_ADDR_WIDTH),
    .AXI_DATA_WIDTH (AXI_DATA_WIDTH),
    .AXI_ID_WIDTH   (AXI_INITIATOR_ID_WIDTH),
    .AXI_USER_WIDTH (AXI_USER_WIDTH)
  ) tile11_slv[1:0] ();

  axi_node_intf_wrap #(
    .NB_MASTER      (1),
    .NB_SLAVE       (2),
    .AXI_ADDR_WIDTH (AXI_ADDR_WIDTH),
    .AXI_DATA_WIDTH (AXI_DATA_WIDTH),
    .AXI_ID_WIDTH   (AXI_INITIATOR_ID_WIDTH),
    .AXI_USER_WIDTH (AXI_USER_WIDTH)
  ) tile11_mux_i (
    .clk          (clk),
    .rst_n        (rst_n),
    .test_en_i    (test_en_i),
    .slave        (tile11_slv),
    .master       (tile11_mux_m),
    .start_addr_i ('0),
    .end_addr_i   ('0)
  );

  hamsa_floo_axi_bridge #(
    .HAMSA_ID_WIDTH   (AXI_INITIATOR_ID_WIDTH),
    .HAMSA_USER_WIDTH (AXI_USER_WIDTH),
    .floo_req_t       (axi_in_req_t),
    .floo_rsp_t       (axi_in_rsp_t)
  ) tile11_mgr_bridge (
    .hamsa      (tile11_mux_m[0]),
    .floo_req_o (cluster_in_req[1][1]),
    .floo_rsp_i (cluster_in_rsp[1][1])
  );
  `AXI_ASSIGN_SLAVE(tile11_slv[0], slave[2]);
  `AXI_ASSIGN_SLAVE(tile11_slv[1], slave[4]);

  hamsa_floo_axi_bridge_noc_init #(
    .HAMSA_ID_WIDTH   (AXI_TARGET_ID_WIDTH),
    .HAMSA_USER_WIDTH (AXI_USER_WIDTH)
  ) tile11_noc_init_bridge (
    .hamsa      (tile11_floo_bridge_m),
    .floo_req_i (cluster_out_req[1][1]),
    .floo_rsp_o (cluster_out_rsp[1][1])
  );
  `AXI_ASSIGN_SLAVE(tile11_floo_s[0], tile11_floo_bridge_m);

  axi_node_intf_wrap #(
    .NB_MASTER      (2),
    .NB_SLAVE       (1),
    .AXI_ADDR_WIDTH (AXI_ADDR_WIDTH),
    .AXI_DATA_WIDTH (AXI_DATA_WIDTH),
    .AXI_ID_WIDTH   (AXI_TARGET_ID_WIDTH),
    .AXI_USER_WIDTH (AXI_USER_WIDTH)
  ) tile11_demux_i (
    .clk          (clk),
    .rst_n        (rst_n),
    .test_en_i    (test_en_i),
    .slave        (tile11_floo_s),
    .master       (tile11_io_m),
    .start_addr_i ({32'h1AC0_0000, 32'h1A80_0000}),
    .end_addr_i   ({32'hFFFF_FFFF, 32'h1ABF_FFFF})
  );

  `AXI_ASSIGN_SLAVE (master[3], tile11_io_m[0]);
  `AXI_ASSIGN_SLAVE (master[4], tile11_io_m[1]);

  // Unused demo HBM ports
  assign hbm_out_rsp = '0;

  floo_axi_mesh_noc i_floo_axi_mesh_noc (
    .clk_i                 (clk),
    .rst_ni                (rst_n),
    .test_enable_i         (test_en_i),
    .cluster_axi_in_req_i  (cluster_in_req),
    .cluster_axi_in_rsp_o  (cluster_in_rsp),
    .cluster_axi_out_req_o (cluster_out_req),
    .cluster_axi_out_rsp_i (cluster_out_rsp),
    .hbm_axi_out_req_o     (hbm_out_req),
    .hbm_axi_out_rsp_i     (hbm_out_rsp)
  );

endmodule

`else

module floo_hamsa_noc_wrap #(
  parameter int unsigned NB_MASTER      = 5,
  parameter int unsigned NB_SLAVE       = 6,
  parameter int unsigned AXI_ADDR_WIDTH = 32,
  parameter int unsigned AXI_DATA_WIDTH = 32,
  parameter int unsigned AXI_ID_WIDTH   = 2,
  parameter int unsigned AXI_USER_WIDTH = 1
) (
  input  logic clk,
  input  logic rst_n,
  input  logic test_en_i,
  AXI_BUS.Slave   slave[NB_SLAVE-1:0],
  AXI_BUS.Master  master[NB_MASTER-1:0],
  input  logic [NB_MASTER-1:0][AXI_ADDR_WIDTH-1:0] start_addr_i,
  input  logic [NB_MASTER-1:0][AXI_ADDR_WIDTH-1:0] end_addr_i
);

  axi_node_intf_wrap #(
    .NB_MASTER      (NB_MASTER),
    .NB_SLAVE       (NB_SLAVE),
    .AXI_ADDR_WIDTH (AXI_ADDR_WIDTH),
    .AXI_DATA_WIDTH (AXI_DATA_WIDTH),
    .AXI_ID_WIDTH   (AXI_ID_WIDTH),
    .AXI_USER_WIDTH (AXI_USER_WIDTH)
  ) axi_interconnect_i (
    .clk          (clk),
    .rst_n        (rst_n),
    .test_en_i    (test_en_i),
    .master       (master),
    .slave        (slave),
    .start_addr_i (start_addr_i),
    .end_addr_i   (end_addr_i)
  );

endmodule

`endif
