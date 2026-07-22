`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/07/2026 01:01:48 AM
// Design Name: 
// Module Name: APB_top_module
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module APB_top_module#(
parameter SIZE = 32
)(
    input wire                 PCLK,
    input wire                 PRESETn,
    input wire                 transfer,
    input wire                 sys_write,
    input wire [SIZE-1:0]      sys_addr,
    input wire [SIZE-1:0]      sys_wdata,
    input wire [(SIZE/8)-1:0]  sys_strb,
    input wire [2:0] sys_prot,
    output wire [SIZE-1:0]     sys_rdata,
    input wire busy,
    output wire sys_PSLVERR
);

    wire                 PSEL;
    wire                 PENABLE;
    wire                 PWRITE;
    wire [SIZE-1:0]      PADDR;
    wire [SIZE-1:0]      PWDATA;
    wire [(SIZE/8)-1:0]  PSTRB;
    wire [2:0]           PPROT;
    wire                 PREADY;
    wire [SIZE-1:0]      PRDATA;
    wire                 PSLVERR;
    
APB_MASTER #(
    .SIZE(SIZE)
) MASTER(
  .PCLK(PCLK),
  .PRESETn(PRESETn),
  .transfer(transfer),
  .sys_write(sys_write),
  .sys_addr(sys_addr),
  .sys_wdata(sys_wdata),
  .sys_strb(sys_strb),
  .sys_rdata(sys_rdata),
  .PSEL(PSEL),
  .PENABLE(PENABLE),
  .PWRITE(PWRITE),
  .PADDR(PADDR),
  .PWDATA(PWDATA),
  .PSTRB(PSTRB),
  .PPROT(PPROT),
  .PREADY(PREADY),
  .PRDATA(PRDATA),
  .PSLVERR(PSLVERR),
  .sys_PSLVERR(sys_PSLVERR),
  .sys_prot(sys_prot)
    );
APB_Slave #(
  .MEM_WIDTH(SIZE),
  .MEM_DEPTH(1024),
  .ADDR_WIDTH(SIZE),
  .WAIT_STATES(2)
    ) SLAVE (
  .PCLK(PCLK),
  .PRESETn(PRESETn),
  .PSEL(PSEL),
  .PENABLE(PENABLE),
  .PWRITE(PWRITE),
  .PADDR(PADDR),
  .PWDATA(PWDATA),
  .PSTRB(PSTRB),
  .PPROT(PPROT),
  .PRDATA(PRDATA),
  .PSLVERR(PSLVERR),
  .PREADY(PREADY),
  .busy(busy)
    );
endmodule
