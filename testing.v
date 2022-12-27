module uartRx (rxStart,rxD,rst,clk,rxData,store,clrRxStartBit);
  //rxStart: Input from the APB interface for start receiving
  //rxD: Serial input from other peripherals
  //store:Signal to the APB interface block indicating that the reception is complete and to store the data
  //rxData:Data received.
  //clrRxStartBit:Signal to APB interface block to clear r×Start
  // 1 start bit , 1 stop bit , 1 parity bit  --> Data
  // Reciver_reg :11-bit register 
  
  //inputs 
  input rxStart,rxD,rst,clk;
  
  //Outputs
  output [10:0] rxData;
  output store,clrRxStartBit;
  
  //flag signals 
  wire rxCountFlag;
  wire rxShiftFlag;
  wire rxBitCountFlag; 
  
  //internal registers 
  reg[3:0] rxBitCount;
  reg[3:0] counter16;
  reg[10:0] rxShiftReg;
  reg[2:0] state;
  reg[2:0] nextState;
  
  //states
  parameter
   IDLE=3'd0,
   COUNT=3'd1,
   BIT_COUNT=3'd2,
   RECEIVED = 3'd3,
   CLEAR =3'd4;
    
  
  //Rx Bit Counter 
  always@(posedge clk,negedge rst)
  begin 
    if((!rst) || (rxBitCount==4'd11) )
      begin
        rxBitCount <=0;
        end 
     else if(rxBitCountFlag)
       begin 
         rxBitCount<=rxBitCount+1;
       end
     end 
     
     // bit rate
   always@(posedge clk,negedge rst)
   begin
      if (!rst)
         counter16<=0;
      else if (rxCountFlag)
         counter16<=counter16+1;
      end 
     
     //storing bits coming from rx
   always@(posedge clk,negedge rst)
   begin 
     if (!rst)
       rxShiftReg<=11'd2047; // starting with all ones 
     else if (rxShiftFlag)
       rxShiftReg<={rxD,rxShiftReg[10:1]};
     
     end
     
     //switch cases of the states
     
    always@(posedge clk,negedge rst)
    begin 
      if (!rst)
        state=IDLE;
    else 
      state=nextState;
    end 
    
    always@(*)
    begin
     nextState=IDLE; 
      case (state)
        
        IDLE: begin
          if(rxStart&&rxD)
            nextState=COUNT;
          else
            nextState=IDLE;
         end
         
         COUNT: begin
            if(counter16<15) 
              nextState=COUNT;
          else 
              nextState=BIT_COUNT;
            end
            
          BIT_COUNT:
          begin
             if (rxBitCount<4'hA)
               nextState=COUNT;
             else 
               nextState=RECEIVED;
             end
              
          RECEIVED:
          begin
               if (rxBitCount<4'hB)
                 nextState=CLEAR;
               else 
                 nextState=RECEIVED;
               end 
               
           CLEAR:
           begin
             nextState=IDLE;
           end
           
           default:
           begin
             nextState=IDLE;
           end
            
     endcase 
   end 
   
   
   //outputs of switch cases   
    assign rxCountFlag =(state==COUNT)?1:0;
    assign rxShiftFlag=(state==BIT_COUNT)?1:0;
   
assign rxBitCountFlag=(state==BIT_COUNT)?1:0;
    assign store=(state==RECEIVED)?1:0;
   
assign clrRxStartBit=(state==CLEAR)?1:0;
   

    assign 
rxData=rxShiftReg;
   

 
endmodule 

 

 

 

 

module uart_tb ();
 
  // Testbench uses a 10 MHz clock
  // Want to interface to 115200 baud UART
  // 10000000 / 115200 = 87 Clocks Per Bit.
  parameter c_CLOCK_PERIOD_NS = 10;
  parameter c_CLKS_PER_BIT    = 16;
  parameter c_BIT_PERIOD      = 160;
   
  reg r_Clock = 0;
  reg r_Rx_Serial = 1;
  wire [10:0] w_Rx_Byte;
  
  reg rxStart,rst;
  wire store,clrRxStartBit;

     
  uartRx u(rxStart,r_Rx_Serial,rst,r_Clock,w_Rx_Byte,store,clrRxStartBit);

 
  // Takes in input byte and serializes it 
  task UART_WRITE_BYTE;
    input [10:0] i_Data;
    integer     ii;
    begin
       
      // Send Start Bit
      r_Rx_Serial <= 1'b0;
      #(c_BIT_PERIOD);
      //#1000;
       
       
      // Send Data Byte
      for (ii=0; ii<11; ii=ii+1)
        begin
          r_Rx_Serial <= i_Data[ii];
          #(c_BIT_PERIOD);
        end
       
      // Send Stop Bit
      r_Rx_Serial <= 1'b1;
      #(c_BIT_PERIOD);
     end
  endtask // UART_WRITE_BYTE  

  always
    #(c_CLOCK_PERIOD_NS/2) r_Clock <= !r_Clock;
 
  // Main Testing:
  initial
    begin
  rst = 1'b1;
  #10
  rst = 1'b0;
  #10
  rst = 1'b1;
  rxStart =1'b1;
           
      // Send a command to the UART (exercise Rx)
      @(posedge r_Clock);
      UART_WRITE_BYTE(11'h00);
      @(posedge r_Clock);
             
      // Check that the correct command was received
      if (w_Rx_Byte == 11'h00)
        $display("Test Passed - Correct Byte Received");
      else
        $display("Test Failed - Incorrect Byte Received");
       
    end
   
endmodule



