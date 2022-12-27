module tx_tb;
 
  // Testbench uses a 10 MHz clock
  // Want to interface to 115200 baud UART
  // 10000000 / 115200 = 87 Clocks Per Bit.
  parameter c_CLOCK_PERIOD_NS = 100;
  parameter c_CLKS_PER_BIT    = 87;
  parameter c_BIT_PERIOD      = 8600;
   
  reg r_Clock = 0;
  reg r_Tx_DV = 0;
  wire w_Tx_Done;
  reg [7:0] r_Tx_data_to_send = 0;
  wire r_tx_Serial;
  wire r_Tx_Active ;
  
  uart_tx #(.DATA_WIDTH(8),.CLKS_PER_BIT(c_CLKS_PER_BIT)) tx(  .i_Clock(r_Clock),
     .i_Tx_DV(r_Tx_DV),
     .i_Tx_Data(r_Tx_data_to_send),
     .o_Tx_Active(r_Tx_Active),
     .o_Tx_Serial(r_tx_Serial),
     .o_Tx_Done(w_Tx_Done));
	 
	
	
	
	always
    #(c_CLOCK_PERIOD_NS/2) r_Clock <= !r_Clock;
	
	initial
    begin
       
      // Tell UART to send a command (exercise Tx)
		r_Tx_DV <= 1'b1;
		r_Tx_data_to_send <= 8'b0000_0000;
		
		//#50
		//r_Tx_data_to_send <= 8'b1001_1001;
		//#50
		//r_Tx_data_to_send <= 8'b1010_1010;	
		  
	end
		
	initial begin
		$monitor("bits in Tx Line = %b",r_tx_Serial);
	end
	
endmodule