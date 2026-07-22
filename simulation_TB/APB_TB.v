    `timescale 1ns/1ps
    
    module APB_TB;
    
    parameter SIZE = 32;
    reg PCLK;
    reg PRESETn;
    reg transfer;
    reg sys_write;
    reg [SIZE-1:0]sys_addr;
    reg [SIZE-1:0]sys_wdata;
    reg [(SIZE/8)-1:0]sys_strb;
    wire [SIZE-1:0]sys_rdata;
    reg busy;
    wire sys_PSLVERR;
    reg [2:0] sys_prot;
APB_top_module #(
.SIZE(SIZE)
) DUT (
.PCLK(PCLK),
.PRESETn(PRESETn),
.transfer(transfer),
.busy(busy),
.sys_write(sys_write),
.sys_addr(sys_addr),
.sys_wdata(sys_wdata),
.sys_strb(sys_strb),
.sys_rdata(sys_rdata),
.sys_PSLVERR(sys_PSLVERR),
.sys_prot(sys_prot)
);
initial begin
PCLK=0;
forever #10 PCLK=~PCLK;
end

initial begin
//reset
$display("Test PRESETn");
PRESETn=0;
transfer=1;
sys_write=1;
sys_addr=32'h00000017;
sys_wdata=32'h12345678;
sys_strb=4'b0110;
busy=1;
sys_prot = 3'b000;
//AT 20ns
#20;
$display("TEST1: WRITE");
//WRITE
sys_prot = 3'b000;
PRESETn=1;
transfer=1;
sys_write=1;
sys_addr=32'h00000004;
sys_wdata=32'h12345678;
sys_strb=4'b1110;
busy=0;

//disturbing
//At 35ns
#15
PRESETn=1;
sys_addr  = 32'h00000008;
sys_wdata = 32'hAAAAAAAA;

//disturbing
//AT 45ns
#10;
PRESETn=1;
sys_addr  = 32'h0000000C;
sys_wdata = 32'h55AA55AA;
//

//AT 50ns, CHANGE VALUE
@(posedge PCLK);
#1;
$display("%0t change value for back-to-back",$time);
transfer  = 1;
sys_write = 1;
sys_addr  = 32'h00000026;
sys_wdata = 32'h98765432;
sys_strb  = 4'b0110;
busy      = 0;

//test next_writing AT 70ns
wait(DUT.MASTER.PENABLE);
@(posedge PCLK);
wait(DUT.SLAVE.PREADY);

//AT 90ns
@(posedge PCLK);
#1;
transfer = 0;
$display("%0t Before @(posedge PCLK)", $time);
//AT 110ns,value must be stable
@(posedge PCLK);

$display("%0t After @(posedge PCLK)", $time);
#1;
transfer  = 1;
busy      = 1;
sys_write = 1;
sys_addr  = 32'h00000030;
sys_wdata = 32'hCAFEBABE;
sys_strb  = 4'b1111;

//SETUP_PHASE
wait(DUT.MASTER.PENABLE);
//ACCESS_PHASE
wait(DUT.SLAVE.PREADY);
//END AT 190ns(210ns WRITE_CACHE)
//AT 210ns
@(posedge PCLK);
#1;
$display("%0t,Cache[12]=%h", $time,DUT.SLAVE.Cache[12]);

transfer = 0;
busy     = 0;

//////////////////////////////////////////////////////////////////// END WRITE
//AT 230ns
@(posedge PCLK);
//reset before beginging read_state
transfer = 0;
busy     = 0;

PRESETn = 0;

//AT 250ns,value must be stable

@(posedge PCLK);
$display("%0t,TEST2: READ(no busy)",$time);
PRESETn = 1;
PRESETn    = 1;
transfer   = 1;
sys_write  = 0;
sys_addr   = 32'h00000004;
sys_strb   = 4'b0000;
busy       = 0;

//AT 270ns
@(posedge PCLK);
#1;
transfer  = 1;
sys_write = 0;
sys_addr  = 32'h00000030;
sys_wdata = 32'hDEADBEEF;
sys_strb  = 4'b0000;
busy      = 0;
wait(DUT.SLAVE.PENABLE);
@(posedge PCLK);
wait(DUT.SLAVE.PREADY);



$display("%0t Read Data (none busy) = %h",$time, sys_rdata);
//END TRANSACTION READ_1

//AT 330ns
@(posedge PCLK);
transfer = 0;


//READ(busy=1)(wait_states)
@(posedge PCLK);
#1;
//AT 350ns
$display("TEST3: READ(busy)");
transfer  = 1;
sys_write = 0;
sys_addr  = 32'h00000008;
sys_strb  = 4'b0000;
busy      = 1;
// Chờ Access phase
wait(DUT.MASTER.PENABLE);
wait(DUT.SLAVE.PREADY);
//AT 470ns
repeat(2) @(posedge PCLK);
#1;
$display("%0t Read Data (busy=1) = %h",$time, sys_rdata);
///////////////////////////////////////////////////////////////END_READ
//RESET
//AT 490ns
@(posedge PCLK)
PRESETn=0;
transfer=0;

//TEST_ADDR_ERR(PLSVERR)
$display("%0t:current",$time);
//AT 510ns
@(posedge PCLK);
PRESETn=1;
transfer=1;
sys_write=1;
sys_addr=32'h00002000;//ERROR
sys_wdata=32'h98765432;
sys_strb=4'b0110;
busy=0;
//BACK-TO-BACK
@(posedge PCLK);
#1;
PRESETn=1;
transfer=1;
sys_write=1;
sys_addr=32'h00000004;
sys_wdata=32'h12345678;
sys_strb=4'b0010;
busy=0;
$display("%0t:current",$time);
wait(DUT.MASTER.PENABLE);
@(posedge PCLK);
wait(DUT.SLAVE.PREADY);

//AT 670ns,turn off signals
repeat(5) @(posedge PCLK);
PRESETn=0;
transfer=0;
sys_write=0;
sys_addr=32'h00000000;
sys_wdata=32'h00000000;
sys_strb=4'b0000;
busy=0;
end
always @(posedge PCLK) begin
#1;
$display("[%0t] PSEL=%b PENABLE=%b PREADY=%b PADDR=%h PWDATA=%h Cache[1]=%h",$time,
DUT.MASTER.PSEL,
DUT.MASTER.PENABLE,
DUT.SLAVE.PREADY,
DUT.MASTER.PADDR,
DUT.MASTER.PWDATA,
DUT.SLAVE.Cache[1]);
end

endmodule