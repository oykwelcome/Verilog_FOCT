//20 order fir_filter
module current_filter
               (
                pClk ,
                pRst    ,
                pFilterIn,
                pFilterOut
                );
   input                   pClk  ; 
  input                   pRst     ;
  input [15:0] pFilterIn ; 
  output[15:0] pFilterOut; //滤波输出
//==============================================================
//20阶滤波器系数，共21个系数，系数对称，取11个系数
//==============================================================
  wire [11:0] coeff1 = 12'd2874;
  wire [11:0] coeff2 = 12'd2946;
  wire [11:0] coeff3 = 12'd3011;
  wire [11:0] coeff4 = 12'd3070;
  wire [11:0] coeff5 = 12'd3121;
  wire [11:0] coeff6 = 12'd3165;
  wire [11:0] coeff7 = 12'd3202;
  wire [11:0] coeff8 = 12'd3230;
  wire [11:0] coeff9 = 12'd3251;
  wire [11:0] coeff10 = 12'd3263;
  wire [11:0] coeff11 = 12'd3267;
//===============================================================
//延时链
//===============================================================
reg [15:0] delay_pipeline1 ;
reg [15:0] delay_pipeline2 ;
reg [15:0] delay_pipeline3 ;
reg [15:0] delay_pipeline4 ;
reg [15:0] delay_pipeline5 ;
reg [15:0] delay_pipeline6 ;
reg [15:0] delay_pipeline7 ;
reg [15:0] delay_pipeline8 ;
reg [15:0] delay_pipeline9 ;
reg [15:0] delay_pipeline10;
reg [15:0] delay_pipeline11;
reg [15:0] delay_pipeline12;
reg [15:0] delay_pipeline13;
reg [15:0] delay_pipeline14;
reg [15:0] delay_pipeline15;
reg [15:0] delay_pipeline16;
reg [15:0] delay_pipeline17;
reg [15:0] delay_pipeline18;
reg [15:0] delay_pipeline19;
reg [15:0] delay_pipeline20;

always@(posedge pClk )
       if(!pRst)
                begin
                    delay_pipeline1 <= 16'b0 ;
                     delay_pipeline2 <= 16'b0 ;
                     delay_pipeline3 <= 16'b0 ;
                     delay_pipeline4 <= 16'b0 ;
                     delay_pipeline5 <= 16'b0 ;
                     delay_pipeline6 <= 16'b0 ;
                     delay_pipeline7 <= 16'b0 ;
                     delay_pipeline8 <= 16'b0 ;
					 delay_pipeline9 <= 16'b0 ;
					 delay_pipeline11 <= 16'b0 ;
					 delay_pipeline12 <= 16'b0 ;
					 delay_pipeline13 <= 16'b0 ;
					 delay_pipeline14 <= 16'b0 ;
					 delay_pipeline15 <= 16'b0 ;
					 delay_pipeline16 <= 16'b0 ;
					 delay_pipeline17 <= 16'b0 ;
					 delay_pipeline18 <= 16'b0 ;
					 delay_pipeline19 <= 16'b0 ;
					 delay_pipeline20 <= 16'b0 ;
                end
       else
                begin
                     delay_pipeline1 <= pFilterIn     ;
                     delay_pipeline2 <= delay_pipeline1 ;
                     delay_pipeline3 <= delay_pipeline2 ;
                     delay_pipeline4 <= delay_pipeline3 ;
                     delay_pipeline5 <= delay_pipeline4 ;
                     delay_pipeline6 <= delay_pipeline5 ;
                     delay_pipeline7 <= delay_pipeline6 ;
                     delay_pipeline8 <= delay_pipeline7 ;
					 delay_pipeline9 <= delay_pipeline8 ;
					 delay_pipeline10 <= delay_pipeline9 ;
					 delay_pipeline11 <= delay_pipeline10 ;
					 delay_pipeline12 <= delay_pipeline11 ;
					 delay_pipeline13 <= delay_pipeline12 ;
					 delay_pipeline14 <= delay_pipeline13 ;
					 delay_pipeline15 <= delay_pipeline14 ;
					 delay_pipeline16 <= delay_pipeline15 ;
					 delay_pipeline17 <= delay_pipeline16 ;
					 delay_pipeline18 <= delay_pipeline17 ;
					 delay_pipeline19 <= delay_pipeline18 ;
					 delay_pipeline20 <= delay_pipeline19 ;
					 
                end
     
//================================================================
//加法，对称结构，减少乘法器的数目
//================================================================
reg [16:0] add_data1 ;
reg [16:0] add_data2 ;
reg [16:0] add_data3 ;
reg [16:0] add_data4 ;
reg [16:0] add_data5 ;
reg [16:0] add_data6 ;
reg [16:0] add_data7 ;
reg [16:0] add_data8 ;
reg [16:0] add_data9 ;
reg [16:0] add_data10 ;
reg [16:0] add_data11 ;

always@(posedge pClk ) 
       if(!pRst)
		   begin
           add_data1 <= 16'b0 ;
		   add_data2 <= 16'b0 ;
		   add_data3 <= 16'b0 ;
		   add_data4 <= 16'b0 ;
		   add_data5 <= 16'b0 ;
		   add_data6 <= 16'b0 ;
		   add_data7 <= 16'b0 ;
		   add_data8 <= 16'b0 ;
		   add_data9 <= 16'b0 ;
		   add_data10 <= 16'b0 ;
		   add_data11 <= 16'b0 ;
		   end
       else
	       begin
           add_data1 <= pFilterIn + delay_pipeline20 ;     //x(0)+x(20)
		   add_data2 <= delay_pipeline1 + delay_pipeline19 ;//x(1)+x(19)
		   add_data3 <= delay_pipeline2 + delay_pipeline18 ;//x(2)+x(18)
		   add_data4 <= delay_pipeline3 + delay_pipeline17 ;//x(3)+x(17)
		   add_data5 <= delay_pipeline4 + delay_pipeline16 ;//x(4)+x(16)
		   add_data6 <= delay_pipeline5 + delay_pipeline15 ;//x(5)+x(15)
		   add_data7 <= delay_pipeline6 + delay_pipeline14 ;//x(6)+x(14)
		   add_data8 <= delay_pipeline7 + delay_pipeline13 ;//x(7)+x(13)
		   add_data9 <= delay_pipeline8 + delay_pipeline12 ;//x(8)+x(12)
		   add_data10 <= delay_pipeline9 + delay_pipeline11 ;//x(9)+x(11)
		   add_data11 <= {delay_pipeline10[15],delay_pipeline10} ;//x(10)
		  
		   end
  
 
//===================================================================
//乘法器
//====================================================================
reg [28:0] multi_data1 ;
reg [28:0] multi_data2 ;
reg [28:0] multi_data3 ;
reg [28:0] multi_data4 ;
reg [28:0] multi_data5 ;
reg [28:0] multi_data6 ;
reg [28:0] multi_data7 ;
reg [28:0] multi_data8 ;
reg [28:0] multi_data9 ;
reg [28:0] multi_data10;
reg [28:0] multi_data11;

always@(posedge pClk) 
       if(!pRst)      
           begin                             
           multi_data1 <= 29'b0 ;
		   multi_data2 <= 29'b0 ;
		   multi_data3 <= 29'b0 ;
		   multi_data4 <= 29'b0 ;
		   multi_data5 <= 29'b0 ;
		   multi_data6 <= 29'b0 ;
		   multi_data7 <= 29'b0 ;
		   multi_data8 <= 29'b0 ;
		   multi_data9 <= 29'b0 ;
		   multi_data10 <= 29'b0 ;
		   multi_data11 <= 29'b0 ;
		   end
       else
	       begin
           multi_data1 <= add_data1*coeff1 ;//（x(0)+x(20)）*h(0)
		   multi_data2 <= add_data2*coeff2 ;//（x(1)+x(19)）*h(1)
		   multi_data3 <= add_data3*coeff3 ;//（x(2)+x(18)）*h(2)
		   multi_data4 <= add_data4*coeff4 ;//（x(3)+x(17)）*h(3)
		   multi_data5 <= add_data5*coeff5 ;//（x(4)+x(16)）*h(4)
		   multi_data6 <= add_data6*coeff6 ;//（x(5)+x(15)）*h(5)
		   multi_data7 <= add_data7*coeff7 ;//（x(6)+x(14)）*h(6)
		   multi_data8 <= add_data8*coeff8 ;//（x(7)+x(13)）*h(7)
		   multi_data9 <= add_data9*coeff9 ;//（x(8)+x(12)）*h(8)
		   multi_data10 <= add_data10*coeff10 ;//（x(9)+x(11)）*h(9)
		   multi_data11 <= add_data11*coeff11 ;//  x(10)*h(10)
		   end

//========================================================================
//流水线累加
//========================================================================
reg [31:0] multi_add;
always@(posedge pClk) 
       if(!pRst)          
           begin                         
           multi_add <= 32'd0;
		   end
       else
           begin
           multi_add <= multi_data1+multi_data2+multi_data3+multi_data4+multi_data5+multi_data6 
		               +multi_data7+multi_data8+multi_data9+multi_data10+multi_data11;
		  
		   end
		   
		   
assign pFilterOut = multi_add>>16;

endmodule
