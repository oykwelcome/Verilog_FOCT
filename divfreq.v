module divFreq(Clk_400K,Clk_10K);

input Clk_400K;
output Clk_10K;

reg Clk_10K;
reg [9:0] cnt_div_fre;
always @ (posedge Clk_400K)
begin
	if(cnt_div_fre == 10'd5)
		begin
		Clk_10K <= ~Clk_10K;
		cnt_div_fre <= 10'd0;
		end
	else
		begin
		Clk_10K <= Clk_10K;
		cnt_div_fre <= cnt_div_fre + 1'b1;
		end
	
end

endmodule
