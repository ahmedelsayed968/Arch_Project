
module uart_tx (
        input                   clk_i,              // System Clock 
        input                   rstn_i,             // reset bit
        output logic            tx_o,               // tx_line output
        output logic            busy_o,             // busy bit
        input  logic            cfg_en_i,           // config enable
        input  logic [15:0]     cfg_div_i,          // config div   for baud rate
        input  logic            cfg_parity_en_i,    // config parity bits enable
        input  logic [1:0]      cfg_bits_i,         // config bits
        input  logic            cfg_stop_bits_i,    // config stop bits 1 or 2
        input  logic [7:0]      tx_data_i,          // data to send
        input  logic            tx_valid_i,         // valid data on the input 
        output reg              tx_ready_o          // ready to send
        );

    // parameter [2:0] IDLE=3'b000;                    // IDLE State
    // parameter [2:0] START_BIT=3'b001;               // Start Bit State
    // parameter [2:0] DATA = 3'b010;                  // Transmitting Data State
    // parameter [2:0] PARITY=3'b011;                  // Parity Bits Transmission State 
    // parameter [2:0] STOP_BIT_FIRST= 3'b100;         // 1st Stop Bit State
    // parameter [2:0] STOP_BIT_LAST=3'b101;           // 2nd Stop Bit State
    
    // logic[2:0] CS =IDLE;                            // Current State 
    // logic[2:0] NS =IDLE;                            // Next State
    enum logic [2:0] {IDLE,START_BIT,DATA,PARITY,STOP_BIT_FIRST,STOP_BIT_LAST} CS = IDLE,NS=IDLE;
    logic [7:0]  logic_data;                        // To Save The received Data And Process it!
    logic [7:0]  logic_data_next;                   // To Save coming Data To Process


    logic [2:0]  logic_bit_count=0;                   // Counter for the transmitted bits 
    logic [2:0]  logic_bit_count_next=0;

    logic [2:0]  s_target_bits;                     

    logic        parity_bit;
    logic        parity_bit_next;

    logic        sampleData;

    logic [15:0] baud_cnt;
    logic        baudgen_en;
    logic        bit_done;

    // for busy State!
    assign    busy_o = (CS != IDLE);     

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
        NS <= CS;
        tx_o <= 1'b1;                                // initial value on the tx output
        sampleData <= 1'b0;
        logic_bit_count_next  = logic_bit_count;
        // logic_data_next = {1'b1,logic_data[7:1]};
        tx_ready_o <= 1'b0;
        baudgen_en <= 1'b0;
        parity_bit_next <= parity_bit;

        case(NS)
// ---------------------------------------------         IDLE STATE       ----------------------------------------------------------------------
            IDLE:
            begin
                if (cfg_en_i)
                    tx_ready_o <= 1'b1;
                    NS <= IDLE;
                if (tx_valid_i)
                begin
                    NS <= START_BIT;
                    sampleData <= 1'b1;
                    logic_data_next <= tx_data_i;
                    logic_bit_count <= 0;

                end
            end

            START_BIT:
            begin
                tx_o <= 1'b0;                        // Start Bit 0
                parity_bit_next <= 1'b0;
                baudgen_en <= 1'b1;                  // Enable BaudRate Generator
                if (bit_done)                       // 
                    NS <= DATA; 
                else
                    NS <= START_BIT;                 
            end

// ---------------------------------------------         DATA TRANSMISSION STATE       ----------------------------------------------------------------------
            DATA:
            begin
                tx_o <= logic_data[logic_bit_count];
                baudgen_en <= 1'b1;
                parity_bit_next <= parity_bit ^ logic_data[logic_bit_count];
                if (bit_done)
                begin
                    if (logic_bit_count == s_target_bits)
                    begin
                        logic_bit_count <= 'h0;
                        if (cfg_parity_en_i)
                        begin
                            NS <= PARITY;
                        end
                        else
                        begin
                            NS <= STOP_BIT_FIRST;
                        end
                    end
                    else
                    begin
                        logic_bit_count <= logic_bit_count + 1;
                        sampleData <= 1'b1;
                    end
                end
                else
                    NS <= DATA;
                
            end

// ---------------------------------------------         PARITY STATE       ----------------------------------------------------------------------
            PARITY:
            begin
                tx_o <= parity_bit;
                baudgen_en <= 1'b1;
                if (bit_done)
                    NS <= STOP_BIT_FIRST;
                else
                    NS <= PARITY;    
            end
// ---------------------------------------------         1st STOP BIT STATE       ----------------------------------------------------------------------
            STOP_BIT_FIRST:
            begin
                tx_o <= 1'b1;
                baudgen_en <= 1'b1;
                if (bit_done)
                begin
                    if (cfg_stop_bits_i)
                        NS <= STOP_BIT_LAST;
                    else
                        NS <= IDLE;
                end
            end
// ---------------------------------------------         2nd STOP BIT STATE       ----------------------------------------------------------------------
            STOP_BIT_LAST:
            begin
                tx_o <= 1'b1;
                baudgen_en <= 1'b1;
                if (bit_done)
                begin
                    NS <= IDLE;
                end
            end
            default:
                NS <= IDLE;
        endcase
    end

    always @(posedge clk_i or negedge rstn_i)
    begin
        if (rstn_i == 1'b0)
        begin
            CS             <= IDLE;
            logic_data       <= 8'hFF;
            logic_bit_count  <=  'h0;
            parity_bit     <= 1'b0;
        end
        else
        begin
            if(bit_done)
            begin
                parity_bit <= parity_bit_next;
            end

            if(sampleData)
            begin
                logic_data <= logic_data_next;
            end

            logic_bit_count  <= logic_bit_count_next;
            if(cfg_en_i)
               CS <= NS;
            else
               CS <= IDLE;
        end
    end

    // To Check The bit Has been Trasmitted or not 
    always_ff @(posedge clk_i or negedge rstn_i)
    begin
        if (rstn_i == 1'b0)
        begin
            baud_cnt <= 'h0;
            bit_done <= 1'b0;
        end
        else
        begin
            if(baudgen_en)
            begin
                if(baud_cnt == cfg_div_i)
                begin
                    baud_cnt <= 'h0;
                    bit_done <= 1'b1;
                end
                else
                begin
                    baud_cnt <= baud_cnt + 1;
                    bit_done <= 1'b0;
                end
            end
            else
            begin
                baud_cnt <= 'h0;
                bit_done <= 1'b0;
            end
        end
    end

endmodule