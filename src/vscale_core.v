`include "vscale_hasti_constants.vh"
`include "vscale_ctrl_constants.vh"
`include "vscale_csr_addr_map.vh"
`include "vscale_platform_constants.vh"

`timescale 1ns/1ps

module vscale_core(
    input                               clk_i,
    input                               reset,
    input [`N_EXT_INTS-1:0]             ext_interrupts_i, 

    // regmap interface
    output                              reg_wen,
    output[14-1 : 0]                    reg_waddr,
    output[`HASTI_BUS_WIDTH-1 : 0]      reg_wdata,         
    output                              reg_ren,
    output[14-1 : 0]                    reg_raddr,
    input [`HASTI_BUS_WIDTH-1 : 0]      reg_rdata
);

wire  [`HASTI_ADDR_WIDTH-1:0]           imem_addr;
wire  [`HASTI_BUS_WIDTH-1:0]            imem_rdata;
wire                                    dmem_en;
wire                                    dmem_wen;
wire  [`HASTI_SIZE_WIDTH-1:0]           dmem_size;
wire  [`HASTI_ADDR_WIDTH-1:0]           dmem_addr;
wire  [`HASTI_BUS_WIDTH-1:0]            dmem_wdata_delayed;
wire  [`HASTI_BUS_WIDTH-1:0]            dmem_rdata;

wire                                    dtcm_wen;
wire  [14-1 : 0]                        dtcm_waddr;
wire  [`HASTI_BUS_WIDTH-1 : 0]          dtcm_wdata;         
wire                                    dtcm_ren;
wire  [14-1 : 0]                        dtcm_raddr;
wire  [`HASTI_BUS_WIDTH-1 : 0]          dtcm_rdata;

sram # (
    .DEPTH(65536)
) itcm (
    .clk                                (clk_i),
    .sram_wen                           (1'b0),
    .sram_waddr                         ('h0),
    .sram_wdata                         ('h0),
    .sram_ren                           (1'b1),
    .sram_raddr                         (imem_addr[15 : 2]),
    .sram_rdata                         (imem_rdata)
);

sram # (
    .DEPTH(65536)
) dtcm (
    .clk                                (clk_i),
    .sram_wen                           (dtcm_wen),
    .sram_waddr                         (dtcm_waddr),
    .sram_wdata                         (dtcm_wdata),
    .sram_ren                           (dtcm_ren),
    .sram_raddr                         (dtcm_raddr),
    .sram_rdata                         (dtcm_rdata)
);

vscale_bus bus(
    .clk_i                              (clk_i),
    .reset                              (reset),

    .dmem_en                            (dmem_en),
    .dmem_wen                           (dmem_wen),
    .dmem_size                          (dmem_size),
    .dmem_addr                          (dmem_addr),
    .dmem_wdata_delayed                 (dmem_wdata_delayed),
    .dmem_rdata                         (dmem_rdata),

    // to dtcm
    .dtcm_wen                           (dtcm_wen),
    .dtcm_waddr                         (dtcm_waddr),
    .dtcm_wdata                         (dtcm_wdata),
    .dtcm_ren                           (dtcm_ren),
    .dtcm_raddr                         (dtcm_raddr),
    .dtcm_rdata                         (dtcm_rdata),

    // to REG
    .reg_wen                            (reg_wen),
    .reg_waddr                          (reg_waddr),
    .reg_wdata                          (reg_wdata),
    .reg_ren                            (reg_ren),
    .reg_raddr                          (reg_raddr),
    .reg_rdata                          (reg_rdata)
);

vscale_pipeline pipeline(
    .clk                                (clk_i),
    .reset                              (reset),
    .ext_interrupts                     (ext_interrupts_i),
    .imem_wait                          (1'b0),
    .imem_addr                          (imem_addr),
    .imem_rdata                         (imem_rdata),
    .imem_badmem_e                      ('h0),
    .dmem_wait                          (1'b0),
    .dmem_en                            (dmem_en),
    .dmem_wen                           (dmem_wen),
    .dmem_size                          (dmem_size),
    .dmem_addr                          (dmem_addr),
    .dmem_wdata_delayed                 (dmem_wdata_delayed),
    .dmem_rdata                         (dmem_rdata),
    .dmem_badmem_e                      ('h0)
);

endmodule // vscale_core
