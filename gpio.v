//                APB4 GPIO                                        //
//                                                                 //
/////////////////////////////////////////////////////////////////////
//                                                                 //
//                Mina Mounir Farid Gendi 1901384                  //
//                                                                 //
//                                                                 //
//   Standard File Header Section  -------
// FILE NAME      : apb_gpio.v
// DEPARTMENT     :
// AUTHOR         : Mina Mounir 
// AUTHOR'S EMAIL : 1901384@eng.asu.edu.eg
// ------------------------------------------------------------------
// RELEASE HISTORY
// VERSION DATE        AUTHOR      DESCRIPTION
// 1.0     2022-22-12  Mina Mounir  initial release
// ------------------------------------------------------------------
// KEYWORDS : AMBA APB4 General Purpose IO GPIO     
// ------------------------------------------------------------------
// PURPOSE  : General purpose IO          
// ------------------------------------------------------------------
// PARAMETERS
//  PARAM NAME        RANGE    DESCRIPTION              DEFAULT UNITS
//  PDATA_SIZE        1+       Databus (and GPIO) size  8       bits
// ------------------------------------------------------------------
// REUSE ISSUES 
//   Reset Strategy      : external asynchronous active low; PRESETn
//   Clock Domains       : PCLK, rising edge
//   Critical Timing     : 
//   Test Features       : na
//   Asynchronous I/F    : no
//   Scan Methodology    : na
//   Instantiations      : na
//   Synthesizable (y/n) : Yes
//   Other               :                                         
// -FHDR-------------------------------------------------------------


/*
 * address  description         comment
 * ------------------------------------------------------------------
 * 0x0      mode register       0=push-pull
 *                              1=open-drain
 * 0x1      direction register  0=input
 *                              1=output
 * 0x2      output register     mode-register=0? 0=drive pad low
 *                                               1=drive pad high
 *                              mode-register=1? 0=drive pad low
 *                                               1=open-drain
 * 0x3      input register      returns data at pad
  */

module apb_gpio1 (PRESETn,PCLK,PSEL,PENABLE,PADDR,PWRITE,PSTRB,PWDATA,PRDATA,PREADY,PSLEVRR,gpio_i,gpio_o,gpio_oe);
	parameter PDATA_SIZE = 32 ,PADDR_SIZE = 4; //must be multiple of 8
	localparam MODE = 0,DIRECTION = 1,OUTPUT= 2,INPUT= 3, INPUT_STAGES = 2;
	input PRESETn, PCLK, PENABLE, PWRITE,PSEL;
	input[PADDR_SIZE-1:0] PADDR;
	input[PDATA_SIZE/8-1:0] PSTRB;
	input[PDATA_SIZE-1:0] PWDATA, gpio_i;
	output reg[PDATA_SIZE-1:0]PRDATA,gpio_o,gpio_oe;
	output PREADY, PSLEVRR ;
	reg[PDATA_SIZE-1:0]input_regs[0:INPUT_STAGES-1] ,dir_reg,out_reg,in_reg, mode_reg ;
	integer i ,j,k;
  
	 //The core supports zero-wait state accesses on all transfers.
  //It is allowed to drive PREADY with a hard wired signal
	assign PREADY  = 1'b1; //always ready
	assign PSLVERR = 1'b0; //Never an error
	//APB write to Mode register
  always @(posedge PCLK,negedge PRESETn)
    if      (!PRESETn              ) mode_reg <= {PDATA_SIZE{1'b0}};
    else if (PSEL & PENABLE & PWRITE & (PADDR == MODE)) begin
			mode_reg[7:0] = PSTRB[0] ? PWDATA[7:0] : mode_reg[7:0];
			mode_reg[15:8] = PSTRB[1] ? PWDATA[15:8] : mode_reg[15:8];
			mode_reg[23:16] = PSTRB[2] ? PWDATA[23:16] : mode_reg[23:16];
			mode_reg[31:24] = PSTRB[3] ? PWDATA[31:24] : mode_reg[31:24];
		end	

	always @(posedge PCLK,negedge PRESETn)
		if      (!PRESETn                   ) dir_reg <= {PDATA_SIZE{1'b0}};
		else if (PSEL & PENABLE & PWRITE & (PADDR == DIRECTION)) begin
			dir_reg[7:0] = PSTRB[0] ? PWDATA[7:0] : dir_reg[7:0];
			dir_reg[15:8] = PSTRB[1] ? PWDATA[15:8] : dir_reg[15:8];
			dir_reg[23:16] = PSTRB[2] ? PWDATA[23:16] : dir_reg[23:16];
			dir_reg[31:24] = PSTRB[3] ? PWDATA[31:24] : dir_reg[31:24];
		end	
		
	always @(posedge PCLK,negedge PRESETn) 
    if      (!PRESETn                  ) out_reg <= {PDATA_SIZE{1'b0}};
    else if ( (PSEL & PENABLE & PWRITE & (PADDR == OUTPUT)) || (PSEL & PENABLE & PWRITE & (PADDR == INPUT))) begin
			out_reg[7:0] = PSTRB[0] ? PWDATA[7:0] : out_reg[7:0];
			out_reg[15:8] = PSTRB[1] ? PWDATA[15:8] : out_reg[15:8];
			out_reg[23:16] = PSTRB[2] ? PWDATA[23:16] : out_reg[23:16];
			out_reg[31:24] = PSTRB[3] ? PWDATA[31:24] : out_reg[31:24];
		end	
		
	  /*
   * APB Reads
   */
  always @(posedge PCLK)
    case (PADDR)
	  MODE     : PRDATA <= mode_reg;	
      DIRECTION: PRDATA <= dir_reg;
      OUTPUT   :  
	  	PRDATA <= out_reg;
	  INPUT    : begin 
		if((PSEL & PENABLE & ~PWRITE))
			PRDATA <= in_reg; //add condition
	  end
      default  : PRDATA <= {PDATA_SIZE{1'b0}};
    endcase	
	
	 always @(posedge PCLK)
    for ( k=0; k<INPUT_STAGES; k = k +1)
       if (k==0) input_regs[k] <= gpio_i;
       else      input_regs[k] <= input_regs[k-1];

  always @(posedge PCLK)
    in_reg <= input_regs[INPUT_STAGES-1];
    //my modification
	
		
	 // mode
  // 0=push-pull    drive out_reg value onto transmitter input
  // 1=open-drain   always drive '0' onto transmitter
  always @(posedge PCLK)
    for (i=0; i<PDATA_SIZE; i = i +1)
      gpio_o[i] <= mode_reg[i] ? 1'b0 : out_reg[i];


  // direction  mode          out_reg
  // 0=input                           disable transmitter-enable (output enable)
  // 1=output   0=push-pull            always enable transmitter
  //            1=open-drain  1=Hi-Z   disable transmitter
  //                          0=low    enable transmitter
  always @(posedge PCLK)
    for (j=0; j<PDATA_SIZE; j = j +1 )
      gpio_oe[j] <= dir_reg[j] & ~(mode_reg[j] ? out_reg[j] : 1'b0)	;
endmodule	
