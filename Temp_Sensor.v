module Temp_Sensor(input CLK_400K,
                    input SYS_START,
					output reg SCL,
					//inout SDA,
					output reg Trans_Over,
					output reg signed[15:0]Temp_Data,
					output reg Error,
					input SDA_IN,
				    output reg SDL_out,
					output reg ACK_Flag
					);

parameter
/* 
MSB输出，所以做一下逆序
WRITE_CMD= 8'h90,//1001是START命令，000是表示地址，0表示写数据，也就是RW_n=0
READ_CMD = 8'h91,
TEMP_CVT = 8'hee,//开始温度转换
TEMP_READ= 8'haa,//开始读取温度信息
ACCESS_CONF = 8'hac,//配置寄存器指令
CONF_DATA = 8'h4a,//配置寄存器数据
DELAY_1S = 18'd200000;//温度转换时间为1秒
*/
WRITE_CMD = 8'b00001001,
READ_CMD = 8'b10001001,
TEMP_CVT = 8'b01110111,//开始温度转换
TEMP_READ= 8'b01010101,//开始读取温度信息
STATE_ERROR = 8'b11111111,//表示出错的状态
ACCESS_CONF = 8'b00110101,//配置寄存器指令 10101100
CONF_DATA = 8'b11010010,//配置寄存器数据
DELAY_1S = 20'd200500;//温度转换时间为1秒

parameter 
on = 1'b1,
off = 1'b0;


reg[19:0]Delay_CNT;
reg[7:0]Cnt1;
reg[4:0]Cnt2;
reg[3:0]Cnt3;
reg[7:0]CRT_STATE;

reg [1:0]State1;
reg [3:0]State2;

//ACK_FLag=1,input;ACK_Flag=0,output
//wire SDA_IN;

//reg ACK;
//reg SDL_out;
//reg ACK_Flag;
reg SDA_OUT;
//assign SDA=(ACK_Flag)?1'bz:SDL_out;
//assign SDA_IN=(ACK_Flag)?SDA:1'bz;

initial
begin
	SCL<=on;
	Trans_Over<=off;
	Temp_Data<= 13'b0;
	Error<= off;
	ACK_Flag<= off;
	//ACK<=1'b0;
	SDL_out <=on;
	Delay_CNT<= 20'b0;
	Cnt1 <= 8'b0;
	Cnt2 <= 5'b0;
	Cnt3 <=4'b0;
	CRT_STATE <= WRITE_CMD;
	State1<= 2'b0;
	State2<= 4'd0;
end
//delay 90degree
always@(negedge CLK_400K)
begin
	if(!SYS_START)
		SDA_OUT<=on;
	else
		SDA_OUT<=SDL_out;
end
always@(posedge CLK_400K )
begin
	if(!SYS_START)
	begin
		SCL<=on;
		Trans_Over<=off;
		Temp_Data<= 13'b0;
		Error<= off;
		ACK_Flag<= off;
		//ACK<=1'b0;
		SDL_out <=on;
		Delay_CNT<= 20'b0;
		Cnt1 <= 8'b0;
		Cnt2 <= 5'b0;
		CRT_STATE <= WRITE_CMD;
		State1<= 2'b0;
		State2<= 4'd0;
		Cnt3 <=4'b0;
	end
	else
	begin
		case(State1)
		2'd0:
		begin
			if(Cnt1==8'b0)//0,START CMD
			begin
				if(Cnt3 < 4'd2)//delay
				begin 
					Cnt3 <= Cnt3+1'b1;
					SCL<=on;
					SDL_out<=on;//默认状态
					ACK_Flag<= off;
					Cnt2 <= 5'b0;
					//State2<= 4'd4;
				end
				else
				begin
					SCL<=on;
					SDL_out<=off;//开始传输，数据线先拉低 START
					ACK_Flag<=off;
					Cnt1<=Cnt1+1'b1;
					Cnt3<= 4'd0;
					Trans_Over<=off;
				end
			end
			/*********
			SDA ----___
			SCL	------___
			**********/
			else if(Cnt1==8'b1)//START  
			begin
				SCL<=off;
				Cnt1<=Cnt1+1'b1;
			end
			
			else if(Cnt1==8'd34)//从设备获取确认信息
			begin
				ACK_Flag<=on;//高阻状态，读取确认信息
				SDL_out<=on;
				Cnt1<=Cnt1+1'b1;
			end
			else if(Cnt1==8'd35)//从设备获取确认信息
			begin
				SCL<=on;
				Cnt1<=Cnt1+1'b1;
			end
			else if(Cnt1==8'd36)//从设备获取确认信息
			begin
				ACK_Flag<=on;
				Cnt1<=Cnt1+1'b1;
			end
			else if(Cnt1==8'd37)//拉高时钟，确认信息输入到ACK中
			begin
				ACK_Flag<=off;//高阻状态，读取确认信息
				case(State2)
				4'd0://配置寄存器指令,0xach   01010010
				begin SDL_out<=off;SCL<=off; Cnt1<=8'd2; State2<=4'd1; CRT_STATE<=ACCESS_CONF;Cnt2<=5'b0; end
				4'd1://配置寄存器数据,0x4a
				begin SDL_out<=off;SCL<=off; Cnt1<=8'd2; State2<=4'd2; CRT_STATE<=CONF_DATA; Cnt2<=5'b0; end
				4'd2://STOP CMD
				begin SDL_out<=off;SCL<=off; Cnt1<=8'd38; State2<=4'd3;CRT_STATE<=WRITE_CMD;Cnt2<=5'b0;  end
				4'd3://delay
				begin
					SDL_out<=on;
					if(Delay_CNT<20'd2012)//>10ms
					begin
						Delay_CNT<= Delay_CNT+1'b1;
						ACK_Flag<=off;//高阻状态，读取确认信息
					end
					else
					begin
						Delay_CNT<= 20'b0;
						Cnt1<=8'd0;
						State2<=4'd4;
					end
				end	
				4'd4://开启温度转换,0xee
				begin SDL_out<=off;SCL<=off;Cnt1<=8'd2; State2<=4'd5;CRT_STATE<=TEMP_CVT; Cnt2<=5'b0; ACK_Flag<=off; end
				4'd5://STOP CMD
				begin SDL_out<=off; SCL<=off; Cnt1<=8'd38; State2<=4'd6;Cnt2<=5'b0; end
				4'd6://转换时间耗时1秒钟，等待
				begin 
					SDL_out<=on;
					CRT_STATE<=WRITE_CMD; //写数据控制命令,0x90
					State1<=2'd2;
					State2<=4'd7;
					Cnt1<=8'd0;
				end
				4'd7:
				begin
					SCL<=off;
					CRT_STATE<=TEMP_READ;//开启读取温度,0xaa
					State2<=4'd8;
					Cnt1<=8'd2;
				end
				4'd8:
				begin
					SCL<=off;
					State2<=4'd9;
				end
				4'd9:
				begin
					SDL_out<=on;
					State2<=4'd10;
				end
				4'd10:
				begin
					SCL<=on;
					CRT_STATE<=READ_CMD;//读数据控制命令,0x91
					State2<=4'd11;
					Cnt1<=8'd0;
				end
				4'd11:
				begin
					SCL<=off;
					State1<=2'd1;//开始读取温度数据
					State2<=4'd0;
					Cnt1<=8'd0;
					Cnt2<=5'd15;
					ACK_Flag <= on;
				end
				default:;
				endcase
			end
			/*******
			SDL  ____--------
			SCL  __-----___
			********/
			else if(Cnt1==8'd38)//STOP CMD
			begin
				Cnt1<=8'd39;
				ACK_Flag <=off;
				SDL_out<= off;
 			end
			else if(Cnt1==8'd39)//STOP CMD
			begin
				Cnt1<=8'd40;
				SCL<=on;
			end
			else if(Cnt1==8'd40)//STOP CMD
			begin
				Cnt1<=8'd37;
				SDL_out<= on;
				ACK_Flag <=off;
			end
			else
			begin
				case(Cnt1[1:0])
				2'd1://5,9,13,17,21,25,29,33
				begin 
					SCL<=off;//时钟线然后拉低
					Cnt1<=Cnt1+1'b1;
			    end
			    2'd2://2,6,10,14,18,22,26,30
				begin
					SDL_out<=CRT_STATE[Cnt2];//SCL下降沿给出数据
					Cnt1<=Cnt1+1'b1;
					Cnt2<=Cnt2+1'b1;
					ACK_Flag<=off;
				end
				default://3,7,11,15,19,23,27,31//4,8,12,16,20,24,28,32
				begin
					SCL<=on;
					Cnt1<=Cnt1+1'b1;
				end
				endcase
			end
		end
		2'd1://开始读取温度信息
		begin
			case(Cnt1)
			8'd32:
			begin
				SCL<=off;
				ACK_Flag<=off;
				Cnt1<=Cnt1+1'b1;
			end
			8'd33://输出确认信息SDA=0
			begin
				SDL_out<=off;
				Cnt1<=Cnt1+1'b1;
			end
			8'd34://输出确认信息SDA=0
			begin
				SCL<=on;
				Cnt1<=Cnt1+1'b1;
			end
			8'd35://输出确认信息SDA=0
			begin
				ACK_Flag<=on;
				Cnt1<=Cnt1+1'b1;
			end
			8'd68://输出不确认信息SDA=1
			begin
				SCL<=off;
				ACK_Flag<=off;
				Cnt1<=Cnt1+1'b1;
			end
			8'd69://输出不确认信息SDA=1
			begin
				SDL_out<=on;
				Cnt1<=Cnt1+1'b1;
			end
			8'd70://输出不确认信息SDA=1
			begin
				SCL<=on;
				Cnt1<=Cnt1+1'b1;
			end
			8'd71://STOP CMD
			begin
				ACK_Flag<=off;
				SCL<=off;
				Cnt1<=Cnt1+1'b1;
			end
			8'd72://STOP CMD
			begin
				SDL_out<=off;
				Cnt1<=Cnt1+1'b1;
			end
			8'd73://STOP CMD
			begin
				SCL<=on;
				Cnt1<=Cnt1+1'b1;
			end
			8'd74:
			begin
				SDL_out<=on;
				Trans_Over<=on;
				Error<= off;
				ACK_Flag<= off;
				Cnt2 <= 5'b0;
				CRT_STATE <= WRITE_CMD;
				State2<= 4'd0;
				if(Delay_CNT<20'd200)//200K 5us*200*10=10ms
					Delay_CNT<= Delay_CNT+1'b1;
				else
				begin
					Delay_CNT<= 20'b0;
					Cnt1<=8'd0;
					State1<=2'd0;
				end	
			end
			default:
			begin
				case(Cnt1[1:0])
				2'd0://0,4,8,12,16,20,24,28----36,40,44,48,52,56,60,64
				begin
					SCL<=off;//时钟线拉低
					ACK_Flag<=on;//输出切换为输入
					SDL_out<= off;/////////
					Cnt1<=Cnt1+1'b1;
				end
				2'd1://1,5,9,13,17,21,25,29----37,41,45,49,53,57,61,65
				begin
					SCL<=off;//时钟线拉低
					Cnt1<=Cnt1+1'b1;
				end
				2'd2://2,6,10,14,18,22,26,30----38,42,46,50,54,58,62,66
				begin
					SCL<=on;
					Cnt1<=Cnt1+1'b1;
				end
				2'd3://3,7,11,15,19,23,27,31----39,43,47,51,55,59,63,67
				begin
					if(Cnt2<=5'd15)
						Temp_Data[Cnt2]<=SDA_IN;
					Cnt1<=Cnt1+1'b1;
					Cnt2<=Cnt2-1'b1;
				end
				endcase
			end
			endcase
		end
		2'd2://等待1秒钟
		begin
			if(Delay_CNT<DELAY_1S)
			begin
				Delay_CNT<= Delay_CNT+1'b1;
				ACK_Flag<= off;
				SDL_out<=on;
				SCL<=on;
			end
			else
			begin
				Delay_CNT<= 20'b0;
				State1<=2'd0;
			end
		end
		
		2'd3://Error
		begin
			if(!Error)
			begin
				SDL_out<=off;
				Error<=on;
			end
			else
			begin
				SCL<=on;
				SDL_out <=on;
				Trans_Over<=off;
				Temp_Data<= 13'b0;
				Error<= on;
				ACK_Flag<= off;
				//ACK<=1'b0;
				Delay_CNT<= 20'b0;
				Cnt1 <= 8'b0;
				Cnt2 <= 5'b0;
				CRT_STATE <= WRITE_CMD;
				State2<= 4'd0;
				//延迟一段时间自启动, add your code here
			end
		end
		endcase
	end

end
endmodule