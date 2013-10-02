`include "headdefine.v"
//��define FEEDBACK
module LTC1668_Driver(input Refin_Clk,//�����໷�ṩ��Ƶ�ʣ�Ϊ2.4�ͣȣ�
					input SYS_START,
					input [15:0]AD_AMP,//���ȴ�С������Ϣ,Ĭ���������
										//�첽�źţ�ע��ͬ��
					input [15:0]AD_BIAS,//���ƫ�ÿ���
					output DAC_CLK,
					output reg signed [15:0]Wave,
					output reg deCurrent,
					output reg deTemper,
					output reg signed [15:0]vStep
					);
 

localparam
          DEFAULT_AMP = 16'h902d,//16'h902d,//pi/2,16'ha9ab--3.5,16'h9900--2.1,16'h8854--0.7,16'ha87b--3.2,16'h91db--1.4(x=3048y+32767)
          DEFAULT_BIAS = 16'h7fff,	//0V
          ZERO = 16'h7fff;

localparam
          on = 1'b1,
          off = 1'b0;

wire Amp_Ctrl_Flag;
wire Bias_Ctrl_Flag;


reg [2:0] State;
reg signed [15:0] SquWave;



assign Bias_Ctrl_Flag = (AD_BIAS==ZERO)?off:on;


assign DAC_CLK = ~(Refin_Clk&SYS_START);






always@(posedge Refin_Clk)
begin
	if(!SYS_START)
	begin
		State<=3'b0;
		SquWave<= ZERO;//Ĭ�����0V��ѹ
		
		
		
	end
	else
	begin
		case(State)
		3'd0:
		begin
			SquWave               <= DEFAULT_AMP;
			State                 <= State+1'b1;
			deCurrent     <= on;
			deTemper <= off;
		end
		3'd1:
		begin
			SquWave               <= DEFAULT_AMP;
			State                 <= State+1'b1;
			deCurrent     <= off;
			deTemper <= on;
		end
		3'd2:
		begin
			if(!Bias_Ctrl_Flag)//��ʾ���û�и�����,����0ƫ�����
				SquWave <=DEFAULT_BIAS;
			else
				SquWave <= AD_BIAS;
			
			State                 <= State+1'b1;
			deCurrent     <= off;
			deTemper <= off;
		end
		3'd3:
		begin
			SquWave               <= ~DEFAULT_AMP;
			State                 <= State+1'b1;
			deCurrent     <= off;
			deTemper <= off;
		end
		3'd4:
		begin
			SquWave               <= ~DEFAULT_AMP;
			State                 <= State+1'b1;
			deCurrent     <= off;
			deTemper <= on;
		end

		3'd5:
		begin
			if(!Bias_Ctrl_Flag)//��ʾ���û�и�����,����0ƫ�����
				SquWave <= DEFAULT_BIAS;
			else
				SquWave <= AD_BIAS;
				
			State                 <= 3'b0;
			deCurrent     <= on;
			deTemper <= off;
			
		end
		default:
		begin
			State<=3'b0;
			//SquWave<= DEFAULT_BIAS;//Ĭ�����0V��?
			
			
		end
		endcase
	end
end


/************************************************
--    --    --    --    --
  -  -  -  -  -  -  -  -  -           �����ź�
   --    --    --    --    --
   
                  --
               -- 
            -- 
         --                           ���ݷ���
      --
   --
---  -  -  -  -  -
*************************************************/
`ifdef FEEDBACK
//DA������ϱ߽��±߽磬�����߽�2pi��λ
//localparam 
//upBoundary   = 16'h6f55,
//downBoundary = -16'h6f55,
//vReset = 16'h8558;//2pi��λ��ѹ

//AD�����źŵ����ĵ�ѹ�ı߽磬�����߽����ջ����ݲ�����
//localparam
//minCenter    = 16'd65535,
//maxCenter    = 16'd0,
//meanCenter   = 16'd16500;





//������ʱһ��ʱ��������ݲ�����
reg [31:0] cntDelay;
reg Flag;
always @ (posedge Refin_Clk)
begin
	if(!SYS_START)
		begin
		Flag <= 1'b0;
		cntDelay <= 32'd0;
		end
	else
		if(cntDelay == 32'd2999)
			Flag <=1'b1;
		else
			cntDelay <= cntDelay +1'b1;

end


//����Ƶ��
reg [15:0] cnt;
localparam FRE_COMP = 16'd511;//2^K-1���������ʣ�����̫�죬�������������̫����������̫�٣�������β�ƽ��
always @ (posedge Refin_Clk)
begin
	if(!Flag)
		cnt <= 16'd0;
	else
		if(cnt==FRE_COMP)
			cnt <= 16'd0;
		else
			cnt <= cnt +1'b1;

end


//���ݲ�Ƶ��
reg [1:0] cnt1;
always @ (posedge Refin_Clk)
begin
	if(!Flag)
		cnt1 <= 2'd0;
	else
		if(cnt1==2'd2)
			cnt1 <= 2'd0;
		else
			cnt1 <= cnt1 +1'b1;

end


`ifdef DYNAMIC
//��ȡ���ݲ���̨�׸߶�
wire [15:0] maxCenter = 16'd23000;
wire [15:0] minCenter = 16'd22000;
wire [15:0] meanCenter = 16'd13960;//16'd18935;
wire signed [15:0]  Index = 16'd10;//�������ӡ���С���񵴣����󣬲�������
reg [24:0] ad_average;
reg signed [15:0] vReal;
//reg signed [15:0] vStep;
always @ (posedge Refin_Clk)
begin
	/*if(!Flag)
		begin
		vReal <= 16'b0;
		vStep <= 16'b0;
		end
	else
		begin
		 // if ((AD_AMP >= maxCenter)||(AD_AMP <= minCenter))
			vReal <= -(AD_AMP - meanCenter);//������ϵͳ
		  // else 
			 // vReal <= 16'b0;
		vStep <= vReal/Index;
		end*/
	if(!Flag)
		begin
		vReal <= 16'b0;
		vStep <= 16'b0;
		ad_average <= AD_AMP;
		end
	else
		begin
		ad_average <= ad_average + AD_AMP;//����ƽ��
		
		if(cnt == FRE_COMP)
			ad_average <= ad_average>>9;
		if(cnt == 20'd0)
			begin
			vReal <= (ad_average - meanCenter);
			vStep <= vReal/Index;
			end
		end
		
end
/*
//������ݲ����ۼ�̨�׸߶�
reg signed [15:0] vSumStep;
always @ (posedge Refin_Clk)
begin
	if(!Flag)
		begin
		vSumStep <= 16'b0; 
		end
	else
		// if(cnt == FRE_COMP)
			// vSumStep <= vSumStep + vStep;
		// else
			// vSumStep <= vSumStep;
			vSumStep <= vStep;
			
end*/

`else
reg signed [15:0] vSumStep/*synthesis preserve*/;
always @ (posedge Refin_Clk)
begin
	if(!Flag)
		begin
		vSumStep <= 16'b0; 
		end
	else
		if(cnt == FRE_COMP)
		
			// vSumStep <= vSumStep + 10'd200;
			vSumStep <=16'd156;
		else
			vSumStep <= vSumStep;
end

`endif


//���ɽ��ݲ�

reg signed [15:0] upBoundary;
reg signed [15:0] downBoundary;
reg signed [15:0] StepWave;
reg [15:0] vReset;
reg signed [15:0] realzero;
always @ (posedge Refin_Clk)
begin
	if(!Flag)
		begin
		// vSumStep <= 16'd500;
		StepWave <= 16'd0;
		upBoundary <= 16'h6fd2;//16'h6f55;
		downBoundary <= -16'h6fd2;//-16'h6f55;
		vReset <= 16'h8170;//2pi��λ��ѹ
		realzero <= 16'd0;
		end
	else
		if(cnt1 == 2'd2)
			begin
			//if((StepWave < upBoundary)&&(StepWave > downBoundary))
				//StepWave = StepWave + vSumStep;
			 //else 
				if((((StepWave+vStep) >= upBoundary)&&(StepWave>realzero))
					||((StepWave>realzero)&&((StepWave+vStep)<realzero)&&(vStep>realzero)))
					StepWave <= StepWave - vReset + vStep;
				else
					if((((StepWave+vStep) <= downBoundary)&&(StepWave<realzero))
						||((StepWave<realzero)&&((StepWave+vStep)>realzero)&&(vStep<realzero)))
						StepWave <= StepWave + vReset + vStep;
					else
						StepWave <= StepWave + vStep;
					
			end 
		else
			StepWave <= StepWave;
end

/*reg signed [15:0] StepWave;//���ݲ���ʱһ��ʱ��
always @ (posedge Refin_Clk)
begin
	if(!SYS_START)
		StepWave <=16'd0;
	else
		StepWave <= StepWave;
end
*/

//���Ʋ�+���ݲ�


always @ (posedge Refin_Clk)
begin
	if(!SYS_START)
		begin
		Wave <= ZERO;
		end
	else
		// if(cnt1==2'd0)
			// Wave <= SquWave; 
		// else
			Wave <= SquWave + StepWave;
			
end



initial
begin
cnt <= 2'd0;
//vReal <= 16'd0;
//vStep <= 16'd0;
// vSumStep <= 16'd0;
StepWave <= 16'd0;
end

`else


always @ (posedge Refin_Clk)
begin
	if(!SYS_START)
		begin
		Wave <= ZERO;
		end
	else
		Wave <= SquWave;
end


`endif




initial
begin
State <= 3'b0;
SquWave <= ZERO;
Wave <= ZERO;
end




endmodule

