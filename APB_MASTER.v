//=========================================================================================================================================================
// Ahmed Adel Hassan , ID: 1900311
// Ahmed Abd Elmotelb Ali, ID:1901401
//=========================================================================================================================================================
module APB_MASTER #(parameter 
    DATA_WIDTH = 'd32,
    ADDRESS_WIDTH = 'd4,// using two Slaves (UARTS, GPIO)
    STRB_WIDTH = 'd4,
    SLAVES_NUM = 'd2) (
input  wire                      PCLK       ,
input  wire                      PRESETn    ,
input  wire  [ADDRESS_WIDTH-1:0] IN_ADDR    ,
input  wire  [DATA_WIDTH-1:0]    IN_DATA    ,
input  wire  [DATA_WIDTH-1:0]    PRDATA     ,
input  wire                      IN_WRITE   ,
input  wire  [STRB_WIDTH-1:0]    IN_STRB    ,
input  wire                      Transfer   ,
input  wire                      PREADY     ,
input  wire                      PSLVERR    , //An error signal, PSLVERR, to indicate the failure of a transfer

output reg                       OUT_SLVERR ,
output reg   [DATA_WIDTH-1:0]    OUT_RDATA  ,
output reg   [ADDRESS_WIDTH-1:0] PADDR      ,
output reg   [DATA_WIDTH-1:0]    PWDATA     ,
output reg                       PWRITE     ,
output reg                       PENABLE    ,
output reg   [STRB_WIDTH-1:0]    PSTRB      ,//Each 8 bits have 1 PSTRB bit, It indicates which byte to be updated during a write 
output reg     [SLAVES_NUM-1:0]  PSEL
  ); 


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


// Address Decoding ================================================================================================

  always @(posedge PCLK, negedge PRESETn) 
    begin
      if (!PRESETn)
        begin
     	    PSEL = 'b0 ;
        end
      else if (next_state == IDLE)
        begin
          PSEL = 'b0 ;
        end
      else
        begin
     	    case(IN_ADDR[3]) //choose which slave will take the bus
            1'b0: begin 
                      PSEL = 'b0000_0001 ;
                    end
            1'b1: begin 
                      PSEL = 'b0000_0010 ;
                    end
            default:begin 
                      PSEL = 'b0000_0000 ;
                    end
          endcase
        end
    end


 // OUTPUT LOGIC========================================================================================================                                               

 always @(posedge PCLK, negedge PRESETn)
   begin
     if(!PRESETn) 
       begin
         PENABLE    <= 1'b0 ;
         PADDR      <= 8'b0 ;//8 bit for address
         PWDATA     <=  'b0 ;
         PWRITE     <= 1'b0 ;
         OUT_RDATA  <=  'b0 ;
         PSTRB      <=  'b0 ;
         OUT_SLVERR <= 1'b0 ;
       end
     else if(next_state == SETUP)
       begin
         PENABLE   <= 1'b0     ;
         PADDR     <= IN_ADDR  ;
         PWRITE    <= IN_WRITE ;
         if(IN_WRITE)
           begin
             PWDATA <= IN_DATA ;
             PSTRB  <= IN_STRB ;
           end
         else 
           begin
             PSTRB <= 'b0 ;
           end 
       end
     else if(next_state == ACCESS)
       begin
         PENABLE <= 1'b1;
         if(PREADY)
           OUT_SLVERR <= PSLVERR ;
           begin
             if(!IN_WRITE)
               begin
                 OUT_RDATA <= PRDATA ;
               end
           end
       end 
      else
        begin
          PENABLE <= 1'b0;
        end 

   end 

 endmodule

