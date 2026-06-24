// Copyright 2025 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Tim Fischer <fischeti@iis.ee.ethz.ch>
// Lorenzo Leone <lleone@iis.ee.ethz.ch>

`include "common_cells/assertions.svh"

/// This module simply translates the address to an endpoint ID.
/// It uses either an address decoder for the system address map,
/// or a simple offset based translation.
module floo_id_translation #(
  // Cadence XRUN: SAM from floo_axi_mesh_noc_pkg (no array params in port list)
  /// The route config
  parameter floo_pkg::route_cfg_t RouteCfg = floo_pkg::RouteDefaultCfg,
  /// The type of the ID
  parameter type id_t = logic,
  /// The type of the IDX field in the address rule
  parameter type sam_idx_t = id_t,
  /// The address type
  parameter type addr_t = logic,
  /// The type of the address rules
  parameter type addr_rule_t = logic,
  /// The type of the offset + len to identify which bits in the address can be masked
  parameter type mask_sel_t = logic
) (
  input  logic  clk_i,   // Only used for assertions
  input  logic  rst_ni,  // Only used for assertions
  input  logic  valid_i, // Only used for assertions
  input  addr_t addr_i,
  output id_t   id_o,
  output mask_sel_t   mask_addr_x_o,
  output mask_sel_t   mask_addr_y_o
);

  // HAMSA stage-1 uses XY routing (UseIdTable=0). Table-based SAM needs floo_axi_mesh_noc_pkg.
  if (RouteCfg.UseIdTable) begin : gen_addr_decoder
    initial $fatal(1, "floo_id_translation: UseIdTable requires floo_axi_mesh_noc_pkg (not in stage-1 PoC)");
  end else if (RouteCfg.RouteAlgo == floo_pkg::XYRouting) begin : gen_xy_offset
    assign id_o.port_id = '0; // Not supported at the moment
    assign id_o.x = addr_i[RouteCfg.XYAddrOffsetX +: $bits(id_o.x)];
    assign id_o.y = addr_i[RouteCfg.XYAddrOffsetY +: $bits(id_o.y)];
  end else if (RouteCfg.RouteAlgo == floo_pkg::IdTable) begin : gen_id_offset
    assign id_o = addr_i[RouteCfg.IdAddrOffset +: $bits(id_o)];
  end else begin: gen_unsupported_routing
    $fatal(1, "Routing algorithm %0s only supports table-based address translation",
        RouteCfg.RouteAlgo);
  end

endmodule
