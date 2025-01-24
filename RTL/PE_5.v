// instatiate MAcC unit here
//`include "MAC_5.v"
`include "log2.vh"
module PE_5 #(
  parameter integer  MAC_DIM                      = 5,
  parameter integer  FEAT_WIDTH                   = 8, // input fetaure bit width
  parameter integer  WGT_WIDTH                    = 8, // input weight bit width
  parameter integer  PE_OUT_WIDTH                 = 16,
  parameter integer  SPAD_WIDTH                   = 64, // fetaure and weight spad width
  parameter integer  NZ_WIDTH                     = 16, //4, // non zero register width
  parameter integer  NUM_NODES                    = 20, // for example cora dataset the number of vertices is 2733, thus we require 12 bits to index/tag the partial result for a node. This is used for assiging tag bits to the partial result, i.e., tag_ou 
  parameter integer  ADDR_WIDTH                   = `C_LOG_2(64)

)(
  //inputs
  input             clk,
  input             reset,
  input             [ADDR_WIDTH*MAC_DIM-1:0]non_zero_add_in,
  input             [FEAT_WIDTH*SPAD_WIDTH-1:0]feature_in ,//fetaure in the feature spad from the feature bus
  input             [WGT_WIDTH*SPAD_WIDTH-1:0] weight_in,//weight in the weight spad from the weight bus
  input             [2:0]non_zero_num,
  input             acc,
  input             done,
  //outputs
  output     reg    sum_vd,
  output        [PE_OUT_WIDTH-1:0] sum_out // the associated tag is fed from the controller to the merge PEs
         
);
// inte
// internal output registers
wire        [WGT_WIDTH-1:0] weight_out_1,weight_out_2,weight_out_3,weight_out_4,weight_out_0;
wire        [FEAT_WIDTH-1:0] feat_out_1,feat_out_2,feat_out_3,feat_out_4,feat_out_0;
// transformation of 1d input to 2d
wire [FEAT_WIDTH-1:0]feature_2d[0:SPAD_WIDTH-1];
wire [WGT_WIDTH-1:0]weight_2d[0:SPAD_WIDTH-1];
wire [ADDR_WIDTH-1:0]non_zero_add_2d[0:MAC_DIM-1];


genvar i;
generate
for(i=0;i<SPAD_WIDTH;i=i+1)begin
    assign feature_2d[i]=feature_in[(i+1)*FEAT_WIDTH-1:i*FEAT_WIDTH];
    assign weight_2d[i]=weight_in[(i+1)*WGT_WIDTH-1:i*WGT_WIDTH];
end
endgenerate

genvar j;
generate
for(j=0;j<MAC_DIM;j=j+1)begin
	assign non_zero_add_2d[j]=non_zero_add_in[(j+1)*ADDR_WIDTH-1:j*ADDR_WIDTH];
end
endgenerate

assign feat_out_0 = feature_2d[non_zero_add_2d[0]];
assign weight_out_0 = weight_2d[non_zero_add_2d[0]];

assign feat_out_1 = non_zero_num>=3'b001 ? feature_2d[non_zero_add_2d[1]]:0;
assign weight_out_1 = non_zero_num>=3'b001 ? weight_2d[non_zero_add_2d[1]]:0;

assign feat_out_2 = non_zero_num>=3'b010 ? feature_2d[non_zero_add_2d[2]]:0;
assign weight_out_2 = non_zero_num>=3'b010 ? weight_2d[non_zero_add_2d[2]]:0;

assign feat_out_3 = non_zero_num>=3'b011 ? feature_2d[non_zero_add_2d[3]]:0;
assign weight_out_3 = non_zero_num>=3'b011 ? weight_2d[non_zero_add_2d[3]]:0;

assign feat_out_4 = non_zero_num==3'b100 ? feature_2d[non_zero_add_2d[4]]:0;
assign weight_out_4 = non_zero_num==3'b100 ? weight_2d[non_zero_add_2d[4]]:0;


//reg sum_ready;
always @ (posedge clk) begin
    if (reset)begin
        sum_vd<=0;
    end else begin
        sum_vd<=done;
    end
end
// add the MAC unit code here//
MAC_5 #(
	 .FEAT_WIDTH (FEAT_WIDTH),                  
	 .WGT_WIDTH (WGT_WIDTH),                   
	 .PE_OUT_WIDTH (PE_OUT_WIDTH)
	 
	) multiplier_inst(
	.clk (clk),
    .acc(acc),

	._a0 (feat_out_0),
	._b0 (weight_out_0),

	._a1 (feat_out_1),
	._b1 (weight_out_1),

   ._a2 (feat_out_2),
	._b2 (weight_out_2),

	._a3 (feat_out_3),
	._b3 (weight_out_3),

   ._a4 (feat_out_4),
	._b4 (weight_out_4),

   ._c1 (),
        //.enable (enable_mac_1),
   .sum_out(sum_out)
	); 

endmodule
          



          
  

