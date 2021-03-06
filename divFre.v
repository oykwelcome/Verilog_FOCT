module divFre(input Clk_24M,
				input signal,
				output reg  Clk_2M4);



reg SRise,FRise,RiseFlag;
always @(posedge Clk_24M)
begin
	//if(!SYS_START)
	//	begin
	//	RiseFlag <= 1'b0;
	//	end
	//else
	//begin
		SRise<= signal;
		FRise <= SRise;
		if(SRise&&(!FRise))
			begin
			RiseFlag <=	1'b1;
			end
		else
		RiseFlag <= RiseFlag;
	//end
end

reg[5:0]Cnt;
always@(posedge Clk_24M)
begin
	if(!RiseFlag)
		begin
		Cnt <= 6'd0;
		Clk_2M4 <= 1'b0;
		end
	else
		begin
		if(Cnt==6'd4)
			begin
			Cnt<=6'd0;
			Clk_2M4 <= ~Clk_2M4;
			end	
		else
			Cnt<= Cnt+1'b1;
		end
end
		
endmodule
