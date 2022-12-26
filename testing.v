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
  output[10:0] rxData;
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
    if(!rst || rxBitCount==4'd11 )
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
       rxShiftReg<=11'd2047;
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
      case (state)
        IDLE: begin
          if(rxStart&&rxD)
            nextState=counter16;
          else
            nextState=IDLE;
         end
         
         COUNT: begin
            if(counter16<4'hF) 
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
               if (rxBitCount==4'hB)
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
   assign clrRxStartBit=(state==CLEAR)?1:0;
   assign store=(state==RECEIVED)?1:0;
    assign rxData=rxShiftReg;
   
 endmodule 
 
   module TB_Rx;  
  input rxStart,rxD,rst,clk;
  
  //Outputs
  output[10:0] rxData;
  output store,clrRxStartBit;
  
  //flag signals 
  wire rxCountFlag;
  wire rxShiftFlag;
  wire rxBitCountFlag 
  
  //internal registers 
  reg[3:0] rxBitCount;
  reg[3:0] counter16;
  reg[10:0] rxShiftReg;
  reg[2:0] state;
  reg[2:0] nextState; 
     initial begin
       $monitor("x = %b , y = %b , z = %b",x,y,z);
       x= 0 ; 
       y = 0 ; 
       #10;
       x= 0 ; 
       y = 1 ; 
       #10;
       x= 1 ; 
       y = 0 ; 
       #10;
       x= 1 ; 
       y = 1 ; 
       #10;
     end
    uartRx aw(rxStart,rxD,rst,clk,rxData,store,clrRxStartBit);
  endmodule;

