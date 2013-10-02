/***************************
Description:���ڲ��Գ���λ��������Vpi �Ӷ���������ķ�ֵ
			��ǰ����£�FFFF--->12.0V  0000--->-12.0V
Refin:24M 250ns/6
ɨ�裺0000-FFFF;ÿ250ns����һ�Σ�
ע�⣺������Ҫ����ʱ����ɾ��
*********************/


module Test_Module(input Refin_Clk,
					output Test_CLK,
					output reg[15:0]Test_Data);
//
reg[2:0] Cnt1;//divide the clock
reg[15:0]Cnt2;// sweep amp

assign Test_CLK = ~Refin_Clk;

always@(posedge Refin_Clk)
begin
	if(Cnt1<1)
	begin
		Cnt1<= Cnt1+1'b1;
		Test_Data<= Cnt2;
	end
	else
	begin
		Cnt1<=3'd0;
		if(Cnt2<16'h8000)
			Cnt2<= Cnt2+16'h1000;
		else
			Cnt2<= 16'h1000;
		
	end
end
endmodule
