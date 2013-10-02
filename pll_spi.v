`include "headdefine.v"

module pll_spi(clk_5M,
			SYS_START,
			pll_clk_5M,
			pll_din,
			pll_LE);

input clk_5M; //10MHZ
input SYS_START;
output pll_clk_5M,pll_LE,pll_din;
//reg [23:0] pll_data_R,pll_data_N,pll_data_C;	//the three registers of the ADF4360-9
//reg [6:0] num;									//a counter used for setting the waiting time  
reg [19:0] cnt;                					//a counter used for sending the datas of the three registers
reg [4:0] pbit;									//used for scanning and reading every bit of the three registers
//reg pll_clk_5M,
reg pll_LE;
reg pll_din;
reg pll_start;

parameter 
WAIT=7'd10,
WIDTH=5'd23,
INTERVAL1=20'd160000,
INTERVAL2=20'd160024;  //INTERVAL1+24

//======================================
//for 8MHz
//======================================
`ifdef In8M
parameter
pll_data_R1=24'h300021,    //R   
pll_data_C1=24'h4fd9c4,    //Control Latch 
pll_data_N1=24'h013836;    //N=B A
`endif


//======================================
//for 800kHz
//======================================
`ifdef In800k
parameter
pll_data_R1=24'h300005,    //R   
pll_data_C1=24'h4fd9c4,    //Control Latch 
pll_data_N1=24'h018636;//24'h019036;//24'h018636;    //N=B A
`endif


//======================================
//for 1.6MHz
//======================================
`ifdef In1M6
parameter
pll_data_R1=24'h300007,    //R   
pll_data_C1=24'h4fd9c4,    //Control Latch 
pll_data_N1=24'h013836;    //24'h01389e;    //N=B A
`endif


//======================================
//for 2.4MHz
//======================================
`ifdef In2M4
parameter
pll_data_R1=24'h30000a,    //R   
pll_data_C1=24'h4fd9c4,    //Control Latch 
pll_data_N1=24'h013836;    //24'h01389e;    //N=B A
`endif



//======================================
//for 3.2MHz
//======================================
`ifdef In3M2
parameter
pll_data_R1=24'h30000d,    //R   
pll_data_C1=24'h4fd9c4,    //Control Latch 
pll_data_N1=24'h013836;    //24'h01389e;    //N=B A
`endif


//======================================
//for 4M
//======================================
`ifdef In4M
parameter
pll_data_R1=24'h300011,    //R   
pll_data_C1=24'h4fd9c4,    //Control Latch 
pll_data_N1=24'h013836;    //24'h01389e;    //N=B A
`endif



//======================================
//for 7.2MHz
//======================================
`ifdef In7M2
parameter
pll_data_R1=24'h30001d,    //R   
pll_data_C1=24'h4fd9c4,    //Control Latch 
pll_data_N1=24'h013836;    //24'h01389e;    //N=B A
`endif






assign pll_clk_5M = (clk_5M&(~pll_LE)&(pll_start));

initial 
begin
	pll_LE <= 1'b1;
	cnt <= 20'b0;
	pbit <= WIDTH;
	pll_din <= 1'b0;
	pll_start <= 1'b0; 
end
always @(negedge clk_5M)																																									
begin
	if(!SYS_START)
	begin
		pll_start <= 1'b1;
	end
	else
	begin
		if((cnt==24)||(cnt==54)||(cnt==INTERVAL2))
			pll_start <= 1'b0;
		else if((cnt>=60)&&(cnt<INTERVAL1))
			pll_start <= 1'b0;
		else 
			pll_start <= 1'b1;
	end
end

always @(negedge clk_5M)																																									
begin
	if(!SYS_START)
	begin							//initialize datas
		pll_LE<=1'b1;
		cnt<=20'b0;
		pbit<=WIDTH;
		pll_din <= 1'b0; 
	end
	else
	begin
		if(cnt<24)					//send the datas of R counter latch
		begin
			cnt<=cnt+1'b1;
			pll_LE<=1'b0;
			pbit<=pbit-1'b1;
			pll_din<=pll_data_R1[pbit];
		end
		else if(cnt<30)				//insert a clk_5M cycle,stop the sending of the R counter latch
		begin
			cnt <= cnt+1'b1;
			pll_LE <= 1'b1;
			pbit <= WIDTH;
		end
		else if(cnt<54)//send the datas of control latch
		begin
			cnt <= cnt+1'b1;
			pll_LE <= 1'b0;
			pbit <= pbit-1'b1;
			pll_din <= pll_data_C1[pbit];
		end
		else if(cnt<60)
		begin
			cnt <= cnt+1'b1;
			pll_LE <= 1'b1;
			pbit <= WIDTH;
		end
		else if(cnt<INTERVAL1)	//interval:Cn=10uf--15ms;Cn=440nf--600us
		begin
			pbit<=WIDTH;
			cnt<=cnt+1'b1;
			pll_LE<=1'b0;
		end
		else if(cnt<INTERVAL2)      //send the datas of N counter latch
		begin
			cnt <= cnt+1'b1;
			pll_LE <= 1'b0;
			pbit <= pbit-1'b1;
			pll_din <= pll_data_N1[pbit];
		end
		else
		begin
			pll_LE <= 1'b1;
		end
	end
end

endmodule
