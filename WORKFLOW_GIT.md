# Git workflow (HAMSA PoC)

- **Push only from your PC** (Cursor / Git Bash): `c:\Users\eyals\hamsa\ddp23_pnx_PoC`
- **University server**: `git pull` only — never `git push`

## PC — push changes

```bash
cd /c/Users/eyals/hamsa/ddp23_pnx_PoC
git checkout ddp23_pnx_PoC
git pull origin ddp23_pnx_PoC
git add -A src/ips/floo_noc scripts src/tb INTEGRATION_STAGE1.md README_PoC.md WORKFLOW_GIT.md
git status
git commit -m "Fix XRUN DUPUNI: HAMSA common_cells, axi_sim, drop vendor RTL"
git push origin ddp23_pnx_PoC
```

## University — sync and sim (no push)

```bash
cd /data/project/tsmc65/users/eyalsho/ws/ddp23_pnx_PoC
git rebase --abort 2>/dev/null; git merge --abort 2>/dev/null; true
git fetch origin && git reset --hard origin/ddp23_pnx_PoC
rm -rf helloworld/xcelium.d helloworld/INCA_libs
make -f src/tb/sim.make APP=helloworld
```
