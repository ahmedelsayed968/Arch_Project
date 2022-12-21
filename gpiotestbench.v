module apb_gpio_test_bench();
  parameter PDATA_SIZE = 32 ,PADDR_SIZE = 4;
  reg PRESETn, PENABLE, PWRITE, PSEL;
  reg PCLK;
  reg[PADDR_SIZE-1:0] PADDR;
	reg[PDATA_SIZE/8-1:0] PSTRB;
	reg[PDATA_SIZE-1:0] PWDATA, gpio_i;
	wire[PDATA_SIZE-1:0]PRDATA,gpio_o,gpio_oe;
	wire PREADY, PSLEVRR ;
	
  apb_gpio gpio(PRESETn,PCLK,PSEL,PENABLE,PADDR,PWRITE,PSTRB,PWDATA,PRDATA,PREADY,PSLEVRR,gpio_i,gpio_o,gpio_oe);
  
  integer i;
	initial begin 
	 PCLK <= 1'b0;
	 PRESETn <= 1'b1;
	 PENABLE <= 1'b1;
	 
	 PSEL <= 1'b1;
	 PADDR<= 4'b0010;
	 PSTRB <= 4'b1111;
	 
	 PWRITE <= 1'b1;
	 
	 PWDATA <= 30;
	/* for(i=0;i<10;i=i+1)begin
	   PWDATA <= i;
	   #5
	   $display("%d,%d",gpio_o,gpio_oe);
	 end
	 
	 
	 PWRITE <= 1'b0;
	 for(i=0;i<10;i=i+1)begin
	   gpio_i <= i;
	   #5
	   $display("%d,%d",PRDATA,gpio_oe);
	 end*/
	 
  end
  
  always 
		#5 PCLK = ~PCLK;
		
    
  
endmodule
