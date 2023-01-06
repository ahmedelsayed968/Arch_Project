module baud_rate  #(
    parameter Counter_Width = 16
)
(
    input   wire                            clk_i,              // System Clock
    input   wire                            rstn_i,             // RESET NEG Logic
    input   wire                            baudgen_en,         // Enable GEN
    input   reg[Counter_Width-1:0]          cfg_div_i,          // wait to send the bit              
    output  reg                             o_bit_done          // output to notify bit has been sent
);
    reg[Counter_Width-1:0] baud_cnt = 0;
    always @(posedge clk_i or negedge rstn_i)
        begin
            if (rstn_i == 1'b0)
            begin
                baud_cnt = 'h0;
                o_bit_done = 1'b0;
            end
            else
            begin
                if(baudgen_en)
                begin
                    if(baud_cnt == cfg_div_i)
                    begin
                        baud_cnt = 'h0;
                        o_bit_done = 1'b1;
                    end
                    else
                    begin
                        baud_cnt = baud_cnt + 1;
                        o_bit_done = 1'b0;
                    end
                end
                else
                begin
                    baud_cnt = 'h0;
                    o_bit_done = 1'b0;
                end
            end
        end
    
endmodule
