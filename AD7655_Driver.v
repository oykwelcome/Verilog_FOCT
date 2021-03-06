/***************************************************
*说明：该模块为Ad7655的驱动
*date:2013/01/29
*Author:Yu Xuejun
*****/

module AD7655_Driver(input Clk_100M,//系统时钟
					input SYS_START,//同步开始线
					input n_BUSY,//转换忙状态
					input n_EOC,//通道完成转换标志，下降沿有效
					input [15:0]ADC_DATA,
					output reg A0,
					output reg AB_n,
					output reg n_CS,//chip select,enable when n_CS=0
					output reg n_RD,//read Enable when set to Low
					output reg n_CNVST,//data begin to convert as the falling edge coming
					output reg[15:0] TEMP_Info,//光纤温度信息
					output reg[15:0] MOD_Info,//调制幅度信息
					output reg[15:0] Current_Info,//电流信息
					output ADC_IMPULSE
					);
//通道数据切换关系
/**********************
---------------------------------
  A0    AB_n     Channel
---------------------------------
  0      1        INA1
  0      0        INB1
  1      1        INA2
  1      0        INB2       
---------------------------------
************************/
parameter 
on = 1'b1,
off = 1'b0,
DELAY_CNVST = 3'd4,//40ns delay
DELAY_BUSY = 5'd28;//280ns delay

reg[2:0]CNVST_cnt;
reg[4:0]BUSY_cnt;

//detect the falling edge of BUSY
reg BUSY_Before;
reg BUSY_After;
reg BUSY_Fall_Flag;

//detect the edge of n_EOC
/**/
reg EOC_Before;
reg EOC_After;
reg EOC_Flag;


assign ADC_IMPULSE= off;

initial
begin
	A0 <= off;
	AB_n <= on;
	n_CS <= on;
	n_RD <= on;
	n_CNVST <= on;
	
	TEMP_Info <= 16'b0;
	MOD_Info <= 16'b0;
	Current_Info <= 16'b0;
	
	CNVST_cnt <= 3'd0;
	BUSY_cnt <= 5'd0;
	
	BUSY_Before <= off;
	BUSY_After <= off;
	BUSY_Fall_Flag <= off;
	/**/
	EOC_Before<=off;
	EOC_After <=off;
	EOC_Flag <= off;
	
end



always@(posedge Clk_100M)
begin
	if(!SYS_START)//the project begin with the rising edge of SYS_START
	begin
		A0 <= off;
		n_CS <= on;
		n_RD <= on;
		n_CNVST <= on;
		CNVST_cnt <= 3'd0;
		BUSY_cnt <= 5'd0;
		
		BUSY_Before <= off;
		BUSY_After <= off;
		BUSY_Fall_Flag <= off;
		
		AB_n <= on;
		TEMP_Info <= 16'b0;
		MOD_Info <= 16'b0;
		Current_Info <= 16'b0;
		
		EOC_Before<=off;
		EOC_After <=off;
		EOC_Flag <= off;
		
		
		
	end
	else
	begin
/*****************************************
Convert process
**********************************************/
		n_CS <= off;
		n_RD <= off;
		// detect the falling edge of n_BUSY
		BUSY_Before <= BUSY_After;
		BUSY_After <= n_BUSY;
		if((BUSY_Before==on)&&(BUSY_After==off))//下降沿
			BUSY_Fall_Flag <= on;
		if(BUSY_Fall_Flag)
		begin
			if(BUSY_cnt<DELAY_BUSY)//delay 280ns
				BUSY_cnt <= BUSY_cnt+1'b1;
			else
			begin
				BUSY_Fall_Flag<=off;
				BUSY_cnt <= 5'd0;
				CNVST_cnt <= 3'd0;
				//A0 <= ~A0;
			end
		end
		if(CNVST_cnt < DELAY_CNVST)//delay 40ns
		begin
			CNVST_cnt <= CNVST_cnt +1'b1;
			n_CNVST <= off;
		end
		else
			n_CNVST <= on;
/**************************************
read data from AD7655
************************************************/
		EOC_Before <= EOC_After;
		EOC_After <= n_EOC;
		//cnter <= cnter + 1'b1;
		if((EOC_Before==on)&&(EOC_After==off))
			EOC_Flag <= on;
		//if((EOC_Before==off)&&(EOC_After==on))
		//	
		if(EOC_Flag)
		begin
			case({A0,AB_n})
			2'b01:Current_Info<= ADC_DATA; //INA1
			2'b00:MOD_Info<= ADC_DATA;//INB1
			
			2'b11:TEMP_Info<= ADC_DATA;//INA2
			2'b10:;				
			endcase
			AB_n<= ~AB_n;
			EOC_Flag <= off;
		end
		
		 
	end
end


endmodule
