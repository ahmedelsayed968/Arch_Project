/* address  description         comment
 * ------------------------------------------------------------------
 * 0x0      mode register       0=push-pull
 *                              1=open-drain
 * 0x1      direction register  0=input
 *                              1=output
 * 0x2      output register     mode-register=0? 0=drive pad low
 *                                               1=drive pad high
 *                              mode-register=1? 0=drive pad low
 *                                               1=open-drain
 * 0x3      input register      returns data at pad*/
  

module apb_gpio1 (APB_RESET_n,APB_CLK,APB_PSEL,APB_PENABLE,APB_PADDR,APB_PWRITE,APB_PSTRB,APB_PWDATA,APB_PRDATA,APB_PREADY,APB_PSLEVRR,GPIO_i,GPIO_o,GPIO_oe);
	parameter PDATA_SIZE = 32 ,PADDR_SIZE = 4; //must be multiple of 8
	localparam MODE = 0,DIRECTION = 1,OUTPUT= 2,INPUT= 3, INPUT_STAGES = 2;
	input APB_RESET_n, APB_CLK, APB_PENABLE, APB_PWRITE,APB_PSEL;
	input[PADDR_SIZE-1:0] APB_PADDR;
	input[PDATA_SIZE/8-1:0] APB_PSTRB;
	input[PDATA_SIZE-1:0] APB_PWDATA, GPIO_i;
	output reg[PDATA_SIZE-1:0]APB_PRDATA,GPIO_o,GPIO_oe;
	output reg APB_PREADY ;
	output reg APB_PSLEVRR;
	reg[PDATA_SIZE-1:0]input_regs[0:INPUT_STAGES-1] ,dir_reg,out_reg,in_reg, mode_reg ;
	integer i ,j,k,l,c=0;

	 //The core supports zero-wait state accesses on all transfers.
  //It is allowed to drive APB_PREADY with a hard wired signal
	task get_PSLEVRR_Status;
	input [PADDR_SIZE-1:0] in;
	output  error;
	begin
		for(l = 0 ; l < PADDR_SIZE ; l = l +1) begin
		if(in[l] === 1'bx ) begin
			c  = c +1 ;
			
		end	
	end	
	error = c? 1'b1 : 1'b0 ;
	end
	endtask

	
	//APB write to Mode register
  always @(posedge APB_CLK,negedge APB_RESET_n)
    if      (!APB_RESET_n) begin
	mode_reg <= {PDATA_SIZE{1'b0}};

	end
    else if (APB_PSEL & APB_PENABLE & APB_PWRITE & (APB_PADDR == MODE)) begin
			mode_reg[7:0] <= APB_PSTRB[0] ? APB_PWDATA[7:0] : mode_reg[7:0];
			mode_reg[15:8] <= APB_PSTRB[1] ? APB_PWDATA[15:8] : mode_reg[15:8];
			mode_reg[23:16] <= APB_PSTRB[2] ? APB_PWDATA[23:16] : mode_reg[23:16];
			mode_reg[31:24] <= APB_PSTRB[3] ? APB_PWDATA[31:24] : mode_reg[31:24];
			
		end	

	always @(posedge APB_CLK,negedge APB_RESET_n)
      if      (!APB_RESET_n )begin
        dir_reg <= {PDATA_SIZE{1'b0}};
        APB_PREADY <= 1'b0 ;
		APB_PSLEVRR <= 1'b0;
      end
		else if (APB_PSEL & APB_PENABLE & APB_PWRITE & (APB_PADDR == DIRECTION)) begin
			dir_reg[7:0] <= APB_PSTRB[0] ? APB_PWDATA[7:0] : dir_reg[7:0];
			dir_reg[15:8] <= APB_PSTRB[1] ? APB_PWDATA[15:8] : dir_reg[15:8];
			dir_reg[23:16] <= APB_PSTRB[2] ? APB_PWDATA[23:16] : dir_reg[23:16];
			dir_reg[31:24] <= APB_PSTRB[3] ? APB_PWDATA[31:24] : dir_reg[31:24];
			APB_PREADY <= 1'b1 ;
		end	
		
	always @(posedge APB_CLK,negedge APB_RESET_n) 
    if      (!APB_RESET_n ) out_reg <= {PDATA_SIZE{1'b0}};
    else if ( (APB_PSEL & APB_PENABLE & APB_PWRITE  &(APB_PADDR == OUTPUT)) || (APB_PSEL & APB_PENABLE & APB_PWRITE  &(APB_PADDR == INPUT))) begin
      if(APB_PREADY) begin
				out_reg[7:0] <= APB_PSTRB[0] ? APB_PWDATA[7:0] : out_reg[7:0];
				out_reg[15:8] <= APB_PSTRB[1] ? APB_PWDATA[15:8] : out_reg[15:8];
				out_reg[23:16] <= APB_PSTRB[2] ? APB_PWDATA[23:16] : out_reg[23:16];
				out_reg[31:24] <= APB_PSTRB[3] ? APB_PWDATA[31:24] : out_reg[31:24];
			end
			else
				out_reg<= 32'bz	;
		end	
		
	  /*
   * APB Reads
   */
  always @(posedge APB_CLK)
    case (APB_PADDR)
	  MODE     : APB_PRDATA <= mode_reg;	
      DIRECTION: APB_PRDATA <= dir_reg;
      OUTPUT   : APB_PRDATA <= out_reg;
      INPUT    :
        if((APB_PSEL & APB_PENABLE & ~APB_PWRITE  )) begin
			APB_PRDATA <= APB_PREADY? in_reg : 32'bz; //add condition
		end
		
      default  : APB_PRDATA <= {PDATA_SIZE{1'b0}};
    endcase	
	
	 always @(posedge APB_CLK) begin
		get_PSLEVRR_Status(GPIO_i,APB_PSLEVRR);
    for ( k=0; k<INPUT_STAGES; k = k +1)
       if (k==0) input_regs[k] <= GPIO_i;
       else      input_regs[k] <= input_regs[k-1];
	end
  always @(posedge APB_CLK)
    in_reg <= input_regs[INPUT_STAGES-1];
    //my modification
	
		
	 // mode
  // 0=push-pull    drive out_reg value onto transmitter input
  // 1=open-drain   always drive '0' onto transmitter
  always @(posedge APB_CLK)
    for (i=0; i<PDATA_SIZE; i = i +1)
      GPIO_o[i] <= mode_reg[i] ? 1'b0 : out_reg[i];


  // direction  mode          out_reg
  // 0=input                           disable transmitter-enable (output enable)
  // 1=output   0=push-pull            always enable transmitter
  //            1=open-drain  1=Hi-Z   disable transmitter
  //                          0=low    enable transmitter
  always @(posedge APB_CLK)
    for (j=0; j<PDATA_SIZE; j = j +1 )
      GPIO_oe[j] <= dir_reg[j] & ~(mode_reg[j] ? out_reg[j] : 1'b0)	;
endmodule	



//write TB
module aq();
  parameter PDATA_SIZE = 32 ,PADDR_SIZE = 4;
  reg APB_RESET_n, APB_PENABLE, APB_PWRITE, APB_PSEL;
  reg APB_CLK;
  reg[PADDR_SIZE-1:0] APB_PADDR;
	reg[PDATA_SIZE/8-1:0] APB_PSTRB;
	reg[PDATA_SIZE-1:0] APB_PWDATA, GPIO_i;
	wire[PDATA_SIZE-1:0]APB_PRDATA,GPIO_o,GPIO_oe;
	wire APB_PREADY, APB_PSLEVRR ;
	
  apb_gpio1 gpio(APB_RESET_n,APB_CLK,APB_PSEL,APB_PENABLE,APB_PADDR,APB_PWRITE,APB_PSTRB,APB_PWDATA,APB_PRDATA,APB_PREADY,APB_PSLEVRR,GPIO_i,GPIO_o,GPIO_oe);
  
  integer i;
	initial begin 
	$display("initially");
	$display("%b,%b,%b",GPIO_i, APB_PRDATA , APB_PREADY);
	 APB_CLK <= 1'b1;
	  APB_RESET_n <= 1'b0;
	  GPIO_i <= 32'b0;
	  #10;
	 APB_RESET_n <= 1'b1;
	 #10
	 //setting mode register
	 APB_PSEL <= 1'b1;
	 APB_PADDR<= 4'b0000;
	 APB_PWRITE <= 1'b1;
	 APB_PSTRB <= 4'b1111;
	 APB_PWDATA <= 0;
	 #10
	 APB_PENABLE <= 1'b1;
	 #10
	 $display("after setting mode register");
	$display("%b,%b,%b",GPIO_i, APB_PRDATA , APB_PREADY);

	///to test the wait state please comment lines 152 to 165...APB_PRDATA should be ZZZZZZ on waveform
	//clearing
	 #10
	 APB_PSEL <= 1'b0;
	 APB_PENABLE <= 1'b0;
	 //setting direction register
	 #10
	 APB_PSEL <= 1'b1;
	 APB_PADDR<= 4'b0001;
	 APB_PWRITE <= 1'b1;
	 APB_PSTRB <= 4'b1111;
	 APB_PWDATA <= 32'h00000000;
	 #10
	 APB_PENABLE <= 1'b1;
	 
	 
	
	 
	 //clearing
	  #10
	 APB_PSEL <= 1'b0;
	 APB_PENABLE <= 1'b0;
	 //reading data
	 GPIO_i<= 32'b1000X10 ;
	 #10
	 APB_PSEL <= 1'b1;
	 APB_PADDR<= 4'b0011;
	 APB_PWRITE <= 1'b0;
	 APB_PSTRB <= 4'b1111;
	  
	 #10
	 APB_PENABLE <= 1'b1;
	 #10
	 $display("after trying to write without setting direction register");
	$display("%b,%b,%b",GPIO_i, APB_PRDATA , APB_PREADY);
	
 
  end
  
  always 
		#5 APB_CLK = ~APB_CLK;
		
    
  
endmodule



//write TB
module aq();
  parameter PDATA_SIZE = 32 ,PADDR_SIZE = 4;
  reg APB_RESET_n, APB_PENABLE, APB_PWRITE, APB_PSEL;
  reg APB_CLK;
  reg[PADDR_SIZE-1:0] APB_PADDR;
	reg[PDATA_SIZE/8-1:0] APB_PSTRB;
	reg[PDATA_SIZE-1:0] APB_PWDATA, GPIO_i;
	wire[PDATA_SIZE-1:0]APB_PRDATA,GPIO_o,GPIO_oe;
	wire APB_PREADY, APB_PSLEVRR ;
	
  apb_gpio1 gpio(APB_RESET_n,APB_CLK,APB_PSEL,APB_PENABLE,APB_PADDR,APB_PWRITE,APB_PSTRB,APB_PWDATA,APB_PRDATA,APB_PREADY,APB_PSLEVRR,GPIO_i,GPIO_o,GPIO_oe);
  
  integer i;
	initial begin 
	$display("initially");
	$display("%b,%b,%b,%b",GPIO_o, APB_PWDATA , APB_PREADY,APB_PSLEVRR);
	 APB_CLK <= 1'b1;
	  APB_RESET_n <= 1'b0;
	  #10;
	 APB_RESET_n <= 1'b1;
	 #10
	 //setting mode register
	 APB_PSEL <= 1'b1;
	 APB_PADDR<= 4'b0000;
	 APB_PWRITE <= 1'b1;
	 APB_PSTRB <= 4'b1111;
	 APB_PWDATA <= 0;
	 #10
	 APB_PENABLE <= 1'b1;
	 #10
	 $display("after setting mode register");
	$display("%b,%b,%b,%b",GPIO_o, APB_PWDATA , APB_PREADY,APB_PSLEVRR);

	 
	 //clearing
	 #10
	 APB_PSEL <= 1'b0;
	 APB_PENABLE <= 1'b0;
	 //setting direction register
	 #10
	 APB_PSEL <= 1'b1;
	 APB_PADDR<= 4'b0001;
	 APB_PWRITE <= 1'b1;
	 APB_PSTRB <= 4'b1111;
	 APB_PWDATA <= 32'h00000000;
	 #10
	 APB_PENABLE <= 1'b1;
	 
	 
	
	 
	 //clearing
	  #10
	 APB_PSEL <= 1'b0;
	 APB_PENABLE <= 1'b0;
	 //writing data
	 APB_PWDATA<= 32'b10x1x ;
	 #10
	 APB_PSEL <= 1'b1;
	 APB_PADDR<= 4'b0010;
	 APB_PWRITE <= 1'b1;
	 APB_PSTRB <= 4'b1111;
	  
	 #10
	 APB_PENABLE <= 1'b1;
	 #10
	 $display("after trying to write without setting direction register");
	$display("%b,%b,%b,%b",GPIO_o, APB_PWDATA , APB_PREADY,APB_PSLEVRR);
	/*#20
	 /* 
	 //setting mode register
	 APB_PSEL <= 1'b1;
	 APB_PADDR<= 4'b0000;
	 APB_PWRITE <= 1'b1;
	 APB_PSTRB <= 4'b1111;
	 APB_PWDATA <= 0;
	 #10
	 APB_PENABLE <= 1'b1;  */
	  
	 //clearing
//	 #10
	// APB_PSEL <= 1'b0;
//	 APB_PENABLE <= 1'b0;
	 //setting direction register
//	 #10
//	 APB_PSEL <= 1'b1;
//	 APB_PADDR<= 4'b0001;
//	 APB_PWRITE <= 1'b1;
//	 APB_PSTRB <= 4'b1111;
//	 APB_PWDATA <= 32'h00000000;
//	 #10
//	 APB_PENABLE <= 1'b1;
	 
	 //clearing
//	  #10
//	 APB_PSEL <= 1'b0;
//	 APB_PENABLE <= 1'b0;
	 //writing data
	// APB_PWDATA<= 32'd15 ;
	// #10
	// APB_PSEL <= 1'b1;
	// APB_PADDR<= 4'b0010;
	// APB_PWRITE <= 1'b1;
	// APB_PSTRB <= 4'b1111;
	  
//	 #10
//	 APB_PENABLE <= 1'b1;
//	 #10
//	 $display("after trying to write after setting direction register");
//	$display("%b,%b,%b",GPIO_o, APB_PWDATA , APB_PREADY);
	
	/* for(i=0;i<10;i=i+1)begin
	   APB_PWDATA <= i;
	   #5
	   $display("%d,%d",GPIO_o,GPIO_oe);
	 end
	 
	 
	 APB_PWRITE <= 1'b0;
	 for(i=0;i<10;i=i+1)begin
	   GPIO_i <= i;
	   #5
	   $display("%d,%d",APB_PRDATA,GPIO_oe);
	 end*/

  end
  
  always 
		#5 APB_CLK = ~APB_CLK;
		
    
  
endmodule
  
  






