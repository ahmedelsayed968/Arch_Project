
module uart_tb;
    parameter APB_ADDR_WIDTH    = 32;
    parameter c_CLOCK_PERIOD_NS = 10;
    parameter c_CLKS_PER_BIT    = 16;
    parameter c_BIT_PERIOD      = 160;

    reg                             CLK = 1'b1;                  
    reg                             RSTN;                 
    reg [APB_ADDR_WIDTH-1:0]        PADDR;
    reg               [31:0]        PWDATA;
    reg                             PWRITE;
    reg                             PSEL;
    reg                             PENABLE;
    wire               [31:0]       PRDATA;
    wire                            PREADY;

    reg                             rx_i;                 
    wire                            tx_o;                  
    reg                             cfg_parity_en;
    reg                             [1:0]cfg_bits_i;
    reg                             cfg_stop_bits;
    reg                             receive_now;
    parameter                       cfg_div = 16'd16;
    wire                            error_in_receiving_o;
    reg                             enable_error_detection_i;      // Negative Logic!!!!! 
    wire                            rx_valid_o;
    reg                             READY_to_receive_i;  
    wire                            bit_sent;
    reg                             start_count;
    reg [7:0]                       data_to_send;
    apb_uart apb_uart(.CLK(CLK),
                                          .RSTN(RSTN),
                                          .PADDR(PADDR),
                                          .PWDATA(PWDATA),
                                          .PWRITE(PWRITE),
                                          .PSEL(PSEL),
                                          .PENABLE(PENABLE),
                                          .PRDATA(PRDATA),
                                          .PREADY(PREADY),
                                          .rx_i(rx_i),
                                          .tx_o(tx_o),
                                          .cfg_parity_en(cfg_parity_en),
                                          .cfg_bits(cfg_bits_i),
                                          .cfg_stop_bits(cfg_stop_bits),
                                          .error_in_receiving(error_in_receiving_o),
                                          .enable_error_detection(enable_error_detection_i),
                                          .rx_valid(rx_valid_o),
                                          .READY_to_receive(READY_to_receive_i));

    
    baud_rate b1(.clk_i(CLK),
                  . rstn_i(RSTN),
                  .baudgen_en(start_count),
                  .cfg_div_i(cfg_div),
                  .o_bit_done(bit_sent));
    always
        #(c_CLOCK_PERIOD_NS/2) CLK <= !CLK;



    // Test tx
    initial begin

        #10 RSTN = 1'b0;
        
        #10; 
        // APB Configuartion wires
        PWDATA = 32'b1010_0101;
        PWRITE = 1'b1;
        RSTN = 1'b1;
        PSEL = 1'b1;
        PENABLE = 1'b1;


        // cfg_div = 'd16;
        cfg_parity_en = 1'b0;
        cfg_bits_i = 2'b11;
        cfg_stop_bits = 1'b0;


        #50;




    end





    // // // Rx Testing
    // task UART_WRITE_BYTE;
    //   input [10:0] i_Data;
    //   integer     ii;
    //   begin
        
    //     // Send Start Bit
    //     rx_i <= 1'b0;
    //     #(c_BIT_PERIOD);
    //     //#1000;
        
        
    //     // Send Data Byte
    //     for (ii=0; ii<8; ii=ii+1)
    //       begin
    //         rx_i <= i_Data[ii];
    //         #(c_BIT_PERIOD);
    //       end
        
    //     // Send Stop Bit
    //     rx_i <= 1'b1;
    //     #(c_BIT_PERIOD);
    //   end
    // endtask // UART_WRITE_BYTE  
      
    //   initial
    //   begin
    //     #10 RSTN = 1'b0;
        
       
    //     // APB Configuartion wires
    //     // PWDATA = 32'b1010_0101;
    //     PWRITE = 1'b0;
    //     RSTN = 1'b1;
    //     PSEL = 1'b1;
    //     PENABLE = 1'b1;
    //     READY_to_receive_i = 1'b1;
    //     enable_error_detection_i = 1'b1;
    //     cfg_stop_bits = 1'b0;
    //     // cfg_div = 'd16;
    //     cfg_parity_en = 1'b0;
    //     cfg_bits_i = 2'b11;

    //     //     cfg_stop_bits = 1'b0;


            
    //     // Send a command to the UART (exercise Rx)
    //     // @(posedge CLK);
    //     UART_WRITE_BYTE(8'b0000_1000);
    //     // @(posedge CLK);

      
    //     // rx_i <= 1'b0;
    //     // start_count = 1'b1;
      
    //     //#1000;
     
       
    //     // Send Stop Bit

    //     // Check that the correct command was received
    //     if (PRDATA == {24'b0,8'b0000_1000})
    //         $display("Test Passed - Correct Byte Received");
    //     else
    //         $display("Test Failed - Incorrect Byte Received");
       
    //   end


endmodule