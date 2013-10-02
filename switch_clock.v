`include "headdefine.v"

module switch_clock(input Clk_100M,
					//input External_PLL,
					//input Standard_CLK,
					input SYS_START,
					//output Refin_Clk
					output reg ClkStart
					);
					
reg[9:0] cnt;
//reg      ClkStart;
	
	
`ifdef USE_ePLL					
always @(posedge Clk_100M)
begin
	if(!SYS_START)
		begin
		cnt <= 10'b0;
		ClkStart <= 1'b0;
		end
	else
		begin
		if(cnt < 10'd1000)
			begin
			cnt <= cnt + 1'b1;
			ClkStart <= 1'b0;
			end
		else
			ClkStart <= 1'b1;
		end
end
`else
always @(posedge Clk_100M)
begin
	ClkStart <= 1'b0;
end			

`endif		
//assign Refin_Clk=(ClkStart)?External_PLL:Standard_CLK;
//assign Refin_Clk=External_PLL;//Standard_CLK;					
endmodule
