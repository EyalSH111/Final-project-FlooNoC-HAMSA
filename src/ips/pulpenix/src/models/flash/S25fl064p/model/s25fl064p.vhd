-------------------------------------------------------------------------------
--  File Name: s25fl064p.vhd
-------------------------------------------------------------------------------
--  Copyright (C) 2012 Spansion, LLC.
--
--  MODIFICATION HISTORY:
--
--  version: |  author:        | mod date: |  changes made:
--    V1.0     D.Stanojkovic    08 Jan 22    Inital Release
--    V1.1     D.Stanojkovic    08 Feb 20    BP bits setting corrected
--    V1.2     D.Stanojkovic    08 Mar 04    MPM mode corrected
--    V1.3     D.Stanojkovic    08 Mar 20    MPM mode removed
--    V1.4     J.Stoickov       08 Dec 10    Latest datasheet aligned
--                                           (S25FL129 064 032P)
--                                           Program Error bit will not be
--                                           set after programming
--                                           in protect memory region
--    V1.5     V.Mancev         10 Sep 29    Implementation of internal pull-up
--                                           for HOLDNeg and WPNeg pins
--    V1.6     V.Mancev         12 Jan 13    Latest datasheet aligned
--                                           (S25FL064P_00_05)
-------------------------------------------------------------------------------
--  PART DESCRIPTION:
--
--  Library:    FLASH
--  Technology: FLASH MEMORY
--  Part:       S25FL064P
--
--   Description: 64 Megabit Serial Flash Memory with 104 MHz SPI Bus Interface
--
-------------------------------------------------------------------------------
--  Known Bugs:
--
-------------------------------------------------------------------------------
LIBRARY IEEE;   USE IEEE.std_logic_1164.ALL;
                USE STD.textio.ALL;
                USE IEEE.VITAL_timing.ALL;
                USE IEEE.VITAL_primitives.ALL;

LIBRARY FMF;    USE FMF.gen_utils.ALL;
                USE FMF.conversions.ALL;
-------------------------------------------------------------------------------
-- ENTITY DECLARATION
-------------------------------------------------------------------------------
ENTITY s25fl064p IS
    GENERIC (
        -- tipd delays: interconnect path delays
        tipd_SCK            : VitalDelayType01 := VitalZeroDelay01;
        tipd_SI             : VitalDelayType01 := VitalZeroDelay01;
        tipd_SO             : VitalDelayType01 := VitalZeroDelay01;

        tipd_CSNeg          : VitalDelayType01 := VitalZeroDelay01;
        tipd_HOLDNeg        : VitalDelayType01 := VitalZeroDelay01;
        tipd_WPNeg          : VitalDelayType01 := VitalZeroDelay01;

        -- tpd delays
        tpd_SCK_SO          : VitalDelayType01Z := UnitDelay01Z; -- tV
        tpd_SCK_SI          : VitalDelayType01Z := UnitDelay01Z; -- tV
        tpd_CSNeg_SO        : VitalDelayType01Z := UnitDelay01Z; -- tDIS
        tpd_HOLDNeg_SO      : VitalDelayType01Z := UnitDelay01Z; -- tLZ,tHZ

        --tsetup values
        tsetup_CSNeg_SCK    : VitalDelayType := UnitDelay;  -- tCSS /
        tsetup_HOLDNeg_SCK  : VitalDelayType := UnitDelay;  -- tHC /
        tsetup_SI_SCK       : VitalDelayType := UnitDelay;  -- tsuDAT /
        tsetup_WPNeg_CSNeg  : VitalDelayType := UnitDelay;  -- tWPS \

        --thold values
        thold_CSNeg_SCK     : VitalDelayType := UnitDelay;  -- tCSH /
        thold_HOLDNeg_SCK   : VitalDelayType := UnitDelay;  -- tCHHH /
        thold_SI_SCK        : VitalDelayType := UnitDelay;  -- thdDAT /
        thold_WPNeg_CSNeg   : VitalDelayType := UnitDelay;  -- tWPH \

        --tpw values: pulse width
        tpw_SCK_serial_fast_posedge     : VitalDelayType := UnitDelay; -- tWH
        tpw_SCK_serial_posedge          : VitalDelayType := UnitDelay; -- tWH
        tpw_SCK_dual_posedge            : VitalDelayType := UnitDelay; -- tWH
        tpw_SCK_rd_jid_posedge          : VitalDelayType := UnitDelay; -- tWH
        tpw_SCK_serial_fast_negedge     : VitalDelayType := UnitDelay; -- tWL
        tpw_SCK_serial_negedge          : VitalDelayType := UnitDelay; -- tWL
        tpw_SCK_dual_negedge            : VitalDelayType := UnitDelay; -- tWL
        tpw_SCK_rd_jid_negedge          : VitalDelayType := UnitDelay; -- tWL
        tpw_CSNeg_read_posedge          : VitalDelayType := UnitDelay; -- tCS
        tpw_CSNeg_pgm_posedge           : VitalDelayType := UnitDelay; -- tCS

        -- tperiod min (calculated as 1/max freq)
        tperiod_SCK_serial_rd       : VitalDelayType := UnitDelay;--fSCK=40MHz
        tperiod_SCK_serial_fast_rd  : VitalDelayType := UnitDelay;--fSCK=104MHz
        tperiod_SCK_dual_fast_rd    : VitalDelayType := UnitDelay;--fSCK=80MHz
        tperiod_SCK_serial_rd_jid   : VitalDelayType := UnitDelay;--fSCK=50MHz

        -- tdevice values: values for internal delays
            -- Page Program Operation
        tdevice_PP          : VitalDelayType    := 3 ms;
            -- Page Program Operation (ACC=9V))
        tdevice_EP          : VitalDelayType    := 2.4 ms;    --tPP
            -- Sector Erase Operation
        tdevice_SE          : VitalDelayType    := 2 sec;   --tSE
            -- Bulk Erase Operation
        tdevice_BE          : VitalDelayType    := 128 sec; --tBE
            -- Write Status Register Operation
        tdevice_WR          : VitalDelayType    := 100 ms;  --tW
            -- Deep Power Down
        tdevice_DP          : VitalDelayType    := 10 us;   --tDP
            -- Release from Software Protect Mode
        tdevice_RES         : VitalDelayType    := 30 us;   --tRES
            -- Parameter block erase
        tdevice_PE          : VitalDelayType    := 800 ms;  --tPE
            -- VCC (min) to CS# Low
        tdevice_PU          : VitalDelayType    := 300 us;   --tPU
        -- generic control parameters
        InstancePath        : STRING    := DefaultInstancePath;
        TimingChecksOn      : BOOLEAN   := DefaultTimingChecks;
        MsgOn               : BOOLEAN   := DefaultMsgOn;
        XOn                 : BOOLEAN   := DefaultXon;
        -- memory file to be loaded
        mem_file_name       : STRING    := "s25fl064p.mem";
        otp_file_name       : STRING    := "s25fl064pOTP.mem";

        UserPreload         : BOOLEAN   := FALSE; --TRUE;
        LongTimming         : BOOLEAN   := TRUE;

        -- For FMF SDF technology file usage
        TimingModel         : STRING    := DefaultTimingModel
    );
    PORT (
        SCK             : IN    std_ulogic := 'U'; -- serial clock input
        SI              : INOUT std_ulogic := 'U'; -- serial data input
        CSNeg           : IN    std_ulogic := 'U'; -- chip select input
        HOLDNeg         : INOUT std_ulogic := 'U'; -- hold input
        WPNeg           : INOUT std_ulogic := 'U'; -- write protect input
        SO              : INOUT std_ulogic := 'U'  -- SO
    );
    ATTRIBUTE VITAL_LEVEL0 of s25fl064p : ENTITY IS TRUE;
END s25fl064p;

-------------------------------------------------------------------------------
-- ARCHITECTURE DECLARATION
-------------------------------------------------------------------------------
ARCHITECTURE vhdl_behavioral of s25fl064p IS
    ATTRIBUTE VITAL_LEVEL0 OF vhdl_behavioral : ARCHITECTURE IS TRUE;

    CONSTANT PartID        : STRING  := "s25fl064p";
    CONSTANT MaxData       : NATURAL := 16#FF#;   --255;
    CONSTANT SecSize       : NATURAL := 16#FFFF#; --65535
    CONSTANT SecSize_4     : NATURAL := 16#FFF#;  --4095
    CONSTANT SecSize_8     : NATURAL := 16#1FFF#; --8191
    CONSTANT OTPSize       : NATURAL := 511;
    CONSTANT OTPLoAddr     : NATURAL := 16#100#;
    CONSTANT OTPHiAddr     : NATURAL := 16#2FF#;
    CONSTANT SecNum        : NATURAL := 127;
    CONSTANT PageNum       : NATURAL := 16#7FFF#;
    CONSTANT HiAddrBit     : NATURAL := 23;
    CONSTANT AddrRANGE     : NATURAL := 16#7FFFFF#;
    CONSTANT BYTE          : NATURAL := 8;
    --Manufacturer Identification
    CONSTANT Manuf_ID      : NATURAL := 16#01#;
    --Electronic Signature
    CONSTANT ES            : NATURAL := 16#16#;
    --Device ID
    --Manufacturer Identification && Memory Type && Memory Capacity
    CONSTANT Jedec_ID      : NATURAL := 16#20#; -- first byte of Device ID
    CONSTANT DeviceID      : NATURAL := 16#0216#;
    CONSTANT ExtendedBytes : NATURAL := 16#4D#;
    CONSTANT ReservedBytes : NATURAL := 16#00#;

-- interconnect path delay signals
    SIGNAL SCK_ipd         : std_ulogic := 'U';
    SIGNAL SI_ipd          : std_ulogic := 'U';
    SIGNAL SO_ipd          : std_ulogic := 'U';
    SIGNAL CSNeg_ipd       : std_ulogic := 'U';
    SIGNAL HOLDNeg_ipd     : std_ulogic := 'U';
    SIGNAL WPNeg_ipd       : std_ulogic := 'U';
    SIGNAL HOLDNeg_pullup  : std_ulogic := 'U';
    SIGNAL WPNeg_pullup    : std_ulogic := 'U';

    ---  internal delays
    SIGNAL PP_in           : std_ulogic := '0';
    SIGNAL PP_out          : std_ulogic := '0';
    SIGNAL PU_in           : std_ulogic := '0';
    SIGNAL PU_out          : std_ulogic := '0';
    SIGNAL SE_in           : std_ulogic := '0';
    SIGNAL SE_out          : std_ulogic := '0';
    SIGNAL BE_in           : std_ulogic := '0';
    SIGNAL BE_out          : std_ulogic := '0';
    SIGNAL EP_in           : std_ulogic := '0';
    SIGNAL EP_out          : std_ulogic := '0';
    SIGNAL WR_in           : std_ulogic := '0';
    SIGNAL WR_out          : std_ulogic := '0';
    SIGNAL DP_in           : std_ulogic := '0';
    SIGNAL DP_out          : std_ulogic := '0';
    SIGNAL PE_in           : std_ulogic := '0';
    SIGNAL PE_out          : std_ulogic := '0';
    SIGNAL RES_in          : std_ulogic := '0';
    SIGNAL RES_out         : std_ulogic := '0';

BEGIN
    ---------------------------------------------------------------------------
    -- Internal Delays
    ---------------------------------------------------------------------------
    -- Artificial VITAL primitives to incorporate internal delays
    PP     :VitalBuf(PP_out,  PP_in,      (tdevice_PP     ,UnitDelay));
    PU     :VitalBuf(PU_out,  PU_in,      (tdevice_PU     ,UnitDelay));
    SE     :VitalBuf(SE_out,  SE_in,      (tdevice_SE     ,UnitDelay));
    BE     :VitalBuf(BE_out,  BE_in,      (tdevice_BE     ,UnitDelay));
    EP     :VitalBuf(EP_out,  EP_in,      (tdevice_EP     ,UnitDelay));
    WR     :VitalBuf(WR_out,  WR_in,      (tdevice_WR     ,UnitDelay));
    DP     :VitalBuf(DP_out,  DP_in,      (tdevice_DP     ,UnitDelay));
    PE     :VitalBuf(PE_out,  PE_in,      (tdevice_PE     ,UnitDelay));
    RES    :VitalBuf(RES_out, RES_in,     (tdevice_RES    ,UnitDelay));

    ---------------------------------------------------------------------------
    -- Wire Delays
    ---------------------------------------------------------------------------
    WireDelay : BLOCK
    BEGIN

        w_1 : VitalWireDelay (SCK_ipd,     SCK, tipd_SCK);
        w_2 : VitalWireDelay (SI_ipd,      SI, tipd_SI);
        w_3 : VitalWireDelay (SO_ipd,      SO, tipd_SO);

        w_4: VitalWireDelay (CSNeg_ipd,   CSNeg, tipd_CSNeg);
        w_5: VitalWireDelay (HOLDNeg_ipd, HOLDNeg, tipd_HOLDNeg);
        w_6: VitalWireDelay (WPNeg_ipd,    WPNeg, tipd_WPNeg);

    END BLOCK;

    ---------------------------------------------------------------------------
    -- Main Behavior Block
    ---------------------------------------------------------------------------
    Behavior: BLOCK

        PORT (
            SCK            : IN    std_ulogic := 'U';
            SIIn           : IN    std_ulogic := 'U';
            SIOut          : OUT   std_ulogic := 'U';
            SOIn           : IN    std_logic  := 'U';
            SOut           : OUT   std_logic  := 'U';
            CSNeg          : IN    std_ulogic := 'U';
            HOLDNegIn      : IN    std_ulogic := 'U';
            HOLDNegOut     : OUT   std_ulogic := 'U';
            WPNegIn        : IN    std_ulogic := 'U';
            WPNegOut       : OUT   std_ulogic := 'U'
        );
        PORT MAP (
             SCK        => SCK_ipd,
             SIIn       => SI_ipd,

             SOIn       => SO_ipd,

             SOut       => SO,

             CSNeg      => CSNeg_ipd,

             HOLDNegIn  => HOLDNeg_ipd,
             WPNegIn    => WPNeg_ipd,

             SIOut      => SI,
             WPNegOut   => WPNeg,
             HOLDNegOut => HOLDNeg
        );

        -- State Machine : State_Type
        TYPE state_type IS (IDLE,
                            WRITE_SR,
                            PAGE_PG,
                            OTP_PG,
                            SECTOR_ER,
                            BULK_ER,
                            P4_ER,
                            P8_ER,
                            DP_DOWN_WAIT,
                            DP_DOWN
                            );

        -- Instruction Type
        TYPE instruction_type IS (NONE,
                                WREN,
                                WRDI,
                                WRR,
                                RDSR,
                                READ,
                                READ_ID,
                                RDID,
                                FAST_READ,
                                DUAL_READ,
                                QUAD_READ,
                                DH_READ,
                                QH_READ,
                                SE,
                                BE,
                                PP,
                                QPP,
                                DP,
                                RES_READ_ES,
                                ENTER_PRL,
                                EXIT_PRL,
                                CLSR,
                                RCR,
                                P4E,
                                P8E,
                                OTPR,
                                OTPP
                                  );

        TYPE WByteType IS ARRAY (0 TO 255) OF INTEGER RANGE -1 TO MaxData;
        --Flash Memory Array
        TYPE MemArray IS ARRAY (0 TO AddrRANGE) OF INTEGER
                                                    RANGE -1 TO MaxData;
        --OTP Memory Array
        TYPE OTPArr IS ARRAY (OTPLoAddr TO OTPHiAddr) OF INTEGER
                                                    RANGE -1 TO MaxData;

    ---------------------------------------------------------------------------
    --  memory declaration
    ---------------------------------------------------------------------------
        SHARED VARIABLE Mem     : MemArray := (OTHERS => MaxData);
        -- OTP Sector
        SHARED VARIABLE OTPMem  : OTPArr := (OTHERS => MaxData);

        SIGNAL WByte            : WByteType := (OTHERS => 0);
        SIGNAL WOTPByte         : INTEGER RANGE -1 TO MaxData;
        -- states
        SIGNAL current_state    : state_type;
        SIGNAL next_state       : state_type;

        SIGNAL Instruct         : instruction_type;
        --zero delay signal
        SIGNAL SOut_zd          : std_logic := 'Z';
        SIGNAL SIOut_zd         : std_logic := 'Z';
        SIGNAL HOLDNegOut_zd    : std_logic := 'Z';
        SIGNAL WPNegOut_zd      : std_logic := 'Z';
        --HOLD delay on output data
        SIGNAL SOut_z           : std_logic := 'Z';
        SIGNAL SIOut_z          : std_logic := 'Z';
        -- powerup
        SIGNAL PoweredUp        : std_logic := '0';

        SHARED VARIABLE Status_reg   : std_logic_vector(7 downto 0)
                                                := (others => '0');

        SIGNAL Status_reg_in         : std_logic_vector(7 downto 0)
                                              := (others => '0');

        -- Status register Write In Progress Bit
        ALIAS WIP    :std_logic IS Status_reg(0);
        -- Status register Write Enable Latch Bit
        ALIAS WEL    :std_logic IS Status_reg(1);
        -- Status register block protect Bits
        ALIAS BP0    :std_logic IS Status_reg(2);
        ALIAS BP1    :std_logic IS Status_reg(3);
        ALIAS BP2    :std_logic IS Status_reg(4);
        -- status register Erase Error bit
        ALIAS E_ERR  :std_logic IS Status_reg(5);
        -- status register Program Error bit
        ALIAS P_ERR  :std_logic IS Status_reg(6);
        -- status register write disable
        ALIAS SRWD   :std_logic IS Status_reg(7);

        SHARED VARIABLE Sec_conf_reg : std_logic_vector(7 downto 0)
                                                := (others => '0');

        SIGNAL Sec_conf_reg_in       : std_logic_vector(7 downto 0)
                                              := (others => '0');

        -- Configuration Register FREEZE bit
        ALIAS FREEZE    :std_logic IS Sec_conf_reg(0);
        -- Configuration Register QUAD bit
        ALIAS QUAD      :std_logic IS Sec_conf_reg(1);
        -- Configuration Register TBPARM bit
        ALIAS TBPARM   :std_logic IS Sec_conf_reg(2);
        -- Configuration Register BPNV bit
        ALIAS BPNV      :std_logic IS Sec_conf_reg(3);
        -- Security Configuration Register the TBPROT bit
        ALIAS TBPROT    :std_logic IS Sec_conf_reg(5);

        -- The Lock Protection Registers for OTP Memory space
        SHARED VARIABLE PR_LOCK1 :std_logic_vector(15 downto 0);
        SHARED VARIABLE PR_LOCK2 :std_logic_vector(15 downto 0);
        SHARED VARIABLE PR_LOCK3 :std_logic_vector(15 downto 0);

        --Command Register
        SIGNAL write            : std_logic := '0';
        SIGNAL cfg_write        : std_logic := '0';
        SIGNAL read_out         : std_logic := '0';

        SIGNAL fast_rd          : boolean   := true;
        SIGNAL rd               : boolean   := false;
        SIGNAL dual             : boolean   := false;
        SIGNAL rd_jid           : boolean   := false;

        SHARED VARIABLE hold_mode : boolean := false;
        SHARED VARIABLE mpm_mode  : boolean := false;

        SHARED VARIABLE read_cnt  : NATURAL := 0;

        SIGNAL change_addr      : std_logic := '0';

        SIGNAL change_BP        : std_logic := '0';

        --FSM control signals
        SIGNAL PDONE            : std_logic := '1'; -- Page Prog. Done
        SIGNAL PSTART           : std_logic := '0'; --Start Page Programming

        SIGNAL WDONE            : std_logic := '1'; -- Write. Done
        SIGNAL WSTART           : std_logic := '0'; --Start Write

        SIGNAL ESTART           : std_logic := '0'; --Start Erase
        SIGNAL EDONE            : std_logic := '1'; --Erase Done

        SIGNAL INITIAL_CONFIG   : std_logic := '0';

        -- Sector and subsector addresses
        SIGNAL SA               : NATURAL RANGE 0 TO SecNum := 0;
        SHARED VARIABLE sect    : NATURAL RANGE 0 TO SecNum;

        SIGNAL Byte_number      : NATURAL RANGE 0 TO 255    := 0;

        -- Sector is protect if '1'
        SHARED VARIABLE Sec_Prot  : std_logic_vector(SecNum downto 0) :=
                                                   (OTHERS => '0');

        SHARED VARIABLE BP        : std_logic_vector(2 downto 0) := "000";

        SIGNAL Address          : NATURAL RANGE 0 TO AddrRANGE := 0;

        -- timing check violation
        SIGNAL Viol                : X01 := '0';

        PROCEDURE ADDRHILO_SEC(
            VARIABLE   AddrLOW  : INOUT NATURAL RANGE 0 to ADDRRange;
            VARIABLE   AddrHIGH : INOUT NATURAL RANGE 0 to ADDRRange;
            VARIABLE   Addr     : NATURAL) IS
            VARIABLE   sector   : NATURAL RANGE 0 TO SecNum;
        BEGIN
            sector   := Addr/16#10000#;
            AddrLOW  := sector*16#10000#;
            AddrHIGH := sector*16#10000# + 16#0FFFF#;
        END ADDRHILO_SEC;

        PROCEDURE ADDRHILO_PG(
            VARIABLE   AddrLOW  : INOUT NATURAL RANGE 0 to ADDRRange;
            VARIABLE   AddrHIGH : INOUT NATURAL RANGE 0 to ADDRRange;
            VARIABLE   Addr     : NATURAL) IS
            VARIABLE   page     : NATURAL RANGE 0 TO PageNum;
        BEGIN
            page     := Addr/16#100#;
            AddrLOW  := Page*16#100#;
            AddrHIGH := Page*16#100# + 16#FF#;
        END AddrHILO_PG;

        PROCEDURE ADDRHILO_PB4(
            VARIABLE   AddrLOW  : INOUT NATURAL RANGE 0 to ADDRRange;
            VARIABLE   AddrHIGH : INOUT NATURAL RANGE 0 to ADDRRange;
            VARIABLE   Addr     : NATURAL) IS
            VARIABLE   Sec      : NATURAL RANGE 0 TO SecNum;
        BEGIN
            Sec      := Addr/16#10000#;
            IF Sec = 0 OR Sec = 1 OR Sec = SecNum OR Sec = SecNum - 1 THEN
                AddrLOW  := (Address/(SecSize_4+1))*(SecSize_4+1);
                AddrHIGH := (Address/(SecSize_4+1))*(SecSize_4+1) + SecSize_4;
            END IF;
        END ADDRHILO_PB4;

        PROCEDURE ADDRHILO_PB8(
            VARIABLE   AddrLOW  : INOUT NATURAL RANGE 0 to ADDRRange;
            VARIABLE   AddrHIGH : INOUT NATURAL RANGE 0 to ADDRRange;
            VARIABLE   Addr     : NATURAL) IS
            VARIABLE   Sec      : NATURAL RANGE 0 TO SecNum;
        BEGIN
            Sec      := Addr/16#10000#;
            IF Sec = 0 OR Sec = SecNum - 1 THEN
                AddrLOW  := (Address/(SecSize_8+1))*(SecSize_8+1);
                AddrHIGH := (Address/(SecSize_8+1))*(SecSize_8+1) + SecSize_8;
            ELSIF Sec = 1 THEN
                AddrLOW  := (Address/(SecSize_8+1))*(SecSize_8+1);
                AddrHIGH := (Address/(SecSize_8+1))*(SecSize_8+1) + SecSize_8;
                IF AddrHIGH > 16#1FFFF# THEN
                    AddrHIGH := 16#1FFFF#;
                END IF;
            ELSIF Sec = SecNum THEN
                AddrLOW  := (Address/(SecSize_8+1))*(SecSize_8+1);
                AddrHIGH := (Address/(SecSize_8+1))*(SecSize_8+1) + SecSize_8;
                IF AddrHIGH > 16#7FFFFF# THEN
                    AddrHIGH := 16#7FFFFF#;
                END IF;
            END IF;
            END ADDRHILO_PB8;

    BEGIN

   ----------------------------------------------------------------------------
    --Power Up time;
    ---------------------------------------------------------------------------
    PoweredUp <= '1' AFTER tdevice_PU;

    ---------------------------------------------------------------------------
    -- VITAL Timing Checks Procedures
    ---------------------------------------------------------------------------
    VITALTimingCheck: PROCESS(SIIn, SOIn, SCK_ipd, CSNeg_ipd, HOLDNegIn,
                              WPNegIn)
         -- Timing Check Variables
        VARIABLE Tviol_SI_SCK     : X01 := '0';
        VARIABLE TD_SI_SCK        : VitalTimingDataType;

        VARIABLE Tviol_HOLD_SCK   : X01 := '0';
        VARIABLE TD_HOLD_SCK      : VitalTimingDataType;

        VARIABLE Tviol_CS_SCK     : X01 := '0';
        VARIABLE TD_CS_SCK        : VitalTimingDataType;

        VARIABLE Tviol_WS_CS      : X01 := '0';
        VARIABLE TD_WS_CS         : VitalTimingDataType;

        VARIABLE Tviol_WH_CS      : X01 := '0';
        VARIABLE TD_WH_CS         : VitalTimingDataType;

        VARIABLE Pviol_CS_read    : X01 := '0';
        VARIABLE PD_CS_read       : VitalPeriodDataType := VitalPeriodDataInit;

        VARIABLE Pviol_CS_pgm     : X01 := '0';
        VARIABLE PD_CS_pgm        : VitalPeriodDataType := VitalPeriodDataInit;

        VARIABLE Pviol_SCK_serial_fast : X01 := '0';
        VARIABLE PD_SCK_serial_fast    : VitalPeriodDataType :=
                                                        VitalPeriodDataInit;

        VARIABLE Pviol_SCK_dual   : X01 := '0';
        VARIABLE PD_SCK_dual      : VitalPeriodDataType := VitalPeriodDataInit;

        VARIABLE Pviol_SCK_rdid   : X01 := '0';
        VARIABLE PD_SCK_rdid      : VitalPeriodDataType := VitalPeriodDataInit;

        VARIABLE Pviol_SCK_serial : X01 := '0';
        VARIABLE PD_SCK_serial    : VitalPeriodDataType := VitalPeriodDataInit;

        VARIABLE Pviol_SCK_serial_fast_rd: X01 := '0';
        VARIABLE PD_SCK_serial_fast_rd : VitalPeriodDataType :=
                                                           VitalPeriodDataInit;

        VARIABLE Pviol_SCK_serial_rd : X01 := '0';
        VARIABLE PD_SCK_serial_rd : VitalPeriodDataType := VitalPeriodDataInit;

        VARIABLE Pviol_SCK_serial_rdid : X01 := '0';
        VARIABLE PD_SCK_serial_rdid: VitalPeriodDataType := VitalPeriodDataInit;

        VARIABLE Pviol_SCK_dual_fast_rd: X01 := '0';
        VARIABLE PD_SCK_dual_fast_rd : VitalPeriodDataType :=
                                                           VitalPeriodDataInit;

        VARIABLE Violation        : X01 := '0';

    BEGIN
    ---------------------------------------------------------------------------
    -- Timing Check Section
    ---------------------------------------------------------------------------
    IF (TimingChecksOn) THEN

        -- Setup/Hold Check between SI and SCK, serial mode
        VitalSetupHoldCheck (
            TestSignal      => SIIn,
            TestSignalName  => "SI",
            RefSignal       => SCK_ipd,
            RefSignalName   => "SCK",
            SetupHigh       => tsetup_SI_SCK,
            SetupLow        => tsetup_SI_SCK,
            HoldHigh        => thold_SI_SCK,
            HoldLow         => thold_SI_SCK,
            CheckEnabled    => SIOut_z /= SIIn,
            RefTransition   => '/',
            HeaderMsg       => InstancePath & PartID,
            TimingData      => TD_SI_SCK,
            Violation       => Tviol_SI_SCK
        );

        -- Setup/Hold Check between HOLD# and SCK /
        VitalSetupHoldCheck (
            TestSignal      => HOLDNegIn,
            TestSignalName  => "HOLD#",
            RefSignal       => SCK_ipd,
            RefSignalName   => "SCK",
            SetupLow        => tsetup_HOLDNeg_SCK,
            SetupHigh       => tsetup_HOLDNeg_SCK,
            HoldLow         => thold_HOLDNeg_SCK,
            HoldHigh        => thold_HOLDNeg_SCK,
            CheckEnabled    => QUAD = '1'
                               AND HOLDNegOut_zd /= HOLDNegIn,
            RefTransition   => '/',
            HeaderMsg       => InstancePath & PartID,
            TimingData      => TD_HOLD_SCK,
            Violation       => Tviol_HOLD_SCK
        );

        -- Setup/Hold Check between CS# and SCK
        VitalSetupHoldCheck (
            TestSignal      => CSNeg_ipd,
            TestSignalName  => "CS#",
            RefSignal       => SCK_ipd,
            RefSignalName   => "SCK",
            SetupHigh       => tsetup_CSNeg_SCK,
            SetupLow        => tsetup_CSNeg_SCK,
            HoldHigh        => thold_CSNeg_SCK,
            HoldLow         => thold_CSNeg_SCK,
            CheckEnabled    => true,
            RefTransition   => '/',
            HeaderMsg       => InstancePath & PartID,
            TimingData      => TD_CS_SCK,
            Violation       => Tviol_CS_SCK
        );

        -- Setup Check between WP# and CS# \
        VitalSetupHoldCheck (
            TestSignal      => WPNegIn,
            TestSignalName  => "WP#",
            RefSignal       => CSNeg_ipd,
            RefSignalName   => "CS#",
            SetupHigh       => tsetup_WPNeg_CSNeg,
            CheckEnabled    => true,
            RefTransition   => '\',
            HeaderMsg       => InstancePath & PartID,
            TimingData      => TD_WS_CS,
            Violation       => Tviol_WS_CS
        );

        -- Hold Check between WP# and CS# /
        VitalSetupHoldCheck (
            TestSignal      => WPNegIn,
            TestSignalName  => "WP#",
            RefSignal       => CSNeg_ipd,
            RefSignalName   => "CS#",
            HoldHigh        => thold_WPNeg_CSNeg,
            CheckEnabled    => SRWD = '1' AND WEL = '1' AND QUAD = '0',
            RefTransition   => '/',
            HeaderMsg       => InstancePath & PartID,
            TimingData      => TD_WH_CS,
            Violation       => Tviol_WH_CS
        );

        -- Period Check CS# for Program/Erase, serial mode
        VitalPeriodPulseCheck (
            TestSignal      =>  CSNeg_ipd,
            TestSignalName  =>  "CS#",
            PulseWidthHigh  =>  tpw_CSNeg_pgm_posedge,
            PeriodData      =>  PD_CS_pgm,
            XOn             =>  XOn,
            MsgOn           =>  MsgOn,
            Violation       =>  Pviol_CS_pgm,
            HeaderMsg       =>  InstancePath & PartID,
            CheckEnabled    =>  TRUE );

        -- Period Check CS# for READ, serial mode
        VitalPeriodPulseCheck (
            TestSignal      =>  CSNeg_ipd,
            TestSignalName  =>  "CS#",
            PulseWidthHigh  =>  tpw_CSNeg_read_posedge,
            PeriodData      =>  PD_CS_read,
            XOn             =>  XOn,
            MsgOn           =>  MsgOn,
            Violation       =>  Pviol_CS_read,
            HeaderMsg       =>  InstancePath & PartID,
            CheckEnabled    =>  rd );

        -- Period Check SCK for READ, serial mode
        VitalPeriodPulseCheck (
            TestSignal      =>  SCK_ipd,
            TestSignalName  =>  "SCK",
            PulseWidthLow   =>  tpw_SCK_serial_negedge,
            PulseWidthHigh  =>  tpw_SCK_serial_posedge,
            PeriodData      =>  PD_SCK_serial,
            XOn             =>  XOn,
            MsgOn           =>  MsgOn,
            Violation       =>  Pviol_SCK_serial,
            HeaderMsg       =>  InstancePath & PartID,
            CheckEnabled    =>  rd);

        -- Period Check SCK for RDID, serial mode
        VitalPeriodPulseCheck (
            TestSignal      =>  SCK_ipd,
            TestSignalName  =>  "SCK",
            PulseWidthLow   =>  tpw_SCK_rd_jid_negedge,
            PulseWidthHigh  =>  tpw_SCK_rd_jid_posedge,
            PeriodData      =>  PD_SCK_rdid,
            XOn             =>  XOn,
            MsgOn           =>  MsgOn,
            Violation       =>  Pviol_SCK_rdid,
            HeaderMsg       =>  InstancePath & PartID,
            CheckEnabled    =>  rd_jid);

        -- Period Check SCK for FAST_READ, serial mode
        VitalPeriodPulseCheck (
            TestSignal      =>  SCK_ipd,
            TestSignalName  =>  "SCK",
            PulseWidthLow   =>  tpw_SCK_serial_fast_negedge,
            PulseWidthHigh  =>  tpw_SCK_serial_fast_posedge,
            PeriodData      =>  PD_SCK_serial_fast,
            XOn             =>  XOn,
            MsgOn           =>  MsgOn,
            Violation       =>  Pviol_SCK_serial_fast,
            HeaderMsg       =>  InstancePath & PartID,
            CheckEnabled    =>  fast_rd );

        -- Period Check SCK for DUAL_READ, serial mode
        VitalPeriodPulseCheck (
            TestSignal      =>  SCK_ipd,
            TestSignalName  =>  "SCK",
            PulseWidthLow   =>  tpw_SCK_dual_negedge,
            PulseWidthHigh  =>  tpw_SCK_dual_posedge,
            PeriodData      =>  PD_SCK_dual,
            XOn             =>  XOn,
            MsgOn           =>  MsgOn,
            Violation       =>  Pviol_SCK_dual,
            HeaderMsg       =>  InstancePath & PartID,
            CheckEnabled    =>  dual);

        -- Period Check SCK for READ, serial mode
        VitalPeriodPulseCheck (
            TestSignal      =>  SCK_ipd,
            TestSignalName  =>  "SCK",
            Period          =>  tperiod_SCK_serial_rd,
            PeriodData      =>  PD_SCK_serial_rd,
            XOn             =>  XOn,
            MsgOn           =>  MsgOn,
            Violation       =>  Pviol_SCK_serial_rd,
            HeaderMsg       =>  InstancePath & PartID,
            CheckEnabled    =>  rd );

        -- Period Check SCK for RDID, serial mode
        VitalPeriodPulseCheck (
            TestSignal      =>  SCK_ipd,
            TestSignalName  =>  "SCK",
            Period          =>  tperiod_SCK_serial_rd_jid,
            PeriodData      =>  PD_SCK_serial_rdid,
            XOn             =>  XOn,
            MsgOn           =>  MsgOn,
            Violation       =>  Pviol_SCK_serial_rdid,
            HeaderMsg       =>  InstancePath & PartID,
            CheckEnabled    =>  rd_jid );

        -- Period Check SCK for other than READ, serial mode
        VitalPeriodPulseCheck (
            TestSignal      =>  SCK_ipd,
            TestSignalName  =>  "SCK",
            Period          =>  tperiod_SCK_serial_fast_rd,
            PeriodData      =>  PD_SCK_serial_fast_rd,
            XOn             =>  XOn,
            MsgOn           =>  MsgOn,
            Violation       =>  Pviol_SCK_serial_fast_rd,
            HeaderMsg       =>  InstancePath & PartID,
            CheckEnabled    =>  fast_rd );

        -- Period Check SCK for other than READ, serial mode
        VitalPeriodPulseCheck (
            TestSignal      =>  SCK_ipd,
            TestSignalName  =>  "SCK",
            Period          =>  tperiod_SCK_dual_fast_rd,
            PeriodData      =>  PD_SCK_dual_fast_rd,
            XOn             =>  XOn,
            MsgOn           =>  MsgOn,
            Violation       =>  Pviol_SCK_dual_fast_rd,
            HeaderMsg       =>  InstancePath & PartID,
            CheckEnabled    =>  dual );

        Violation := Tviol_SI_SCK               OR
                     Tviol_HOLD_SCK             OR
                     Tviol_CS_SCK               OR
                     Tviol_WS_CS                OR
                     Tviol_WH_CS                OR
                     Pviol_CS_read              OR
                     Pviol_CS_pgm               OR
                     Pviol_SCK_serial_fast      OR
                     Pviol_SCK_dual             OR
                     Pviol_SCK_rdid             OR
                     Pviol_SCK_serial           OR
                     Pviol_SCK_serial_rd        OR
                     Pviol_SCK_serial_rdid      OR
                     Pviol_SCK_serial_fast_rd   OR
                     Pviol_SCK_dual_fast_rd;

        Viol <= Violation;

        ASSERT Violation = '0'
            REPORT InstancePath & partID & ": simulation may be" &
                    " inaccurate due to timing violations"
            SEVERITY WARNING;

        END IF;
    END PROCESS VITALTimingCheck;

----------------------------------------------------------------------------
-- sequential process for FSM state transition
----------------------------------------------------------------------------
    StateTransition : PROCESS(next_state, PoweredUp)

    BEGIN
        IF PoweredUp = '1' THEN
            current_state <= next_state;
        END IF;
    END PROCESS StateTransition;

    ---------------------------------------------------------------------------
    --  Write cycle decode
    ---------------------------------------------------------------------------
    BusCycleDecode : PROCESS(SCK_ipd, CSNeg_ipd, HOLDNeg_pullup, SIIn, RES_in)

        TYPE bus_cycle_type IS (STAND_BY,
                                CODE_BYTE,
                                ADDRESS_BYTES,
                                DUMMY_BYTES,
                                MODE_BYTE,
                                DATA_BYTES
                                );
        TYPE quad_data_type IS ARRAY (0 TO 511) OF INTEGER RANGE 0 TO 15;

        VARIABLE bus_cycle_state : bus_cycle_type;

        VARIABLE data_cnt        : NATURAL := 0;
        VARIABLE addr_cnt        : NATURAL := 0;
        VARIABLE code_cnt        : NATURAL := 0;
        VARIABLE mode_cnt        : NATURAL := 0;
        VARIABLE dummy_cnt       : NATURAL := 0;
        VARIABLE bit_cnt         : NATURAL := 0;
        VARIABLE Data_in         : std_logic_vector(2047 downto 0)
                                                    := (others => '0');
        VARIABLE quad_data_in    : quad_data_type;
        VARIABLE quad_nybble     : std_logic_vector(3 downto 0);
        VARIABLE Quad_slv        : std_logic_vector(3 downto 0);
        VARIABLE code            : std_logic_vector(7 downto 0);
        VARIABLE code_in         : std_logic_vector(7 downto 0);
        VARIABLE Byte_slv        : std_logic_vector(7 downto 0);
        VARIABLE addr_bytes      : std_logic_vector(HiAddrBit downto 0);
        VARIABLE Address_in      : std_logic_vector(23 downto 0);
        VARIABLE mode_bytes      : std_logic_vector(7 downto 0);
        VARIABLE mode_in         : std_logic_vector(7 downto 0);
    BEGIN

        IF rising_edge(CSNeg_ipd) AND NOT(bus_cycle_state = DATA_BYTES)
        AND NOT(bus_cycle_state = DUMMY_BYTES) THEN
            bus_cycle_state := STAND_BY;
        ELSE
        CASE bus_cycle_state IS
            WHEN STAND_BY =>
                IF falling_edge(CSNeg_ipd) THEN
                    Instruct <= NONE;
                    write    <= '1';
                    code_cnt  := 0;
                    addr_cnt  := 0;
                    data_cnt  := 0;
                    mode_cnt  := 0;
                    dummy_cnt := 0;
                    bus_cycle_state := CODE_BYTE;
                END IF;

            WHEN CODE_BYTE =>
                IF rising_edge(SCK_ipd) AND
                   ((HOLDNeg_pullup='1' AND QUAD='0') OR QUAD ='1') THEN
                    Code_in(code_cnt) := SIIn;
                    code_cnt := code_cnt + 1;
                    IF code_cnt = BYTE THEN
                        --MSB first
                        FOR I IN 7 DOWNTO 0 LOOP
                            code(i) := code_in(7-i);
                        END LOOP;

                        CASE code IS
                            WHEN "00000110" => --06h
                                Instruct <= WREN;
                                bus_cycle_state := DATA_BYTES;
                            WHEN "00000100" => --04h
                                Instruct <= WRDI;
                                bus_cycle_state := DATA_BYTES;
                            WHEN "00000001" => --01h
                                Instruct <= WRR;
                                bus_cycle_state := DATA_BYTES;
                            WHEN "00000101" => --05h
                                Instruct <= RDSR;
                                bus_cycle_state := DATA_BYTES;
                            WHEN "00000011" => --03h
                                Instruct <= READ;
                                bus_cycle_state := ADDRESS_BYTES;
                            WHEN "00001011" => --0Bh
                                Instruct <= FAST_READ;
                                    bus_cycle_state := ADDRESS_BYTES;
                            WHEN "10011111" => --9Fh
                                Instruct <= RDID;
                                bus_cycle_state := DATA_BYTES;
                            WHEN "10010000" =>
                                Instruct <= READ_ID; --90h
                                bus_cycle_state := ADDRESS_BYTES;
                            WHEN "10101011" =>
                                Instruct <= RES_READ_ES; --ABh
                                bus_cycle_state := DUMMY_BYTES;
                            WHEN "11011000"  => --D8h
                                Instruct <= SE;
                                bus_cycle_state := ADDRESS_BYTES;
                            WHEN "11000111" | "01100000" => --C7h or 60h
                                Instruct <= BE;
                                bus_cycle_state := DATA_BYTES;
                            WHEN "00000010" => --02h
                                Instruct <= PP;
                                bus_cycle_state := ADDRESS_BYTES;
                            WHEN "00110010" => --32h
                                Instruct <= QPP;
                                bus_cycle_state := ADDRESS_BYTES;
                            WHEN "10111001" => --B9h
                                Instruct <= DP;
                                bus_cycle_state := DATA_BYTES;
                            WHEN "00110000" => --30h
                                Instruct <= CLSR;
                                bus_cycle_state := DATA_BYTES;
                            WHEN "00110101" => --35h
                                Instruct <= RCR;
                                bus_cycle_state := DATA_BYTES;
                            WHEN "00100000" => --20h
                                Instruct <= P4E;
                                bus_cycle_state := ADDRESS_BYTES;
                            WHEN "01000000" =>--40h
                                Instruct <= P8E;
                                bus_cycle_state := ADDRESS_BYTES;
                            WHEN "01000010" => --42h
                                Instruct <= OTPP;
                                bus_cycle_state := ADDRESS_BYTES;
                            WHEN "01001011" => --4Bh
                                Instruct <= OTPR;
                                bus_cycle_state := ADDRESS_BYTES;
                            WHEN "00111011" => --3Bh
                                Instruct <= DUAL_READ;
                                bus_cycle_state := ADDRESS_BYTES;
                            WHEN "01101011" => --6Bh
                                Instruct <= QUAD_READ;
                                bus_cycle_state := ADDRESS_BYTES;
                            WHEN "10111011" => --BBh
                                Instruct <= DH_READ;
                                bus_cycle_state := ADDRESS_BYTES;
                            WHEN "11101011" => --EBh
                                Instruct <= QH_READ;
                                bus_cycle_state := ADDRESS_BYTES;
                            WHEN others =>
                                null;
                        END CASE;
                    END IF;
                END IF;

                WHEN ADDRESS_BYTES =>
                    IF rising_edge(SCK_ipd) THEN
                        IF ((Instruct=FAST_READ OR Instruct=OTPR
                        OR Instruct=DUAL_READ) AND
                           ((HOLDNeg_pullup='1' AND QUAD='0') OR QUAD ='1'))
                        OR (Instruct=QUAD_READ AND QUAD = '1') THEN
                            Address_in(addr_cnt) := SIIn;
                            addr_cnt := addr_cnt + 1;
                            IF addr_cnt = 3*BYTE THEN
                                FOR I IN 23 DOWNTO 23-HiAddrBit LOOP
                                    addr_bytes(23-i) := Address_in(i);
                                END LOOP;
                                Address <= to_nat(addr_bytes);
                                change_addr <= '1','0' AFTER 1 ns;
                                bus_cycle_state := DUMMY_BYTES;
                            END IF;
                        ELSIF Instruct = DH_READ AND
                          ((HOLDNeg_pullup='1' AND QUAD='0') OR QUAD ='1') THEN
                            IF SOIn /= 'Z' THEN
                                Address_in(2*addr_cnt)   := SOIn;
                                Address_in(2*addr_cnt+1) := SIIn;
                                read_cnt := 0;
                                addr_cnt := addr_cnt + 1;
                                IF addr_cnt = 12 THEN
                                    addr_cnt := 0;
                                    FOR I IN 23 DOWNTO 23-HiAddrBit LOOP
                                        addr_bytes(23-i) := Address_in(i);
                                    END LOOP;
                                    Address <= to_nat(addr_bytes);
                                    change_addr <= '1','0' AFTER 1 ns;
                                    bus_cycle_state := MODE_BYTE;
                                END IF;
                            ELSE
                                mpm_mode := FALSE;
                                bus_cycle_state := STAND_BY;
                            END IF;
                        ELSIF Instruct = QH_READ THEN
                            IF QUAD = '1' THEN
                                IF SOIn /= 'Z' THEN
                                    Address_in(4*addr_cnt)   := HOLDNegIn;
                                    Address_in(4*addr_cnt+1) := WPNegIn;
                                    Address_in(4*addr_cnt+2) := SOIn;
                                    Address_in(4*addr_cnt+3) := SIIn;
                                    read_cnt := 0;
                                    addr_cnt := addr_cnt + 1;
                                    IF addr_cnt = 6 THEN
                                        addr_cnt := 0;
                                        FOR I IN 23 DOWNTO 23-HiAddrBit LOOP
                                            addr_bytes(23-i) := Address_in(i);
                                        END LOOP;
                                        Address <= to_nat(addr_bytes);
                                        change_addr <= '1','0' AFTER 1 ns;
                                        bus_cycle_state := MODE_BYTE;
                                    END IF;
                                ELSE
                                    mpm_mode := FALSE;
                                    bus_cycle_state := STAND_BY;
                                END IF;
                            ELSE
                                bus_cycle_state := STAND_BY;
                            END IF;
                        ELSIF ((HOLDNeg_pullup='1' AND QUAD='0') OR
                                QUAD ='1') THEN
                            Address_in(addr_cnt) := SIIn;
                            addr_cnt := addr_cnt + 1;
                            IF addr_cnt = 3*BYTE THEN
                                FOR I IN 23 DOWNTO 23-HiAddrBit LOOP
                                    addr_bytes(23-i) := Address_in(i);
                                END LOOP;
                                Address <= to_nat(addr_bytes);
                                change_addr <= '1','0' AFTER 1 ns;
                                bus_cycle_state := DATA_BYTES;
                            END IF;
                        END IF;
                    END IF;

                WHEN MODE_BYTE =>
                    IF rising_edge(SCK_ipd) THEN
                        IF Instruct=DH_READ AND
                          ((HOLDNeg_pullup='1' AND QUAD='0') OR QUAD ='1') THEN
                            mode_in(2*mode_cnt)   := SOIn;
                            mode_in(2*mode_cnt+1) := SIIn;
                            mode_cnt := mode_cnt + 1;
                            IF mode_cnt = BYTE/2 THEN
                                mode_cnt := 0;
                                FOR I IN 7 DOWNTO 0 LOOP
                                    mode_bytes(i) := mode_in(7-i);
                                END LOOP;
                                bus_cycle_state := DATA_BYTES;
                            END IF;
                        ELSIF Instruct=QH_READ AND QUAD = '1' THEN
                            mode_in(4*mode_cnt)   := HOLDNegIn;
                            mode_in(4*mode_cnt+1) := WPNegIn;
                            mode_in(4*mode_cnt+2) := SOIn;
                            mode_in(4*mode_cnt+3) := SIIn;
                            mode_cnt := mode_cnt + 1;
                            IF mode_cnt = BYTE/4 THEN
                                mode_cnt := 0;
                                FOR I IN 7 DOWNTO 0 LOOP
                                    mode_bytes(i) := mode_in(7-i);
                                END LOOP;
                                bus_cycle_state := DUMMY_BYTES;
                            END IF;
                        END IF;
                        dummy_cnt := 0;
                    END IF;

                WHEN DUMMY_BYTES =>
                    IF rising_edge(SCK_ipd) THEN
                        IF QUAD = '1' AND (Instruct=QUAD_READ
                        OR Instruct=QH_READ) THEN
                            dummy_cnt := dummy_cnt + 1;
                            IF dummy_cnt = BYTE AND Instruct=QUAD_READ THEN
                                bus_cycle_state := DATA_BYTES;
                            ELSIF dummy_cnt = BYTE/2 AND Instruct=QH_READ THEN
                                bus_cycle_state := DATA_BYTES;
                            END IF;
                        ELSIF ((HOLDNeg_pullup='1' AND QUAD='0') OR
                                QUAD ='1') THEN
                            dummy_cnt := dummy_cnt + 1;
                            IF dummy_cnt = BYTE THEN
                                IF Instruct=FAST_READ OR Instruct=OTPR OR
                                Instruct=DUAL_READ THEN
                                    bus_cycle_state := DATA_BYTES;
                                END IF;
                            ELSIF dummy_cnt = 3*BYTE THEN
                                bus_cycle_state := DATA_BYTES;
                            END IF;
                        END IF;
                    END IF;

                    IF rising_edge(CSNeg_ipd) THEN
                        IF (((HOLDNeg_pullup='1' AND QUAD='0') OR QUAD ='1')
                           AND dummy_cnt = 0 AND Instruct = RES_READ_ES) THEN
                            write <= '0';
                        END IF;
                        bus_cycle_state := STAND_BY;
                    END IF;

                WHEN DATA_BYTES =>
                    IF falling_edge(SCK_ipd) AND CSNeg_ipd = '0' THEN
                        IF ((Instruct = READ OR Instruct = FAST_READ
                        OR Instruct = DUAL_READ OR Instruct = DH_READ
                        OR Instruct = RES_READ_ES OR Instruct = RDID
                        OR Instruct = READ_ID OR Instruct = RDSR
                        OR Instruct = RCR OR Instruct = OTPR)
                        AND ((HOLDNeg_pullup='1' AND QUAD='0') OR QUAD ='1'))
                        OR ((Instruct=QUAD_READ OR Instruct=QH_READ)
                        AND QUAD = '1') THEN
                            read_out <= '1', '0' AFTER 1 ns;
                        END IF;
                    END IF;
                    IF rising_edge(SCK_ipd) THEN
                        IF QUAD = '1' AND Instruct=QPP THEN
                            quad_nybble := HOLDNegIn & WPNegIn & SOIn & SIIn;
                            IF data_cnt > 511 THEN
                            --In case of quad mode and QPP,
                            --if more than 512 bytes are sent to the device
                                FOR I IN 0 TO 510 LOOP
                                    quad_data_in(i) := quad_data_in(i+1);
                                END LOOP;
                                quad_data_in(511) := to_nat(quad_nybble);
                                data_cnt := data_cnt +1;
                            ELSE
                                IF quad_nybble /= "ZZZZ" THEN
                                    quad_data_in(data_cnt) :=
                                    to_nat(quad_nybble);
                                END IF;
                                    data_cnt := data_cnt +1;
                            END IF;
                        ELSIF ((HOLDNeg_pullup='1' AND QUAD='0') OR
                                QUAD ='1') THEN
                            IF data_cnt > 2047 THEN
                            --In case of serial mode and PP,
                            --if more than 256 bytes are sent to the device
                                IF bit_cnt = 0 THEN
                                    FOR I IN 0 TO (255*BYTE - 1) LOOP
                                        Data_in(i) := Data_in(i+8);
                                    END LOOP;
                                END IF;
                                Data_in(2040 + bit_cnt) := SIIn;
                                bit_cnt := bit_cnt + 1;
                                IF bit_cnt = 8 THEN
                                    bit_cnt := 0;
                                END IF;
                                data_cnt := data_cnt + 1;
                            ELSE
                                Data_in(data_cnt) := SIIn;
                                data_cnt := data_cnt + 1;
                                bit_cnt := 0;
                            END IF;
                        END IF;
                    END IF;

                    IF rising_edge(CSNeg_ipd) THEN
                        IF mpm_mode AND mode_bytes(7 downto 4) = "1010"
                        AND (Instruct = DH_READ OR Instruct = QH_READ) THEN
                            bus_cycle_state := ADDRESS_BYTES;
                        ELSE
                            mpm_mode := FALSE;
                            bus_cycle_state := STAND_BY;
                        END IF;
                        CASE Instruct IS
                            WHEN WREN | WRDI | DP | BE | SE | P4E | P8E
                            | CLSR  =>
                                IF ((HOLDNeg_pullup='1' AND QUAD='0') OR
                                     QUAD ='1') THEN
                                    IF data_cnt = 0 THEN
                                        write <= '0';
                                    END IF;
                                END IF;
                            WHEN RES_READ_ES =>
                                IF ((HOLDNeg_pullup='1' AND QUAD='0') OR
                                     QUAD ='1') THEN
                                    write <= '0';
                                END IF;
                            WHEN WRR =>
                                IF ((HOLDNeg_pullup='1' AND QUAD='0') OR
                                     QUAD ='1') THEN
                                    IF ((data_cnt mod 8) = 0 AND
                                         data_cnt > 0) THEN
                                        IF data_cnt = 8 THEN
                                            write <= '0';
                                            cfg_write  <= '0';
                                            FOR i IN 0 TO 7 LOOP
                                                Status_reg_in(i) <=
                                                               Data_in(7-i);
                                            END LOOP;
                                        ELSIF data_cnt = 16 THEN
                                        --After the 16th cycle both the
                                        --Status and Configuration Registers
                                        --are written to.
                                            write <= '0';
                                            cfg_write  <= '1';
                                            FOR i IN 0 TO 7 LOOP
                                                Status_reg_in(i) <=
                                                               Data_in(7-i);
                                                Sec_conf_reg_in(i) <=
                                                              Data_in(15-i);
                                            END LOOP;
                                        END IF;
                                    END IF;
                                END IF;

                            WHEN PP =>
                                IF ((HOLDNeg_pullup='1' AND QUAD='0') OR
                                     QUAD ='1') THEN
                                    IF data_cnt > 0 THEN
                                        IF data_cnt mod 8 = 0 THEN
                                            write <= '0';
                                            FOR I IN 0 TO 255 LOOP
                                                FOR J IN 7 DOWNTO 0 LOOP
                                                    Byte_slv(j) :=
                                                    Data_in((i*8) + (7-j));
                                                END LOOP;
                                                WByte(i) <=
                                                    to_nat(Byte_slv);
                                            END LOOP;
                                            IF data_cnt > 256*BYTE THEN
                                                Byte_number <= 255;
                                            ELSE
                                                Byte_number <= data_cnt/8-1;
                                            END IF;
                                        END IF;
                                    END IF;
                                END IF;

                            WHEN QPP =>
                                IF data_cnt > 0 THEN
                                    IF data_cnt mod 2 = 0 THEN
                                        write <= '0';
                                        FOR I IN 0 TO 255 LOOP
                                            FOR J IN 1 DOWNTO 0 LOOP
                                                Quad_slv :=
                                                to_slv(quad_data_in((i*2) +
                                                (1-j)),4);

                                                Byte_slv(4*j+3 DOWNTO 4*j) :=
                                                Quad_slv;
                                            END LOOP;
                                            WByte(i) <=
                                                to_nat(Byte_slv);
                                        END LOOP;
                                        IF data_cnt > 512 THEN
                                            Byte_number <= 255;
                                        ELSE
                                            Byte_number <= data_cnt/2-1;
                                        END IF;
                                    END IF;
                                END IF;

                            WHEN OTPP =>
                                IF ((HOLDNeg_pullup='1' AND QUAD='0') OR
                                     QUAD ='1') THEN
                                    IF data_cnt = 8 THEN
                                        write <= '0';
                                        FOR J IN 7 DOWNTO 0 LOOP
                                            Byte_slv(j) := Data_in(7-j);
                                        END LOOP;
                                        WOTPByte <= to_nat(Byte_slv);
                                    END IF;
                                END IF;

                            WHEN others =>
                                null;
                        END CASE;
                    END IF;

            END CASE;
        END IF;

    END PROCESS BusCycleDecode;

    ---------------------------------------------------------------------------
    -- Timing control for the Page Program
    ---------------------------------------------------------------------------
    ProgTime : PROCESS(PSTART)
        VARIABLE pob      : time;
    BEGIN
        IF LongTimming THEN
            pob  := tdevice_PP;
        ELSE
            pob  := tdevice_PP / 100;
        END IF;
        IF rising_edge(PSTART) AND PDONE = '1' THEN
            IF Sec_Prot(SA) = '0' THEN
                PDONE <= '0', '1' AFTER pob;
            END IF;
        END IF;
    END PROCESS ProgTime;

    ---------------------------------------------------------------------------
    -- Timing control for the Write Status Register
    ---------------------------------------------------------------------------
    WriteTime : PROCESS(WSTART)
        VARIABLE wob      : time;
    BEGIN
        IF LongTimming THEN
            wob  := tdevice_WR;
        ELSE
            wob  := tdevice_WR / 100;
        END IF;
        IF rising_edge(WSTART) AND WDONE = '1' THEN
            WDONE <= '0', '1' AFTER wob;
        END IF;
    END PROCESS WriteTime;

    ---------------------------------------------------------------------------
    -- Timing control for the Bulk Erase
    ---------------------------------------------------------------------------
    ErsTime : PROCESS(ESTART)
        VARIABLE seo      : time;
        VARIABLE beo      : time;
        VARIABLE peo      : time;
        VARIABLE duration : time;
    BEGIN
        IF LongTimming THEN
            seo := tdevice_SE;
            beo := tdevice_BE;
            peo := tdevice_PE;
        ELSE
            seo := tdevice_SE / 1000;
            beo := tdevice_BE / 1000;
            peo := tdevice_PE / 1000;
        END IF;
        IF rising_edge(ESTART) AND EDONE = '1' THEN
            IF Instruct = BE THEN
                duration := beo;
            ELSIF Instruct = P4E OR Instruct = P8E THEN
                duration := peo;
            ELSE --Instruct = SE
                duration := seo;
            END IF;
            EDONE <= '0', '1' AFTER duration;
        END IF;
    END PROCESS ErsTime;

    CheckCEOnPowerUP :PROCESS
    BEGIN
        IF CSNeg /= '1' THEN
            REPORT InstancePath & partID &
            ": Device is selected during Power Up"
            SEVERITY WARNING;
        END IF;
        WAIT;
    END PROCESS;

    ---------------------------------------------------------------------------
    -- Main Behavior Process
    -- combinational process for next state generation
    ---------------------------------------------------------------------------
    StateGen :PROCESS(write, CSNeg, WDONE, PDONE, EDONE, DP_out)

    BEGIN
        -----------------------------------------------------------------------
        -- Functionality Section
        -----------------------------------------------------------------------

        CASE current_state IS
            WHEN IDLE          =>
                IF falling_edge(write) THEN
                    IF Instruct = WRR AND WEL = '1'
                       AND not(SRWD='1' AND WPNeg_pullup='0' AND QUAD='0') THEN
                       -- can not execute if HPM is entered
                       -- or if WEL bit is zero
                        next_state <= WRITE_SR;
                    ELSIF (Instruct = PP OR Instruct = QPP) AND WEL = '1' THEN
                        sect := Address / 16#10000#;
                        IF Sec_Prot(sect) = '0' THEN
                            next_state <=  PAGE_PG;
                        END IF;
                    ELSIF Instruct = OTPP AND WEL = '1' THEN
                        IF Address = 256 OR Address = 257 OR
                        ((Address >= 258 AND Address <= 273) AND
                        PR_LOCK1((Address-258)/8) = '1') OR Address = 274 OR
                        Address = 275 OR((Address >= 276 AND Address <= 531)
                        AND PR_LOCK2((Address-276)/16) = '1') OR Address = 532
                        OR Address = 533 OR((Address >= 534 AND Address <= 767)
                        AND PR_LOCK3((Address-534)/16) = '1') THEN
                            next_state <=  OTP_PG;
                        END IF;
                    ELSIF Instruct = SE AND WEL = '1' THEN
                        sect := Address / 16#10000#;
                        IF Sec_Prot(sect) = '0' THEN
                            next_state <=  SECTOR_ER;
                        END IF;
                    ELSIF Instruct = P4E AND WEL = '1' THEN
                        sect := Address / 16#10000#;
                        IF Sec_Prot(sect) = '0' AND (((sect=0 OR sect=1)
                        AND TBPARM='0') OR ((sect=SecNum OR sect=SecNum-1)
                        AND TBPARM='1')) THEN
                            next_state <=  P4_ER;
                        END IF;
                    ELSIF Instruct = P8E AND WEL = '1' THEN
                        sect := Address / 16#10000#;
                        IF Sec_Prot(sect) = '0' AND (((sect=0 OR sect=1)
                        AND TBPARM='0') OR ((sect=SecNum OR sect=SecNum-1)
                        AND TBPARM='1')) THEN
                            next_state <=  P8_ER;
                        END IF;
                    ELSIF Instruct = BE AND WEL = '1' AND
                    (BP0='0' AND BP1='0' AND BP2='0') THEN
                        next_state <= BULK_ER;
                    ELSIF Instruct = DP THEN
                        next_state <= DP_DOWN_WAIT;
                    ELSE
                        next_state <= IDLE;
                    END IF;
                END IF;

            WHEN WRITE_SR     =>
                IF rising_edge(WDONE) THEN
                    next_state <= IDLE;
                END IF;

            WHEN PAGE_PG       =>
                IF rising_edge(PDONE) THEN
                    next_state <= IDLE;
                END IF;

            WHEN OTP_PG       =>
                IF rising_edge(PDONE) THEN
                    next_state <= IDLE;
                END IF;

            WHEN BULK_ER | SECTOR_ER | P4_ER | P8_ER  =>
                IF rising_edge(EDONE) THEN
                    next_state <= IDLE;
                END IF;

            WHEN DP_DOWN_WAIT =>
                IF rising_edge(DP_out) THEN
                    next_state <= DP_DOWN;
                END IF;

            WHEN DP_DOWN     =>
                IF falling_edge(write) AND Instruct = RES_READ_ES THEN
                    next_state <= IDLE;
                END IF;

        END CASE;

    END PROCESS StateGen;

    ---------------------------------------------------------------------------
    --FSM Output generation and general funcionality
    ---------------------------------------------------------------------------
    Functional : PROCESS(write,read_out, WDONE, PDONE, EDONE, current_state,
                         CSNeg_ipd, HOLDNeg_pullup, Instruct, Address, WByte,
                         DP_out, RES_out, change_addr, PoweredUp, WPNeg_pullup)
        --Common Flash Interface Query codes
        TYPE CFItype   IS ARRAY (16#07# TO 16#50#) OF
                                              INTEGER RANGE -1 TO 16#FF#;
        TYPE WDataType IS ARRAY (0 TO 255) OF INTEGER RANGE -1 TO MaxData;

        VARIABLE CFI_array      : CFItype   := (OTHERS => -1);
        VARIABLE WData          : WDataType := (OTHERS => 0);
        VARIABLE WOTPData       : INTEGER RANGE -1 to MaxData;
        VARIABLE oe             : boolean := FALSE;

        VARIABLE AddrLo         : NATURAL;
        VARIABLE AddrHi         : NATURAL;
        VARIABLE Addr           : NATURAL;
        VARIABLE Addr_tmp       : NATURAL;

        VARIABLE read_addr      : NATURAL RANGE 0 TO AddrRANGE;
        VARIABLE data_out       : std_logic_vector(7 downto 0);
        VARIABLE ident_out      : std_logic_vector(647 downto 0);
        VARIABLE CFI_array_tmp  : std_logic_vector(591 downto 0);

        VARIABLE old_bit        : std_logic_vector(7 downto 0);
        VARIABLE new_bit        : std_logic_vector(7 downto 0);
        VARIABLE old_int        : INTEGER RANGE -1 to MaxData;
        VARIABLE new_int        : INTEGER RANGE -1 to MaxData;
        VARIABLE wr_cnt         : NATURAL RANGE 0 TO 255;

        VARIABLE sect           : NATURAL RANGE 0 TO SecNum;
        VARIABLE cnt            : NATURAL RANGE 0 TO 256 := 0;

    BEGIN
        -----------------------------------------------------------------------
        -- Functionality Section
        -----------------------------------------------------------------------

        oe := rising_edge(read_out) AND PoweredUp = '1';

        IF Instruct'EVENT THEN
            read_cnt := 0;
            fast_rd  <= true;
            rd_jid   <= false;
            dual     <= false;
            rd       <= false;
            IF Instruct = DH_READ OR Instruct = QH_READ THEN
                mpm_mode := TRUE;
            END IF;
        END IF;

        IF rising_edge(PoweredUp) THEN

            FREEZE := '0';
            --When BPNV is set to '1'. the BP2-0 bits in Status Register are
            --volatile and will be reset binary 111 after power-on reset
            IF BPNV = '1' THEN
                BP0 := '1';
                BP1 := '1';
                BP2 := '1';
                BP := BP2 & BP1 & BP0;
                change_BP <= '1', '0' AFTER 1 ns;
            END IF;
        END IF;

        IF rising_edge(change_addr) THEN
            read_addr := Address;
        END IF;

        IF RES_out'EVENT AND RES_out = '1' THEN
            RES_in <= '0';
        END IF;

        CASE current_state IS
            WHEN IDLE          =>
                IF falling_edge(write) THEN
                    read_cnt := 0;
                    IF RES_in = '1' AND Instruct /= DP THEN
                        ASSERT false
                            REPORT InstancePath & partID & "Command results" &
                                  " can be corrupted, a delay of tRES" &
                                  " currently in progress."
                            SEVERITY WARNING;
                    END IF;
                    IF Instruct = WREN THEN
                        WEL := '1';
                    ELSIF Instruct = WRDI THEN
                        WEL := '0';
                    ELSIF Instruct = WRR AND WEL = '1' THEN
                        IF not(SRWD='1' AND WPNeg_pullup='0' AND QUAD='0') THEN
                        -- can not execute if HPM is entered
                        -- or if WEL bit is zero
                            WSTART <= '1', '0' AFTER 1 ns;
                            WIP    := '1';
                        ELSE
                            WEL := '0';
                        END IF;
                    ELSIF (Instruct = PP OR Instruct = QPP) AND WEL = '1' THEN
                        sect := Address / 16#10000#;
                        IF Sec_Prot(sect) = '0' THEN
                            PSTART <= '1', '0' AFTER 1 ns;
                            INITIAL_CONFIG <= '1';
                            WIP := '1';
                            SA <= sect;
                            Addr := Address;
                            Addr_tmp := Address;
                            wr_cnt := Byte_number;
                            FOR I IN wr_cnt DOWNTO 0 LOOP
                                IF Viol /= '0' THEN
                                    WData(i) := -1;
                                ELSE
                                    WData(i) := WByte(i);
                                END IF;
                            END LOOP;
                        ELSE
                            WEL   := '0';
                        END IF;
                    ELSIF Instruct = OTPP AND WEL = '1' THEN
                        IF Address = 256 OR Address = 257 OR
                        ((Address >= 258 AND Address <= 273) AND
                        PR_LOCK1((Address-258)/8)='1') OR Address=274 OR
                        Address=275 OR ((Address>=276 AND Address<=531)
                        AND PR_LOCK2((Address-276)/16)='1') OR Address=532
                        OR Address=533 OR ((Address>=534 AND Address<=767)
                        AND PR_LOCK3((Address-534)/16) = '1') THEN
                            PSTART <= '1', '0' AFTER 1 ns;
                            WIP := '1';
                            Addr := Address;
                            IF Viol /= '0' THEN
                                WOTPData := -1;
                            ELSE
                                WOTPData := WOTPByte;
                            END IF;
                        ELSIF (Address < 100 OR Address > 767 ) THEN
                            P_ERR := '1';
                            WEL   := '0';
                        ELSE
                            WEL   := '0';
                        END IF;
                    ELSIF Instruct = SE AND WEL = '1' THEN
                        sect := Address / 16#10000#;
                        IF Sec_Prot(sect) = '0' THEN
                            ESTART <= '1', '0' AFTER 1 ns;
                            INITIAL_CONFIG <= '1';
                            WIP := '1';
                            Addr := Address;
                        ELSE
                            WEL   := '0';
                        END IF;
                    ELSIF Instruct = BE AND WEL = '1' THEN
                        IF (BP0='0' AND BP1='0' AND BP2='0') THEN
                            ESTART <= '1', '0' AFTER 1 ns;
                            INITIAL_CONFIG <= '1';
                            WIP := '1';
                         ELSE
                            WEL   := '0';
                        END IF;
                    ELSIF Instruct = P4E AND WEL = '1' THEN
                        sect := Address / 16#10000#;
                        IF ((sect=0 OR sect=1) AND TBPARM='0')
                        OR ((sect=SecNum OR sect=SecNum-1)
                        AND TBPARM='1') THEN
                            IF Sec_Prot(sect) = '0' THEN
                                ESTART <= '1', '0' AFTER 1 ns;
                                INITIAL_CONFIG <= '1';
                                WIP := '1';
                                Addr := Address;
                            ELSE
                                WEL   := '0';
                            END IF;
                        ELSE
                            E_ERR := '1';
                            WEL   := '0';
                        END IF;
                    ELSIF Instruct = P8E AND WEL = '1' THEN
                        sect := Address / 16#10000#;
                        IF ((sect=0 OR sect=1) AND TBPARM='0')
                        OR ((sect=SecNum OR sect=SecNum-1)
                        AND TBPARM='1') THEN
                            IF Sec_Prot(sect) = '0' THEN
                                ESTART <= '1', '0' AFTER 1 ns;
                                INITIAL_CONFIG <= '1';
                                WIP := '1';
                                Addr := Address;
                            ELSE
                                WEL   := '0';
                            END IF;
                        ELSE
                            E_ERR := '1';
                            WEL   := '0';
                        END IF;
                    ELSIF Instruct = CLSR THEN
                       E_ERR := '0';
                       P_ERR := '0';
                    ELSIF Instruct = DP THEN
                        RES_in <= '0';
                        DP_in  <= '1';
                    ELSIF Instruct = RES_READ_ES THEN
                        RES_in <= '1';
                    END IF;

                ELSIF oe AND RES_in = '0' THEN
                    IF Instruct = RDSR THEN
                        --Read Status Register
                        SOut_zd <= Status_reg(7-read_cnt);
                        read_cnt := read_cnt + 1;
                        IF read_cnt = 8 THEN
                            read_cnt := 0;
                        END IF;
                    ELSIF Instruct = RCR THEN
                        --Read Security Conf. Register
                        SOut_zd <= Sec_conf_reg(7-read_cnt);
                        read_cnt := read_cnt + 1;
                        IF read_cnt = 8 THEN
                            read_cnt := 0;
                        END IF;
                    ELSIF Instruct = READ OR Instruct = FAST_READ THEN
                        --Read Memory array
                        IF Instruct = READ THEN
                            fast_rd <= false;
                            rd_jid  <= false;
                            rd      <= true;
                        END IF;
                        data_out := to_slv(Mem(read_addr),8);
                        SOut_zd <= data_out(7-read_cnt);
                        read_cnt := read_cnt + 1;
                        IF read_cnt = 8 THEN
                            read_cnt := 0;
                            IF read_addr = AddrRANGE THEN
                                read_addr := 0;
                            ELSE
                                read_addr := read_addr + 1;
                            END IF;
                        END IF;
                    ELSIF Instruct = DUAL_READ OR Instruct = DH_READ THEN
                        --Read Memory array
                        fast_rd  <= false;
                        rd       <= false;
                        rd_jid   <= false;
                        dual     <= true;
                        data_out := to_slv(Mem(read_addr),8);
                        SOut_zd  <= data_out(7-2*read_cnt);
                        SIOut_zd <= data_out(6-2*read_cnt);
                        read_cnt := read_cnt + 1;
                        IF read_cnt = 4 THEN
                            read_cnt := 0;
                            IF read_addr = AddrRANGE THEN
                                read_addr := 0;
                            ELSE
                                read_addr := read_addr + 1;
                            END IF;
                        END IF;
                    ELSIF (Instruct = QUAD_READ OR Instruct = QH_READ)
                    AND QUAD = '1' THEN
                        --Read Memory array
                        fast_rd <= false;
                        rd      <= false;
                        rd_jid  <= false;
                        dual    <= true;
                        data_out := to_slv(Mem(read_addr),8);
                        HOLDNegOut_zd   <= data_out(7-4*read_cnt);
                        WPNegOut_zd     <= data_out(6-4*read_cnt);
                        SOut_zd         <= data_out(5-4*read_cnt);
                        SIOut_zd        <= data_out(4-4*read_cnt);
                        read_cnt := read_cnt + 1;
                        IF read_cnt = 2 THEN
                            read_cnt := 0;
                            IF read_addr = AddrRANGE THEN
                                read_addr := 0;
                            ELSE
                                read_addr := read_addr + 1;
                            END IF;
                        END IF;
                    ELSIF Instruct = OTPR  THEN
                        IF (read_addr>=OTPLoAddr) AND (read_addr<=OTPHiAddr)
                        THEN
                            --Read OTP Memory array
                            fast_rd <= true;
                            rd_jid  <= false;
                            rd      <= false;
                            data_out := to_slv(OTPMem(read_addr),8);
                            SOut_zd <= data_out(7-read_cnt);
                            read_cnt := read_cnt + 1;
                            IF read_cnt = 8 THEN
                                read_cnt := 0;
                                read_addr := read_addr + 1;
                            END IF;
                        ELSIF (read_addr > OTPHiAddr) THEN
                        --OTP Read operation will not wrap to the
                        --starting address after the OTP address is at
                        --its maximum or Read Password Protection Mode
                        --is selected; instead, the data beyond the
                        --maximum OTP address will be undefined.
                            SOut_zd <= 'U';
                            read_cnt := read_cnt + 1;
                            IF read_cnt = 8 THEN
                                read_cnt := 0;
                            END IF;
                        END IF;
                    ELSIF Instruct = RDID THEN
                        --Read Device ID
                        --can be terminated by driving CSNeg high
                        --at any time
                        fast_rd <= false;
                        rd_jid  <= true;
                        rd      <= false;
                        ident_out := to_slv(Manuf_ID,8) & to_slv(DeviceID,16) &
                        to_slv(ExtendedBytes,8) & to_slv(ReservedBytes,8) &
                        to_slv(ReservedBytes,8) & to_slv(ReservedBytes,8) &
                        CFI_array_tmp;
                        SOut_zd <= ident_out(647-read_cnt);
                        read_cnt  := read_cnt + 1;
                        IF read_cnt = 648 THEN
                            read_cnt := 0;
                        END IF;
                    ELSIF Instruct = READ_ID THEN
                        --Read Manufacturer and Device ID
                        IF read_addr MOD 2 = 0 THEN
                            data_out := to_slv(Manuf_ID,8);
                            SOut_zd <= data_out(7 - read_cnt);
                            read_cnt := read_cnt + 1;
                            IF read_cnt = 8 THEN
                                read_cnt := 0;
                                read_addr := read_addr + 1;
                            END IF;
                        ELSE
                            data_out := to_slv(ES,8);
                            SOut_zd <= data_out(7 - read_cnt);
                            read_cnt := read_cnt + 1;
                            IF read_cnt = 8 THEN
                                read_cnt := 0;
                                read_addr := 0;
                            END IF;
                        END IF;
                    END IF;
                ELSIF oe AND RES_in = '1' THEN
                    SOut_zd <= 'X';
                    read_cnt := read_cnt + 1;
                    IF read_cnt = 8 THEN
                        read_cnt := 0;
                    END IF;
                    ASSERT false
                        REPORT InstancePath & partID & "Command results" &
                              " can be corrupted, a delay of tRES" &
                              " currently in progress."
                        SEVERITY WARNING;
                END IF;

            WHEN WRITE_SR      =>
                IF oe AND Instruct = RDSR THEN
                    --Read Status Register
                    SOut_zd <= Status_reg(7-read_cnt);
                    read_cnt := read_cnt + 1;
                    IF read_cnt = 8 THEN
                        read_cnt := 0;
                    END IF;
                END IF;
                IF oe AND Instruct = RCR THEN
                    SOut_zd <= Sec_conf_reg(7-read_cnt);
                    read_cnt := read_cnt + 1;
                    IF read_cnt = 8 THEN
                        read_cnt := 0;
                    END IF;
                END IF;

                IF WDONE = '1' THEN
                    WIP  := '0';
                    WEL  := '0';
                    SRWD := Status_reg_in(7);--MSB first

                    IF FREEZE='0' THEN
                    --The Freeze Bit, when set to 1, locks the current
                    --state of the BP2-0 bits in Status Register,
                    --the TBPROT and TBPARM bits in the Config Register
                    --As long as the FREEZE bit remains cleared to logic
                    --'0', the other bits of the Configuration register
                    --including FREEZE are writeable.

                        BP2  := Status_reg_in(4);
                        BP1  := Status_reg_in(3);
                        BP0  := Status_reg_in(2);

                        BP   := BP2 & BP1 & BP0;

                        IF cfg_write = '1' THEN

                            FREEZE  := Sec_conf_reg_in(0);--MSB first

                            IF TBPARM = '0' AND INITIAL_CONFIG = '0' THEN
                                TBPARM  := Sec_conf_reg_in(2);
                            END IF;

                            IF TBPROT = '0' AND INITIAL_CONFIG = '0' THEN
                                TBPROT  := Sec_conf_reg_in(5);
                            END IF;

                        END IF;

                        change_BP <= '1', '0' AFTER 1 ns;
                    END IF;

                    IF cfg_write = '1' THEN
                        QUAD := Sec_conf_reg_in(1);

                        IF BPNV = '0' THEN
                            BPNV := Sec_conf_reg_in(3);
                        END IF;
                    END IF;
                END IF;

            WHEN PAGE_PG       =>
                IF oe AND Instruct = RDSR THEN
                    --Read Status Register
                    SOut_zd <= Status_reg(7-read_cnt);
                    read_cnt := read_cnt + 1;
                    IF read_cnt = 8 THEN
                        read_cnt := 0;
                    END IF;
                END IF;
                IF oe AND Instruct = RCR THEN
                    SOut_zd <= Sec_conf_reg(7-read_cnt);
                    read_cnt := read_cnt + 1;
                    IF read_cnt = 8 THEN
                        read_cnt := 0;
                    END IF;
                END IF;

                ADDRHILO_PG(AddrLo, AddrHi, Addr);
                cnt := 0;

                FOR i IN 0 TO wr_cnt LOOP
                    new_int := WData(i);
                    old_int := Mem(Addr + i - cnt);
                    IF new_int > -1 THEN
                        new_bit := to_slv(new_int,8);
                        IF old_int > -1 THEN
                            old_bit := to_slv(old_int,8);
                            FOR j IN 0 TO 7 LOOP
                                IF old_bit(j) = '0' THEN
                                    new_bit(j) := '0';
                                END IF;
                            END LOOP;
                            new_int := to_nat(new_bit);
                        END IF;
                        WData(i) := new_int;
                    ELSE
                        WData(i) := -1;
                    END IF;

                    Mem(Addr + i - cnt) :=  -1;

                    IF (Addr + i) = AddrHi THEN
                        Addr := AddrLo;
                        cnt := i + 1;
                    END IF;
                END LOOP;
                cnt :=0;
                IF PDONE = '1' THEN
                    WIP := '0';
                    WEL := '0';
                    FOR i IN 0 TO wr_cnt LOOP
                        Mem(Addr_tmp + i - cnt) := WData(i);
                        IF (Addr_tmp + i) = AddrHi THEN
                            Addr_tmp := AddrLo;
                            cnt := i + 1;
                        END IF;
                    END LOOP;
                END IF;

            WHEN OTP_PG     =>
                IF oe AND Instruct = RDSR THEN
                    --Read Status Register
                    SOut_zd <= Status_reg(7-read_cnt);
                    read_cnt := read_cnt + 1;
                    IF read_cnt = 8 THEN
                        read_cnt := 0;
                    END IF;
                END IF;
                IF oe AND Instruct = RCR THEN
                    SOut_zd <= Sec_conf_reg(7-read_cnt);
                    read_cnt := read_cnt + 1;
                    IF read_cnt = 8 THEN
                        read_cnt := 0;
                    END IF;
                END IF;

                new_int := WOTPData;
                old_int := OTPMem(Addr);
                IF new_int > -1 THEN
                    new_bit := to_slv(new_int,8);
                    IF old_int > -1 THEN
                        old_bit := to_slv(old_int,8);
                        FOR j IN 0 TO 7 LOOP
                            IF old_bit(j) = '0' THEN
                                new_bit(j) := '0';
                            END IF;
                        END LOOP;
                        new_int := to_nat(new_bit);
                    END IF;
                    WOTPData := new_int;
                ELSE
                    WOTPData := -1;
                END IF;
                OTPMem(Addr) :=  -1;
                IF PDONE = '1' THEN
                    WIP := '0';
                    WEL := '0';
                    OTPMem(Addr) := WOTPData;
                    PR_LOCK1 := to_slv(OTPMem(257),8) & to_slv(OTPMem(256),8);
                    PR_LOCK2 := to_slv(OTPMem(275),8) & to_slv(OTPMem(274),8);
                    PR_LOCK3 := to_slv(OTPMem(533),8) & to_slv(OTPMem(532),8);
                END IF;

            WHEN SECTOR_ER     =>
                IF oe AND Instruct = RDSR THEN
                    --Read Status Register
                    SOut_zd <= Status_reg(7-read_cnt);
                    read_cnt := read_cnt + 1;
                    IF read_cnt = 8 THEN
                        read_cnt := 0;
                    END IF;
                END IF;
                IF oe AND Instruct = RCR THEN
                    SOut_zd <= Sec_conf_reg(7-read_cnt);
                    read_cnt := read_cnt + 1;
                    IF read_cnt = 8 THEN
                        read_cnt := 0;
                    END IF;
                END IF;

                ADDRHILO_SEC(AddrLo, AddrHi, Addr);
                FOR i IN AddrLo TO AddrHi LOOP
                    Mem(i) := -1;
                END LOOP;
                IF EDONE = '1' THEN
                    WIP := '0';
                    WEL := '0';
                    FOR i IN AddrLo TO AddrHi LOOP
                        Mem(i) :=  MaxData;
                    END LOOP;
                END IF;

            WHEN BULK_ER       =>
                IF oe AND Instruct = RDSR THEN
                    --Read Status Register
                    SOut_zd <= Status_reg(7-read_cnt);
                    read_cnt := read_cnt + 1;
                    IF read_cnt = 8 THEN
                        read_cnt := 0;
                    END IF;
                END IF;
                IF oe AND Instruct = RCR THEN
                    SOut_zd <= Sec_conf_reg(7-read_cnt);
                    read_cnt := read_cnt + 1;
                    IF read_cnt = 8 THEN
                        read_cnt := 0;
                    END IF;
                END IF;
                FOR i IN 0 TO AddrRANGE LOOP
                    Mem(i) := -1;
                END LOOP;
                IF EDONE = '1' THEN
                    WIP := '0';
                    WEL := '0';
                    FOR i IN 0 TO AddrRANGE LOOP
                        Mem(i) :=  MaxData;
                    END LOOP;
                END IF;

            WHEN P4_ER     =>
                IF oe AND Instruct = RDSR THEN
                    --Read Status Register
                    SOut_zd <= Status_reg(7-read_cnt);
                    read_cnt := read_cnt + 1;
                    IF read_cnt = 8 THEN
                        read_cnt := 0;
                    END IF;
                END IF;
                IF oe AND Instruct = RCR THEN
                    SOut_zd <= Sec_conf_reg(7-read_cnt);
                    read_cnt := read_cnt + 1;
                    IF read_cnt = 8 THEN
                        read_cnt := 0;
                    END IF;
                END IF;
                ADDRHILO_PB4(AddrLo, AddrHi, Addr);
                FOR i IN AddrLo TO AddrHi LOOP
                    Mem(i) := -1;
                END LOOP;
                IF EDONE = '1' THEN
                    WIP := '0';
                    WEL := '0';
                    FOR i IN AddrLo TO AddrHi LOOP
                        Mem(i) :=  MaxData;
                    END LOOP;
                END IF;

            WHEN P8_ER     =>
                IF oe AND Instruct = RDSR THEN
                    --Read Status Register
                    SOut_zd <= Status_reg(7-read_cnt);
                    read_cnt := read_cnt + 1;
                    IF read_cnt = 8 THEN
                        read_cnt := 0;
                    END IF;
                END IF;
                IF oe AND Instruct = RCR THEN
                    SOut_zd <= Sec_conf_reg(7-read_cnt);
                    read_cnt := read_cnt + 1;
                    IF read_cnt = 8 THEN
                        read_cnt := 0;
                    END IF;
                END IF;
                ADDRHILO_PB8(AddrLo, AddrHi, Addr);
                FOR i IN AddrLo TO AddrHi LOOP
                    Mem(i) := -1;
                END LOOP;
                IF EDONE = '1' THEN
                    WIP := '0';
                    WEL := '0';
                    FOR i IN AddrLo TO AddrHi LOOP
                        Mem(i) :=  MaxData;
                    END LOOP;
                END IF;

            WHEN DP_DOWN_WAIT =>
                IF rising_edge(DP_out) THEN
                    DP_in <= '0';
                ELSIF DP_in = '1' AND Instruct'EVENT THEN
                    ASSERT false
                        REPORT InstancePath & partID & "Command results" &
                              " can be corrupted, a delay of tPD" &
                              " currently in progress."
                        SEVERITY WARNING;
                END IF;

            WHEN DP_DOWN     =>
                IF falling_edge(write) THEN
                    IF Instruct = RES_READ_ES THEN
                        RES_in <= '1';
                    END IF;
                ELSIF oe AND Instruct = RES_READ_ES THEN
                    --Read Electronic Signature
                    data_out := to_slv(ES,8);
                    SOut_zd <= data_out(7 - read_cnt);
                    read_cnt := read_cnt + 1;
                    IF read_cnt = 8 THEN
                        read_cnt := 0;
                    END IF;
                END IF;

        END CASE;

        --Output Disable Control
        IF (CSNeg_ipd = '1') THEN
            SIOut_zd        <= 'Z';
            HOLDNegOut_zd   <= 'Z';
            WPNegOut_zd     <= 'Z';
            SOut_zd         <= 'Z';
        END IF;

        IF NOW = 0 ns THEN
            CFI_array(16#07#) := 16#FF#;
            CFI_array(16#08#) := 16#FF#;
            CFI_array(16#09#) := 16#FF#;
            CFI_array(16#0A#) := 16#FF#;
            CFI_array(16#0B#) := 16#FF#;
            CFI_array(16#0C#) := 16#FF#;
            CFI_array(16#0D#) := 16#FF#;
            CFI_array(16#0E#) := 16#FF#;
            CFI_array(16#0F#) := 16#FF#;
            --Product Group CFI Query Identification String
            CFI_array(16#10#) := 16#51#;
            CFI_array(16#11#) := 16#52#;
            CFI_array(16#12#) := 16#59#;
            CFI_array(16#13#) := 16#02#;
            CFI_array(16#14#) := 16#00#;
            CFI_array(16#15#) := 16#40#;
            CFI_array(16#16#) := 16#00#;
            CFI_array(16#17#) := 16#00#;
            CFI_array(16#18#) := 16#00#;
            CFI_array(16#19#) := 16#00#;
            CFI_array(16#1A#) := 16#00#;
            --Product Group CFI system interface string
            CFI_array(16#1B#) := 16#27#;
            CFI_array(16#1C#) := 16#36#;
            CFI_array(16#1D#) := 16#00#;
            CFI_array(16#1E#) := 16#00#;
            CFI_array(16#1F#) := 16#0B#;
            CFI_array(16#20#) := 16#0B#;
            CFI_array(16#21#) := 16#09#;
            CFI_array(16#22#) := 16#10#;
            CFI_array(16#23#) := 16#01#;
            CFI_array(16#24#) := 16#01#;
            CFI_array(16#25#) := 16#02#;
            CFI_array(16#26#) := 16#01#;
            --Product Group CFI Device Geometry Definition
            CFI_array(16#27#) := 16#17#;
            CFI_array(16#28#) := 16#05#;
            CFI_array(16#29#) := 16#05#;
            CFI_array(16#2A#) := 16#08#;
            CFI_array(16#2B#) := 16#00#;
            CFI_array(16#2C#) := 16#02#;
            CFI_array(16#2D#) := 16#1F#;
            CFI_array(16#2E#) := 16#00#;
            CFI_array(16#2F#) := 16#10#;
            CFI_array(16#30#) := 16#00#;
            CFI_array(16#31#) := 16#7D#;
            CFI_array(16#32#) := 16#00#;
            CFI_array(16#33#) := 16#00#;
            CFI_array(16#34#) := 16#01#;
            CFI_array(16#35#) := 16#00#;
            CFI_array(16#36#) := 16#00#;
            CFI_array(16#37#) := 16#00#;
            CFI_array(16#38#) := 16#00#;
            CFI_array(16#39#) := 16#00#;
            CFI_array(16#3A#) := 16#00#;
            CFI_array(16#3B#) := 16#00#;
            CFI_array(16#3C#) := 16#00#;
            CFI_array(16#3D#) := 16#FF#;
            CFI_array(16#3E#) := 16#FF#;
            CFI_array(16#3F#) := 16#FF#;
            --Product Group CFI Primary Vendor-Specific Extended Query
            CFI_array(16#40#) := 16#50#;
            CFI_array(16#41#) := 16#52#;
            CFI_array(16#42#) := 16#49#;
            CFI_array(16#43#) := 16#31#;
            CFI_array(16#44#) := 16#33#;
            CFI_array(16#45#) := 16#15#;
            CFI_array(16#46#) := 16#00#;
            CFI_array(16#47#) := 16#02#;
            CFI_array(16#48#) := 16#00#;
            CFI_array(16#49#) := 16#05#;
            CFI_array(16#4A#) := 16#00#;
            CFI_array(16#4B#) := 16#01#;
            CFI_array(16#4C#) := 16#03#;
            CFI_array(16#4D#) := 16#85#;
            CFI_array(16#4E#) := 16#95#;
            CFI_array(16#4F#) := 16#07#;
            CFI_array(16#50#) := 16#00#;
        END IF;

        CFI_array_tmp :=to_slv(CFI_array(16#07#), 8) &
                        to_slv(CFI_array(16#08#), 8) &
                        to_slv(CFI_array(16#09#), 8) &
                        to_slv(CFI_array(16#0A#), 8) &
                        to_slv(CFI_array(16#0B#), 8) &
                        to_slv(CFI_array(16#0C#), 8) &
                        to_slv(CFI_array(16#0D#), 8) &
                        to_slv(CFI_array(16#0E#), 8) &
                        to_slv(CFI_array(16#0F#), 8) &
                        to_slv(CFI_array(16#10#), 8) &
                        to_slv(CFI_array(16#11#), 8) &
                        to_slv(CFI_array(16#12#), 8) &
                        to_slv(CFI_array(16#13#), 8) &
                        to_slv(CFI_array(16#14#), 8) &
                        to_slv(CFI_array(16#15#), 8) &
                        to_slv(CFI_array(16#16#), 8) &
                        to_slv(CFI_array(16#17#), 8) &
                        to_slv(CFI_array(16#18#), 8) &
                        to_slv(CFI_array(16#19#), 8) &
                        to_slv(CFI_array(16#1A#), 8) &
                        to_slv(CFI_array(16#1B#), 8) &
                        to_slv(CFI_array(16#1C#), 8) &
                        to_slv(CFI_array(16#1D#), 8) &
                        to_slv(CFI_array(16#1E#), 8) &
                        to_slv(CFI_array(16#1F#), 8) &
                        to_slv(CFI_array(16#20#), 8) &
                        to_slv(CFI_array(16#21#), 8) &
                        to_slv(CFI_array(16#22#), 8) &
                        to_slv(CFI_array(16#23#), 8) &
                        to_slv(CFI_array(16#24#), 8) &
                        to_slv(CFI_array(16#25#), 8) &
                        to_slv(CFI_array(16#26#), 8) &
                        to_slv(CFI_array(16#27#), 8) &
                        to_slv(CFI_array(16#28#), 8) &
                        to_slv(CFI_array(16#29#), 8) &
                        to_slv(CFI_array(16#2A#), 8) &
                        to_slv(CFI_array(16#2B#), 8) &
                        to_slv(CFI_array(16#2C#), 8) &
                        to_slv(CFI_array(16#2D#), 8) &
                        to_slv(CFI_array(16#2E#), 8) &
                        to_slv(CFI_array(16#2F#), 8) &
                        to_slv(CFI_array(16#30#), 8) &
                        to_slv(CFI_array(16#31#), 8) &
                        to_slv(CFI_array(16#32#), 8) &
                        to_slv(CFI_array(16#33#), 8) &
                        to_slv(CFI_array(16#34#), 8) &
                        to_slv(CFI_array(16#35#), 8) &
                        to_slv(CFI_array(16#36#), 8) &
                        to_slv(CFI_array(16#37#), 8) &
                        to_slv(CFI_array(16#38#), 8) &
                        to_slv(CFI_array(16#39#), 8) &
                        to_slv(CFI_array(16#3A#), 8) &
                        to_slv(CFI_array(16#3B#), 8) &
                        to_slv(CFI_array(16#3C#), 8) &
                        to_slv(CFI_array(16#3D#), 8) &
                        to_slv(CFI_array(16#3E#), 8) &
                        to_slv(CFI_array(16#3F#), 8) &
                        to_slv(CFI_array(16#40#), 8) &
                        to_slv(CFI_array(16#41#), 8) &
                        to_slv(CFI_array(16#42#), 8) &
                        to_slv(CFI_array(16#43#), 8) &
                        to_slv(CFI_array(16#44#), 8) &
                        to_slv(CFI_array(16#45#), 8) &
                        to_slv(CFI_array(16#46#), 8) &
                        to_slv(CFI_array(16#47#), 8) &
                        to_slv(CFI_array(16#48#), 8) &
                        to_slv(CFI_array(16#49#), 8) &
                        to_slv(CFI_array(16#4A#), 8) &
                        to_slv(CFI_array(16#4B#), 8) &
                        to_slv(CFI_array(16#4C#), 8) &
                        to_slv(CFI_array(16#4D#), 8) &
                        to_slv(CFI_array(16#4E#), 8) &
                        to_slv(CFI_array(16#4F#), 8) &
                        to_slv(CFI_array(16#50#), 8);

    END PROCESS Functional;

    Protect : PROCESS(change_BP)
    BEGIN
        IF rising_edge(change_BP) THEN

            CASE BP IS
                WHEN "000" =>
                    Sec_Prot := (others => '0');
                WHEN "001" =>
                    IF TBPROT = '0' THEN
                        Sec_Prot(SecNum downto (SecNum+1)*63/64)
                                                    := (others => '1');
                        Sec_Prot((SecNum+1)*63/64 - 1 downto 0)
                                                    := (others => '0');
                    ELSE
                        Sec_Prot((SecNum+1)/64 - 1 downto 0)
                                                    := (others => '1');
                        Sec_Prot(SecNum downto (SecNum+1)/64)
                                                    := (others => '0');
                    END IF;
                WHEN "010" =>
                    IF TBPROT =  '0' THEN
                        Sec_Prot(SecNum downto (SecNum+1)*31/32)
                                                    := (others => '1');
                        Sec_Prot((SecNum+1)*31/32 - 1 downto 0)
                                                    := (others => '0');
                    ELSE
                        Sec_Prot((SecNum+1)/32 - 1 downto 0)
                                                    := (others => '1');
                        Sec_Prot(SecNum downto (SecNum+1)/32)
                                                    := (others => '0');
                    END IF;
                WHEN "011" =>
                    IF TBPROT =  '0' THEN
                        Sec_Prot(SecNum downto (SecNum+1)*15/16)
                                                    := (others => '1');
                        Sec_Prot((SecNum+1)*15/16 - 1 downto 0)
                                                    := (others => '0');
                    ELSE
                        Sec_Prot((SecNum+1)/16 - 1 downto 0)
                                                    := (others => '1');
                        Sec_Prot(SecNum downto (SecNum+1)/16)
                                                    := (others => '0');
                    END IF;
                WHEN "100" =>
                    IF TBPROT =  '0' THEN
                        Sec_Prot(SecNum downto (SecNum+1)*7/8)
                                                    := (others => '1');
                        Sec_Prot((SecNum+1)*7/8 - 1 downto 0)
                                                    := (others => '0');
                    ELSE
                        Sec_Prot((SecNum+1)/8 - 1 downto 0)
                                                    := (others => '1');
                        Sec_Prot(SecNum downto (SecNum+1)/8)
                                                    := (others => '0');
                    END IF;
                WHEN "101" =>
                    IF TBPROT =  '0' THEN
                        Sec_Prot(SecNum downto (SecNum+1)*3/4)
                                                    := (others => '1');
                        Sec_Prot((SecNum+1)*3/4 - 1 downto 0)
                                                    := (others => '0');
                    ELSE
                        Sec_Prot((SecNum+1)/4 - 1 downto 0)
                                                    := (others => '1');
                        Sec_Prot(SecNum downto (SecNum+1)/4)
                                                    := (others => '0');
                    END IF;
                WHEN "110" =>
                    IF TBPROT =  '0' THEN
                        Sec_Prot(SecNum downto (SecNum+1)/2)
                                                    := (others => '1');
                        Sec_Prot((SecNum+1)/2 - 1 downto 0)
                                                    := (others => '0');
                    ELSE
                        Sec_Prot((SecNum+1)/2 - 1 downto 0)
                                                    := (others => '1');
                        Sec_Prot(SecNum downto (SecNum+1)/2)
                                                    := (others => '0');
                    END IF;
                WHEN OTHERS =>
                    Sec_Prot := (others => '1');
            END CASE;
        END IF;
    END PROCESS Protect;

    HOLD_FRAME_ON_PO_ZD : PROCESS(SOut_zd, SIOut_zd, HOLDNeg_pullup)
    BEGIN
        IF (HOLDNeg_pullup = '0' AND QUAD /= '1') THEN
            hold_mode := TRUE;
            SIOut_z <= 'Z';
            SOut_z  <= 'Z';
        ELSE
            IF hold_mode THEN
                SIOut_z <= SIOut_zd AFTER tpd_HOLDNeg_SO(trz0);
                SOut_z  <= SOut_zd AFTER tpd_HOLDNeg_SO(trz0);
                hold_mode := FALSE;
            ELSE
                SIOut_z <= SIOut_zd;
                SOut_z  <= SOut_zd;
                hold_mode := FALSE;
            END IF;
        END IF;
    END PROCESS HOLD_FRAME_ON_PO_ZD;

    HOLD_PULL_UP : PROCESS(HOLDNegIn)
    BEGIN
        IF (QUAD = '0') THEN
            IF (HOLDNegIn = 'Z') THEN
                HOLDNeg_pullup <= '1';
            ELSE
                HOLDNeg_pullup <= HOLDNegIn;
            END IF;
        END IF;
    END PROCESS HOLD_PULL_UP;

    WP_PULL_UP : PROCESS(WPNegIn)
    BEGIN
        IF (QUAD = '0') THEN
            IF (WPNegIn = 'Z') THEN
                WPNeg_pullup <= '1';
            ELSE
                WPNeg_pullup <= WPNegIn;
            END IF;
        END IF;
    END PROCESS WP_PULL_UP;

    ---------------------------------------------------------------------------
    ---- File Read Section - Preload Control
    ---------------------------------------------------------------------------
    MemPreload : PROCESS

        -- text file input variables
        FILE mem_file         : text  is  mem_file_name;
        FILE otp_file        : text  is  otp_file_name;
        VARIABLE ind         : NATURAL RANGE 0 TO AddrRANGE := 0;
        VARIABLE secsi_ind   : NATURAL RANGE 16#100# TO 16#2FF# := 16#100#;
        VARIABLE buf         : line;

    BEGIN
    ---------------------------------------------------------------------------
    --s25fl064p memory preload file format
-----------------------------------
    ---------------------------------------------------------------------------
    --   /       - comment
    --   @aaaaaa - <aaaaaa> stands for address
    --   dd      - <dd> is byte to be written at Mem(aaaaaa++)
    --             (aaaaaa is incremented at every load)
    --   only first 1-7 columns are loaded. NO empty lines !!!!!!!!!!!!!!!!
    ---------------------------------------------------------------------------

         -- memory preload
        IF (mem_file_name /= "none" AND UserPreload) THEN
            ind := 0;
            Mem := (OTHERS => MaxData);
            WHILE (not ENDFILE (mem_file)) LOOP
                READLINE (mem_file, buf);
                IF buf(1) = '/' THEN
                    NEXT;
                ELSIF buf(1) = '@' THEN
                    IF ind > AddrRANGE THEN
                        ASSERT false
                            REPORT "Given preload address is out of" &
                                   "memory address range"
                            SEVERITY warning;
                    ELSE
                        ind := h(buf(2 to 7)); --address
                    END IF;
                ELSE
                    Mem(ind) := h(buf(1 to 2));
                    ind := ind + 1;
                END IF;
            END LOOP;
        END IF;

    ---------------------------------------------------------------------------
    --s25fl064p_otp memory preload file format
-----------------------------------
    ---------------------------------------------------------------------------
    --   /       - comment
    --   @aaa - <aaa> stands for address
    --   dd      - <dd> is byte to be written at OTPMem(aaa++)
    --             (aaa is incremented at every load)
    --   only first 1-4 columns are loaded. NO empty lines !!!!!!!!!!!!!!!!
    ---------------------------------------------------------------------------

         -- memory preload
        IF (otp_file_name /= "none" AND UserPreload) THEN
            secsi_ind := 16#100#;
            OTPMem := (OTHERS => MaxData);
            WHILE (not ENDFILE (otp_file)) LOOP
                READLINE (otp_file, buf);
                IF buf(1) = '/' THEN
                    NEXT;
                ELSIF buf(1) = '@' THEN
                    IF secsi_ind > 16#2FF# OR secsi_ind < 16#100# THEN
                        ASSERT false
                            REPORT "Given preload address is out of" &
                                   "OTP address range"
                            SEVERITY warning;
                    ELSE
                        secsi_ind := h(buf(2 to 4)); --address
                    END IF;
                ELSE
                    OTPMem(secsi_ind) := h(buf(1 to 2));
                    PR_LOCK1 := to_slv(OTPMem(257),8) & to_slv(OTPMem(256),8);
                    PR_LOCK2 := to_slv(OTPMem(275),8) & to_slv(OTPMem(274),8);
                    PR_LOCK3 := to_slv(OTPMem(533),8) & to_slv(OTPMem(532),8);
                    secsi_ind := secsi_ind + 1;
                END IF;
            END LOOP;
        END IF;

        WAIT;
    END PROCESS MemPreload;

    ----------------------------------------------------------------------------
    -- Path Delay Section
    ----------------------------------------------------------------------------

    S_Out_PathDelay_Gen : PROCESS(SOut_z)

            VARIABLE SO_GlitchData : VitalGlitchDataType;
        BEGIN
            VitalPathDelay01Z (
                OutSignal       => SOut,
                OutSignalName   => "PO",
                OutTemp         => SOut_z,
                GlitchData      => SO_GlitchData,
                Paths           => (
                    0 => (InputChangeTime => SCK_ipd'LAST_EVENT,
                        PathDelay       => VitalExtendtofillDelay(tpd_SCK_SO),
                        PathCondition   => SOut_z /= 'Z'
                                           AND (NOT dual)),
                    1 => (InputChangeTime => SCK_ipd'LAST_EVENT,
                        PathDelay       => VitalExtendtofillDelay(tpd_SCK_SI),
                        PathCondition   => SOut_z /= 'Z'
                                           AND dual),
                    2 => (InputChangeTime => CSNeg_ipd'LAST_EVENT,
                        PathDelay       => tpd_CSNeg_SO,
                        PathCondition   => CSNeg_ipd = '1'),
                    3 => (InputChangeTime => HOLDNegIn'LAST_EVENT,
                        PathDelay       => tpd_HOLDNeg_SO,
                        PathCondition   => TRUE)
                )
            );
        END PROCESS;

    SI_Out_PathDelay : PROCESS(SIOut_z)

            VARIABLE SI_GlitchData : VitalGlitchDataType;
        BEGIN
            VitalPathDelay01Z (
                OutSignal       => SIOut,
                OutSignalName   => "SI",
                OutTemp         => SIOut_z,
                GlitchData      => SI_GlitchData,
                Paths           => (
                    0 => (InputChangeTime => SCK_ipd'LAST_EVENT,
                        PathDelay       => VitalExtendtofillDelay(tpd_SCK_SI),
                        PathCondition   => SIOut_z /= 'Z' AND dual),
                    1 => (InputChangeTime => CSNeg_ipd'LAST_EVENT,
                        PathDelay       => tpd_CSNeg_SO,
                        PathCondition   => CSNeg_ipd = '1' AND dual),
                    2 => (InputChangeTime => HOLDNegIn'LAST_EVENT,
                        PathDelay       => tpd_HOLDNeg_SO,
                        PathCondition   => dual)
                )
            );
        END PROCESS;

    HOLD_Out_PathDelay : PROCESS(HOLDNegOut_zd)

            VARIABLE HOLD_GlitchData : VitalGlitchDataType;
        BEGIN
            VitalPathDelay01Z (
                OutSignal       => HOLDNegOut,
                OutSignalName   => "HOLDNeg",
                OutTemp         => HOLDNegOut_zd,
                GlitchData      => HOLD_GlitchData,
                Paths           => (
                    0 => (InputChangeTime => SCK_ipd'LAST_EVENT,
                        PathDelay       => VitalExtendtofillDelay(tpd_SCK_SI),
                        PathCondition   => HOLDNegOut_zd /= 'Z' AND dual
                                           AND QUAD = '1'),
                    1 => (InputChangeTime => CSNeg_ipd'LAST_EVENT,
                        PathDelay       => tpd_CSNeg_SO,
                        PathCondition   => CSNeg_ipd = '1' AND dual
                                           AND QUAD = '1')
                )
            );
        END PROCESS;

    WP_Out_PathDelay : PROCESS(WPNegOut_zd)

            VARIABLE WP_GlitchData : VitalGlitchDataType;
        BEGIN
            VitalPathDelay01Z (
                OutSignal       => WPNegOut,
                OutSignalName   => "WPNeg",
                OutTemp         => WPNegOut_zd,
                GlitchData      => WP_GlitchData,
                Paths           => (
                    0 => (InputChangeTime => SCK_ipd'LAST_EVENT,
                        PathDelay       => VitalExtendtofillDelay(tpd_SCK_SI),
                        PathCondition   => HOLDNegOut_zd /= 'Z'AND dual
                                           AND QUAD = '1'),
                    1 => (InputChangeTime => CSNeg_ipd'LAST_EVENT,
                        PathDelay       => tpd_CSNeg_SO,
                        PathCondition   => CSNeg_ipd = '1' AND dual
                                           AND QUAD = '1')
                )
            );
        END PROCESS;
    END BLOCK behavior;
END vhdl_behavioral;
