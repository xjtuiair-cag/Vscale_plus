`include "vscale_ctrl_constants.vh"
`include "vscale_csr_addr_map.vh"

`timescale 1ns/1ps
module vscale_hex_tb();

localparam inst_hexfile_bytes = 65536;
localparam data_hexfile_bytes = 65536;
string base_dir = "/home/wenzhe/Projects/github/Vscale_plus";

reg clk;
reg reset;

reg [255:0]                reason = 0;
reg [1023:0]               loadmem = 0;
reg [1023:0]               vpdfile = 0;
reg [  63:0]               max_cycles = 0;
reg [  63:0]               trace_count = 0;
integer                    stderr = 32'h80000002;

reg [7 : 0]                ext_int_sig = 8'h0;

reg [7:0]                  inst_hexfile [0 : inst_hexfile_bytes-1];
reg [7:0]                  data_hexfile [0 : data_hexfile_bytes-1];

wire                        reg_wen;
wire  [13 : 0]              reg_waddr;
wire  [31 : 0]              reg_wdata;

vscale_core DUT(
    .clk_i(clk),
    .reset(reset),
    .ext_interrupts_i(ext_int_sig),

    .reg_wen(reg_wen),
    .reg_waddr(reg_waddr),
    .reg_wdata(reg_wdata),         
    .reg_ren(),
    .reg_raddr(),
    .reg_rdata()
);

initial begin
    clk = 0;
    reset = 1;

    repeat(200) @(posedge clk);
    ext_int_sig = 1;
    forever begin
        @(posedge clk);
        if(reg_wen && reg_waddr == 'h0) begin
            break;
        end
    end
    ext_int_sig = 0;

    repeat(500) @(posedge clk);
    ext_int_sig = 3;
    forever begin
        @(posedge clk);
        if(reg_wen && reg_waddr == 'h0) begin
            break;
        end
    end
    ext_int_sig = 2;
    forever begin
        @(posedge clk);
        if(reg_wen && reg_waddr == 'h0) begin
            break;
        end
    end
    ext_int_sig = 0;
end

always #5 clk = !clk;

integer i = 0;
integer j = 0;

initial begin
    // Load code section
    $readmemh({base_dir, "/software/output/1_itcm.verilog"}, inst_hexfile);
    for(i=0; i<inst_hexfile_bytes; i=i+4) begin
        DUT.itcm.mem[i/4] = {inst_hexfile[i+3], inst_hexfile[i+2], inst_hexfile[i+1], inst_hexfile[i]};
    end
    
    // Load data section
    $readmemh({base_dir, "/software/output/1_dtcm.verilog"}, data_hexfile);
    for(i=0; i<data_hexfile_bytes; i=i+4) begin
        DUT.dtcm.mem[i/4] = {data_hexfile[i+3], data_hexfile[i+2], data_hexfile[i+1], data_hexfile[i]};
    end
    
    // $fsdbAutoSwitchDumpfile(1000,"../fsdb/outcome.fsdb",100);
    // $fsdbDumpon;
    // $fsdbDumpMDA;
    // $fsdbDumpvars(0,DUT);
    
    // $vcdplusfile(vpdfile);
    $vcdpluson();
    // $vcdplusmemon();
    #100 reset = 0;
end // initial begin

always @(posedge clk) begin
    trace_count = trace_count + 1;
    
    if (max_cycles > 0 && trace_count > max_cycles)
        reason = "timeout";
    
    if (reason) begin
        $fdisplay(stderr, "*** FAILED *** (%s) after %d simulation cycles", reason, trace_count);
        // $fsdbDumpoff;
        // $vcdplusclose;
        $finish;
    end
end

endmodule // vscale_hex_tb

