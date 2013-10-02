module divFre(input Clk_24M,
				output reg  Clk_2M4);

reg[5:0]Cnt;
always@(posedge Clk_24M)
begin
	if(Cnt==6'd4)
		begin
		Cnt<=6'd0;
		Clk_2M4 <= ~Clk_2M4;
		end
	
	else
	Cnt<= Cnt+1'b1;
end
endmodule
