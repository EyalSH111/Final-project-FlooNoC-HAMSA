# ddp23_pnx_PoC — HAMSA Stage-1 FlooNoC

Single-tile FlooNoC integration in the HAMSA (PULPenix) SoC: **axi_node** kept for intra-tile traffic; **xtrn** routed through `floo_axi_chimney` + 5-port `floo_axi_router`.

Related project: [Final-project-FlooNoC-HAMSA](https://github.com/EyalSH111/Final-project-FlooNoC-HAMSA) (standalone FlooNoC mesh demos, Questa).

## Quick start (Cadence XRUN / irun)

```bash
export PULP_ENV=/path/to/ddp23_pnx_PoC
cd $PULP_ENV
make -f src/tb/sim.make APP=helloworld BAUD_RATE=2500000
grep FLOO_MON helloworld/xrun.log
```

See [INTEGRATION_STAGE1.md](INTEGRATION_STAGE1.md) for architecture, break test, and file list.

## FlooNoC RTL

Vendored under `src/ips/floo_noc/` (`floo_noc.f`). No `$FLOO_NOC_ROOT` required for this PoC.
