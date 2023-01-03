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
	 

	//APB write to Mode register
  always @(posedge PCLK,negedge PRESETn)
    if      (!PRESETn) begin
	mode_reg <= {PDATA_SIZE{1'b0}};
	PREADY <= 1'b0 ;
	end
    else if (PSEL & PENABLE & PWRITE & (PADDR == MODE)) begin
			mode_reg[7:0] = PSTRB[0] ? PWDATA[7:0] : mode_reg[7:0];
			mode_reg[15:8] = PSTRB[1] ? PWDATA[15:8] : mode_reg[15:8];
			mode_reg[23:16] = PSTRB[2] ? PWDATA[23:16] : mode_reg[23:16];
			mode_reg[31:24] = PSTRB[3] ? PWDATA[31:24] : mode_reg[31:24];
		end	

	always @(posedge PCLK,negedge PRESETn)
		if      (!PRESETn ) dir_reg <= {PDATA_SIZE{1'b0}};
		else if (PSEL & PENABLE & PWRITE & (PADDR == DIRECTION)) begin
			dir_reg[7:0] = PSTRB[0] ? PWDATA[7:0] : dir_reg[7:0];
			dir_reg[15:8] = PSTRB[1] ? PWDATA[15:8] : dir_reg[15:8];
			dir_reg[23:16] = PSTRB[2] ? PWDATA[23:16] : dir_reg[23:16];
			dir_reg[31:24] = PSTRB[3] ? PWDATA[31:24] : dir_reg[31:24];
			PREADY <= 1'b1 ;
		end	
		
	always @(posedge PCLK,negedge PRESETn) 
    if      (!PRESETn ) out_reg <= {PDATA_SIZE{1'b0}};
    else if ( (PSEL & PENABLE & PWRITE  &(PADDR == OUTPUT)) || (PSEL & PENABLE & PWRITE  &(PADDR == INPUT))) begin
			if(PREADY) begin
				out_reg[7:0] = PSTRB[0] ? PWDATA[7:0] : out_reg[7:0];
				out_reg[15:8] = PSTRB[1] ? PWDATA[15:8] : out_reg[15:8];
				out_reg[23:16] = PSTRB[2] ? PWDATA[23:16] : out_reg[23:16];
				out_reg[31:24] = PSTRB[3] ? PWDATA[31:24] : out_reg[31:24];
			end
			else
				out_reg<= 32'bz	;
		end	
		
	  /*
   * APB Reads
   */
  always @(posedge PCLK)
    case (PADDR)
	  MODE     : PRDATA <= mode_reg;	
      DIRECTION: PRDATA <= dir_reg;
      OUTPUT   : PRDATA <= out_reg;
      INPUT    :
		if((PSEL & PENABLE & ~PWRITE & PREADY)) 
			PRDATA <= in_reg; //add condition
	
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
