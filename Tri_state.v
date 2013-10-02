module Tri_state(inout SDA,
input SDA_out,
				input ACK_Flag,
				
				output SDA_in);
				
				
assign SDA= (ACK_Flag)?1'bz:SDA_out;
assign SDA_in = (ACK_Flag)?SDA:1'bz;				
endmodule
