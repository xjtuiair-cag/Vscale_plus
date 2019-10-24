`include "vscale_hasti_constants.vh"
`include "vscale_ctrl_constants.vh"
`include "vscale_csr_addr_map.vh"
`include "vscale_platform_constants.vh"

`timescale 1ns/1ps

module vscale_bus(
    input                               clk_i,
    input                               reset,

    // to vscale pipeline
    // input [`HASTI_ADDR_WIDTH-1:0]       imem_addr,
    // input [`HASTI_BUS_WIDTH-1:0]        imem_rdata,

    input                               dmem_en,
    input                               dmem_wen,
    input [`HASTI_SIZE_WIDTH-1:0]       dmem_size,
    input [`HASTI_ADDR_WIDTH-1:0]       dmem_addr,
    input [`HASTI_BUS_WIDTH-1:0]        dmem_wdata_delayed,
    output[`HASTI_BUS_WIDTH-1:0]        dmem_rdata,

    // to itcm
    // output                              itcm_ren,
    // output[`HASTI_ADDR_WIDTH-1 : 0]     itcm_raddr,
    // input [`HASTI_BUS_WIDTH-1 : 0]      itcm_rdata,

    // to dtcm
    output                              dtcm_wen,
    output[14-1 : 0]                    dtcm_waddr,
    output reg [`HASTI_BUS_WIDTH-1 : 0]      dtcm_wdata,         
    output                              dtcm_ren,
    output[14-1 : 0]                    dtcm_raddr,
    input [`HASTI_BUS_WIDTH-1 : 0]      dtcm_rdata,         

    // to REG
    output                              reg_wen,
    output[14-1 : 0]                    reg_waddr,
    output[`HASTI_BUS_WIDTH-1 : 0]      reg_wdata,         
    output                              reg_ren,
    output[14-1 : 0]                    reg_raddr,
    input [`HASTI_BUS_WIDTH-1 : 0]      reg_rdata
);

// -----
// REG & WIRE declaration
reg                                     dtcm_is_enable;
reg                                     regmap_is_enable;

reg                                     dmem_en_dly1;
reg                                     dmem_wen_dly1;
reg   [`HASTI_SIZE_WIDTH-1:0]           dmem_size_dly1;
reg   [`HASTI_ADDR_WIDTH-1:0]           dmem_addr_dly1;
reg                                     dtcm_is_enable_dly1;
reg                                     regmap_is_enable_dly1;

// -----
// memory map
// The memory map is compatible with PICO-RV32 version
// Type       | Start_Addr        | End_Addr
// -----------|-------------------|------------
// ITCM         0x00000000          0x0000ffff
// DTCM         0x00100000          0x0010ffff
// REGMAP       0x20000000          0x2000ffff
always @(*) begin
    dtcm_is_enable = 1'b0;
    regmap_is_enable = 1'b0;
    if(dmem_addr[`HASTI_ADDR_WIDTH-1 : 20] == 'h1) begin
        dtcm_is_enable = 1'b1;
    end
    if(dmem_addr[`HASTI_ADDR_WIDTH-1 : 20] == 'h200) begin
        regmap_is_enable = 1'b1;
    end
end

always @(posedge clk_i) begin
    dmem_en_dly1 <= dmem_en;
    dmem_wen_dly1 <= dmem_wen;
    dmem_size_dly1 <= dmem_size;
    dmem_addr_dly1 <= dmem_addr;
    dtcm_is_enable_dly1 <= dtcm_is_enable;
    regmap_is_enable_dly1 <= regmap_is_enable;
end

// interface of dtcm
assign dtcm_wen = dmem_en_dly1 & dmem_wen_dly1 & dtcm_is_enable_dly1;
assign dtcm_waddr = dmem_addr_dly1[15 : 2];
always @(*) begin
    case(dmem_size_dly1)
        3'h0: begin
            if(dmem_addr_dly1[1 : 0] == 'h0) begin
                dtcm_wdata = {dtcm_rdata[31 : 8], dmem_wdata_delayed[7 : 0]};
            end else if(dmem_addr_dly1[1 : 0] == 'h1) begin
                dtcm_wdata = {dtcm_rdata[31 : 16], dmem_wdata_delayed[15 : 8], dtcm_rdata[7 : 0]};
            end else if(dmem_addr_dly1[1 : 0] == 'h2) begin
                dtcm_wdata = {dtcm_rdata[31 : 24], dmem_wdata_delayed[23 : 16], dtcm_rdata[15 : 0]};
            end else begin
                dtcm_wdata = {dmem_wdata_delayed[31 : 24], dtcm_rdata[23 : 0]};
            end
        end
        3'h1: begin
            if(dmem_addr_dly1[1 : 1] == 1'b0) begin
                dtcm_wdata = {dtcm_rdata[31 : 16], dmem_wdata_delayed[15 : 0]};
            end else begin
                dtcm_wdata = {dmem_wdata_delayed[31 : 16], dtcm_rdata[15 : 0]};
            end
        end
        default: begin
            dtcm_wdata = dmem_wdata_delayed;
        end
    endcase
end

assign dtcm_ren = dmem_en & dtcm_is_enable;
assign dtcm_raddr = dmem_addr[15 : 2];

// interface of regmap
assign reg_wen = dmem_en_dly1 & dmem_wen_dly1 & regmap_is_enable_dly1;
assign reg_waddr = dmem_addr_dly1[15 : 2];
assign reg_wdata = dmem_wdata_delayed;

assign reg_ren = dmem_en & ~dmem_wen & regmap_is_enable;
assign reg_raddr = dmem_addr[15 : 2];

assign dmem_rdata = (dmem_en_dly1 & dtcm_is_enable_dly1) ? dtcm_rdata
                  : (dmem_en_dly1 & regmap_is_enable_dly1) ? reg_rdata
                  : 'h0;

endmodule
