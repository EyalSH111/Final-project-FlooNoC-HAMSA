# HAMSA Minimal Integration Notes

This document captures the concrete delta from the current FlooNoC defaults to
the minimal HAMSA-oriented bring-up profile.

## Frozen Baseline (from provided HAMSA note)

- Data width: 32
- Address width: 32
- ID width: up to 10
- Ordering mode: in-order first-pass, no reorder buffers
- Topology target: 2x2 minimal mesh
- Handshake adaptation required at SoC edge: req/gnt/rvalid <-> AXI valid/ready

## Per-file Delta Map

- `floogen/examples/hamsa_axi_mesh_2x2.yml`
  - New FlooGen config for a 2x2 AXI mesh.
  - AXI protocol widths set to 32-bit data/address and 10-bit IDs.
  - Minimal endpoint set: 2x2 clusters + two memory endpoints.

- `hw/test/floo_hamsa_params_pkg.sv`
  - New HAMSA-oriented parameter package.
  - `AxiCfgHamsa`:
    - `AddrWidth = 32`
    - `DataWidth = 32`
    - `InIdWidth = 10`
    - `OutIdWidth = 10`
    - `UserWidth = 1`
  - `ChimneyCfgHamsa`:
    - `BRoBType = NoRoB`
    - `RRoBType = NoRoB`
    - `MaxUniqueIds = 1`

## Suggested Bring-up Flow

1. Generate NoC RTL from the HAMSA config:
   - `uv run floogen rtl -c floogen/examples/hamsa_axi_mesh_2x2.yml -o generated`
2. Compile with a mesh TB (or dedicated HAMSA TB after wrapper integration).
3. Run a directed transfer from one initiator to one memory target.

## Directed Verification Checklist

Monitor the following in simulation:

- Source ingress:
  - AXI AW/AR/W valid-ready handshakes accepted.
- NI conversion:
  - AXI request converted to flits on request link.
- Routing:
  - Flits traverse expected XY path across 2x2 routers.
- Destination egress:
  - Flits converted back into AXI toward memory/slave.
- Completion:
  - B/R responses return with expected ID and order.
  - Readback equals last write value for directed test address.

## Open Item (external to this repository)

The final req/gnt/rvalid bridge logic needs exact HAMSA top/interface signal
definitions from HAMSA RTL (`axi_bus.sv` or equivalent wrapper/top module).
