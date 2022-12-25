


module final_test_bench();
  parameter PDATA_SIZE = 32 ,PADDR_SIZE = 4;
  reg PRESETn, PENABLE, PWRITE, PSEL;
  reg PCLK;
  reg[PADDR_SIZE-1:0] PADDR;
	reg[PDATA_SIZE/8-1:0] PSTRB;
	reg[PDATA_SIZE-1:0] PWDATA, gpio_i;
	wire[PDATA_SIZE-1:0]PRDATA,gpio_o,gpio_oe;
	wire PREADY, PSLEVRR ;
	 integer k = 1;
  apb_gpio1 gpio(PRESETn,PCLK,PSEL,PENABLE,PADDR,PWRITE,PSTRB,PWDATA,PRDATA,PREADY,PSLEVRR,gpio_i,gpio_o,gpio_oe);
  
  integer i;
	initial begin 
	  $display("gpio out\tgpio enable\tgpio inut\tPWDATA\tPRDATA");
	$monitor("%h, %h, %h, %h, %h,%b",gpio_o,gpio_oe,gpio_i,PWDATA,PRDATA,PSTRB);
	 PCLK <= 1'b1;
	 PRESETn <= 1'b1;
	 
	 //setting mode register
	 PSEL <= 1'b1;
	 PADDR<= 4'b0000;
	 PWRITE <= 1'b1;
	 PSTRB <= 4'b1111;
	 PWDATA <= 0;
	 #10
	 PENABLE <= 1'b1;
	 

	 //clearing
	 #10
	 PSEL <= 1'b0;
	 PENABLE <= 1'b0;
	 //setting direction register
	 #10
	 PSEL <= 1'b1;
	 PADDR<= 4'b0001;
	 PWRITE <= 1'b1;
	 PSTRB <= 4'hf;
	 PWDATA <= 32'hffffffff;
	 #10
	 PENABLE <= 1'b1;
	 
	

	 //clearing
	  #10
	 PSEL <= 1'b0;
	 PENABLE <= 1'b0;
	 //writing data
	 #10
	 PSEL <= 1'b1;
	 PADDR<= 4'b0010;
	 PWRITE <= 1'b1;
	 
	 // testing setting each bit once
	 PSTRB <= 8'hff;
	 #10
	
	 for(i=0;i<32;i=i+1)begin
		PENABLE <= 1'b0;
	   PWDATA <= k<<i;
	   #10
	   PENABLE <= 1'b1;
	   #10;
	 end
	 
	 
	 
	// testing allowing writting on one bit at once
	
	#10;
	$display("***********************************************************************");
	 $display("gpio out\tgpio enable\tgpio inut\tPWDATA\tPRDATA");

	 for(i=0;i<32;i=i+1)begin
		PENABLE <= 1'b0;
		PSTRB <= 4'hf;
		PWDATA <= 0;
		#10
		PENABLE <= 1'b1;
		#10
		PENABLE <= 1'b0;
		PSTRB <= i;
	   PWDATA <= -1;
	   #10
	   PENABLE <= 1'b1;
	   #10;
	 end
	
	 
  end
  
  always 
		#5 PCLK = ~PCLK;
		
    
  
endmodule


