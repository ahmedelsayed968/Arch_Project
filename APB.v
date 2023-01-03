module APB (
input  wire                      Transfer   ,
input  wire                      PREADY     ,
input  wire                      PSLVERR    , //An error signal, PSLVERR, to indicate the failure of a transfer
input  wire                      PCLK       ,
input  wire                      PRESETn    
  ); 
// ===============================(implementation of APB finite state machine(FSM) )===============================================================================
// Control Signals ==========================================================================================================

  reg  [1:0]  current_state , 
              next_state    ;

 
// States Encoded in Gray Encoding =======================================================================================

  localparam   [1:0]   IDLE     = 2'b00 ,
                       SETUP    = 2'b01 ,
                       ACCESS   = 2'b11 ;
  
// State Transition ======================================================================================================

  always @(posedge PCLK or negedge PRESETn)
    begin
      if(!PRESETn)
        begin
          current_state <= IDLE;          
        end
      else
        begin
          current_state <= next_state; 
        end 
    end
// Next State Logic ======================================================================================================== 

  always@(*)
    begin
      case(current_state)            
            IDLE:   begin 
                      if(!Transfer)
                        begin
                          next_state = IDLE ;
                        end
                      else
                        begin
                          next_state = SETUP ; 
                        end
                    end
            SETUP:  begin
                      next_state = ACCESS ;
                    end
            ACCESS: begin
                      if(Transfer & !PSLVERR)
                        begin
                          if(PREADY)
                            begin
                              next_state = SETUP ;
                            end
                          else
                            begin
                              next_state = ACCESS ;
                            end
                        end
                      else 
                        begin
                         next_state = IDLE ;
                        end
                    end
            default: next_state = IDLE ; 
      endcase
    end
endmodule