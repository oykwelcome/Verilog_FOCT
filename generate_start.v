
					
module generate_start(input Clk_100M,
				input Clk_800K,
				input ePLL_LOCK,
				// input[15:0]Temp_Info,
				// input[15:0]Mod_Info,
				// input[15:0]Crt_Info,
				// input Trans_Over,
				// input[12:0]Temp_Data,
				// input Error,
				 output  reg SYS_START,
				// output  [15:0]Amp_Pos_Control,
				output  [15:0]Bias_Control
				);

				
//assign Amp_Pos_Control = 16'h7fff;//16'ha741;
assign Bias_Control = 16'h7fff;
				
				

reg [15:0]Cnt1;
reg FRise;
reg SRise;
reg RiseFlag;
initial
begin
	Cnt1<=16'd0;
	SYS_START<=0;
	FRise <=0;
	SRise <=0;
	RiseFlag <=0;
end

always@(posedge Clk_100M)
begin
   SRise<= Clk_800K;
   FRise <= SRise;
   if(SRise&&(!FRise))//Rising Edge 检测400K的上跳沿
   begin
	   RiseFlag <=	1'b1;
   end
   else;
end

always@(posedge Clk_800K)
begin
	if(!RiseFlag)
	begin
		Cnt1<=16'd0;
		SYS_START<=0;
	end
	else
	begin
		if(Cnt1<16'd1000)//复位，延时时间为2.5us*40000=100ms
		begin
			SYS_START <=0;
			Cnt1<= Cnt1 +1'b1;
		end
		else
		 SYS_START <= 1;
	end
end

//assign SYS_START = 1'b1;

/*
reg delay;
always @(posedge Clk_100M)
begin
	delay <= ePLL_LOCK;
	SYS_START <= delay;
end
*/


endmodule
