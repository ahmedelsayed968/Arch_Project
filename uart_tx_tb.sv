//`include "uart_tx.sv"

module uart_tx_tb();
    reg            CLK = 1;                // System Clock 
    reg            RSTN;               // reset bit
    wire           tx_o;               // tx_line output
    wire           busy_o;             // busy bit
    reg [15:0]     cfg_div_i;          // config div   for baud rate
    reg            cfg_parity_en_i;    // config parity bits enable
    reg [1:0]      cfg_bits_i;         // config bits
    reg            cfg_stop_bits_i;    // config stop bits 1 or 2
    reg [7:0]      tx_data;          // data to send
    reg            tx_valid;         // valid data on the input 
    wire           tx_ready;          // ready to send

    // logicister addresses
    // parameter RBR = 3'h0, THR = 3'h0, DLL = 3'h0, IER = 3'h1, DLM = 3'h1, IIR = 3'h2,
    //           FCR = 3'h2, LCR = 3'h3, MCR = 3'h4, LSR = 3'h5, MSR = 3'h6, SCR = 3'h7;
    // parameter c_CLOCK_PERIOD_NS = 100;
    
    uart_tx uart_tx_i
    (
        .clk_i              ( CLK                           ),
        .rstn_i             ( RSTN                          ),
        .tx_o               ( tx_o                          ),
        /* verilator lint_off PINCONNECTEMPTY */
        .busy_o             (          busy_o               ),
        /* lint_on */
        .cfg_en_i           ( 1'b1                          ),
        .cfg_div_i          ( cfg_div_i),
        .cfg_parity_en_i    (cfg_parity_en_i),
        .cfg_bits_i         ( cfg_bits_i),
        .cfg_stop_bits_i    (cfg_stop_bits_i),

        .tx_data_i          ( tx_data                       ),
        .tx_valid_i         ( tx_valid                      ),
        .tx_ready_o         ( tx_ready                      )
    );

    always
        #50 CLK <= !CLK;
    
    initial begin 
        tx_data = 4'b1000;
        tx_valid = 1'b1;
        RSTN = 1'b1;
        cfg_div_i = 'd16;
        cfg_parity_en_i = 1'b1;
        cfg_bits_i = 2'b11;
        cfg_stop_bits_i = 1'b1;

    end



    


endmodule
