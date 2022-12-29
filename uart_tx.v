
module uart_tx #( parameter DATA_WIDTH = 8)(
        input  wire                         clk_i,              // System Clock 
        input  wire                         rstn_i,             // reset bit
        output reg                          tx_o,               // tx_line output
        output wire                         busy_o,             // busy bit
        input  wire                         cfg_en_i,           // config enable
        input  reg [15:0]                   cfg_div_i,          // config div   for baud rate
        input  wire                         cfg_parity_en_i,    // config parity bits enable
        input  reg [1:0]                    cfg_bits_i,         // config bits
        input  wire                         cfg_stop_bits_i,    // config stop bits 1 or 2
        input  reg [DATA_WIDTH-1:0]         tx_data_i,          // data to send
        input  reg                          tx_valid_i,         // valid data on the input 
        output reg                          tx_ready_o          // ready to send
        );

    parameter [2:0] IDLE=3'b000;                                // IDLE State
    parameter [2:0] START_BIT=3'b001;                           // Start Bit State
    parameter [2:0] DATA = 3'b010;                              // Transmitting Data State
    parameter [2:0] PARITY=3'b011;                              // Parity Bits Transmission State 
    parameter [2:0] STOP_BIT_FIRST= 3'b100;                     // 1st Stop Bit State
    parameter [2:0] STOP_BIT_LAST=3'b101;                       // 2nd Stop Bit State

    reg [2:0] CS =IDLE;                                         // Current State 
    reg [2:0] NS =IDLE;                                         // Next State
    reg [DATA_WIDTH-1:0]  reg_data;                             // To Save The received Data And Process it!
    reg [DATA_WIDTH-1:0]  reg_data_next;                        // To Save coming Data To Process


    reg [2:0]  reg_bit_count=0;                                 // Counter for the transmitted bits 
    reg [2:0]  reg_bit_count_next=0;

    reg [2:0]  s_target_bits;                                   //TODO Make it More Generic!                   

    reg        parity_bit;                                      
    reg        parity_bit_next;

    reg        sampleData;

    // reg [15:0] baud_cnt;
    reg        baudgen_en;
    wire        bit_done;

    // for busy State!
    assign    busy_o = (CS != IDLE);     


    baud_rate   baud_rate_gen(.clk_i(clk_i),
                            .rstn_i(rstn_i),
                            .baudgen_en(baudgen_en),
                            .cfg_div_i(cfg_div_i),
                            .o_bit_done(bit_done));


    always@(*)
    begin
        case(cfg_bits_i)
            2'b00:
                s_target_bits = 3'h4;
            2'b01:
                s_target_bits = 3'h5;
            2'b10:
                s_target_bits = 3'h6;
            2'b11:
                s_target_bits = 3'h7;
        endcase
    end



    always@(*)
    begin
        NS = CS;
        tx_o = 1'b1;
        sampleData = 1'b0;
        reg_bit_count_next  = reg_bit_count;
        reg_data_next = {1'b1,reg_data[7:1]};
        tx_ready_o = 1'b0;
        baudgen_en = 1'b0;
        parity_bit_next = parity_bit;
        case(CS)

            IDLE:
            begin
                if (cfg_en_i)
                    tx_ready_o = 1'b1;
                if (tx_valid_i)
                begin
                    NS = START_BIT;
                    sampleData = 1'b1;
                    reg_data_next = tx_data_i;
                end
            end

            START_BIT:
            begin
                tx_o = 1'b0;
                parity_bit_next = 1'b0;
                baudgen_en = 1'b1;
                if (bit_done)
                    NS = DATA;
            end

            DATA:
            begin
                tx_o = reg_data[0];
                baudgen_en = 1'b1;
                parity_bit_next = parity_bit ^ reg_data[0];
                if (bit_done)
                begin
                    if (reg_bit_count == s_target_bits)
                    begin
                        reg_bit_count_next = 'h0;
                        if (cfg_parity_en_i)
                        begin
                            NS = PARITY;
                        end
                        else
                        begin
                            NS = STOP_BIT_FIRST;
                        end
                    end
                    else
                    begin
                        reg_bit_count_next = reg_bit_count + 1;
                        sampleData = 1'b1;
                    end
                end
            end

            PARITY:
            begin
                tx_o = parity_bit;
                baudgen_en = 1'b1;
                if (bit_done)
                    NS = STOP_BIT_FIRST;
            end

            STOP_BIT_FIRST:
            begin
                tx_o = 1'b1;
                baudgen_en = 1'b1;
                if (bit_done)
                begin
                    if (cfg_stop_bits_i)
                        NS = STOP_BIT_LAST;
                    else
                        NS = IDLE;
                end
            end

            STOP_BIT_LAST:
            begin
                tx_o = 1'b1;
                baudgen_en = 1'b1;
                if (bit_done)
                begin
                    NS = IDLE;
                end
            end

            default:
                NS = IDLE;
        endcase
    end

    always @(posedge clk_i or negedge rstn_i)
    begin
        if (rstn_i == 1'b0)
        begin
            CS             = IDLE;
            reg_data       = 8'hFF;
            reg_bit_count  =  'h0;
            parity_bit     = 1'b0;
        end
        else
        begin
            if(bit_done)
            begin
                parity_bit = parity_bit_next;
            end

            if(sampleData)
            begin
                reg_data = reg_data_next;
            end

            reg_bit_count  = reg_bit_count_next;
            if(cfg_en_i)
               CS = NS;
            else
               CS = IDLE;
        end
    end
    

endmodule