`timescale 1ns/1ps
module sram #(
    parameter   DEPTH = 65536
) (
    input                   clk,
    input                   sram_wen,
    input [13 : 0]          sram_waddr,
    input [31 : 0]          sram_wdata,
    input                   sram_ren,
    input [13 : 0]          sram_raddr,
    output[31 : 0]          sram_rdata
);

reg   [31 : 0]          mem[0 : DEPTH/4 - 1];

reg   [31 : 0]          sram_rdata_t;

integer i;

always @(posedge clk) begin
    if(sram_wen) begin
        mem[sram_waddr] <= sram_wdata;
    end
end

always @(posedge clk) begin
    if(sram_ren) begin
        sram_rdata_t <= mem[sram_raddr];
    end
end
assign sram_rdata = sram_rdata_t;
 
endmodule
