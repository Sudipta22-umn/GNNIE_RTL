module MAC_5 # (
  parameter integer  FEAT_WIDTH                   = 8,
  parameter integer  WGT_WIDTH                    = 8,
  parameter integer  PE_OUT_WIDTH               = 16
 
)(
// inputs
  input                                  clk,acc,
  //input                                  enable, 
  input   [FEAT_WIDTH-1:0]              _a0,_a1,_a2,_a3,_a4,
  input   [WGT_WIDTH-1:0]               _b0,_b1,_b2,_b3,_b4,
  input   [FEAT_WIDTH-1:0]              _c1, // if there is any overflow from previous addition

//outputs
  output  reg   [PE_OUT_WIDTH-1:0]       sum_out
  
);


always @ (posedge clk)
	begin
        if (acc)begin
	        sum_out <= _a0*_b0+_a1*_b1+_a2*_b2+_a3*_b3+_a4*_b4+sum_out;
		end else begin
            sum_out <= _a0*_b0+_a1*_b1+_a2*_b2+_a3*_b3+_a4*_b4;
        end
	end

endmodule

