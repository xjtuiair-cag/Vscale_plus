`define CSR_ADDR_WIDTH          12
`define CSR_COUNTER_WIDTH       64

`define CSR_ADDR_MSTATUS        12'h300
`define CSR_ADDR_MISA           12'h301
`define CSR_ADDR_MTDELEG        12'h302
`define CSR_ADDR_MIE            12'h304
`define CSR_ADDR_MTVEC          12'h305
`define CSR_ADDR_MCNTINHIBIT    12'h320
`define CSR_ADDR_MTIMECMP       12'h321
`define CSR_ADDR_MTIMECMPH      12'h322
`define CSR_ADDR_MSCRATCH       12'h340
`define CSR_ADDR_MEPC           12'h341
`define CSR_ADDR_MCAUSE         12'h342
`define CSR_ADDR_MTVAL          12'h343
`define CSR_ADDR_MIP            12'h344

`define CSR_ADDR_MCYCLE         12'hB00
`define CSR_ADDR_MINSTRET       12'hB02
`define CSR_ADDR_MCYCLEH        12'hB80
`define CSR_ADDR_MINSTRETH      12'hB82
`define CSR_ADDR_TIME           12'hC01
`define CSR_ADDR_TIMEH          12'hC81

`define CSR_ADDR_MVENDORID      12'hF11
`define CSR_ADDR_MARCHID        12'hF12
`define CSR_ADDR_MIMPID         12'hF13
`define CSR_ADDR_MHARTID        12'hF14

`define CSR_CMD_WIDTH 3
`define CSR_IDLE      0
`define CSR_READ      4
`define CSR_WRITE     5
`define CSR_SET       6
`define CSR_CLEAR     7

`define CNTINHIBIT_CY 0
`define CNTINHIBIT_TM 1
`define CNTINHIBIT_IR 2

`define MTVEC_MODE_DIRECT 0
`define MTVEC_MODE_VECTOR 1

`define ECODE_WIDTH                      4
`define ECODE_INST_ADDR_MISALIGNED       0
`define ECODE_INST_ADDR_FAULT            1
`define ECODE_ILLEGAL_INST               2
`define ECODE_BREAKPOINT                 3
`define ECODE_LOAD_ADDR_MISALIGNED       4
`define ECODE_LOAD_ACCESS_FAULT          5
`define ECODE_STORE_AMO_ADDR_MISALIGNED  6
`define ECODE_STORE_AMO_ACCESS_FAULT     7
`define ECODE_ECALL_FROM_U               8
`define ECODE_ECALL_FROM_S               9
`define ECODE_ECALL_FROM_H              10
`define ECODE_ECALL_FROM_M              11
`define ECODE_INST_PAGE_FAULT           12
`define ECODE_LOAD_PAGE_FAULT           13
`define ECODE_STORE_AMO_PAGE_FAULT      15

`define ICODE_U_SOFTWARE    0
`define ICODE_S_SOFTWARE    1
`define ICODE_H_SOFTWARE    2
`define ICODE_M_SOFTWARE    3
`define ICODE_U_TIMER       4
`define ICODE_S_TIMER       5
`define ICODE_H_TIMER       6
`define ICODE_M_TIMER       7
`define ICODE_U_EXTINT      8
`define ICODE_S_EXTINT      9
`define ICODE_H_EXTINT      10
`define ICODE_M_EXTINT      11

`define PRV_WIDTH     2
`define PRV_U         0
`define PRV_S         1
`define PRV_H         2
`define PRV_M         3
