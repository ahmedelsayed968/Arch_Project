// FIFO_Tx
include "Clk_generator.v"

module fifo_tx(clk_fifo_tx, data_in, next_frame, data_out,fifo_tx_full,fifo_tx_empty);
	input clk_fifo_tx;
	input next_frame;
	parameter DATA_WIDTH = 'd8;							// default data_width is 8bit  
	parameter MAX_FIFO_FRAME = 'd16	;					// default max. elements is 16
	output reg[DATA_WIDTH-1:0] data_out;				// to return the the front of QUEUE/FIFo
	input [DATA_WIDTH-1:0] data_in;
	reg[MAX_FIFO_FRAME-1:0] mem_fifo[DATA_WIDTH-1:0];	// to store coming elements into QUEUE/FIFo
	output reg fifo_tx_full = 1'b0;								// to check fifo is full or not
    output reg fifo_tx_empty= 1'b1;								// to check fifo is empty or not
	
	reg[$clog2(MAX_FIFO_FRAME):0] front_pos =-1;			// top of the QUEUE/FIFo

	reg[$clog2(MAX_FIFO_FRAME):0] rear_pos  =-1;			// back of the QUEUE/FIFo
	reg write;
	
	
	// handling writting on FIFO
	always @ (posedge clk_fifo_tx)
	    begin
			if(write==1'b1)
    			begin
    				// circular implementation!
    				if ((rear_pos+1)% MAX_FIFO_FRAME == front_pos)
        				begin
        					fifo_tx_full <= 1'b1;
        				end
    				
    				else if(front_pos == -1)
    					begin
    						rear_pos  <= 0;
    						front_pos <= 0;
    						mem_fifo[rear_pos] <= data_in;
    						fifo_tx_empty 		<= 1'b1;
    					
    					end
    					
    				else	
    					begin
    						mem_fifo[rear_pos] 	<= data_in;		// store element @ back
    						rear_pos			<=	(rear_pos+1)%MAX_FIFO_FRAME;	// increment rear position
    						
    					end
    		    end
			else
				begin
					if(front_pos==-1)
						fifo_tx_empty <= 1'b1;
					
					else if(front_pos==rear_pos)
						begin
							data_out <= mem_fifo[front_pos];
							front_pos <= -1;
							rear_pos <= -1;
						end
					else
						begin
							data_out <= mem_fifo[front_pos];
							front_pos <= (front_pos+1) % MAX_FIFO_FRAME;
						end
				
				end
			
		end

endmodule



module fifoTs;
	
	
	