//`include "serial_adder.v"

module MERGE_PE_COMB #(
  parameter integer  PSUM_WIDTH                   = 8, // input psum bit width
  parameter integer  TAG_WIDTH                    = 18, // input tag bit width for 2^10 number of nodes 
  parameter integer  PSUM_SPAD_WIDTH              = 16 // number of psum and tags = 16 
) (
  //inputs
  //input             clk,
  //input             reset,
  input             [PSUM_WIDTH*PSUM_SPAD_WIDTH-1:0] psum_in,
  input             [TAG_WIDTH*PSUM_SPAD_WIDTH-1:0] tag_in ,//fetaure in the feature spad from the feature bus
  //input             start,
  //output           done,
  output       [PSUM_WIDTH*PSUM_SPAD_WIDTH-1:0] psum_out
  //output        [TAG_WIDTH*PSUM_SPAD_WIDTH-1:0]  tag_out
);

//2d
wire [PSUM_WIDTH-1:0]psum_in_2d[0:PSUM_SPAD_WIDTH-1];
wire [TAG_WIDTH-1:0]tag_in_2d[0:PSUM_SPAD_WIDTH-1];
wire [PSUM_WIDTH-1:0]psum_out_2d[0:PSUM_SPAD_WIDTH-1];

genvar i,j;
generate
for(i=0;i<PSUM_SPAD_WIDTH;i=i+1)begin
  assign psum_in_2d[i]=psum_in[i*PSUM_WIDTH+PSUM_WIDTH-1:i*PSUM_WIDTH];
  assign tag_in_2d[i]=tag_in[i*TAG_WIDTH+TAG_WIDTH-1:i*TAG_WIDTH];
  assign psum_out[i*PSUM_WIDTH+PSUM_WIDTH-1:i*PSUM_WIDTH]=psum_out_2d[i];
end
endgenerate

//adder block
wire [PSUM_SPAD_WIDTH-1:0]ctr[0:PSUM_SPAD_WIDTH-1];

generate
for(i=0;i<PSUM_SPAD_WIDTH-1;i=i+1)begin:ACC
    for(j=i+1;j<PSUM_SPAD_WIDTH;j=j+1)begin
        assign ctr[i][j]=tag_in_2d[i]==tag_in_2d[j];
    end
    if(i!=PSUM_SPAD_WIDTH-1)begin
    serial_adder#(
        .NUM(PSUM_SPAD_WIDTH-i),
        .bitwidth(PSUM_WIDTH)
    )inst(
        .ctr({ctr[i][PSUM_SPAD_WIDTH-1:i+1],1'b1}),
        .data_in(psum_in[PSUM_WIDTH*PSUM_SPAD_WIDTH-1:i*PSUM_WIDTH]),
        .sum(psum_out_2d[i])
    );
    end else begin
        assign psum_out_2d[i]=psum_in_2d[i];
    end
end
endgenerate

endmodule
