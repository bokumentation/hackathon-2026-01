`ifndef DEFS_SVH
`define DEFS_SVH

`define DEF_HEADER_BITS      96
`define DEF_PAYLOAD_BITS     96
`define DEF_PAYLOAD_DATA_BITS 72
`define DEF_INTEGRITY_BITS   24

`define DEF_HALF_PERIOD      9
`define DEF_QUARTER_PERIOD   4
`define DEF_TIMING_TOLERANCE 2
`define DEF_TIMEOUT_CYCLES   4096

`define DEF_PREAMBLE         32'hAAAAAAAA
`define DEF_TYPE_WORD        16'hD391
`define DEF_CONSTANT_WORD    32'h0DFFFFFE

`define DEF_CRC_POLY         24'h864CFB
`define DEF_CRC_INIT         24'hB704CE

`endif
