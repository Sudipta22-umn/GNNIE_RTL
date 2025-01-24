//`include "PE_TOP_4.v"
//`include "PE_TOP_5.v"
//`include "PE_TOP_6.v"
`timescale 1ns/1ps
`include "log2.vh"
module PE_ROW_6 #(
  parameter integer  MAC_DIM                      = 6,
  parameter integer  FEAT_WIDTH                   = 8, // input fetaure bit width
  parameter integer  WGT_WIDTH                    = 8, // input weight bit width
  parameter integer  PE_OUT_WIDTH                 = 8, // output width for the sum
  parameter integer  SPAD_WIDTH                  = 64, // fetaure and weight spad width; max lenght of the k-subvector that can be assigned to a PE
  parameter integer  PE_DIM                       = 16, // PE array row/column dimension
  parameter integer  NZ_WIDTH                     = 16, // the maximum number of non-zeros 
  parameter integer  NUM_NODES                    = 20, // for example cora dataset the number of vertices is 2733, thus we require 12 bits to index/tag the partial result for a node. This is used for assiging tag bits to the partial result, i.e., tag_out
  parameter integer  LOG_PE_DIM                   =`C_LOG_2(PE_DIM),
  parameter integer  ADDR_WIDTH                   = `C_LOG_2(SPAD_WIDTH),
  parameter integer  WGT_INDEX                    = `C_LOG_2(WGT_WIDTH)
) (
    //inputs
    input             clk,
    input             reset,
    //input             start,
    input             [ADDR_WIDTH*MAC_DIM-1:0]non_zero_add_bus, // required for each of 16 subvectors fed to each PE in arow
    //input             [FEAT_WIDTH*SPAD_WIDTH*PE_DIM-1:0]data_bus,//fetaure in the feature spad from the feature bus // Feature vector dimension = 8*64*16 bits = fetaure length = 1024 (each @1B)
    input             [FEAT_WIDTH*SPAD_WIDTH-1:0]data_bus,
    //input             [WGT_WIDTH*SPAD_WIDTH*PE_DIM-1:0] weight_bus,//weight in the weight spad from the weight bus
    input             [2:0] non_zero_num, // fixed/variable?
    //input             [3:0] enable_top, // one enable pin for each PE in the row
    input             [LOG_PE_DIM-1:0] weight_enable_top,// one weight/feature select pin for each PE in the row
    //input             [WGT_INDEX-1:0] w_index,
    input             broad_cast_enable,
    input             acc,done,
    input             psum_rd,
    //outputs
    //output reg        [PE_OUT_WIDTH*PE_DIM-1:0] sum_out_bus, //at a time there can be 16 partial sums sent form the 16 merge PE to the output buffer
    //output         [PE_OUT_WIDTH*PE_DIM-1:0] tag_out_bus, //one tag assigned for each of the partial sums     
    output        [PE_OUT_WIDTH*PE_DIM-1:0] sum_out_bus,
    output        [PE_DIM-1:0] out_vd,
    output        data_bus_rd
);

assign data_bus_rd=psum_rd;
// transformation of 3d to 2d
// wire [FEAT_WIDTH*SPAD_WIDTH-1:0] feature_3d  [0:PE_DIM-1];
// wire [WGT_WIDTH*SPAD_WIDTH-1:0]  weight_3d   [0:PE_DIM-1];
// wire [FEAT_WIDTH*NZ_WIDTH-1:0]    non_zero_3d [0:PE_DIM-1];

//control logic

wire [PE_DIM-1:0] weight_enable_converted;
assign weight_enable_converted=1<<weight_enable_top;

wire [PE_DIM-1:0]pe_rd;
genvar i;
generate
  for (i=0;i<PE_DIM;i=i+1)begin : COL
    PE_TOP_6 #(
      .FEAT_WIDTH(FEAT_WIDTH),                  
      .WGT_WIDTH(WGT_WIDTH),             
      .PE_OUT_WIDTH(PE_OUT_WIDTH),              
      .SPAD_WIDTH(SPAD_WIDTH),              
      .NZ_WIDTH(NZ_WIDTH),              
      .NUM_NODES(NUM_NODES)
    )PE_6(
      .clk(clk),
      .reset(reset),
      .addr_bus(non_zero_add_bus), 
      .data_bus(data_bus), // first 16 part goes to the each of the PE in the same column // how to connect the interim data bus //
      //.weight_in(weight_3d[0]), // we take one column of the weight matrix at a time // easy solution to have to 16 of them
      .non_zero_num (non_zero_num),
      .x_we (broad_cast_enable),
      .w_we (weight_enable_converted[i]),
      //.w_index(w_index),
      .acc(acc),
      .done(done),
      //.data_rd(pe_rd[i]),
      .out(sum_out_bus[PE_OUT_WIDTH*i+PE_OUT_WIDTH-1:PE_OUT_WIDTH*i]), // need to fix this; this is the port which goes to the merge pe input to eventually to the output
      .out_vd(out_vd[i])
    );  
end // ends COL
endgenerate

endmodule


 

