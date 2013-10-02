module LT1668_Driver(input Refin_Clk,//ÓÉËøÏà»·Ìá¹©µÄÆµÂÊ£¬Îª24£Í£È£Ú
					input SYS_START,
					input [15:0]Amp_Pos_Control,//·ù¶È´óĞ¡¿ØÖÆĞÅÏ¢,Ä¬ÈÏÂú·ùÊä³ö
					input [15:0]Bias_Control,//Êä³öÆ«ÖÃ¿ØÖÆ
					output DAC_CLK,
					output reg [15:0]DAC_DATA
					//output [15:0]Amp_Neg_Control,
					//output reg[2:0]State
					);

parameter 
DEFAUT_POS_AMP = 16'hffff,	//12.5V
DEFAUT_NEG_AMP = 16'h0,		//-12.5V 
DEFAUT_BIAS_AMP = 16'h7fff,	//0V
on = 1'b1,
off = 1'b0;

wire Amp_Ctrl_Flag;
wire Bias_Ctrl_Flag;

reg [15:0]Amp_Neg_Control;
reg[2:0]State;
reg[15:0]Amp_pos;
reg[15:0]Bias_Ctrl;

//assign Amp_Neg_Control = ~Amp_Pos;
assign Bias_Ctrl_Flag = (Bias_Control==16'h0)?off:on;
assign Amp_Ctrl_Flag =  (Amp_Pos_Control==16'h0)?off:on;
assign DAC_CLK = (Refin_Clk&SYS_START);



always@(negedge Refin_Clk)
begin
	if(!SYS_START)
	begin
		State<=3'b0;
		DAC_DATA<= DEFAUT_BIAS_AMP;//Ä¬ÈÏÊä³ö0VµçÑ¹
		Amp_pos <= Amp_Pos_Control;
		Bias_Ctrl <= Bias_Control;
		Amp_Neg_Control <= ~Amp_Pos_Control;
	end
	else
	begin
		case(State)
		3'd0,3'd1:
		begin
			if(!Amp_Ctrl_Flag)//±íÊ¾Íâ½çÃ»ÓĞ¸øÊäÈë,²ÉÓÃÂú·ùÊä³ö
				DAC_DATA <= DEFAUT_POS_AMP;
			else
				DAC_DATA <= Amp_pos;
			State <= State+1'b1;
		end
		3'd2:
		begin
			if(!Bias_Ctrl_Flag)//±íÊ¾Íâ½çÃ»ÓĞ¸øÊäÈë,²ÉÓÃ0Æ«ÖÃÊä³ö
				DAC_DATA <= DEFAUT_BIAS_AMP;
			else
				DAC_DATA <= Bias_Ctrl;
			State <= State+1'b1;
		end
		3'd3,3'd4:
		begin
			if(!Amp_Ctrl_Flag)//±íÊ¾Íâ½çÃ»ÓĞ¸øÊäÈë,²ÉÓÃÂú·ùÊä³ö
				DAC_DATA <= DEFAUT_NEG_AMP;
			else
				DAC_DATA <= Amp_Neg_Control;
			State <= State+1'b1;
		end
		3'd5:
		begin
			if(!Bias_Ctrl_Flag)//±íÊ¾Íâ½çÃ»ÓĞ¸øÊäÈë,²ÉÓÃ0Æ«ÖÃÊä³ö
				DAC_DATA <= DEFAUT_BIAS_AMP;
			else
				DAC_DATA <= Bias_Ctrl;
			State <= 3'b0;
			Amp_pos <= Amp_Pos_Control;
			Bias_Ctrl <= Bias_Control;
		end
		default:
		begin
			State<=3'b0;
			DAC_DATA<= DEFAUT_BIAS_AMP;//Ä¬ÈÏÊä³ö0VµçÑ
			Amp_pos <= Amp_Pos_Control;
			Bias_Ctrl <= Bias_Control;
			Amp_Neg_Control <= ~Amp_Pos_Control;
		end
		endcase
	end
end
endmodule
