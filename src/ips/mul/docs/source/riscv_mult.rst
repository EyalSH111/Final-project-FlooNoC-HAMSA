.. sectnum::

.. toctree::
   :maxdepth: 2

.. header:: `Decoder`

###########################################################################
Overview
###########################################################################

| The multiplier module will be a sub design of GENPRO project, under the core region design. 
| RI5CY uses a single-cycle 32-bit x 32-bit multiplier with a 32-bit result. All instructions of the RISC-V M instruction set extension are supported. 
| The multiplications with upper-word result (MSP of 32-bit x 32-bit multiplication), take 4 cycles to compute. 
| The RI5CY also supports non-standard extensions for multiply-accumulate and half-word multiplications with an optional post-multiplication shift & round. 
| The multiplier has optional support in Dot Product Instructions. 

###########################################################################
High level description
###########################################################################

The multiplier will be use by the RISCY+ core in the core region of the Pulpenix 

.. figure:: /figures/2_pulpenix_diagram.png

The multiplier will be used in 1 pipe line stage: 

**EX stage**

| When an instruction which requires the multiplier operation is decoded, the decoder passes the required signals to the EX stage, and then it passes to the multiplier "sub-design" inputs to calculate the multiplication result as required in the instruction, when each "sub_design" is performing a different multiplication method.
| The EX stage could be stalled for 4 clock cycles due to multiplier commands, but most of the commands takes 1 cycle (will be detailed below) 

.. figure:: /figures/2_pulpenix_pipeline.png

###########################################################################
Component leve description
###########################################################################

***************************************************************************
Block Diagran
***************************************************************************

.. figure:: /figures/3_mult_block_diaram.png

***************************************************************************
Port List
***************************************************************************

Input port list:

.. table:: Input Port List
+-----------------+------+------------------------+----------------------------------------------------------------------------------------+
| Name            | Size | Source                 | Description                                                                            |
+=================+======+========================+========================================================================================+
| operator_i      | 3    | decoder                | Controls the multiplication operation which is executed, and the result that is chosen |
+-----------------+------+------------------------+----------------------------------------------------------------------------------------+
| op_a_i          | 32   | Alu_operand_a          | Operand a (c + a*b) of int_mult                                                        |
+-----------------+------+------------------------+----------------------------------------------------------------------------------------+
| op_b_i          | 32   | Alu_operand_b          | Operand b (c + a*b) of int_mult                                                        |
+-----------------+------+------------------------+----------------------------------------------------------------------------------------+
| op_c_i          | 32   | Alu_operand_c          | Operand c (c + a*b) of int_mult                                                        |
+-----------------+------+------------------------+----------------------------------------------------------------------------------------+
| imm_i           | 5    | Id_stage (from instr.) | Immediate value for shifting the result                                                |
+-----------------+------+------------------------+----------------------------------------------------------------------------------------+
| enable_i        | 1    | decoder                | Enables the mul_h to start computing the result (SM)                                   |
+-----------------+------+------------------------+----------------------------------------------------------------------------------------+
| short_subword_i | 1    | decoder                | Which subword(16'b MSP/LSP) of each operand to use for computation of int mul          |
+-----------------+------+------------------------+----------------------------------------------------------------------------------------+
| short_signed_i  | 2    | decoder                | Indicates the sign of each operand of int mul                                          |
+-----------------+------+------------------------+----------------------------------------------------------------------------------------+
| ex_ready_i      | 1    | EX stage               | execution stage indicates when it is ready to sample the mul_h result                  |
+-----------------+------+------------------------+----------------------------------------------------------------------------------------+
| dot_signed_i    | 2    | decoder                | Indicates the sign of each operand of dot mul                                          |
+-----------------+------+------------------------+----------------------------------------------------------------------------------------+
| dot_op_a_i      | 32   | Alu_operand_a          | Operand a (c+ [i:0:2/4](a[i]*b[i]) of dot_mult                                         |
+-----------------+------+------------------------+----------------------------------------------------------------------------------------+
| dot_op_b_i      | 32   | Alu_operand_b          | Operand b (c+ [i:0:2/4](a[i]*b[i]) of dot_mult                                         |
+-----------------+------+------------------------+----------------------------------------------------------------------------------------+
| dot_op_c_i      | 32   | Alu_operand_c          | Operand c (c+ [i:0:2/4](a[i]*b[i]) of dot_mult                                         |
+-----------------+------+------------------------+----------------------------------------------------------------------------------------+
| Rst_n           | 1    |                        | Reset mul_h state machine value                                                        |
+-----------------+------+------------------------+----------------------------------------------------------------------------------------+
| clk             | 1    |                        | Module's clock input                                                                   |
+-----------------+------+------------------------+----------------------------------------------------------------------------------------+
   
Output port list:

.. table:: Output Port List       
+--------------+------+-----------------------------+-----------------------------------------------------------------------------+
| Name         | Size | Destination                 | Description                                                                 |
+==============+======+=============================+=============================================================================+
| multicycle_o | 1    | Ex stage/controller/decoder | Indicates that a mul_h operation is in progress, which takes 4 clock cycles |
+--------------+------+-----------------------------+-----------------------------------------------------------------------------+
| ready_o      | 1    | Alu/id stage/mul            | When mul_h is ready to start calculation                                    |
+--------------+------+-----------------------------+-----------------------------------------------------------------------------+
| result_o     | 32   | Register file/alu           | The multiplication result which is chosen by final mux (operator_i)         |
+--------------+------+-----------------------------+-----------------------------------------------------------------------------+

Parameters list:

.. table:: Parameters List
+----------------+-------+-----------------------------------------------------------------------------------------------------------------------------------------------------+
| Name           | Value | Description                                                                                                                                         |
+================+=======+=====================================================================================================================================================+
| SHARED_DSP_MUL | 0     | indicates if the multiplier supports dot product instruction, it is used to offload dot-product instructions to the shared unit if it is available. |
+----------------+-------+-----------------------------------------------------------------------------------------------------------------------------------------------------+


***************************************************************************
Functionality
***************************************************************************

Unit procedure:
---------------------------------------------------------------------------

There are 3 calculation which executed in parallel:

1. Simple integer multiplier - MAC32/MSU32

2. Integer multiplier with extensions - IMM/IMM-ROUND/MUL_HIGH

3. Dot product multiplier DOT8

4. Dot product multiplier DOT16

| We will detail the various operations later in the document.

| A mux controls the result which is chosen to go to the output. The signal which the mux uses to choose is operator_i. 
| The options for this signal for each operation's result to be chosen:

1. MUL_MAC32, MUL_MSU32

2. MUL_I, MUL_IR, MUL_H

3. MUL_DOT8,

4. MUL_DOT16


When:

* MUL_MAC32 = 3'b000;
* MUL_MSU32 = 3'b001;
* MUL_I     = 3'b010;
* MUL_IR    = 3'b011;
* MUL_DOT8  = 3'b100;
* MUL_DOT16 = 3'b101;
* MUL_H     = 3'b110;


Detail on each operation:

Simple integer multiplier 
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
This part of the multiplier design is responsible for simple MAC operations.

    **Functionality**

    | There are 2 modes of operation, the control signal to choose between the modes is: int_op_msu. 
    | int_is_msu = (operator_i == MUL_MSU32)
    | The result saves only the 32 least significant bits.
    | The calculation is the same for both modes, but the operands are manipulated by int_op_msu to have the required result.

    **The singnals**:

    | int_op_a_msu = for result manipulation, op_a_i ^ {32{int_is_msu}}
    | int_op_b_msu = for result manipulation op_b_i & {32{int_is_msu}}
    | int_result = holds the result:
    | $signed(op_c_i) + $signed(int_op_b_msu) + $signed(int_op_a_msu) * $signed(op_b_i)

    +	Mode MAC
        | It will perfrom a simple MAC operation, without touching the operands. c= c+ a*b
        | It will multiply the 2 operands - op_a_i, op_b_i
        | And add the result to a third operand - op_c_i. 
        | Since int_is_msu = 0 : int_op_b_msu = 0 & int_op_a_msu = op_a_i.
        | So the computation will be - $signed(op_c_i) + 0 + $signed(op_a_i) * $signed(op_b_i)

    +	Mode MSU
        | It will perform a simple MSU operation, which means that instead of accumulate we devaluate: c= c - a*b
        | In this mode we need to change the sign of operand a, in 2's complement: -a=¯a+1
        | So in the multiplication: c=c - a*b=c+(¯a+1)*b=c+ ¯a*b+b  
        | We can see the result in the next way:
        | $signed(op_c_i) + $signed(op_b_i) + $signed(¯a) * $signed(op_b_i)

Integer multiplier with extensions
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
This part of the multiplier design is responsible for MAC operations with the next additional options:

*   Immediate shift of the result.

*   Result rounding

*   Calculate the 32 MSBs of the result.

    **Functionally**

    There are 2 modes of operation:
    +   MUL_I/MUL_IR:
        | Operands preparation:
        | The design gets 2 operands, each 32'b. but the multiplication will use only a subword of 16'b - to get a 32'b result. The sub-word is chosen by the signal: mult_operator_o.
        | When short_subword_i== 1 -> the 16'b MSBs are chosen, if short_subword_i== 0 the LSBs are chosen. The chosen portions is inserted to short_op_a/b.
        | A sign bit is added to short_op_a/b, considering the msb of the operands, and the signal short_signed_i - which indicates if the operand is signed or not.
        | The signal short_op_c holds the value of op_c_i.
        | The signal short_mul holds the result of $signed(short_op_a) * $signed(short_op_b).
        | The signal short_mac holds the result of $signed(short_op_c) + $signed(short_mul) + $signed(short_round). 
        | The signal short_result holds the result of short_mac >>> imm_i. this is the result for the final mux.

    +   MUL_H
        | In mul_high calculation, we are calculating 32b operand*32b operand = 64b operand and taking the 32 MSBs.
        | The calculation is divided to 4 clock cycles:
        | We will divide each operand to 2 portions:

        .. table:: divided operands
        +-----------+-----------------------+---------------------+
        |           | Part 1 (high) [16:31] | Part 0 (low) [0:15] |
        +===========+=======================+=====================+
        | Operand a | a.1                   | a.0                 |
        +-----------+-----------------------+---------------------+
        | Operand b | b.1                   | b.0                 |
        +-----------+-----------------------+---------------------+

        | We will calculate the result in the next way: (each clock cycle in different highlight color)
        | Res = a*b = (a.1«16'b +a.0)* (b.1«16'b +b.0) =(a.1*b.1)<<32'b + (a.1*b.0 +a.0*b.1)<<16'b +(a.0*b.0)
	    | Schematic of the parts, the highlight are the parts we want to have in the results.
        | (Result bits in **bold**)

        .. table:: divided operands  
        +----------------+-------------------------+------------------+------------------+-----------+
        | O.F.           | **[63:48]**             | **[47:32]**      | [31:16]          | [15:0]    |
        +================+=========================+==================+==================+===========+
        |                |                         | Carry(a.0*b.0)   | a.0 * b.0        | a.0 * b.0 |
        +----------------+-------------------------+------------------+------------------+-----------+
        |                | Carry(a.1*b.0 +a.0*b.1) | a.1*b.0 +a.0*b.1 | a.1*b.0 +a.0*b.1 |           |
        +----------------+-------------------------+------------------+------------------+-----------+
        | Carry(a.1*b.1) | a.1*b.1                 |                  |                  |           |
        +----------------+-------------------------+------------------+------------------+-----------+
        |                |                         |                  |                  |           |
        +----------------+-------------------------+------------------+------------------+-----------+
	
        | We will perform multiplication of 16b*16b, and have a result of 32b length. 
        | So we will each step multiply one part with another, and use shifts so we will have the correct result
        | We are interested in the 32'b MSB of the results.
        | For this calculation there is a state machine which responsible only for this operation.
    
        | We will give a short explanation on some of the signals for better understanding the SM:
        | *mulh_imm* - how much shift is needed for the result.
        | *mulh_subword* - which part of the registers will be used as operator. 0 for [15:0] 1 for [31:16]. 2 bits for each operand
        | *mulh_signed* - tells if the operands are signed or unsigned
        | *mulh_shift_arith* - indicated when the result is signed, and the shift needs to be arithmetic.
        | *mulh_carry_q* - saves the carry bit for the result calculation.
        | *mulh_active* - indicated when mulh operation is performed (for operand manipulation).
        | *mulh_save* - if we need to save the carry to mulh_carry_q.
        | *mulh_clearcarry* - when carry needs to be clean - equal to zero
        | *mulh_ready* -indicates when the multiplier is on IDLE/FINISH, and it can get a new operation.

        | *mulh_CS* - the state machine current stage
        | *mulh_NS* - the state machine next stage
        | *short_mac_msb1* - the last bit of the result (short_mac[33])that will be used for shifting the result considering if its signed/unsigned. 
        | *short_mac_msb0* - the one before last bit (short_mac[32]) that will be used for shifting the result considering if its signed/unsigned. 

        **Diagram of the SM:**

        .. figure:: /figures/3_2_1_state_machine.png

        Explanation on each state:

        *   IDLE:
        | mulh_active = 0 since it is not active
        | mulh_ready = 1 since its ready to get an operation
        | 
        | The SM is waiting that the next condition will be true: ((operator_i == MUL_H) && enable_i)
        | operator_i == MUL_H - indicates that operation of mul_h is needed.
        | enable_i - the mult gets an enable to start the operation.
        | 
        | When the condition is true - the SM moves to the stage: STEP0, if not- it stays in IDLE
        
        *   STEP0
        | The SM enters an active step, which will perform the first part of the result's computing.
        | In this step, we will perform a.0*b.0>>> 16. 
        | 
        | multicycle_o = 1 - inform we are entering a multicycle operation, and the pipe signals we need will be in use more than one cycle.
        | mulh_active = 1 
        | mulh_ready = 0
        | mulh_save = 0 - will not overflow anyway. (Sign extension bit = 0 for both)
        | mulh_subword     = 2'b00 - we are taking the LSB of both registers
        | mulh_signed      = 2'b00 - not treated as signed.
        | mulh_shift_arith = 0 - since it's unsigned
        | mulh_imm         = 5'd16 - for result calculation
        | 
        | Then the result is shifted by 16 bits since we need only the 16'b MSB to calculate the result. 
        | The result will return to this block through operand c - so we could add it to the calculation afterword.
        
        *   STEP1
        | In this step, we will perform a.1*b.0 + (a.0*b.0 >>> 16)
        | mulh_signed = {short_signed_i[1], 1'b0} - a.1 is signed since it's the MSB of the operand, b.0 not signed since it's the LSB.
        | mulh_subword = 2'b10 - for operand a we take the 16'b MSB, and for b the 16'b LSB.
        | mulh_save = 1'b1 - we will need to save the carry since we need to add a.0*b.1 to the result
        | mulh_shift_arith = 1'b1 - the shift is arithmetic since the result is signed (but mulh_imm = 5'd16 so it doesn't matter)
        
        *   STEP2
        | In this step, we will perform (a.0*b.1 + (a.1*b.0 + (a.0*b.0 >>> 16 )) )>>> 16
        | mulh_signed      = {1'b0, short_signed_i[0]} - b.1 is signed since it's the MSB of the operand, a.0 not signed since it's the LSB.
        | mulh_subword     = 2'b01 - for operand a we take the 16'b LSB, and for b the 16'b MSB.
        | mulh_imm         = 5'd16 - for result calculation
        | mulh_save        = 1'b1 - we want to clear the carry, (save 0)  since the carry bits are shifted back
        | mulh_clearcarry  = 1'b1 - to reset the carry value
        | mulh_shift_arith = 1'b1 - we will have a signed result, so we need to shift considering the sign
        
        *   FINISH
        | In this final step, we will perform a.1*b.1 + ((a.0*b.1 + (a.1*b.0 + (a.0*b.0 >>> 16 )) )>>> 16)
        | mulh_signed  = short_signed_i - b.1  & a.1 are signed since it's the MSB of the operands
        | mulh_subword = 2'b11 - we take the 16'b MSB for both operands
        | mulh_ready = 1'b1 - since we finished the calculation, and the result is ready.
        | mulh_active = 1'b1
        | multicycle_o     = 1'b0
        | 
        | We will return to IDLE stage only when signal ex_ready_i == 1, so we know that the result has been sampled and move on to the next stage.



Dot product multiplier
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

    Vectorial instructions perform operations in a SIMD-like manner on multiple sub-word elements at the same time. This is done by segmenting the data path into smaller parts when 8 or    16-bit operations should be performed. 

    Vectorial instructions are available in two flavors: 
    + 8-Bit, to perform four operations on the 4 bytes inside a 32-bit word at the same time 
    + 16-Bit, to perform two operations on the 2 half-words inside a 32-bit word at the same time 
        
    **Only exist if SHARED_DSP_MULT == 0  (if not the output results are zero)**
    *   Signals for DOT8	

    | dot_char_op_a - 4x9 matrix, when each line is a 8'b part of the dot_op_a_i operand, and an additional sign extension bit
    | dot_char_op_b - 4x9 matrix, when each line is a 8'b part of the dot_op_b_i operand, and an additional sign extension bit
    | dot_char_mul - 4x9 matrix, each line holds the dot_op_a_i[i] * dot_op_b_i[i] result, when I is the line index. 
    | dot_char_result - holds the sum of the dot_op_a_i[i] * dot_op_b_i[i] result plus the operand c input, when i= 0:3.
    
    *   Signals for DOT16

    | dot_short_op_a - 2x17 matrix, when each line is a 16'b part of the dot_op_a_i operand, and an additional sign extension bit
    | dot_short_op_b - 2x17 matrix, when each line is a 16'b part of the dot_op_b_i operand, and an additional sign extension bit
    | dot_char_mul - 2x17 matrix, each line holds the dot_op_a_i[i] * dot_op_b_i[i] result, when I is the line index. 
    | dot_char_result - holds the sum of the dot_op_a_i[i] * dot_op_b_i[i] result plus the operand c input, when i= 0:1.
    

###########################################################################
Waveforms
###########################################################################

Code snippet:
4a0:	02f70633          	mul	a2,a4,a5
4a4:	02f73ab3          	mulhu	s5,a4,a5

In this snippet we encounter 2 types of format instruction:

.. figure:: /figures/3_3_mul_instr.png
.. figure:: /figures/3_3_mulh_instr.png

We will need the register table:
.. figure:: /figures/3_3_reg_table.png

We will interpret each instruction, follow the waves and see the multiplier operation:
1.	4a0:	02f70633          	mul	a2,a4,a5


   This command will multiply x[a5] by x[a4] and save the result to register x[a2].
       .. figure:: /figures/3_3_1_first_instr_fields.png

    | Rs1 - operand b register x[01110] = x[15] = a[5]
    | Rs2 - operand a register x[01111] = x[14]=a[4]
    | rd  - destination register x[01100] =x[12]=a[2]
    
    We are performing a simple MUL operation and taking the 32 LSBs of the result thus the multiplier in use is the int mult - simple multiplier (MUL_MAC32)
    
    .. figure:: /figures/3_3_1_first_instr_waves.png
    
    The command which just exited the id stage and entered the ex stage - which the multiplier is in - is the command with pc 4a0.
    
    **Marker 1**
    
    | We can see that operator_i = 000 = MUL_MAC32.
    | Op_a = 'h 3 = 'd 3
    | Op_b = 'h FFFFFFFD = 'd -3
    | Op_c = 'h 0
    
    | As explained before, we are creating the next signals: (also in the waves)
    | int_is_msu = (operator_i == MUL_MSU32) = 0
    | int_op_a_msu = op_a_i ^ {32{int_is_msu}} = op_a_i
    | int_op_b_msu = op_b_i & {32{int_is_msu}} = 0
    
    | And the result is calculated in the next way:
    | int_result = $signed(op_c_i) + $signed(int_op_b_msu) + $signed(int_op_a_msu) * $signed(op_b_i);
    | = 0 + 0 + $signed(op_a_i) * $signed(op_b_i);
    
    So the value of int_result needs to be 3*-3 = -9 = 'h FFFFFFF7, and that's what we get in the waves.
    
    | This result is being chosen by the result mux, since the operator is MUL_MAC32, and we get in the result_o the value. 
    | In next clock cycle the value is written in the destination register:
    
    .. figure:: /figures/3_3_1_first_instr_waves2.png
   

2.	4a4:	02f73ab3          	mulhu	s5,a4,a5

    | This command will multiply x[a2] by x[a4] (both unsigned) and save the result to register x[a5].
    | Command by fields of the instruction:

    .. figure:: /figures/3_3_1_second_instr_fields.png
    
    | Rs1 - operand b register x[01110] = x[15] = a[5]
    | Rs2 - operand a register x[01111] = x[14]=a[4]
    | rd  - destination register x[10101] =x[21]=s[5]
     
    We are performing a simple MUL operation and taking the 32 MSBs of the result thus the multiplier in use is the mul high/mul_h.
    
    .. figure:: /figures/3_3_1_second_instr_waves.png
    
    **Marker 2**:
    
    | Looking at the register file:
    | At x[15] the value - 0000-0003
    | At x[14] the value - FFFF-FFFD
    
    .. figure:: /figures/3_3_1_second_instr_mem_viewer.png
    
    
    | The result we expect to get:
    | (0000-0003 * FFFF-FFFD) >> 32 = 2FFFFFFF7 >> 32 = 2
    
    The operator_i changes to 110 = MUL_H, and enable_i = 1 - the state machine can continue to STEP0. (= next state)
    
    **Marker 3**:

    | Starting step0, as explained before - we will calculate op_a[15:0]*op_b[15:0] and shift the result by 16.
    | Short_op_a = 0FFFD
    | Short_op_b = 00003
    | The result is = 0002 FFF7. Shifted by 16 - > 0000 0002.
    | The result is selected by the result mux.
    
    **Marker 4**:
    
    | We see that operand c now holds the result from previous stage (0000_0002), the calculation for this stage: a.1*b.0 + (a.0*b.0 >>> 16).
    | Short_op_a = 0FFFD
    | Short_op_b = 00000
    | Result is 0, and it is added to operand c.
    | The result remains the same - 0000_0002, and wil be chosen again by the result mux.
    
    **Marker 5**:
    
    | The calculation for this stage: (a.0*b.1 + (a.1*b.0 + (a.0*b.0 >>> 16 )) )>>> 16.
    | Short_op_a = 0FFFF
    | Short_op_b = 00003
    | The multiplier result is 0002_FFFD, and it is added to operand c -> 
    | 0002_FFFD + 0000_0002 = 0002_FFFF
    | The result is shifted by 16b -> so the result of this stage is 0000_0002.
    
    **Marker 6**:
    
    | Calculation performed: a.1*b.1 + ((a.0*b.1 + (a.1*b.0 + (a.0*b.0 >> 16 )) )>> 16 ) Short_op_a = 0FFFF
    | Short_op_b = 00000
    | The multiplier result is 0, and it is added to operand c - 0000_0002.
    
    The final result of the instruction is - 0000_0002, and this is the value which will be written to the register file in destination register( x[21]=s[5])
    
    .. figure:: /figures/3_3_1_second_instr_waves2.png
    
    Looking at the register file 1 clock cycle after the calculation ends, we see that x[21] holds the result of the multiplier.

