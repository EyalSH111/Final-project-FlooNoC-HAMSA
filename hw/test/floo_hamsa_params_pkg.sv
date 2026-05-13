// Copyright 2026
// Minimal HAMSA-oriented FlooNoC profile for bring-up.

package floo_hamsa_params_pkg;
  // Minimal profile taken from the provided HAMSA integration note:
  // 32-bit data/address and up-to-10-bit IDs.
  localparam floo_pkg::axi_cfg_t AxiCfgHamsa = '{
    AddrWidth: 32,
    DataWidth: 32,
    UserWidth: 1,
    InIdWidth: 10,
    OutIdWidth: 10
  };

  // Keep ordering simple for first integration step.
  localparam floo_pkg::chimney_cfg_t ChimneyCfgHamsa = '{
    EnSbrPort: 1'b1,
    EnMgrPort: 1'b1,
    MaxTxns: 32,
    MaxUniqueIds: 1,
    MaxTxnsPerId: 32,
    BRoBType: floo_pkg::NoRoB,
    BRoBSize: 0,
    RRoBType: floo_pkg::NoRoB,
    RRoBSize: 0,
    CutAx: 1'b0,
    CutRsp: 1'b0
  };
endpackage
