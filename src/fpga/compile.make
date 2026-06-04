DI ?= 1
APP ?= helloworld
PULP_APPS = ${PULP_ENV}/apps
PULP_LIBS = ${PULP_APPS}/libs
APP_SRC_DIR = ${PULP_APPS}/${APP}
PULP_SW_UTILS = ${PULP_APPS}/sw_utils

CLK_PERIOD = 100
BAUD_RATE = 115200
ITERATIONS ?= 400

ifeq ($(DI), 1)
    INSTR_WIDTH = 4
else
    INSTR_WIDTH = 1
endif


.PHONY:all
all: compile

.PHONY:clean
clean:
	$(MAKE) --directory=${APP_SRC_DIR} clean
	\rm -f slm_files/*.mif
	\rm -f slm_files/*.slm

.PHONY:cleanall
cleanall:
	$(MAKE) --directory=${APP_SRC_DIR} cleanall
	\rm -f slm_files/*.mif
	\rm -f slm_files/*.slm

.PHONY: compile
compile: slm_files/app_instr.mif
	echo COMPILED

slm_files/l2_stim.slm:
	mkdir -p slm_files
	$(MAKE) --directory=${APP_SRC_DIR} BAUD_RATE=${BAUD_RATE} CLK_PERIOD=${CLK_PERIOD} ITERATIONS=${ITERATIONS}
	cp ${APP_SRC_DIR}/*.slm slm_files

slm_files/app_instr.mif: slm_files/l2_stim.slm
	cd slm_files && ${PULP_SW_UTILS}/slm2mif.py l2_stim.slm tcdm_bank0.slm ${INSTR_WIDTH}

