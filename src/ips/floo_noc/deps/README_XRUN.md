# FlooNoC vendored deps — Cadence XRUN notes

## No vendored `common_cells` RTL in git

HAMSA builds `common_cells` from `$PULP_ENV/src/ips/common_cells` only.

This directory keeps **headers** (`include/`) and Bender metadata. Any `.sv` under `deps/common_cells/` (except `include/`) causes `*E,DUPUNI` with `riscv-dbg.f`.

`make compile` runs `scripts/fix_floo_xrun_dupuni.sh` to delete stray `src/` trees left on old clones.

## AXI for simulation

Simulation lists only the four files in `../xrun_compat/axi_sim/` (not `deps/axi/src/`, which contains many other `.sv` files XRUN may compile in the same directory).

Headers: `+incdir+$PULP_ENV/src/ips/floo_noc/deps/axi/include`

After changing deps layout:

```bash
rm -rf helloworld/xcelium.d helloworld/INCA_libs
make -f src/tb/sim.make APP=helloworld
```
