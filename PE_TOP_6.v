//`include "PE_6.v"
`include "log2.vh"
module PE_TOP_6#(
  parameter integer  MAC_DIM                      = 6,
  parameter integer  FEAT_WIDTH                   = 1, // input fetaure bit width
  parameter integer  WGT_WIDTH                    = 8, // input weight bit width
  parameter integer  PE_OUT_WIDTH                 = 8,
  parameter integer  SPAD_WIDTH                   = 64, // fetaure and weight spad width
  parameter integer  NZ_WIDTH                     = 16, //4, // non zero register width
  parameter integer  NUM_NODES                    = 20, // for example cora dataset the number of vertices is 2733, thus we require 12 bits to index/tag the partial result for a node. This is used for assiging tag bits to the partial result, i.e., tag_ou
  parameter integer  ADDR_WIDTH                   = `C_LOG_2(SPAD_WIDTH),
  parameter integer  WGT_INDEX                    = `C_LOG_2(WGT_WIDTH)
)(
//update the bitwidth and input ,output
input clk,
input reset,
input [ADDR_WIDTH*MAC_DIM-1:0] addr_bus,// for the non zero add
input [FEAT_WIDTH*SPAD_WIDTH-1:0] data_bus, // for fetaure and the weigth
input [2:0]non_zero_num,
input acc,done,
input w_we,x_we,
//input [WGT_INDEX-1:0]w_index,
//output data_rd,
output [PE_OUT_WIDTH-1:0] out,
output out_vd
);
reg acc_buffer,done_buffer;
reg[WGT_WIDTH-1:0] w_buffer[0:SPAD_WIDTH-1];
wire [WGT_WIDTH*SPAD_WIDTH-1:0] w_buffer_1d;
reg[FEAT_WIDTH*SPAD_WIDTH-1:0] x_buffer;
reg[ADDR_WIDTH*MAC_DIM-1:0] addr_buffer;
reg[2:0] num_buffer;
wire[WGT_INDEX-1:0]w_index;

assign w_index=addr_bus[WGT_INDEX-1:0];
 
genvar i;
generate
    for(i=0;i<WGT_WIDTH;i=i+1)begin
        always @ (posedge clk) begin
            /*if (reset)begin
                w_buffer[8*i]<=0;
                w_buffer[8*i+1]<=0;
                w_buffer[8*i+2]<=0;
                w_buffer[8*i+3]<=0;
                w_buffer[8*i+4]<=0;
                w_buffer[8*i+5]<=0;
                w_buffer[8*i+6]<=0;
                w_buffer[8*i+7]<=0;
            end else*/
             if (w_we)begin
                w_buffer[w_index*WGT_WIDTH+i]<=data_bus[WGT_WIDTH*i+WGT_WIDTH-1:WGT_WIDTH*i];
            end
        end
    end
endgenerate


always @ (posedge clk) begin
    if ((~reset) & x_we) begin
        x_buffer<=data_bus;
        addr_buffer<=addr_bus;
        num_buffer<=non_zero_num;
        acc_buffer<=acc;
        done_buffer<=done;
    end
end

/*
// x_buffer
reg[7:0]x;
always @posedge(clk) begin
    if (rst)begin
        x<=0;
    end else if (~w_we) begin
        x<= data_bus  ;
    end
end
*/
//w buffer 2d to 1d
generate
    for(i=0;i<SPAD_WIDTH;i=i+1)begin
        assign w_buffer_1d[WGT_WIDTH*i+WGT_WIDTH-1:WGT_WIDTH*i]=w_buffer[i];
    end
endgenerate
//use w_buffer and x to connect to PE compute
PE_6 #(
	.FEAT_WIDTH   (FEAT_WIDTH),                  
    .WGT_WIDTH    (WGT_WIDTH),               
    .PE_OUT_WIDTH (PE_OUT_WIDTH),              
    .SPAD_WIDTH   (SPAD_WIDTH),              
    .NZ_WIDTH     (NZ_WIDTH),              
    .NUM_NODES    (NUM_NODES)
)PE_6_inst(
	.clk(clk),
	.reset(reset),
	.non_zero_add_in(addr_buffer),
	.feature_in(x_buffer),
    .weight_in(w_buffer_1d),
    //.weight_in(w_buffer[7]),
    .non_zero_num (num_buffer),
    .acc (acc_buffer),
    .done(done_buffer),

    .sum_out (out), // need to fix this; this is the port which goes to the merge pe input to eventually to the output
    .sum_vd(out_vd)
);  


endmodule
