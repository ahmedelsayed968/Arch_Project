// clock Generator
module CLKGEN(CLK);
	output reg CLK;
	parameter Delay = 50;
	initial
		CLK = 0;
	always
		#Delay CLK <= ~CLK;
endmodule

module tsClk;
    wire clk;
    
    
    
    initial begin
        
        $monitor("%b",clk);
        end
    CLKGEN cl1(.CLK(clk));    

endmodule        
