//=========================================================================================================================================================
// Ahmed Adel Hassan , ID: 1900311
// Ahmed Abd Elmotelb Ali, ID:1901401
//=========================================================================================================================================================
`timescale 1ns/100ps
 
module APB_BUS_TB ();


//Parameters and input/output signals==============================================================================================================================

parameter DATA_WIDTH_TB = 'd32,
 			 ADDRESS_WIDTH_TB = 'd4,// using two Slaves (UARTS, GPIO)
  			 STRB_WIDTH_TB = 'd4,
   			 SLAVES_NUM_TB = 'd2;
  reg  [DATA_WIDTH_TB-1:0]     IN_DATA_TB   ;    
  reg  [DATA_WIDTH_TB-1:0]     PRDATA_TB    ;         
  reg                          IN_WRITE_TB  ;   
  reg  [STRB_WIDTH_TB-1:0]     IN_STRB_TB   ;    
  reg                          Transfer_TB  ;   
  reg                          PREADY_TB    ;     
  reg                          PSLVERR_TB   ;  
  reg                          PCLK_TB      ;      
  reg                          PRESETn_TB   ;    
  reg  [ADDRESS_WIDTH_TB-1:0]  IN_ADDR_TB   ;    
              
 wire                          OUT_SLVERR_TB;  
 wire   [DATA_WIDTH_TB-1:0]    OUT_RDATA_TB ;  
 wire   [ADDRESS_WIDTH_TB-1:0] PADDR_TB     ;      
 wire   [DATA_WIDTH_TB-1:0]    PWDATA_TB    ;     
 wire                          PWRITE_TB    ;     
 wire                          PENABLE_TB   ;         
 wire   [STRB_WIDTH_TB-1:0]    PSTRB_TB     ;      
 wire   [SLAVES_NUM_TB-1:0]    PSEL_TB      ;  

 

//Initial Block=============================================================================================================================================

initial
begin
	init();
	
	rst();
	
    $display("////////////////////////////////////// write opteration with no waits//////////////////////////////////////////");
    write_no_wait('b10,'b01);
  
    $display("/////////////////////////////////////Test write opteration with waits////////////////////////////////////////////");
    write_with_wait('b10,'b01);
  
  	$display("/////////////////////////////////////Test read opteration with no waits//////////////////////////////////////////");
    read_no_wait('b10,'b01);
  
    $display("/////////////////////////////////////Test read opteration with waits////////////////////////////////////////////");
    read_with_wait('b10,'b01);
	
  #20

$finish;
end


//Clock_Generator

 always #5 PCLK_TB = ~ PCLK_TB;
 

//DUT instantiation===================================================================================================================================================

 APB_BUS #(.DATA_WIDTH(DATA_WIDTH_TB),  .ADDRESS_WIDTH(ADDRESS_WIDTH_TB), .STRB_WIDTH(STRB_WIDTH_TB), .SLAVES_NUM(SLAVES_NUM_TB))
 DUT (
 .PCLK(PCLK_TB),
 .PRESETn(PRESETn_TB),
 .IN_ADDR(IN_ADDR_TB),
 .IN_DATA(IN_DATA_TB),
 .PRDATA(PRDATA_TB),
 .IN_WRITE(IN_WRITE_TB),
 .Transfer(Transfer_TB),
 .PREADY(PREADY_TB),
 .PSLVERR(PSLVERR_TB),
 .IN_STRB(IN_STRB_TB),
	
 .PSTRB(PSTRB_TB),
 .OUT_SLVERR(OUT_SLVERR_TB),
 .OUT_RDATA(OUT_RDATA_TB),
 .PADDR(PADDR_TB),
 .PWDATA(PWDATA_TB),
 .PWRITE(PWRITE_TB),
 .PENABLE(PENABLE_TB),
 .PSEL(PSEL_TB)
 );


task init();
 begin
	# 10

	PCLK_TB = 'b0;
	PRESETn_TB = 'b1;
	PSLVERR_TB = 'b0;
	Transfer_TB = 'b0;
	PREADY_TB = 'b0;
	IN_ADDR_TB = 4'b1011;//let any address
	IN_DATA_TB = 'd0;
	IN_STRB_TB = 'b0101;
	IN_WRITE_TB = 'b0;
	PRDATA_TB = 'b0;
	end 
endtask

task rst();
 begin
	PRESETn_TB = 'b1;	
	#10 	
	PRESETn_TB = 'b0;	
	#10 	
	PRESETn_TB = 'b1;	
	end 
endtask


//Write operation with no waits==================================================================================================================================

task write_no_wait(
    input reg  [SLAVES_NUM_TB-1:0]  SLAVE1,
	 input reg  [SLAVES_NUM_TB-1:0]  SLAVE2
); 
begin
    #10
  Transfer_TB = 'b1;
	IN_ADDR_TB = 4'b1111;              //address = 1111
	IN_DATA_TB = 'd240;
	IN_WRITE_TB = 'b1;
	PREADY_TB = 'b0;
    #15
    $display("************First write operation test************");
    if (PSEL_TB == SLAVE1 && PADDR_TB == IN_ADDR_TB && PWDATA_TB == IN_DATA_TB)
       $display("First Setup process done successfully with no errors :-) ");	
	else
       $display("Same thing going wrong :-( ,First Setup process has an error");	
	#5
	
	PREADY_TB = 'b1;
	#10
	//Put the second transfer data
	IN_ADDR_TB = 4'b0001;           //address =0001;
	IN_DATA_TB = 'd15;
	PREADY_TB = 'b0;

	#5
    if (PENABLE_TB == 1'b0)
       $display("First write operation done successfully with no errors :-)");	
	else
       $display("First write operation has an error");	
  
	#5
	$display("************Second write operation test************");
    if (PSEL_TB == SLAVE2 && PADDR_TB == IN_ADDR_TB && PWDATA_TB == IN_DATA_TB)
       $display("Second Setup process done successfully with no errors :-)");	
	else
       $display("Same thing going wrong :-( ,Second Setup process has an error");	
	   
	PREADY_TB = 'b1;
	Transfer_TB = 'b0;
	#10
	PREADY_TB = 'b0;
	#5
    if (PENABLE_TB == 1'b0)
       $display("Second write operation done successfully with no errors :-)");	
	else
       $display("Second write operation has an error");	
    
	  #15
	  $display("************No anthoer write operation needed test************");
	  if (PENABLE_TB == 1'b0)
       $display("Master return to idle state successsfully when no anthor wirte operation needed");	
	else
       $display("Master operation has an error");
end
endtask



//Write operation with waits=========================================================================================================================================

task write_with_wait(
    input reg  [SLAVES_NUM_TB-1:0]  SLAVE1,
	 input reg  [SLAVES_NUM_TB-1:0]  SLAVE2
);
begin
  #10
  Transfer_TB = 'b1;
	IN_ADDR_TB = 4'b1111;              //address = 1111
	IN_DATA_TB = 'd240;
	IN_WRITE_TB = 'b1;
	PREADY_TB = 'b0;
    #15
    $display("************First write operation test************");
    if (PSEL_TB == SLAVE1 && PADDR_TB == IN_ADDR_TB && PWDATA_TB == IN_DATA_TB)
       $display("First Setup process done successfully with no errors :-)");	
	else
       $display("Same thing going wrong :-( ,First Setup process has an error");	
	#25
	if (PENABLE_TB == 1'b1)
       $display("Master is waiting");	
	else
       $display("An Error occur: Master didn't wait");	
       
	PREADY_TB = 'b1;
	#10
	//Put the second transfer data
	IN_ADDR_TB = 4'b0001;           //address = 0001;
	IN_DATA_TB = 'd15;
	PREADY_TB = 'b0;
	
	#5
    if (PENABLE_TB == 1'b0)
       $display("First write operation done successfully with no errors :-)");	
	else
       $display("First write operation has an error");	
  
	#5
	$display("************Second write operation test************");
    if (PSEL_TB == SLAVE2 && PADDR_TB == IN_ADDR_TB && PWDATA_TB == IN_DATA_TB)
       $display("Second Setup process done successfully with no errors :-)");	
	else
       $display("Same thing going wrong :-( ,Second Setup process has an error");
	
	#20
	if (PENABLE_TB == 1'b1)
       $display("Master is waiting");	
	else
       $display("An Error occur: Master didn't wait");	
       
	PREADY_TB = 'b1;
	Transfer_TB = 'b0;
	#10
	PREADY_TB = 'b0;
	#5
    if (PENABLE_TB == 1'b0)
       $display("Second write operation done successfully with no errors :-)");	
	else
       $display("Second write operation has an error");	
    
	  #15
	  $display("************No anthoer write operation needed test************");
	  if (PENABLE_TB == 1'b0)
       $display("Master return to idle state successsfully when no anthor wirte operation needed");	
	else
       $display("Master operation has an error");
end
endtask


//Read operation with no waits===================================================================================================================================
 
task read_no_wait(
    input reg  [SLAVES_NUM_TB-1:0]  SLAVE1,
	 input reg  [SLAVES_NUM_TB-1:0]  SLAVE2
);
begin
    #10
    Transfer_TB = 'b1;
	IN_ADDR_TB = 4'b1111;              //address = 1111
	IN_WRITE_TB = 'b0;
	PREADY_TB = 'b0;
    #15
    $display("************First read operation test************");
    if (PSEL_TB == SLAVE1 && PADDR_TB == IN_ADDR_TB)
       $display("First Setup process done successfully with no errors :-)");	
	else
       $display("Same thing going wrong :-( ,First Setup process has an error");	
	#5
	
	PREADY_TB = 'b1;
	PRDATA_TB = 'd240;
  #10
  //Put the second transfer data
	IN_ADDR_TB = 4'b0001;           //address =0001;
	PREADY_TB = 'b0;

	#5
	if (OUT_RDATA_TB == PRDATA_TB && PENABLE_TB == 1'b0)
       $display("First read operation done successfully with no errors :-)");	
	else
       $display("First read operation has an error");	

	   
	$display("************Second read operation test************");
    if (PSEL_TB == SLAVE2 && PADDR_TB == IN_ADDR_TB)
       $display("Second Setup process done successfully with no errors :-)");	
	else
       $display("Same thing going wrong :-( ,Second Setup process has an error");		
	   
	#5
	PREADY_TB = 'b1;
	PRDATA_TB = 'd15;
	#5
	Transfer_TB = 'b0;
    #5
	PREADY_TB = 'b0;
	#5
    if (OUT_RDATA_TB == PRDATA_TB && PENABLE_TB == 1'b0)
       $display("Second read operation done successfully with no errors :-)");	
	else
       $display("Second read operation has an error");	
   
	
	  #25
	  $display("************No anthoer read operation needed test************");
	  if (PENABLE_TB == 1'b0)
       $display("Master return to idle state successsfully when no anthor read operation needed");	
	else
       $display("Master operation has an error");
end
endtask




//Read operation with waits===============================================================================================================================

task read_with_wait(
    input reg  [SLAVES_NUM_TB-1:0]  SLAVE1,
	 input reg  [SLAVES_NUM_TB-1:0]  SLAVE2
);
begin
    #10
    Transfer_TB = 'b1;
	IN_ADDR_TB = 4'b1111;              //address = 1111
	IN_WRITE_TB = 'b0;
	PREADY_TB = 'b0;
    #15
    $display("************First read operation test************");
    if (PSEL_TB == SLAVE1 && PADDR_TB == IN_ADDR_TB)
       $display("First Setup process done successfully with no errors :-)");	
	else
       $display("Same thing going wrong :-( ,First Setup process has an error");		
	#25
	if (PENABLE_TB == 1'b1)
       $display("Master is waiting");	
	else
       $display("An Error occur: Master didn't wait");	
	
	PREADY_TB = 'b1;
	PRDATA_TB = 'd240;
    #10
	//Put the second transfer data
	IN_ADDR_TB = 4'b0001;           //address =0001;
	PREADY_TB = 'b0;

	#5
	if (OUT_RDATA_TB == PRDATA_TB && PENABLE_TB == 1'b0)
       $display("First read operation done successfully with no errors :-)");	
	else
       $display("First read operation has an error");
	
  
	$display("************Second read operation test************");
    if (PSEL_TB == SLAVE2 && PADDR_TB == IN_ADDR_TB)
       $display("Second Setup process done successfully with no errors :-)");	
	else
       $display("Same thing going wrong :-( ,Second Setup process has an error");
	   
	#25
	if (PENABLE_TB == 1'b1)
       $display("Master is waiting");	
	else
       $display("An Error occur: Master didn't wait");	
	   
	PREADY_TB = 'b1;
	PRDATA_TB = 'd15;
	#5
	Transfer_TB = 'b0;
    #5
	PREADY_TB = 'b0;
	#5
    if (OUT_RDATA_TB == PRDATA_TB && PENABLE_TB == 1'b0)
       $display("Second read operation done successfully with no errors :-)");	
	else
       $display("Second read operation has an error");	
  
	
	  #25
	  $display("************No anthoer read operation needed test************");
	  if (PENABLE_TB == 1'b0)
       $display("Master return to idle state successsfully when no anthor read operation needed");	
	else
       $display("Master operation has an error");
end
endtask
endmodule


