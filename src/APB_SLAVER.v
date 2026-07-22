`timescale 1ns / 1ps

module APB_Slave #(
    parameter MEM_WIDTH = 32,
    parameter MEM_DEPTH = 1024,
    parameter ADDR_WIDTH = 32,
    parameter WAIT_STATES = 2
)
(

    input PCLK,
    input PRESETn,

    // APB Interface
    input PSEL,
    input PENABLE,
    input PWRITE,

    input [ADDR_WIDTH-1:0] PADDR,
    input [MEM_WIDTH-1:0] PWDATA,
    input [(MEM_WIDTH/8)-1:0] PSTRB,
    input [2:0] PPROT,

    output reg [MEM_WIDTH-1:0] PRDATA,
    output reg PSLVERR,
    output wire PREADY,
    input wire busy
    
);
//1024 entries × 32 bits (default)
reg [MEM_WIDTH-1:0] Cache [0:MEM_DEPTH-1];

wire [ADDR_WIDTH-1:0] word_addr;

assign word_addr = PADDR >> 2;      // Byte Address -> Word Address

wire addr_err;

//WAIT STATES
reg [1:0] wait_PRE;
always @(posedge PCLK or negedge PRESETn) begin
 if(!PRESETn) begin
  wait_PRE<=0;
 end else 
 if(!busy)begin
 wait_PRE<=0;
 end else begin
  if(PSEL && PENABLE) begin
   if(wait_PRE<WAIT_STATES) begin
   wait_PRE<=wait_PRE+1;
   end else begin
    wait_PRE<=0;
   end
   end else begin
    wait_PRE<=0;
   end
  end
 end
assign PREADY=busy?(wait_PRE==WAIT_STATES):1'b1;  

assign addr_err = (word_addr >= MEM_DEPTH);

always@(posedge PCLK or negedge PRESETn) begin
if(!PRESETn) begin
end
//WRITE_CACHE
else if(PSEL && PENABLE && PREADY && PWRITE && !addr_err &&(PPROT ==3'b000)) begin
 if(PSTRB[0]) begin
  Cache[word_addr] [7:0]<= PWDATA[7:0];
 end
 if(PSTRB[1]) begin
  Cache[word_addr] [15:8]<=PWDATA[15:8];
 end
 if(PSTRB[2]) begin
  Cache[word_addr] [23:16]<=PWDATA[23:16];
 end
 if(PSTRB[3]) begin
  Cache[word_addr] [31:24]<=PWDATA[31:24];
 end
end
end
always@(*) begin
//default 

PSLVERR=1'b0;
PRDATA=0;

//transaction completed
if(PSEL && PENABLE && PREADY) begin
//addr checked
if(PPROT==3'b000) begin
 if(!addr_err) begin
//WRITE
  if(PWRITE) begin
    PSLVERR=1'b0;
  end else begin
//READ
    if(PSTRB!=0) begin
       PSLVERR=1'b1;
    end else begin
       PRDATA=Cache[word_addr];
	PSLVERR=1'b0;
    end
  end
  end else begin
   PSLVERR = 1'b1;
  end
 end else begin
 PSLVERR=1'b1;
end
end
end
endmodule
  