/***********************************************************************************
 **=================================================================================
 ** 						All right reserve 2012-2013(A) 
 ** 						Created &maintain by CoreTechnology
 **
 ** ģ �� ��:   
 ** ��    ��:   
 **             
 **
 ** ԭ �� ��:   
 ** �� �� ��:   
 **
 **=================================================================================
 ***********************************************************************************/
 module DS18B20(Clk,nRst,UpDate,Data,DQ,GND);
 input Clk;  //����ʱ��50MHz
 input nRst;  //���븴λ
 // input En;  // �����¶�ת��
 output UpDate;  //������±�־
 output [15:0] Data;  //������¶�����
 inout DQ;  //���ݹܽ�
 output GND;
 
 
 wire GND = 1'b0;
 /*				����������				*/
 wire En = 1'b1;  //��������

 wire DQ;  //��������
 reg DqDir;  //����ѡ�� 0������ 1�����
 reg DqOut;  //�������
 assign DQ = (DqDir == 1'b0) ?  1'bz : DqOut;  //˫��˿ڣ��ۺ�ʱ��Ҫʹ����̬�ڣ�����ʱ�ɲ���force��䡣
 //�����Ƶ����������ʱ��Ϊ50MHz
 localparam  ClkCnt   = 250,  //1/50 * 250 = 5us 
			RstPulse = 100,  //100 * 5us = 500us
			Samples  = 16;  //16 * 5us = 80us
 
 
 
 //״̬��ʹ�õ�״̬����
`define  RSTIDLE   4'b0000  //��λ����
`define	 RSTPUL    4'b0001  //��λ����
`define  RSTWAIT   4'b0010  //�ȴ��������ͷ�����
`define  RSTPRE    4'b0011  //��������
`define  WIREIDLE  4'b0100  //д���ݿ���
`define  WIREPUL   4'b0101  //д����
`define  WIREBIT   4'b0110  //дλ
`define  WIRESFT   4'b0111  //������λ
`define  READIDLE  4'b1000  //�����ݿ���
`define  READPUL   4'b1001  //������
`define  READBIT   4'b1010  //��λ
`define  READSFT   4'b1011  //������λ
`define  CMDIDLE   4'b1100  //ָ��ȴ�����
`define  CMDFUN    4'b1101  //���ܺ���
`define  CMDDELY   4'b1110  //ָ����ʱ
			




			
			
 /*				5��sʱ�Ӳ���				*/
 reg [7:0] DivCnt;  //ʱ�ӷ�Ƶ����ֵ
 wire PulseClk;
 assign PulseClk = (DivCnt == ClkCnt);
 always@(posedge Clk )
 begin
	if(~nRst) begin
	     DivCnt = 1'b0;  //����ֵ����
	end
	else if(En) begin
		if(PulseClk & TimingEn)  //ռ�ձ� ��=50%
			DivCnt = 8'd0;
	    else 
			DivCnt = DivCnt+1'b1;
	end
	else begin
		DivCnt = 1'b0;  //����ֵ����
	end
 end
 
 
 
 
 
 /*				ds18b20ʱ�����				*/
 reg TimingEn; //ʱ��ʹ�ܱ�־
 reg [6:0] TimingCnt;  //ʱ�����
 always@(posedge Clk )
 begin
	if(~nRst) begin
	     TimingCnt = 7'b0;  //����ֵ����
	end
	else if(TimingEn) begin
		if(PulseClk)
			TimingCnt = TimingCnt+1'b1;  //����
		else
			TimingCnt = TimingCnt;  //���ּ���ֵ
	end
	else begin
		TimingCnt = 7'b0;  //����ֵ����
	end
 end
 
 
 
 
 /*				ds18b20��λ��������				*/
 reg DsRstEn;  //ds18b20��λʹ��
 /*				ds18b20д���ݶ�������				*/
 reg WireEn;  //ds18b20д����ʹ��
 reg [3:0] wSftCnt;  // дbit����  
 reg [7:0] WireCmd;  //дָ��
 reg [7:0] WireBus;  //д����
 /*				ds18b20�����ݶ�������				*/
 reg ReadEn;  //ds18b20������ʹ��
 reg [3:0] rSftCnt;  // дbit����  
 reg [7:0] ReadData;  //������
 /*				ds18b20ָ��ܶ�������				*/
 reg [3:0] CmdCnt;  //ָ�����
 reg [7:0] DataH;
 reg [7:0] DataL;
 wire [15:0] Data={DataH,DataL};  //�������
 reg UpDate;  //������±�־ 
 
/*				ds18b20״̬��				*/
 reg [3:0] nextstate;
 always@(posedge Clk )
 begin
 	if(~nRst) begin
		wSftCnt <= 4'b0000;  //�ϵ��ds18b20д������λ��������
		rSftCnt <= 4'b0000;  //�ϵ��ds18b20��������λ��������
		DsRstEn <= 1'b0;  //�ϵ��ds18b20��λʹ�ܱ�־����
		WireEn <= 1'b0;  //�ϵ��ds18b20дʹ�ܱ�־����
		ReadEn <= 1'b0;  //�ϵ��ds18b20��ʹ�ܱ�־����
		WireCmd <= 8'b0;  //�ϵ��ds18b20дָ���־����
		CmdCnt <= 4'b0;;  //ָ���������
		UpDate <= 1'b0;  //������ݸ��±�־����
		DqDir <= 1'b0;  //����Ϊ����
		nextstate <= `CMDIDLE;  //״̬����
	end
	else begin 
		case(nextstate)
 /*				ds18b20��������				*/
			`CMDIDLE: begin  
				if(En == 1'b1) begin //ʹ��18b20
					DsRstEn <= 1'b1;  //ʹ�ܸ�λ����
					UpDate <= 1'b0;  //������ݸ��±�־����
					nextstate <= `RSTIDLE;  //������λʱ��
				end
				else begin
					DsRstEn <= 1'b0;  //���ܸ�λ����
					CmdCnt <= 1'b0;  //ָ���������
					UpDate <= 1'b0;  //������ݸ��±�־����
					DqDir <= 1'b0;  //����Ϊ����
					nextstate <= `CMDIDLE;  //����δ֪�����ת����ʼλ��
				end
			end
			`CMDFUN: begin
				CmdCnt <= CmdCnt + 1'b1;  //����
				case(CmdCnt)
					4'b0000: begin
						nextstate <= `WIREIDLE;  //����д����
						WireEn <= 1'b1;  //ʹ��д����
						WireCmd <= 8'hcc;  //����0xcc
					end
					4'b0001: begin
						nextstate <= `WIREIDLE;  //����д����
						WireEn <= 1'b1;  //ʹ��д����
						WireCmd <= 8'h44;  //����0x44
					end
					4'b0010: begin
						nextstate <= `CMDDELY;  //ָ��ȴ�
					end
					4'b0011: begin
						DsRstEn <= 1'b1;  //ʹ�ܸ�λ����
						nextstate <= `RSTIDLE;  //������λʱ��
					end
					4'b0100: begin
						nextstate <= `WIREIDLE;  //����д����
						WireEn <= 1'b1;  //ʹ��д����
						WireCmd <= 8'hcc;  //����0xcc
					end
					4'b0101: begin
						nextstate <= `WIREIDLE;  //����д����
						WireEn <= 1'b1;  //ʹ��д����
						WireCmd <= 8'hbe;  //����0xbe
					end
					4'b0110: begin
						nextstate <= `READIDLE;  //���������ݵ�λ
						ReadEn <= 1'b1;  //ʹ�ܶ�����
					end
					4'b0111: begin
						DataL <= ReadData;  //�����λ����
						nextstate <= `READIDLE;  //���������ݵ�λ
						ReadEn <= 1'b1;  //ʹ�ܶ�����
					end	
					4'b1000: begin
						DataH <= ReadData;  //�����λ����
						UpDate <= 1'b1;   //������ݸ��±�־��λ
						nextstate <= `CMDIDLE;  //״̬����
					end
					default: nextstate <= `CMDIDLE;  //����δ֪�����ת����ʼλ�� 
				endcase
				
			end
 /*				ds18b20ָ����ʱ				*/
			`CMDDELY: begin
				TimingEn <= 1'b1;  //ʹ��ʱ��
				if(TimingCnt == RstPulse) begin
					TimingEn <= 1'b0;  //����ʱ��
					nextstate <= `CMDFUN;  //���͹���ָ��
				end
				else begin
					nextstate <= `CMDDELY;  //�����ȴ�ִ��
				end
			end
			
			
			
			
			
			
 /*				ds18b20��λʱ��				*/
			`RSTIDLE: begin
				if(DsRstEn) begin
					DqDir <= 1'b1;  //����Ϊ���
					DqOut <= 1'b0;  //����������
					TimingEn <= 1'b1;  //ʹ��ʱ��
					nextstate <= `RSTPUL;  //������λʱ��
				end
				else begin
					nextstate <= `RSTIDLE;  //�����ȴ�ִ��
				end
			end
			`RSTPUL: begin
				if(TimingCnt == RstPulse) begin
					DqDir <= 1'b0;  //����Ϊ����
					DqOut <= 1'b1;  //����������
					TimingEn <= 1'b0;  //����ʱ��
					nextstate <= `RSTWAIT;  //�����������ߣ��ȴ��ӻ�Ӧ��
				end
				else begin
					nextstate <= `RSTPUL;  //�����ȴ�ִ��
				end
			end
			`RSTWAIT: begin
				TimingEn <= 1'b1;  //ʹ��ʱ��
				if(!DQ) begin
					nextstate <= `RSTPRE;  //��λ�ɹ�״̬
				end
				else if(TimingCnt == RstPulse) begin
					TimingEn <= 1'b0;  //����ʱ��
					nextstate <= `RSTIDLE;  //���ؿ���״̬
				end
			end
			`RSTPRE: begin
				if(TimingCnt == RstPulse) begin
					DsRstEn <= 1'b0;  //���ܸ�λ����
					TimingEn <= 1'b0;  //����ʱ��
					DqDir <= 1'b0;  //����Ϊ����
					DqOut <= 1'b1;  //����������
					nextstate <= `CMDFUN;  //���͹���ָ��
				end
			end
			
			
			
 /*				ds18b20дʱ��				*/
			`WIREIDLE: begin 
				if(WireEn) begin
					DqDir <= 1'b1;  //����Ϊ���
					DqOut <= 1'b0;  //����������
					TimingEn <= 1'b1;  //ʹ��ʱ��
					WireBus <= WireCmd;   //дָ���
					nextstate <= `WIREPUL;  //����дʱ��
				end
				else begin
					WireBus <= 8'b0000_0000;  //�������
					nextstate <= `WIREIDLE;  //״̬����
				end
			end
			`WIREPUL: begin
				TimingEn <= 1'b1;  //ʹ��ʱ��
				if(PulseClk) begin  //�ȴ�5us
					TimingEn <= 1'b0;  //����ʱ��
					nextstate <= `WIREBIT;  //дbit
				end
				else begin
					nextstate <= `WIREPUL;  //�����ȴ�ִ��
				end
			end
			`WIREBIT: begin
				TimingEn <= 1'b1;  //ʹ��ʱ��
				DqOut <= WireBus[0];  //дһλ
				if(TimingCnt == Samples) begin 
					TimingEn <= 1'b0;  //����ʱ��
					DqOut <= 1'b1;  //����������
					nextstate <= `WIRESFT;  //������λ
				end
				else begin
					nextstate <= `WIREBIT;  //�����ȴ�ִ��
				end
			end
			`WIRESFT: begin
				TimingEn <= 1'b1;  //ʹ��ʱ��
				if(PulseClk) begin  //���Ϊ5us
					DqDir <= 1'b1;  //����Ϊ���
					DqOut <= 1'b0;  //����������
					TimingEn <= 1'b0;  //����ʱ��
					WireBus <= WireBus >> 1'b1;  //��λ
					wSftCnt <= wSftCnt + 1'b1;  //��¼����
					if(wSftCnt == 4'b0111) begin
						wSftCnt <= 4'b0000;  //��������
						DqDir <= 1'b0;  //����Ϊ����
						DqOut <= 1'b1;  //����������
						nextstate <= `CMDFUN;  //���͹���ָ��
					end
					else begin
						nextstate <= `WIREPUL;  //����дʱ��
					end
				end
				else begin
					nextstate <= `WIRESFT;  //�����ȴ�ִ��
				end
			end
			
			
			
			
			
 /*				ds18b20��ʱ��				*/
			`READIDLE: begin 
				if(ReadEn) begin
					DqDir <= 1'b1;  //����Ϊ���
					DqOut <= 1'b0;  //����������
					TimingEn <= 1'b1;  //ʹ��ʱ��
					nextstate <= `READPUL;  //����дʱ��
				end
				else begin
					ReadData <= 8'b0000_0000;  //������� 
					nextstate <= `READIDLE;  //״̬����
				end
			end
			`READPUL: begin
				TimingEn <= 1'b1;  //ʹ��ʱ��
				if(PulseClk) begin  //�ȴ�5us
					TimingEn <= 1'b0;  //����ʱ��
					DqDir <= 1'b0;  //����Ϊ����
					DqOut <= 1'b1;  //����������
					nextstate <= `READBIT;  //��bit
				end
				else begin
					nextstate <= `READPUL;  //�����ȴ�ִ��
				end
			end
			`READBIT: begin
				TimingEn <= 1'b1;  //ʹ��ʱ��
				if(PulseClk) begin  //�ȴ�5us
					TimingEn <= 1'b0;  //����ʱ��
					ReadData[7] <= DQ;  //��һλ
					nextstate <= `READSFT;  //������λ
				end
				else begin
					nextstate <= `READBIT;  //�����ȴ�ִ��
				end
			end
			`READSFT: begin
				TimingEn <= 1'b1;  //ʹ��ʱ��
				if(TimingCnt == Samples) begin  //���Ϊ80us
					TimingEn <= 1'b0;  //ʹ��ʱ��
					DqDir <= 1'b1;  //����Ϊ���
					DqOut <= 1'b0;  //����������
					rSftCnt <= rSftCnt + 1'b1;  //��¼����
					if(rSftCnt == 4'b0111) begin
						rSftCnt <= 4'b0000;  //��������
						DqDir <= 1'b0;  //����Ϊ����
						DqOut <= 1'b1;  //����������
						nextstate <= `CMDFUN;  //���͹���ָ��
					end
					else begin
						ReadData <= ReadData >> 1'b1;  //��λ
						nextstate <= `READPUL;  //����дʱ��
					end
				end
				else begin
					nextstate <= `READSFT;  //�����ȴ�ִ��
				end
			end
			default: nextstate <= `CMDIDLE;  //����δ֪�����ת����ʼλ��
		endcase
	end
 end
 endmodule
 