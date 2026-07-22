`timescale 1ns/1ps

module APB_MASTER #(
parameter SIZE = 32
)
(
input  wire PCLK,
input  wire PRESETn,
input  wire transfer,
input  wire sys_write,
input  wire [SIZE-1:0]sys_addr,
input  wire [SIZE-1:0]sys_wdata,
input  wire [(SIZE/8)-1:0]sys_strb,
output reg  [SIZE-1:0]sys_rdata,
output reg sys_PSLVERR,
output reg PSEL,
output reg PENABLE,
output reg PWRITE,
output reg [SIZE-1:0]PADDR,
output reg [SIZE-1:0]PWDATA,
output reg [(SIZE/8)-1:0]PSTRB,
output reg [2:0]PPROT,
input  wire PREADY,
input  wire [SIZE-1:0]PRDATA,
input  wire PSLVERR,
input wire [2:0] sys_prot
);
localparam IDLE_PHASE=3'b001;
localparam SETUP_PHASE=3'b010;
localparam ACCESS_PHASE=3'b100;
reg write_reg;
reg [SIZE-1:0]addr_reg;
reg [SIZE-1:0]wdata_reg;
reg [(SIZE/8)-1:0]strb_reg;
reg [2:0] current_state;
reg [2:0] next_state;
reg [2:0] prot_reg;


always @(posedge PCLK or negedge PRESETn) begin
if(!PRESETn)begin
 current_state <= IDLE_PHASE;
 write_reg<=1'b0;
 addr_reg<=0;
 wdata_reg<=0;
 strb_reg<=0;
 sys_rdata<=0;
 sys_PSLVERR<=1'b0;
 prot_reg  <= 3'b000;
end else begin
 current_state <= next_state;
 sys_PSLVERR<=1'b0;
 //WRITE_DATA
   if(current_state==IDLE_PHASE && transfer) begin
    addr_reg<=sys_addr;
    write_reg<=sys_write;
    wdata_reg<=sys_wdata;
    strb_reg<=sys_strb;
    prot_reg  <= sys_prot;
     //NEW VALUE FROM SYSTEM TO SETUP_PHASE
   end
   if (current_state == ACCESS_PHASE && PREADY && transfer) begin
    write_reg <= sys_write;
    addr_reg  <= sys_addr;
    wdata_reg <= sys_wdata;
    strb_reg  <= sys_strb;
    prot_reg  <= sys_prot;
   end 
    //READ_DATA
   if (current_state == ACCESS_PHASE && PREADY) begin
    if(PSLVERR) begin
    sys_PSLVERR<=PSLVERR;
    end else begin
     sys_PSLVERR<=1'b0;
     if(!write_reg) begin       
    sys_rdata <= PRDATA;
   end
  end
 end
end
end
always @(*) begin
 next_state=current_state;
 
 case(current_state)
 IDLE_PHASE: begin 
 if(transfer) begin
  next_state=SETUP_PHASE;
 end else 
  next_state=IDLE_PHASE;
 end
 SETUP_PHASE: begin
  next_state=ACCESS_PHASE;
 end
 ACCESS_PHASE: begin
 if(PREADY) begin
   if(transfer) begin
   next_state=SETUP_PHASE;
   end else begin
   next_state=IDLE_PHASE;
   end
 end else begin
  next_state=ACCESS_PHASE;
 end
 end
  default: begin
  next_state=IDLE_PHASE;
  end
 endcase
end

//OUTPUT MOORE FSM
always @(*)begin
 PSEL=0;
 PENABLE=0;
 PWRITE=0;
 PADDR=0;
 PWDATA=0;
 PSTRB=0;
 PPROT=3'b000;
 case(current_state)
 IDLE_PHASE: begin
//default
 end
 SETUP_PHASE: begin
 PSEL=1;
 PENABLE=0;
 PWRITE=write_reg;
 PADDR=addr_reg;
 PWDATA=wdata_reg;
 PSTRB=strb_reg;
 PPROT   = prot_reg;
 end
 ACCESS_PHASE:begin
 PSEL=1'b1;
 PENABLE=1'b1;
 PWRITE=write_reg;
 PADDR=addr_reg;
 PWDATA=wdata_reg;
 PSTRB=strb_reg;
 PPROT=prot_reg;
 end
 endcase
 end
endmodule