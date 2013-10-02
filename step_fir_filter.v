

module step_fir_filter
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
//8阶滤波器系数，共9个系数，系数对称
//==============================================================
  wire [12:0] coeff1 = 13'd5725;
  wire [12:0] coeff2 = 13'd5864;
  wire [12:0] coeff3 = 13'd5972;
  wire [12:0] coeff4 = 13'd6051;
  wire [12:0] coeff5 = 13'd6098;
  wire [12:0] coeff6 = 13'd6114;
			
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
					 delay_pipeline10 <= 16'b0 ;
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

always@(posedge pClk ) 
       if(!pRst)
		   begin
           add_data1 <= 17'b0 ;
		   add_data2 <= 17'b0 ;
		   add_data3 <= 17'b0 ;
		   add_data4 <= 17'b0 ;
		   add_data5 <= 17'b0 ;
		   add_data5 <= 17'b0 ;
		   end
       else
	       begin
           add_data1 <= {pFilterIn[15],pFilterIn} + {delay_pipeline10[15],delay_pipeline10} ;     //x(0)+x(10)
		   add_data2 <= {delay_pipeline1[15],delay_pipeline1} + {delay_pipeline9[15],delay_pipeline9} ;//x(1)+x(9)
		   add_data3 <= {delay_pipeline2[15],delay_pipeline2} + {delay_pipeline8[15],delay_pipeline8} ;//x(2)+x(8)
		   add_data4 <= {delay_pipeline3[15],delay_pipeline3} + {delay_pipeline7[15],delay_pipeline7} ;//x(3)+x(7)
		   add_data5 <= {delay_pipeline4[15],delay_pipeline4} + {delay_pipeline6[15],delay_pipeline6} ;//x(4)+x(6)
		   add_data6 <= {delay_pipeline5[15],delay_pipeline5} ;//x(5)
		   end
  
 
//===================================================================
//乘法器
//====================================================================
reg [29:0] multi_data1 ;
reg [29:0] multi_data2 ;
reg [29:0] multi_data3 ;
reg [29:0] multi_data4 ;
reg [29:0] multi_data5 ;
reg [29:0] multi_data6 ;
always@(posedge pClk) 
       if(!pRst)      
           begin                             
           multi_data1 <= 30'b0 ;
		   multi_data2 <= 30'b0 ;
		   multi_data3 <= 30'b0 ;
		   multi_data4 <= 30'b0 ;
		   multi_data5 <= 30'b0 ;
		   multi_data6 <= 30'b0 ;
		   end
       else
	       begin
           multi_data1 <= {{13{add_data1[16]}},add_data1}*coeff1 ;//（x(0)+x(10)）*h(0)
		   multi_data2 <= {{13{add_data2[16]}},add_data2}*coeff2 ;//（x(1)+x(9)）*h(1)
		   multi_data3 <= {{13{add_data3[16]}},add_data3}*coeff3 ;//（x(2)+x(8)）*h(2)
		   multi_data4 <= {{13{add_data4[16]}},add_data4}*coeff4 ;//（x(3)+x(7)）*h(3)
		   multi_data5 <= {{13{add_data5[16]}},add_data5}*coeff5 ;//（x(4)+x(6)）*h(4)
		   multi_data6 <= {{13{add_data6[16]}},add_data6}*coeff6 ;//（x(5)）*h(5)
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
           multi_add <= {{2{multi_data1[29]}},multi_data1}+{{2{multi_data2[29]}},multi_data2}
		                +{{2{multi_data3[29]}},multi_data3}+{{2{multi_data4[29]}},multi_data4}
						+{{2{multi_data5[29]}},multi_data5}+{{2{multi_data6[29]}},multi_data6};
		   //（x(4)+x(6)）*h(4)+x(5)*h(5)
		   end
		   
		   
assign pFilterOut = multi_add>>16;

endmodule
