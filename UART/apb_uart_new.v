module apb_uart #(
    parameter   cfg_div=16'd16,
                APB_ADDR_WIDTH = 'd32
                
)(
    input  wire                         CLK,                  // System Clock
    input  wire                         RSTN,                 // Reset bit
  
    input  wire [APB_ADDR_WIDTH-1:0]    PADDR,
    
    input  wire               [31:0]    PWDATA,
    input  wire                         PWRITE,
    input  wire                         PSEL,
    input  wire                         PENABLE,
    output reg               [31:0]     PRDATA,
    output wire                         PREADY,  
    input  wire                         rx_i,                 // Receiver input
    output wire                         tx_o,                  // Transmitter output
    input  wire                         cfg_parity_en,
    input  reg                          [1:0]cfg_bits,
    input  wire                         cfg_stop_bits,       
    output  wire                        error_in_receiving,
    input wire                          enable_error_detection,      // Negative Logic!!!!! 
    output wire                         rx_valid,
    input wire                          READY_to_receive,
    input wire                          store,
    input wire                          clearRx    
                          
    
);

    wire rx_busy , tx_busy; 
    assign PREADY  = 1'b1;
    assign PSLVERR = 1'b0;
    reg [7:0] tx_data;
    reg tx_valid;
    wire [10:0] rx_data;
   
    uartRx uart_Rx(
        .clk(CLK),
        .rst(RSTN),
        .rxD(rx_i),
        .rxStart(PENABLE),
        .rxData(rx_data),
        .store(store),
        .clrRxStartBit(clearRx)
    );

    uart_tx uart_tx_i
    (
        .clk_i              ( CLK                           ),
        .rstn_i             ( RSTN                          ),
        .tx_o               ( tx_o                          ),

        .busy_o             (   tx_busy                      ),

        .cfg_en_i           ( 1'b1                          ),
        .cfg_div_i          ( cfg_div                       ),
        .cfg_parity_en_i    ( cfg_parity_en                ),
        .cfg_bits_i         ( cfg_bits              ),
        .cfg_stop_bits_i    ( cfg_stop_bits                ),

        .tx_data_i          ( tx_data                       ),
        .tx_valid_i         ( tx_valid                      ),
        .tx_ready_o         ( tx_ready                      )
    );



    always@(posedge CLK)
    begin
        if(PSEL && PENABLE && PWRITE)
        begin
            if (!tx_busy)
            begin
                tx_data <= PWDATA[7:0];
                tx_valid <= 1'b1;
            end    


        end

    end
    


    always@(posedge CLK)
    begin
        if(PSEL && PENABLE && !PWRITE)
        begin
          if (store)
            begin
                PRDATA = {24'b0,rx_data[8:1]};
     // Check that the correct command was received
                  if (PRDATA[10:0] == 11'h00)
                     $display("Test Passed - Correct Byte Received");
                  else
                      $display("Test Failed - Incorrect Byte Received");
       
            end 
        end
    end
    // always@(*)
    assign    PREADY = (PWRITE && !tx_busy) || (!PWRITE && !rx_busy);
    



endmodule
