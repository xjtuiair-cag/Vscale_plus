`include "rv32_opcodes.vh"
`include "vscale_csr_addr_map.vh"
`include "vscale_ctrl_constants.vh"
`include "vscale_platform_constants.vh"

`timescale 1ns/1ps

module vscale_csr_file(
    input                               clk,
    input [`N_EXT_INTS-1:0]             ext_interrupts, 
    input                               reset,
    input [`CSR_ADDR_WIDTH-1:0]         addr,
    input [`CSR_CMD_WIDTH-1:0]          cmd,
    input [`XPR_LEN-1:0]                wdata,
    output wire [`PRV_WIDTH-1:0]        prv,
    output                              illegal_access,
    output reg [`XPR_LEN-1:0]           rdata,
    input                               retire,
    input                               exception,
    input [`ECODE_WIDTH-1:0]            exception_code,
    input                               pop_prvstack_en,
    input [`XPR_LEN-1:0]                exception_load_addr,
    input [`XPR_LEN-1:0]                exception_PC,
    output reg [`XPR_LEN-1:0]           handler_PC,
    output [`XPR_LEN-1:0]               epc,
    output                              interrupt_pending,
    output reg                          interrupt_taken
);

reg [`XPR_LEN-1 : 0]                    cnt_inhibit;
reg [`CSR_COUNTER_WIDTH-1:0]            cycle_full;
reg [`CSR_COUNTER_WIDTH-1:0]            instret_full;
reg [5:0]                               priv_stack;
reg [`XPR_LEN-1:0]                      mtvec;
reg [1 : 0]                             mtvec_mode;
reg [`XPR_LEN-1:0]                      mie;
reg                                     mtip;
reg                                     msip;
reg [`CSR_COUNTER_WIDTH-1:0]            mtimecmp;
reg [`CSR_COUNTER_WIDTH-1:0]            mtime_full;
reg [`XPR_LEN-1:0]                      mscratch;
reg [`XPR_LEN-1:0]                      mepc;
reg [`ECODE_WIDTH-1:0]                  mecode;
reg                                     mint;
reg [`XPR_LEN-1:0]                      mbadaddr;

wire                                    ie_bit;

wire [`XPR_LEN-1:0]                     mvendorid;
wire [`XPR_LEN-1:0]                     marchid;
wire [`XPR_LEN-1:0]                     mimpid;
wire [`XPR_LEN-1:0]                     mhartid;
wire [`XPR_LEN-1:0]                     mstatus;
wire [`XPR_LEN-1:0]                     misa;
wire [`XPR_LEN-1:0]                     mtdeleg;
wire                                    meip;
wire [6 : 0]                            mcustip;
wire [`XPR_LEN-1:0]                     mip;
wire [`XPR_LEN-1:0]                     mcause;

wire                                    mtimer_expired;

wire                                    tmp_system_en;
wire                                    tmp_system_wen;
wire                                    system_en;
wire                                    system_wen;
wire                                    wen_internal;
wire                                    illegal_region;
reg                                     defined;
reg [`XPR_LEN-1:0]                      wdata_internal;
wire                                    uinterrupt;
wire                                    minterrupt;
reg [`ECODE_WIDTH-1:0]                  interrupt_code;

wire                                    code_imem;
wire [`XPR_LEN-1:0]                     padded_prv = prv;

assign tmp_system_en = cmd[2];
assign tmp_system_wen = cmd[1] || cmd[0];

assign illegal_region = (tmp_system_wen && (addr[11:10] == 2'b11))
                      || (tmp_system_en && addr[9:8] > prv);

assign illegal_access = illegal_region || (tmp_system_en && !defined);

assign system_en = tmp_system_en & ~illegal_access;
assign system_wen = tmp_system_wen & ~illegal_access;
assign wen_internal = system_wen;

always @(*) begin
    wdata_internal = wdata;
    if (system_wen) begin
        case (cmd)
            `CSR_SET : wdata_internal = rdata | wdata;
            `CSR_CLEAR : wdata_internal = rdata & ~wdata;
            default : wdata_internal = wdata;
        endcase // case (cmd)
    end
end // always @ begin

assign uinterrupt = 1'b0;
assign minterrupt = |(mie & mip);
assign interrupt_pending = |mip;

always @(*) begin
    interrupt_code = `ICODE_M_SOFTWARE;
    if(|(mip[11:0] & mie[11:0]) ) begin
        if(mip[3] & mie[3]) begin
            interrupt_code = `ICODE_M_SOFTWARE;
        end else if(mip[7] & mie[7]) begin
            interrupt_code = `ICODE_M_TIMER;
        end else if(mip[11] & mie[11]) begin
            interrupt_code = `ICODE_M_EXTINT;
        end
    end else if(|(mip[18:12] & mie[18:12]) ) begin
        if(mip[12] & mie[12]) begin
            interrupt_code = 'd12;
        end else if(mip[13] & mie[13]) begin
            interrupt_code = 'd13;
        end else if(mip[14] & mie[14]) begin
            interrupt_code = 'd14;
        end else if(mip[15] & mie[15]) begin
            interrupt_code = 'd15;
        end else if(mip[16] & mie[16]) begin
            interrupt_code = 'd16;
        end else if(mip[17] & mie[17]) begin
            interrupt_code = 'd17;
        end else if(mip[18] & mie[18]) begin
            interrupt_code = 'd18;
        end
    end
end

always @(*) begin
    case (prv)
        `PRV_U : interrupt_taken = (ie_bit && uinterrupt) || minterrupt;
        `PRV_M : interrupt_taken = (ie_bit && minterrupt);
        default : interrupt_taken = 1'b0;
    endcase // case (prv)
end

// assign handler_PC = mtvec + (padded_prv << 5);
always @(*) begin
    if(mtvec_mode == `MTVEC_MODE_VECTOR && interrupt_taken) begin
        handler_PC = mtvec + (interrupt_code << 2);
    end else begin
        handler_PC = mtvec;
    end
end

// RISC-V core signs
assign mvendorid = 'h0;
assign marchid = 'h0;
assign mimpid = 'h0;
assign mhartid = 'h0;

always @(posedge clk) begin
    if (reset) begin
        priv_stack <= 6'b001_110;
    end else if (wen_internal && addr == `CSR_ADDR_MSTATUS) begin
        priv_stack <= {wdata_internal[12:11], wdata_internal[7], 2'h3, wdata_internal[3]};
    end else if (exception | interrupt_taken) begin
        // no delegation to U means all exceptions go to M
        priv_stack <= {priv_stack[2:0],2'b11,1'b0};
    end else if (pop_prvstack_en) begin
        priv_stack <= {2'b00,1'b1,priv_stack[5:3]};
    end
end // always @ (posedge clk)

assign prv = priv_stack[2:1];
assign ie_bit = priv_stack[0];

// this implementation has SD, VM, MPRV, XS, and FS set to 0
assign mstatus = {20'b0, priv_stack[5:4], 3'h0, priv_stack[3], 3'h0, priv_stack[0], 3'h0};

// support instruction set:    ZY_XWVU_TSRQ_PONM_LKJI_HGFE_DCBA
assign misa = {2'h1, 4'h0, 26'b00_0000_0000_0001_0001_0000_0000};

assign mtdeleg = 0;

assign mtimer_expired = (mtimecmp >= mtime_full);

always @(posedge clk) begin
    if (reset) begin
        mtip <= 0;
        msip <= 0;
    end else begin
        if (mtimer_expired)
            mtip <= 1;
        if (wen_internal && addr == `CSR_ADDR_MTIMECMP)
            mtip <= 0;
        if (wen_internal && addr == `CSR_ADDR_MIP) begin
            mtip <= wdata_internal[7];
            msip <= wdata_internal[3];
        end
    end // else: !if(reset)
end // always @ (posedge clk)
assign meip = ext_interrupts[0];
assign mcustip = ext_interrupts[7:1];
assign mip = {13'h0, mcustip, meip, 3'b0, mtip, 3'b0, msip, 3'b0};

always @(posedge clk) begin
    if (reset) begin
        mie <= 0;
    end else if (wen_internal && addr == `CSR_ADDR_MIE) begin
        mie <= wdata_internal;
    end
end // always @ (posedge clk)

always @(posedge clk) begin
    if (interrupt_taken)
        mepc <= (exception_PC & {{30{1'b1}},2'b0}) + `XPR_LEN'h4;
    if (exception)
        mepc <= exception_PC & {{30{1'b1}},2'b0};
    if (wen_internal && addr == `CSR_ADDR_MEPC)
        mepc <= wdata_internal & {{30{1'b1}},2'b0};
end
assign epc = mepc;

always @(posedge clk) begin
    if (reset) begin
        mecode <= 0;
        mint <= 0;
    end else if (wen_internal && addr == `CSR_ADDR_MCAUSE) begin
        mecode <= wdata_internal[3:0];
        mint <= wdata_internal[31];
    end else begin
        if (interrupt_taken) begin
            mecode <= interrupt_code;
            mint <= 1'b1;
        end else if (exception) begin
            mecode <= exception_code;
            mint <= 1'b0;
        end
    end // else: !if(reset)
end // always @ (posedge clk)
assign mcause = {mint,27'b0,mecode};

assign code_imem = (exception_code == `ECODE_INST_ADDR_MISALIGNED)
    || (exception_code == `ECODE_INST_ADDR_MISALIGNED);

always @(posedge clk) begin
    if (exception)
        mbadaddr <= (code_imem) ? exception_PC : exception_load_addr;
    if (wen_internal && addr == `CSR_ADDR_MTVAL)
        mbadaddr <= wdata_internal;
end

always @(*) begin
    case (addr)
        `CSR_ADDR_MSTATUS       : begin rdata = mstatus; defined = 1'b1; end
        `CSR_ADDR_MISA          : begin rdata = misa; defined = 1'b1; end
        `CSR_ADDR_MTDELEG       : begin rdata = mtdeleg; defined = 1'b1; end
        `CSR_ADDR_MIE           : begin rdata = mie; defined = 1'b1; end
        `CSR_ADDR_MTVEC         : begin rdata = {mtvec[`XPR_LEN-1 : 2], mtvec_mode}; defined = 1'b1; end
        `CSR_ADDR_MCNTINHIBIT   : begin rdata = cnt_inhibit; defined = 1'b1; end
        `CSR_ADDR_MTIMECMP      : begin rdata = mtimecmp[0 +: `XPR_LEN]; defined = 1'b1; end
        `CSR_ADDR_MTIMECMPH     : begin rdata = mtimecmp[`XPR_LEN +: `XPR_LEN]; defined = 1'b1; end
        `CSR_ADDR_MSCRATCH      : begin rdata = mscratch; defined = 1'b1; end
        `CSR_ADDR_MEPC          : begin rdata = mepc; defined = 1'b1; end
        `CSR_ADDR_MCAUSE        : begin rdata = mcause; defined = 1'b1; end
        `CSR_ADDR_MTVAL         : begin rdata = mbadaddr; defined = 1'b1; end
        `CSR_ADDR_MIP           : begin rdata = mip; defined = 1'b1; end

        `CSR_ADDR_MCYCLE        : begin rdata = cycle_full[0+:`XPR_LEN]; defined = 1'b1; end
        `CSR_ADDR_MINSTRET      : begin rdata = instret_full[0+:`XPR_LEN]; defined = 1'b1; end
        `CSR_ADDR_MCYCLEH       : begin rdata = cycle_full[`XPR_LEN+:`XPR_LEN]; defined = 1'b1; end
        `CSR_ADDR_MINSTRETH     : begin rdata = instret_full[`XPR_LEN+:`XPR_LEN]; defined = 1'b1; end
        `CSR_ADDR_TIME          : begin rdata = mtime_full[0+:`XPR_LEN]; defined = 1'b1; end
        `CSR_ADDR_TIMEH         : begin rdata = mtime_full[`XPR_LEN+:`XPR_LEN]; defined = 1'b1; end

        `CSR_ADDR_MVENDORID     : begin rdata = mvendorid; defined = 1'b1; end
        `CSR_ADDR_MARCHID       : begin rdata = marchid; defined = 1'b1; end
        `CSR_ADDR_MIMPID        : begin rdata = mimpid; defined = 1'b1; end
        `CSR_ADDR_MHARTID       : begin rdata = mhartid; defined = 1'b1; end

        // non-standard
        // ...
        default : begin rdata = 0; defined = 1'b0; end
    endcase // case (addr)
end // always @ (*)

always @(posedge clk) begin
    if (reset) begin
        cnt_inhibit <= 'h0;
        cycle_full <= 0;
        instret_full <= 0;
        mtime_full <= 0;
        mtvec <= 'h0;
        mtimecmp <= 0;
        mscratch <= 0;
    end else begin
        if(cnt_inhibit[`CNTINHIBIT_CY]) begin
            cycle_full <= cycle_full + 1;
        end
        if (retire & cnt_inhibit[`CNTINHIBIT_IR]) begin
            instret_full <= instret_full + 1;
        end
        //if(cnt_inhibit[CNTINHIBIT_TM]) begin
        mtime_full <= mtime_full + 1;
        //end
        if (wen_internal) begin
            case (addr)
                // mstatus handled separately
                // misa is read-only
                // mtdeleg is constant;
                // mie handled separately
                `CSR_ADDR_MTVEC         : {mtvec[`XPR_LEN-1 : 2], mtvec_mode} <= wdata_internal;
                `CSR_ADDR_MCNTINHIBIT   : cnt_inhibit <= wdata_internal;
                `CSR_ADDR_MTIMECMP      : mtimecmp[0 +: `XPR_LEN] <= wdata_internal;
                `CSR_ADDR_MTIMECMPH     : mtimecmp[`XPR_LEN +: `XPR_LEN] <= wdata_internal;
                `CSR_ADDR_MSCRATCH      : mscratch <= wdata_internal;
                // mepc handled separately
                // mcause handled separately
                // mbadaddr handled separately
                // mip handled separately
                `CSR_ADDR_MCYCLE        : cycle_full[0+:`XPR_LEN] <= wdata_internal;
                `CSR_ADDR_MINSTRET      : instret_full[0+:`XPR_LEN] <= wdata_internal;
                `CSR_ADDR_MCYCLEH       : cycle_full[`XPR_LEN+:`XPR_LEN] <= wdata_internal;
                `CSR_ADDR_MINSTRETH     : instret_full[`XPR_LEN+:`XPR_LEN] <= wdata_internal;
                `CSR_ADDR_TIME          : mtime_full[0+:`XPR_LEN] <= wdata_internal;
                `CSR_ADDR_TIMEH         : mtime_full[`XPR_LEN+:`XPR_LEN] <= wdata_internal;
                // mvendorid is read-only
                // marchid is read-only
                // mimpid is read-only
                // mhartid is read-only
                default : ;
            endcase // case (addr)
        end // if (wen_internal)
    end // else: !if(reset)
end // always @ (posedge clk)

endmodule // vscale_csr_file
