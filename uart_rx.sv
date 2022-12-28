
module uart_rx (
        input  logic            clk_i,
        input  logic            rstn_i,
        input  logic            rx_i,
        input  logic [15:0]     cfg_div_i,
        input  logic            cfg_en_i,
        input  logic            cfg_parity_en_i,
        input  logic [1:0]      cfg_bits_i,
        input  logic            cfg_stop_bits_i,
        output logic            busy_o,
        output logic            err_o,
        input  logic            err_clr_i,
        output logic [7:0]      rx_data_o,
        output logic            rx_valid_o,
        input  logic            rx_ready_i
    );

    parameter [2:0] IDLE=3'b000;
    parameter [2:0] START_BIT=3'b001;
    parameter [2:0] DATA = 3'b010;
    parameter [2:0] SAVE_DATA = 3'b011;
    parameter [2:0] PARITY=3'b100;
    parameter [2:0] STOP_BIT= 3'b101;
    
    logic[2:0] CS =IDLE;
    logic[2:0] NS =IDLE;


    logic [7:0]  logic_data;
    logic [7:0]  logic_data_next;

    logic [2:0]  logic_rx_sync;


    logic [2:0]  logic_bit_count;
    logic [2:0]  logic_bit_count_next;

    logic [2:0]  s_target_bits;

    logic        parity_bit;
    logic        parity_bit_next;

    logic        sampleData;

    logic [15:0] baud_cnt;
    logic        baudgen_en;
    logic        bit_done;

    logic        start_bit;
    logic        set_error;
    logic        s_rx_fall;

    always @*
        busy_o <= (CS != IDLE);

    always @*
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

    always @*
    begin
        NS = CS;
        sampleData = 1'b0;
        logic_bit_count_next  = logic_bit_count;
        logic_data_next = logic_data;
        rx_valid_o = 1'b0;
        baudgen_en = 1'b0;
        start_bit  = 1'b0;
        parity_bit_next = parity_bit;
        set_error  = 1'b0;

        case(CS)
            IDLE:
            begin
                if (s_rx_fall)
                begin
                    NS = START_BIT;
                    baudgen_en = 1'b1;
                    start_bit  = 1'b1;
                end
            end

            START_BIT:
            begin
                parity_bit_next = 1'b0;
                baudgen_en = 1'b1;
                start_bit  = 1'b1;
                if (bit_done)
                    NS = DATA;
            end

            DATA:
            begin
                baudgen_en = 1'b1;
                parity_bit_next = parity_bit ^ logic_rx_sync[2];
                case(cfg_bits_i)
                    2'b00:
                        logic_data_next = {3'b000,logic_rx_sync[2],logic_data[4:1]};
                    2'b01:
                        logic_data_next = {2'b00,logic_rx_sync[2],logic_data[5:1]};
                    2'b10:
                        logic_data_next = {1'b0,logic_rx_sync[2],logic_data[6:1]};
                    2'b11:
                        logic_data_next = {logic_rx_sync[2],logic_data[7:1]};
                endcase

                if (bit_done)
                begin
                    sampleData = 1'b1;
                    if (logic_bit_count == s_target_bits)
                    begin
                        logic_bit_count_next = 'h0;
                        NS = SAVE_DATA;
                    end
                    else
                    begin
                        logic_bit_count_next = logic_bit_count + 1;
                    end
                end
            end
            SAVE_DATA:
            begin
                baudgen_en = 1'b1;
                rx_valid_o = 1'b1;
                if(rx_ready_i)
                    if (cfg_parity_en_i)
                        NS = PARITY;
                    else
                        NS = STOP_BIT;
            end
            PARITY:
            begin
                baudgen_en = 1'b1;
                if (bit_done)
                begin
                    if(parity_bit != logic_rx_sync[2])
                        set_error = 1'b1;
                    NS = STOP_BIT;
                end
            end
            STOP_BIT:
            begin
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
            CS             <= IDLE;
            logic_data       <= 8'hFF;
            logic_bit_count  <=  'h0;
            parity_bit     <= 1'b0;
        end
        else
        begin
            if(bit_done)
                parity_bit <= parity_bit_next;
            if(sampleData)
                logic_data <= logic_data_next;

            logic_bit_count  <= logic_bit_count_next;
            if(cfg_en_i)
               CS <= NS;
            else
               CS <= IDLE;
        end
    end
    always@*
        s_rx_fall <= ~logic_rx_sync[1] & logic_rx_sync[2];
    always @(posedge clk_i or negedge rstn_i)
    begin
        if (rstn_i == 1'b0)
            logic_rx_sync <= 3'b111;
        else
        begin
            if (cfg_en_i)
                logic_rx_sync <= {logic_rx_sync[1:0],rx_i};
            else
                logic_rx_sync <= 3'b111;
        end
    end

    always @(posedge clk_i or negedge rstn_i)
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
                if(!start_bit && (baud_cnt == cfg_div_i))
                begin
                    baud_cnt <= 'h0;
                    bit_done <= 1'b1;
                end
                else if(start_bit && (baud_cnt == {1'b0,cfg_div_i[15:1]}))
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

    always @(posedge clk_i or negedge rstn_i)
    begin
        if (rstn_i == 1'b0)
        begin
            err_o <= 1'b0;
        end
        else
        begin
            if(err_clr_i)
            begin
                err_o <= 1'b0;
            end
            else
            begin
                if(set_error)
                    err_o <= 1'b1;
            end
        end
    end
    always@*
        rx_data_o <= logic_data;

endmodule