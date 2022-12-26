
module uart_tx 
  #(parameter CLKS_PER_BIT = 87, DATA_WIDTH = 8)
  (
   input       i_Clock,
   input       i_Tx_DV,
   input [DATA_WIDTH-1:0] i_Tx_Data, 
   output      o_Tx_Active,
   output reg  o_Tx_Serial,
   output      o_Tx_Done
   );
  
  parameter s_IDLE         = 3'b000;
  parameter s_TX_START_BIT = 3'b001;
  parameter s_TX_DATA_BITS = 3'b010;
  parameter s_TX_STOP_BIT  = 3'b011;
  parameter s_CLEANUP      = 3'b100;
   
  reg [2:0]    r_SM_Main     = 0;
  reg [7:0]    r_Clock_Count = 0;
  reg [$clog2(DATA_WIDTH)-1:0]    r_Bit_Index   = 0;
  reg [DATA_WIDTH-1:0]    r_Tx_Data     = 0;
  
  reg          r_Tx_Done     = 0;
  reg          r_Tx_Active   = 0;
     
  always @(posedge i_Clock)
    begin
       
      case (r_SM_Main)
        s_IDLE :							// *Idel State*
          begin
            o_Tx_Serial   <= 1'b1;         	// Idle state will be 1 for tx_serial
            r_Tx_Done     <= 1'b0;			// set tx_done 0
            r_Clock_Count <= 0;				// set counter 0 
            r_Bit_Index   <= 0;				// current bit index 0
             
            if (i_Tx_DV == 1'b1)			// flag to transmit data
              begin							
                r_Tx_Active <= 1'b1;		
                r_Tx_Data   <= i_Tx_Data;	
                r_SM_Main   <= s_TX_START_BIT;
              end
            else
              r_SM_Main <= s_IDLE;
          end 
         
         
        
        s_TX_START_BIT :						// *Start bit State*
          begin
            o_Tx_Serial <= 1'b0;				// Send out Start Bit. Start bit = 0	
             
            // Wait CLKS_PER_BIT-1 clock cycles for start bit to finish
            if (r_Clock_Count < CLKS_PER_BIT-1)
              begin
                r_Clock_Count <= r_Clock_Count + 1;
                r_SM_Main     <= s_TX_START_BIT;
              end
            else
              begin
                r_Clock_Count <= 0;
                r_SM_Main     <= s_TX_DATA_BITS;
              end
          end 
         
         
               
        s_TX_DATA_BITS :							// *Transmitting Data*
          begin
            o_Tx_Serial <= r_Tx_Data[r_Bit_Index];
			
            // Wait CLKS_PER_BIT-1 clock cycles for data bits to finish  
            if (r_Clock_Count < CLKS_PER_BIT-1)
              begin
                r_Clock_Count <= r_Clock_Count + 1;
                r_SM_Main     <= s_TX_DATA_BITS;
              end
            else
              begin
                r_Clock_Count <= 0;
                 
                // Check if we have sent out all bits
                if (r_Bit_Index < DATA_WIDTH-1)
                  begin
                    r_Bit_Index <= r_Bit_Index + 1;
                    r_SM_Main   <= s_TX_DATA_BITS;
                  end
                else
                  begin
                    r_Bit_Index <= 0;
                    r_SM_Main   <= s_TX_STOP_BIT;
                  end
              end
          end 
         
         
        
        s_TX_STOP_BIT :							// *Stop Bit State*
          begin
            o_Tx_Serial <= 1'b1;				// Send out Stop bit.  Stop bit = 1
             
            // Wait CLKS_PER_BIT-1 clock cycles for Stop bit to finish
            if (r_Clock_Count < CLKS_PER_BIT-1)
              begin
                r_Clock_Count <= r_Clock_Count + 1;
                r_SM_Main     <= s_TX_STOP_BIT;
              end
            else
              begin
                r_Tx_Done     <= 1'b1;
                r_Clock_Count <= 0;
                r_SM_Main     <= s_CLEANUP;
                r_Tx_Active   <= 1'b0;
              end
          end 
         
         
        // Stay here 1 clock
        s_CLEANUP :
          begin
            r_Tx_Done <= 1'b1;
            r_SM_Main <= s_IDLE;
          end
         
         
        default :
          r_SM_Main <= s_IDLE;
         
      endcase
    end
 
  assign o_Tx_Active = r_Tx_Active;
  assign o_Tx_Done   = r_Tx_Done;
   
endmodule