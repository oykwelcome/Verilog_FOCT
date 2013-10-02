/***********************************************************************************
 **=================================================================================
 ** 						All right reserve 2012-2013(A) 
 ** 						Created &maintain by CoreTechnology
 **
 ** 模 块 名:   
 ** 描    述:   
 **             
 **
 ** 原 作 者:   
 ** 参 与 者:   
 **
 **=================================================================================
 ***********************************************************************************/
 module DS18B20(Clk,nRst,UpDate,Data,DQ,GND);
 input Clk;  //输入时钟50MHz
 input nRst;  //输入复位
 // input En;  // 启动温度转换
 output UpDate;  //输出更新标志
 output [15:0] Data;  //输出的温度数据
 inout DQ;  //数据管脚
 output GND;
 
 
 wire GND = 1'b0;
 /*				定义与声明				*/
 wire En = 1'b1;  //线网类型

 wire DQ;  //线网类型
 reg DqDir;  //方向选择 0：输入 1：输出
 reg DqOut;  //输出数据
 assign DQ = (DqDir == 1'b0) ?  1'bz : DqOut;  //双向端口，综合时需要使用三态口，仿真时可采用force语句。
 //定义分频参数，输入时钟为50MHz
 localparam  ClkCnt   = 250,  //1/50 * 250 = 5us 
			RstPulse = 100,  //100 * 5us = 500us
			Samples  = 16;  //16 * 5us = 80us
 
 
 
 //状态机使用的状态变量
`define  RSTIDLE   4'b0000  //复位空闲
`define	 RSTPUL    4'b0001  //复位脉冲
`define  RSTWAIT   4'b0010  //等待，主机释放总线
`define  RSTPRE    4'b0011  //存在脉冲
`define  WIREIDLE  4'b0100  //写数据空闲
`define  WIREPUL   4'b0101  //写脉冲
`define  WIREBIT   4'b0110  //写位
`define  WIRESFT   4'b0111  //数据移位
`define  READIDLE  4'b1000  //读数据空闲
`define  READPUL   4'b1001  //读脉冲
`define  READBIT   4'b1010  //读位
`define  READSFT   4'b1011  //数据移位
`define  CMDIDLE   4'b1100  //指令等待空闲
`define  CMDFUN    4'b1101  //功能函数
`define  CMDDELY   4'b1110  //指令延时
			




			
			
 /*				5μs时钟产生				*/
 reg [7:0] DivCnt;  //时钟分频计数值
 wire PulseClk;
 assign PulseClk = (DivCnt == ClkCnt);
 always@(posedge Clk )
 begin
	if(~nRst) begin
	     DivCnt = 1'b0;  //计数值归零
	end
	else if(En) begin
		if(PulseClk & TimingEn)  //占空比 ！=50%
			DivCnt = 8'd0;
	    else 
			DivCnt = DivCnt+1'b1;
	end
	else begin
		DivCnt = 1'b0;  //计数值归零
	end
 end
 
 
 
 
 
 /*				ds18b20时序产生				*/
 reg TimingEn; //时序使能标志
 reg [6:0] TimingCnt;  //时序计数
 always@(posedge Clk )
 begin
	if(~nRst) begin
	     TimingCnt = 7'b0;  //计数值归零
	end
	else if(TimingEn) begin
		if(PulseClk)
			TimingCnt = TimingCnt+1'b1;  //计数
		else
			TimingCnt = TimingCnt;  //保持计数值
	end
	else begin
		TimingCnt = 7'b0;  //计数值归零
	end
 end
 
 
 
 
 /*				ds18b20复位定义类型				*/
 reg DsRstEn;  //ds18b20复位使能
 /*				ds18b20写数据定义类型				*/
 reg WireEn;  //ds18b20写数据使能
 reg [3:0] wSftCnt;  // 写bit次数  
 reg [7:0] WireCmd;  //写指令
 reg [7:0] WireBus;  //写数据
 /*				ds18b20读数据定义类型				*/
 reg ReadEn;  //ds18b20读数据使能
 reg [3:0] rSftCnt;  // 写bit次数  
 reg [7:0] ReadData;  //读数据
 /*				ds18b20指令功能定义类型				*/
 reg [3:0] CmdCnt;  //指令计数
 reg [7:0] DataH;
 reg [7:0] DataL;
 wire [15:0] Data={DataH,DataL};  //输出数据
 reg UpDate;  //输出更新标志 
 
/*				ds18b20状态机				*/
 reg [3:0] nextstate;
 always@(posedge Clk )
 begin
 	if(~nRst) begin
		wSftCnt <= 4'b0000;  //上电后，ds18b20写数据移位计数置零
		rSftCnt <= 4'b0000;  //上电后，ds18b20读数据移位计数置零
		DsRstEn <= 1'b0;  //上电后，ds18b20复位使能标志置零
		WireEn <= 1'b0;  //上电后，ds18b20写使能标志置零
		ReadEn <= 1'b0;  //上电后，ds18b20读使能标志置零
		WireCmd <= 8'b0;  //上电后，ds18b20写指令标志置零
		CmdCnt <= 4'b0;;  //指令计数置零
		UpDate <= 1'b0;  //输出数据更新标志置零
		DqDir <= 1'b0;  //设置为输入
		nextstate <= `CMDIDLE;  //状态空闲
	end
	else begin 
		case(nextstate)
 /*				ds18b20功能设置				*/
			`CMDIDLE: begin  
				if(En == 1'b1) begin //使能18b20
					DsRstEn <= 1'b1;  //使能复位功能
					UpDate <= 1'b0;  //输出数据更新标志置零
					nextstate <= `RSTIDLE;  //启动复位时序
				end
				else begin
					DsRstEn <= 1'b0;  //禁能复位功能
					CmdCnt <= 1'b0;  //指令计数清零
					UpDate <= 1'b0;  //输出数据更新标志置零
					DqDir <= 1'b0;  //设置为输入
					nextstate <= `CMDIDLE;  //其它未知情况跳转至起始位置
				end
			end
			`CMDFUN: begin
				CmdCnt <= CmdCnt + 1'b1;  //计数
				case(CmdCnt)
					4'b0000: begin
						nextstate <= `WIREIDLE;  //启动写数据
						WireEn <= 1'b1;  //使能写数据
						WireCmd <= 8'hcc;  //发送0xcc
					end
					4'b0001: begin
						nextstate <= `WIREIDLE;  //启动写数据
						WireEn <= 1'b1;  //使能写数据
						WireCmd <= 8'h44;  //发送0x44
					end
					4'b0010: begin
						nextstate <= `CMDDELY;  //指令等待
					end
					4'b0011: begin
						DsRstEn <= 1'b1;  //使能复位功能
						nextstate <= `RSTIDLE;  //启动复位时序
					end
					4'b0100: begin
						nextstate <= `WIREIDLE;  //启动写数据
						WireEn <= 1'b1;  //使能写数据
						WireCmd <= 8'hcc;  //发送0xcc
					end
					4'b0101: begin
						nextstate <= `WIREIDLE;  //启动写数据
						WireEn <= 1'b1;  //使能写数据
						WireCmd <= 8'hbe;  //发送0xbe
					end
					4'b0110: begin
						nextstate <= `READIDLE;  //启动读数据低位
						ReadEn <= 1'b1;  //使能读数据
					end
					4'b0111: begin
						DataL <= ReadData;  //保存低位数据
						nextstate <= `READIDLE;  //启动读数据低位
						ReadEn <= 1'b1;  //使能读数据
					end	
					4'b1000: begin
						DataH <= ReadData;  //保存高位数据
						UpDate <= 1'b1;   //输出数据更新标志置位
						nextstate <= `CMDIDLE;  //状态空闲
					end
					default: nextstate <= `CMDIDLE;  //其它未知情况跳转至起始位置 
				endcase
				
			end
 /*				ds18b20指令延时				*/
			`CMDDELY: begin
				TimingEn <= 1'b1;  //使能时序
				if(TimingCnt == RstPulse) begin
					TimingEn <= 1'b0;  //禁能时序
					nextstate <= `CMDFUN;  //发送功能指令
				end
				else begin
					nextstate <= `CMDDELY;  //继续等待执行
				end
			end
			
			
			
			
			
			
 /*				ds18b20复位时序				*/
			`RSTIDLE: begin
				if(DsRstEn) begin
					DqDir <= 1'b1;  //设置为输出
					DqOut <= 1'b0;  //拉低数据线
					TimingEn <= 1'b1;  //使能时序
					nextstate <= `RSTPUL;  //启动复位时序
				end
				else begin
					nextstate <= `RSTIDLE;  //继续等待执行
				end
			end
			`RSTPUL: begin
				if(TimingCnt == RstPulse) begin
					DqDir <= 1'b0;  //设置为输入
					DqOut <= 1'b1;  //拉高数据线
					TimingEn <= 1'b0;  //禁能时序
					nextstate <= `RSTWAIT;  //主机拉高总线，等待从机应答
				end
				else begin
					nextstate <= `RSTPUL;  //继续等待执行
				end
			end
			`RSTWAIT: begin
				TimingEn <= 1'b1;  //使能时序
				if(!DQ) begin
					nextstate <= `RSTPRE;  //复位成功状态
				end
				else if(TimingCnt == RstPulse) begin
					TimingEn <= 1'b0;  //禁能时序
					nextstate <= `RSTIDLE;  //返回空闲状态
				end
			end
			`RSTPRE: begin
				if(TimingCnt == RstPulse) begin
					DsRstEn <= 1'b0;  //禁能复位功能
					TimingEn <= 1'b0;  //禁能时序
					DqDir <= 1'b0;  //设置为输入
					DqOut <= 1'b1;  //拉高数据线
					nextstate <= `CMDFUN;  //发送功能指令
				end
			end
			
			
			
 /*				ds18b20写时序				*/
			`WIREIDLE: begin 
				if(WireEn) begin
					DqDir <= 1'b1;  //设置为输出
					DqOut <= 1'b0;  //拉低数据线
					TimingEn <= 1'b1;  //使能时序
					WireBus <= WireCmd;   //写指令传输
					nextstate <= `WIREPUL;  //启动写时序
				end
				else begin
					WireBus <= 8'b0000_0000;  //数据清空
					nextstate <= `WIREIDLE;  //状态空闲
				end
			end
			`WIREPUL: begin
				TimingEn <= 1'b1;  //使能时序
				if(PulseClk) begin  //等待5us
					TimingEn <= 1'b0;  //禁能时序
					nextstate <= `WIREBIT;  //写bit
				end
				else begin
					nextstate <= `WIREPUL;  //继续等待执行
				end
			end
			`WIREBIT: begin
				TimingEn <= 1'b1;  //使能时序
				DqOut <= WireBus[0];  //写一位
				if(TimingCnt == Samples) begin 
					TimingEn <= 1'b0;  //禁能时序
					DqOut <= 1'b1;  //拉高数据线
					nextstate <= `WIRESFT;  //数据移位
				end
				else begin
					nextstate <= `WIREBIT;  //继续等待执行
				end
			end
			`WIRESFT: begin
				TimingEn <= 1'b1;  //使能时序
				if(PulseClk) begin  //间隔为5us
					DqDir <= 1'b1;  //设置为输出
					DqOut <= 1'b0;  //拉低数据线
					TimingEn <= 1'b0;  //禁能时序
					WireBus <= WireBus >> 1'b1;  //移位
					wSftCnt <= wSftCnt + 1'b1;  //记录次数
					if(wSftCnt == 4'b0111) begin
						wSftCnt <= 4'b0000;  //次数置零
						DqDir <= 1'b0;  //设置为输入
						DqOut <= 1'b1;  //拉高数据线
						nextstate <= `CMDFUN;  //发送功能指令
					end
					else begin
						nextstate <= `WIREPUL;  //启动写时序
					end
				end
				else begin
					nextstate <= `WIRESFT;  //继续等待执行
				end
			end
			
			
			
			
			
 /*				ds18b20读时序				*/
			`READIDLE: begin 
				if(ReadEn) begin
					DqDir <= 1'b1;  //设置为输出
					DqOut <= 1'b0;  //拉低数据线
					TimingEn <= 1'b1;  //使能时序
					nextstate <= `READPUL;  //启动写时序
				end
				else begin
					ReadData <= 8'b0000_0000;  //数据清空 
					nextstate <= `READIDLE;  //状态空闲
				end
			end
			`READPUL: begin
				TimingEn <= 1'b1;  //使能时序
				if(PulseClk) begin  //等待5us
					TimingEn <= 1'b0;  //禁能时序
					DqDir <= 1'b0;  //设置为输入
					DqOut <= 1'b1;  //拉高数据线
					nextstate <= `READBIT;  //读bit
				end
				else begin
					nextstate <= `READPUL;  //继续等待执行
				end
			end
			`READBIT: begin
				TimingEn <= 1'b1;  //使能时序
				if(PulseClk) begin  //等待5us
					TimingEn <= 1'b0;  //禁能时序
					ReadData[7] <= DQ;  //读一位
					nextstate <= `READSFT;  //数据移位
				end
				else begin
					nextstate <= `READBIT;  //继续等待执行
				end
			end
			`READSFT: begin
				TimingEn <= 1'b1;  //使能时序
				if(TimingCnt == Samples) begin  //间隔为80us
					TimingEn <= 1'b0;  //使能时序
					DqDir <= 1'b1;  //设置为输出
					DqOut <= 1'b0;  //拉低数据线
					rSftCnt <= rSftCnt + 1'b1;  //记录次数
					if(rSftCnt == 4'b0111) begin
						rSftCnt <= 4'b0000;  //次数置零
						DqDir <= 1'b0;  //设置为输入
						DqOut <= 1'b1;  //拉高数据线
						nextstate <= `CMDFUN;  //发送功能指令
					end
					else begin
						ReadData <= ReadData >> 1'b1;  //移位
						nextstate <= `READPUL;  //启动写时序
					end
				end
				else begin
					nextstate <= `READSFT;  //继续等待执行
				end
			end
			default: nextstate <= `CMDIDLE;  //其它未知情况跳转至起始位置
		endcase
	end
 end
 endmodule
 