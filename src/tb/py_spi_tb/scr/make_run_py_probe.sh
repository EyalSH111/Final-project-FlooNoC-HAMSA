python $PULP_ENV/src/tb/py_spi_tb/py/py_tests/$2 &
make -f /project/generic/users/$USER/ws/ddp23_pulpenix/ddp23_pnx/src/tb/sim.make BAUD_RATE=2500000 APP=$1 XRUN_FLAGS="+define+ENABLE_SPI_PY_TB -input ../probe_dbg.tcl"
# XRUN_FLAGS="+define+ENABLE_SPI_PY_TB -"
