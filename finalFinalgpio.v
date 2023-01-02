//                APB  GPIO  module                                 //
//                                                                 //
/////////////////////////////////////////////////////////////////////
//                                                                 //
//                Mina Mounir Farid Gendi 1901384                  //
//                                                                 //
//                                                                 //
//   Standard File Header Section  -------
// FILE NAME      : APB_GPIO.v
// AUTHOR         : Mina Mounir  Farid Gendi
// DEPARTMENT     : Senior 1 Section 4 CSE Department Ain Shams University 
// AUTHOR'S EMAIL : 1901384@eng.asu.edu.eg
// ------------------------------------------------------------------
// RELEASE HISTORY

// KEYWORDS :  APB General Purpose IO GPIO     
// ------------------------------------------------------------------
// PURPOSE  : General purpose IO          
// ------------------------------------------------------------------
// PARAMETERS
//  PARAM NAME        RANGE    DESCRIPTION              DEFAULT UNITS
//  PDATA_SIZE        1+       Databus (and GPIO) size  32       bits
//  PADDR_SIZE        1+       Addrbus (and GPIO) size  4        bits
// ------------------------------------------------------------------
// REUSE ISSUES 
//   Reset Strategy      : external asynchronous active low; PRESETn
//   Clock Domains       : PCLK, rising edge
//   Clock frequency     : 770MHz (optimized)
//   Test Features       : na
//   Asynchronous I/F    : no
//   Scan Methodology    : na
//   Instantiations      : in GPIO testbench
//   Synthesizable (y/n) : Yes
//   APB role			 : slave       
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
  

module APB_GPIO (APB_RESET_n,APB_CLK,APB_PSEL,APB_PENABLE,APB_PADDR,APB_PWRITE,APB_PSTRB,APB_PWDATA,APB_PRDATA,APB_PREADY,APB_PSLEVRR,GPIO_i,GPIO_o,GPIO_oe);
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
	integer i ,j,k,l,c=0; //iteration variables for the "for" loop statements
//task to always get the status of PSLEVRR  
	task get_PSLEVRR_Status;
	input [PADDR_SIZE-1:0] in;
	output  error;
	begin
		for(l = 0 ; l < PADDR_SIZE ; l = l +1) begin
		if(in[l] === 1'bx ) begin 
			c  = c +1 ;  //count number of errors
	   end	
	end	
	error = c? 1'b1 : 1'b0 ; //if errors > 0 then drive PSLEVRR to 1
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
	//APB write to direction register
	//also marks the slave ready for transaction and error free 
  always @(posedge APB_CLK,negedge APB_RESET_n) 
      if      (!APB_RESET_n )begin
        dir_reg <= {PDATA_SIZE{1'b0}};
        APB_PREADY <= 1'b0 ;
		APB_PSLEVRR <= 1'b0;
      end
	  else begin 
        get_PSLEVRR_Status(GPIO_i,APB_PSLEVRR);
	  if (APB_PSEL & APB_PENABLE & APB_PWRITE & (APB_PADDR == DIRECTION)) begin
			dir_reg[7:0] <= APB_PSTRB[0] ? APB_PWDATA[7:0] : dir_reg[7:0];
			dir_reg[15:8] <= APB_PSTRB[1] ? APB_PWDATA[15:8] : dir_reg[15:8];
			dir_reg[23:16] <= APB_PSTRB[2] ? APB_PWDATA[23:16] : dir_reg[23:16];
			dir_reg[31:24] <= APB_PSTRB[3] ? APB_PWDATA[31:24] : dir_reg[31:24];
			APB_PREADY <= 1'b1 ;
			APB_PSLEVRR <= 1'b0;
		end	
	 end
	//APB write to Output register
    //treat writes to Input register same		
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
        if((APB_PSEL & APB_PENABLE & ~APB_PWRITE )) begin
				APB_PRDATA[7:0] <= APB_PSTRB[0] ? in_reg[7:0] : APB_PRDATA[7:0];
				APB_PRDATA[15:8] <= APB_PSTRB[1] ? in_reg[15:8] : APB_PRDATA[15:8];
				APB_PRDATA[23:16] <= APB_PSTRB[2] ? in_reg[23:16] : APB_PRDATA[23:16];
				APB_PRDATA[31:24] <= APB_PSTRB[3] ? in_reg[31:24] : APB_PRDATA[31:24];
					
		end
		
      default  : APB_PRDATA <= {PDATA_SIZE{1'b0}};
    endcase	
	//internal regs used to stablize input to avoid metastability (avoid  setup and hold time violations)
	 always @(posedge APB_CLK) begin
	   for ( k=0; k<INPUT_STAGES; k = k +1)
       if (k==0) input_regs[k] <= GPIO_i;
       else      input_regs[k] <= input_regs[k-1];
	end
	
  always @(posedge APB_CLK)
    if(APB_PREADY)
    in_reg <= input_regs[INPUT_STAGES-1];
	else
	in_reg <= 32'bz;
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
