//`timescale 1ns/1ps
//`include "MERGE_PE_COMB.v"
//

module MERGE_PE_TOP#(
  parameter integer  PSUM_WIDTH                   = 8, // input psum bit width
  parameter integer  TAG_WIDTH                    = 18, // input tag bit width for 2^10 number of nodes 
  parameter integer  PSUM_SPAD_WIDTH              = 16 // number of psum and tags = 16 
)(
  //inputs
  input             clk,
  input             rst,
  input             [PSUM_WIDTH*PSUM_SPAD_WIDTH-1:0] psum_in,
  input             [PSUM_SPAD_WIDTH-1:0]psum_vd,

  input             [TAG_WIDTH*PSUM_SPAD_WIDTH-1:0] tag_in ,//fetaure in the feature spad from the feature bus
  input             tag_vd,

  input           out_rd,
  output reg      [PSUM_WIDTH*PSUM_SPAD_WIDTH-1:0] psum_out_r,
  //output reg      tag_rec_rd,
  output reg      psum_tag_rd,
  output reg      out_vd
  //output reg       [TAG_WIDTH*PSUM_SPAD_WIDTH-1:0]  tag_out_r
);

reg      [PSUM_WIDTH*PSUM_SPAD_WIDTH-1:0] psum_in_r;
reg      [TAG_WIDTH*PSUM_SPAD_WIDTH-1:0] tag_in_r;//fetaure in the feature spad from the feature bus
wire     [PSUM_WIDTH*PSUM_SPAD_WIDTH-1:0] psum_out;
reg [1:0]state;
localparam  IDLE = 2'd0;
localparam  WAIT_RD = 2'd1;
localparam  WAIT_VD = 2'd2;
localparam  TRANS = 2'd3;
always @(posedge clk or posedge rst)begin
  if (rst)begin
      state<=IDLE;
      psum_in_r<=0;
      tag_in_r<=0;
      psum_out_r<=0;
  end else if (state==IDLE)begin
      if(out_rd)
        state<=WAIT_RD;
      else
        state<=IDLE;
  end else if (state==WAIT_RD)begin
      state<=WAIT_VD;
      //tag_rec_rd<=1;
      psum_tag_rd<=1;
  end else if (state==WAIT_VD)begin
      if(tag_vd==1'b1 &(psum_vd=={PSUM_WIDTH{1'b1}}))begin
        state<=TRANS;
        psum_in_r<=psum_in;
        tag_in_r<=tag_in;
        psum_out_r<=psum_out;
      end else begin
        state<=WAIT_VD;
      end
  end else if (state==TRANS) begin
      state<=IDLE;
      out_vd<=1;
  end 
end






  //wire       [TAG_WIDTH*PSUM_SPAD_WIDTH-1:0]  tag_out;

MERGE_PE_COMB #(
      .PSUM_WIDTH(PSUM_WIDTH),                 
      .TAG_WIDTH(TAG_WIDTH),             
      .PSUM_SPAD_WIDTH(PSUM_SPAD_WIDTH)   
)MERGE_PE_dut(
 .psum_in(psum_in_r),
 .tag_in(tag_in_r),

 .psum_out(psum_out)
 //.tag_out(tag_out)
);


endmodule
