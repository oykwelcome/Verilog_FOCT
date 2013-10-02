module Eigen_Freq(input Refin_Clk,
				//input signal,
				input SYS_START,
				output reg Eigen_Freq_Temp,//����¶���Ϣ�ı���Ƶ��
				output reg Eigen_Freq_Crt,//���������Ϣ�ı���Ƶ��
				output  Eigrn_Ferq_Amp//������Ʒ�����Ϣ
				);
/**********************************************
*˵��������Ƶ������ģ�飬�����¶Ƚ���ı���Ƶ�ʣ���������ı���Ƶ��,����һ����������Ƶ��;
*������ź�ģ�Ͳο��������ͼ������������������ѯ����ʦ
*date: 2013/01/29
*Author:Yuxuejun
******/				

/******************************
Refin_Clk  --_  _--_  _--_  _--_  _--   24MHZ
			  --    --    --    --
--------------------------------------------
Temp_Clk     -  -  -  -  -  -  -  -
		   -- -- -- -- -- -- -- -- --
-----------------------------------------------
		   --    --    --    --
Crt_Clk      ____  ____  ____  ____
------------------------------------------------

Amp_CLk
*********************************/
parameter 
on = 1'b1,
off = 1'b0;

reg[2:0]Cnt;
reg[9:0] CntDelay;
reg Delay;
assign Eigrn_Ferq_Amp = Refin_Clk ;

initial
begin
	Cnt <= 3'd0;
	Eigen_Freq_Temp<= off;
	Eigen_Freq_Crt <= on;
	//Eigrn_Ferq_Amp <= off;
end


/*
always@(posedge Clk_100M)
begin
	if(!SYS_START)
	begin
		CntDelay <= 10'b0;
		Delay <= 1'b0;
	end
	else
		begin
		if(CntDelay < 10'd1)
		begin
			Delay <= 1'b0;
			CntDelay<=CntDelay+1'b1;
		end
		else
			Delay <= 1'b1;
		end
end

reg SRise,FRise,RiseFlag;
always @(posedge Refin_Clk)
begin
	if(!SYS_START)
		begin
		RiseFlag <= 1'b0;
		end
	else
	begin
		SRise<= signal;
		FRise <= SRise;
		if(SRise&&(!FRise))
			begin
			RiseFlag <=	1'b1;
			end
		else
		RiseFlag <= RiseFlag;
	end

end
*/


always@(posedge Refin_Clk)
begin
	if(!SYS_START)
	begin
		Cnt <= 3'd0;
		Eigen_Freq_Temp<= off;
		Eigen_Freq_Crt <= off;//on;
		//Eigrn_Ferq_Amp <= off;
	end
	else
	begin
		case(Cnt)
		3'd0:
		begin
			Eigen_Freq_Temp <= on;
			Eigen_Freq_Crt <= on;
			Cnt <= Cnt+1'b1;
		end
		3'd1:
		begin
			Eigen_Freq_Temp <= off;
			Eigen_Freq_Crt <= on;
			Cnt <= Cnt+1'b1;
		end
		3'd2:
		begin
			Eigen_Freq_Temp <= off;
			Eigen_Freq_Crt <= off;
			Cnt <= Cnt+1'b1;
		end
		3'd3:
		begin
			Eigen_Freq_Temp <= on;
			Eigen_Freq_Crt <= on;
			Cnt <= Cnt+1'b1;
		end
		3'd4:
		begin
			Eigen_Freq_Temp <= off;
			Eigen_Freq_Crt <= on;
			Cnt <= Cnt+1'b1;
		end
		3'd5:
		begin
			Eigen_Freq_Temp <= off;
			Eigen_Freq_Crt <= off;
			Cnt <=3'b0;
		end
		default:
		begin
			Cnt <= 3'd0;
			Eigen_Freq_Temp<= off;
			Eigen_Freq_Crt <= off;//on;
			//Eigrn_Ferq_Amp <= off;
		end
		endcase
	end
end

endmodule