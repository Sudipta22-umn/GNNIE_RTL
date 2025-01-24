/*`include "MAC_4.v"
`include "MAC_5.v"
`include "MAC_6.v"

`include "PE_4.v"
`include "PE_5.v"
`include "PE_6.v"

`include "PE_TOP_4.v"
`include "PE_TOP_5.v"
`include "PE_TOP_6.v"
`include "MERGE_PE_TOP.v"
`include "PE_row.v"*/
`timescale 1ns/1ps
`include "log2.vh"
//PE_ARRAY
module accelerator #(
  parameter integer  FEAT_WIDTH                   = 1, // input fetaure bit width
  parameter integer  WGT_WIDTH                    = 8, // input weight bit widthweight_enable_top
  parameter integer  PE_OUT_WIDTH                 = 8, // output width for the sum
  parameter integer  SPAD_WIDTH                   = 64, // fetaure and weight spad width; max lenght of the k-subvector that can be assigned to a PE
  parameter integer  PE_DIM                       = 16, // PE array row/column dimension
  parameter integer  ROW_DIM                      = 16, // PE array row dimension
  parameter integer  NZ_WIDTH                     = 16, // the maximum number of non-zeros 
  parameter integer  NUM_NODES                    = 4, // for example cora dataset the number of vertices is 2733, thus we require 12 bits to index/tag the partial result for a node. This is used for assiging tag bits to the partial result, i.e., tag_out
  parameter integer LOG_PE_DIM                   =`C_LOG_2(PE_DIM),
  parameter integer  ADDR_WIDTH                   = `C_LOG_2(SPAD_WIDTH),
  parameter integer  WGT_INDEX                    = `C_LOG_2(WGT_WIDTH)
) (
    //inputs
    input             clk,
    input             reset,
    //input             [ADDR_WIDTH*76-1:0]non_zero_add_bus, // required for each of 16 subvectors fed to each PE in arow
    //input             [FEAT_WIDTH*SPAD_WIDTH*PE_DIM-1:0]data_bus,//fetaure in the feature spad from the feature bus // Feature vector dimension = 8*64*16 bits = fetaure length = 1024 (each @1B)
    input             [FEAT_WIDTH*SPAD_WIDTH*ROW_DIM-1:0]data_bus,
    //input             [WGT_WIDTH*SPAD_WIDTH*PE_DIM-1:0] weight_bus,//weight in the weight spad from the weight bus
    input             [39:0] non_zero_num_bus, // fixed/variable?
    //input             [3:0] enable_top, // one enable pin for each PE in the row
    input             [LOG_PE_DIM*ROW_DIM-1:0] weight_enable_top,// one weight/feature select pin for each PE in the row
    input             [ROW_DIM-1:0] broad_cast_enable,
    // top start signal for the merge PEs
    input             [NUM_NODES*ROW_DIM-1:0] tag_in_bus,
    input             [ROW_DIM-1:0] acc,done,            
    //input             
    //outputs
    //output reg        [PE_OUT_WIDTH*PE_DIM-1:0] sum_out_bus, //at a time there can be 16 partial sums sent form the 16 merge PE to the output buffer
    input            [ROW_DIM-1:0]sum_out_rd,
    output           [ROW_DIM-1:0]data_bus_rd,
    output           [ROW_DIM-1:0]psum_tag_rd,
    //output           [NUM_NODES*PE_DIM*ROW_DIM-1:0] tag_out_bus, //one tag assigned for each of the partial sums     
    output           [PE_OUT_WIDTH*PE_DIM*ROW_DIM-1:0] sum_out_bus, // top level output needs to be three dimensional too?
    output           [ROW_DIM-1:0] sum_vd // top done signal for the merge PEs

);

// interanl wires
// 2D data and non zero address
wire [ROW_DIM-1:0]data_tag_vd;
assign data_tag_vd=broad_cast_enable;
wire  [FEAT_WIDTH*SPAD_WIDTH-1:0] data_2d  [0:ROW_DIM-1];
wire [ADDR_WIDTH*6-1:0]   non_zero_2d [0:ROW_DIM-1];

// 2D  tag comes from the top module and sliced column-wise for a input to the merge PEs (a row of merge PEs)
//wire  [NUM_NODES-1:0] tag_out_2d [0:ROW_DIM-1];
// 2D sum out is 2D output of the PE row
// each of them is sliced column-wise for a output of the Megre PEs (a row of merge PEs)
wire  [PE_OUT_WIDTH*PE_DIM-1:0] sum_out_2d [0:ROW_DIM-1];
wire  [2:0]non_zero_num[0:15];
 
wire  [PE_DIM-1:0] psum_vd[0:ROW_DIM-1];

genvar i,j;

generate
for(i=0;i<ROW_DIM;i=i+1)begin
  if(i<8)begin
    assign non_zero_num[i] = {1'b0,non_zero_num_bus[i*2+1:i*2]};
  end else begin
    assign non_zero_num[i]= non_zero_num_bus[3*i-6:3*i-8];
  end
end

endgenerate
generate
for(i=0;i<ROW_DIM;i=i+1)begin
    assign data_2d[i]=data_bus[(i+1)*FEAT_WIDTH*SPAD_WIDTH-1:i*FEAT_WIDTH*SPAD_WIDTH]; // converts from input 3d data bus to 2d 
     // converts from the 3d non zero add bus to 2d 
    //assign tag_out_2d[i]=tag_in_bus[(i+1)*NUM_NODES-1:i*NUM_NODES]; // converts from the 3d non zero add bus to 2d 
end
endgenerate

// connect the 16 rows here
//genvar i;
wire [PE_DIM-1:0] weight_enable_converted[ROW_DIM-1:0];
generate
for (i=0;i<ROW_DIM;i=i+1)begin : ROW
  assign weight_enable_converted[i]=1<<weight_enable_top[LOG_PE_DIM*i+LOG_PE_DIM-1:LOG_PE_DIM*i];
  if(i<8) begin
    NZ_GEN_4 nz_unit(
        .clk(clk),
        .reset(reset),
        .data_bus(data_2d[i]),
        .non_zero_add_bus(non_zero_2d[i][ADDR_WIDTH*4-1:0])
        //.data_out(),
        //.done()
    );
    //assign non_zero_2d[i][ADDR_WIDTH*4-1:0]
    /*
    PE_ROW_4 #(
      .FEAT_WIDTH(FEAT_WIDTH),                  
      .WGT_WIDTH(WGT_WIDTH),             
      .PE_OUT_WIDTH(PE_OUT_WIDTH),              
      .SPAD_WIDTH(SPAD_WIDTH),
      .PE_DIM (PE_DIM),              
      .NZ_WIDTH(NZ_WIDTH),              
      .NUM_NODES(NUM_NODES)
    )PE_ROW(
      .clk(clk),
      .reset(reset),
      .non_zero_add_bus(non_zero_2d[i][ADDR_WIDTH*4-1:0]), 
      .data_bus(data_2d[i]), // first 16 part goes to the each of the PE in the same column // how to connect the interim data bus //
      //.weight_in(weight_3d[0]), // we take one column of the weight matrix at a time // easy solution to have to 16 of them
      .non_zero_num (non_zero_num[i][1:0]),
      .broad_cast_enable(broad_cast_enable[i]),
      .weight_enable_top(weight_enable_top[LOG_PE_DIM*i+LOG_PE_DIM-1:LOG_PE_DIM*i]),
      .acc(acc[i]),
      .done(done[i]),
      .psum_rd(psum_rd[i]),
      
      .sum_out_bus(sum_out_2d[i]), // need to fix this; this is the port which goes to the merge pe input to eventually to the output
      .out_vd(psum_vd[i]),
      .data_bus_rd(data_bus_rd[i])
    );  
    */
    for (j=0;j<PE_DIM;j=j+1)begin:COL4
        PE_TOP_4 #(
          .FEAT_WIDTH(FEAT_WIDTH),                  
          .WGT_WIDTH(WGT_WIDTH),             
          .PE_OUT_WIDTH(PE_OUT_WIDTH),              
          .SPAD_WIDTH(SPAD_WIDTH),              
          .NZ_WIDTH(NZ_WIDTH),              
          .NUM_NODES(NUM_NODES)
        )PE_4(
          .clk(clk),
          .reset(reset),
          .addr_bus(non_zero_2d[i][ADDR_WIDTH*4-1:0]), 
          .data_bus(data_2d[i]), // first 16 part goes to the each of the PE in the same column // how to connect the interim data bus //
          //.weight_in(weight_3d[0]), // we take one column of the weight matrix at a time // easy solution to have to 16 of them
          .non_zero_num (non_zero_num[i][1:0]),
          .w_we (weight_enable_converted[i][j]),
          //.w_index(w_index),
          .x_we (broad_cast_enable[i]),
          .acc(acc[i]),
          .done(done[i]),
          //.data_rd(pe_rd[i]),
          .out(sum_out_2d[i][PE_OUT_WIDTH*j+PE_OUT_WIDTH-1:PE_OUT_WIDTH*j]), 
          .out_vd(psum_vd[i][j])
        );  

    end // COL


    end else if(i<12) begin
    NZ_GEN_5 nz_unit(
        .clk(clk),
        .reset(reset),
        .data_bus(data_2d[i]),
        .non_zero_add_bus(non_zero_2d[i][ADDR_WIDTH*5-1:0])
        //.data_out(),
        //.done()
    );
      //assign non_zero_2d[i][ADDR_WIDTH*5-1:0]=non_zero_add_bus[(i+1)*ADDR_WIDTH*5-8*ADDR_WIDTH-1:i*ADDR_WIDTH*5-8*ADDR_WIDTH];
      /*PE_ROW_5 #(
      .FEAT_WIDTH(FEAT_WIDTH),         
      .WGT_WIDTH(WGT_WIDTH),             
      .PE_OUT_WIDTH(PE_OUT_WIDTH),              
      .SPAD_WIDTH(SPAD_WIDTH),
      .PE_DIM (PE_DIM),              
      .NZ_WIDTH(NZ_WIDTH),              
      .NUM_NODES(NUM_NODES)
    )PE_ROW(
      .clk(clk),
      .reset(reset),
      .non_zero_add_bus(non_zero_2d[i][ADDR_WIDTH*5-1:0]), 
      .data_bus(data_2d[i]), // first 16 part goes to the each of the PE in the same column // how to connect the interim data bus //
      //.weight_in(weight_3d[0]), // we take one column of the weight matrix at a time // easy solution to have to 16 of them
      .non_zero_num (non_zero_num[i]),
      .broad_cast_enable(broad_cast_enable[i]),
      .weight_enable_top(weight_enable_top[LOG_PE_DIM*i+LOG_PE_DIM-1:LOG_PE_DIM*i]),
      .acc(acc[i]),
      .done(done[i]),
      .psum_rd(psum_rd[i]),
      
      .sum_out_bus(sum_out_2d[i]), 
      .out_vd(psum_vd[i]),
      .data_bus_rd(data_bus_rd[i])
    );  */
    for (j=0;j<PE_DIM;j=j+1)begin:COL5
    PE_TOP_5 #(
          .FEAT_WIDTH(FEAT_WIDTH),                  
          .WGT_WIDTH(WGT_WIDTH),             
          .PE_OUT_WIDTH(PE_OUT_WIDTH),              
          .SPAD_WIDTH(SPAD_WIDTH),              
          .NZ_WIDTH(NZ_WIDTH),              
          .NUM_NODES(NUM_NODES)
        )PE_5(
          .clk(clk),
          .reset(reset),
          .addr_bus(non_zero_2d[i][ADDR_WIDTH*5-1:0]), 
          .data_bus(data_2d[i]), // first 16 part goes to the each of the PE in the same column // how to connect the interim data bus //
          //.weight_in(weight_3d[0]), // we take one column of the weight matrix at a time // easy solution to have to 16 of them
          .non_zero_num (non_zero_num[i]),
          .x_we (broad_cast_enable[i]),
          .w_we (weight_enable_converted[i][j]),
          //.w_index(w_index),
          .acc(acc[i]),
          .done(done[i]),
          //.data_rd(pe_rd[i]),
          .out(sum_out_2d[i][PE_OUT_WIDTH*j+PE_OUT_WIDTH-1:PE_OUT_WIDTH*j]), 
          .out_vd(psum_vd[i][j])
        );
    end //COL
    end else begin
    NZ_GEN_6 nz_unit(
        .clk(clk),
        .reset(reset),
        .data_bus(data_2d[i]),
        .non_zero_add_bus(non_zero_2d[i][ADDR_WIDTH*6-1:0])
        //.data_out(),
        //.done()
    );
      //assign non_zero_2d[i][ADDR_WIDTH*6-1:0]=non_zero_add_bus[(i+1)*ADDR_WIDTH*6-20*ADDR_WIDTH-1:i*ADDR_WIDTH*6-20*ADDR_WIDTH];
    /*
    PE_ROW_6 #(
      .FEAT_WIDTH(FEAT_WIDTH),                  
      .WGT_WIDTH(WGT_WIDTH),             
      .PE_OUT_WIDTH(PE_OUT_WIDTH),              
      .SPAD_WIDTH(SPAD_WIDTH),
      .PE_DIM (PE_DIM),              
      .NZ_WIDTH(NZ_WIDTH),              
      .NUM_NODES(NUM_NODES)
    )PE_ROW(
      .clk(clk),
      .reset(reset),
      .non_zero_add_bus(non_zero_2d[i][ADDR_WIDTH*6-1:0]), 
      .data_bus(data_2d[i]), // first 16 part goes to the each of the PE in the same column // how to connect the interim data bus //
      //.weight_in(weight_3d[0]), // we take one column of the weight matrix at a time // easy solution to have to 16 of them
      .non_zero_num (non_zero_num[i]),
      .broad_cast_enable(broad_cast_enable[i]),
      .weight_enable_top(weight_enable_top[LOG_PE_DIM*i+LOG_PE_DIM-1:LOG_PE_DIM*i]),
      .acc(acc[i]),
      .done(done[i]),
      .psum_rd(psum_rd[i]),
      
      .sum_out_bus(sum_out_2d[i]) , 
      .out_vd(psum_vd[i]),
      .data_bus_rd(data_bus_rd[i])
    );
    */

     for(j=0;j<PE_DIM;j=j+1)begin:COL6
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
          .addr_bus(non_zero_2d[i][ADDR_WIDTH*6-1:0]), 
          .data_bus(data_2d[i]), 
          .non_zero_num (non_zero_num[i]),
          .x_we (broad_cast_enable[i]),
          .w_we (weight_enable_converted[i][j]),
          .acc(acc[i]),
          .done(done[i]),
          .out(sum_out_2d[i][PE_OUT_WIDTH*j+PE_OUT_WIDTH-1:PE_OUT_WIDTH*j]), 
          .out_vd(psum_vd[i][j])
        );  
    end // ends COL

    end // ends if
end //  PE_ROW
endgenerate


// wires for final psum out and tag out of the PE array

wire  [NUM_NODES*PE_DIM-1:0] final_tag_2d_out[0:ROW_DIM-1];
wire  [PE_OUT_WIDTH*PE_DIM-1:0] final_psum_2d_out[0:ROW_DIM-1];
//wire  [PE_DIM-1:0] psum_tag_rd[0:ROW_DIM-1];

//wire  [PE_DIM-1:0]m_ena,
//genvar i;
generate
  for (i=0;i<PE_DIM;i=i+1)begin : MERGE
    MERGE_PE_TOP #(
      //.PSUM_WIDTH(FEAT_WIDTH), 
       .PSUM_WIDTH(PE_OUT_WIDTH),                 
      .TAG_WIDTH(NUM_NODES),             
      .PSUM_SPAD_WIDTH(PE_DIM)             
    )MERGE_PE(
      .clk(clk),
      .rst(reset),
      //.psum_in({ [PE_OUT_WIDTH*(i+1)-1:PE_OUT_WIDTH*i]sum_out_2d[0],[PE_OUT_WIDTH*(i+1)-1:PE_OUT_WIDTH*i]sum_out_2d[1],[PE_OUT_WIDTH*(i+1)-1:PE_OUT_WIDTH*i]sum_out_2d[2],[PE_OUT_WIDTH*(i+1)-1:PE_OUT_WIDTH*i]sum_out_2d[3],[PE_OUT_WIDTH*(i+1)-1:PE_OUT_WIDTH*i]sum_out_2d[4],[PE_OUT_WIDTH*(i+1)-1:PE_OUT_WIDTH*i]sum_out_2d[5],[PE_OUT_WIDTH*(i+1)-1:PE_OUT_WIDTH*i]sum_out_2d[6],[PE_OUT_WIDTH*(i+1)-1:PE_OUT_WIDTH*i]sum_out_2d[7],[PE_OUT_WIDTH*(i+1)-1:PE_OUT_WIDTH*i]sum_out_2d[8],[PE_OUT_WIDTH*(i+1)-1:PE_OUT_WIDTH*i]sum_out_2d[9],[PE_OUT_WIDTH*(i+1)-1:PE_OUT_WIDTH*i]sum_out_2d[10],[PE_OUT_WIDTH*(i+1)-1:PE_OUT_WIDTH*i]sum_out_2d[11],[PE_OUT_WIDTH*(i+1)-1:PE_OUT_WIDTH*i]sum_out_2d[12],[PE_OUT_WIDTH*(i+1)-1:PE_OUT_WIDTH*i]sum_out_2d[13],[PE_OUT_WIDTH*(i+1)-1:PE_OUT_WIDTH*i]sum_out_2d[14],[PE_OUT_WIDTH*(i+1)-1:PE_OUT_WIDTH*i]sum_out_2d[15] }), //have to come from each PE column
      .psum_in({sum_out_2d[0][PE_OUT_WIDTH*(i+1)-1:PE_OUT_WIDTH*i],sum_out_2d[1][PE_OUT_WIDTH*(i+1)-1:PE_OUT_WIDTH*i],sum_out_2d[2][PE_OUT_WIDTH*(i+1)-1:PE_OUT_WIDTH*i],sum_out_2d[3][PE_OUT_WIDTH*(i+1)-1:PE_OUT_WIDTH*i],sum_out_2d[4][PE_OUT_WIDTH*(i+1)-1:PE_OUT_WIDTH*i],sum_out_2d[5][PE_OUT_WIDTH*(i+1)-1:PE_OUT_WIDTH*i],sum_out_2d[6][PE_OUT_WIDTH*(i+1)-1:PE_OUT_WIDTH*i],sum_out_2d[7][PE_OUT_WIDTH*(i+1)-1:PE_OUT_WIDTH*i],sum_out_2d[8][PE_OUT_WIDTH*(i+1)-1:PE_OUT_WIDTH*i],sum_out_2d[9][PE_OUT_WIDTH*(i+1)-1:PE_OUT_WIDTH*i],sum_out_2d[10][PE_OUT_WIDTH*(i+1)-1:PE_OUT_WIDTH*i],sum_out_2d[11][PE_OUT_WIDTH*(i+1)-1:PE_OUT_WIDTH*i],sum_out_2d[12][PE_OUT_WIDTH*(i+1)-1:PE_OUT_WIDTH*i],sum_out_2d[13][PE_OUT_WIDTH*(i+1)-1:PE_OUT_WIDTH*i],sum_out_2d[14][PE_OUT_WIDTH*(i+1)-1:PE_OUT_WIDTH*i],sum_out_2d[15][PE_OUT_WIDTH*(i+1)-1:PE_OUT_WIDTH*i]}),
      .psum_vd({psum_vd[0][i],psum_vd[1][i],psum_vd[2][i],psum_vd[3][i],psum_vd[4][i],psum_vd[5][i],psum_vd[6][i],psum_vd[7][i],psum_vd[8][i],psum_vd[9][i],psum_vd[10][i],psum_vd[11][i],psum_vd[12][i],psum_vd[13][i],psum_vd[14][i],psum_vd[15][i]}),
      //.tag_in ({ [PE_OUT_WIDTH*(i+1)-1:PE_OUT_WIDTH*i]tag_out_2d[0],[PE_OUT_WIDTH*(i+1)-1:PE_OUT_WIDTH*i]tag_out_2d[1],[PE_OUT_WIDTH*(i+1)-1:PE_OUT_WIDTH*i]tag_out_2d[2],[PE_OUT_WIDTH*(i+1)-1:PE_OUT_WIDTH*i]tag_out_2d[3],[PE_OUT_WIDTH*(i+1)-1:PE_OUT_WIDTH*i]tag_out_2d[4],[PE_OUT_WIDTH*(i+1)-1:PE_OUT_WIDTH*i]tag_out_2d[5],[PE_OUT_WIDTH*(i+1)-1:PE_OUT_WIDTH*i]tag_out_2d[6],[PE_OUT_WIDTH*(i+1)-1:PE_OUT_WIDTH*i]tag_out_2d[7],[PE_OUT_WIDTH*(i+1)-1:PE_OUT_WIDTH*i]tag_out_2d[8],[PE_OUT_WIDTH*(i+1)-1:PE_OUT_WIDTH*i]tag_out_2d[9],[PE_OUT_WIDTH*(i+1)-1:PE_OUT_WIDTH*i]tag_out_2d[10],[PE_OUT_WIDTH*(i+1)-1:PE_OUT_WIDTH*i]tag_out_2d[11],[PE_OUT_WIDTH*(i+1)-1:PE_OUT_WIDTH*i]tag_out_2d[12],[PE_OUT_WIDTH*(i+1)-1:PE_OUT_WIDTH*i]tag_out_2d[13],[PE_OUT_WIDTH*(i+1)-1:PE_OUT_WIDTH*i]tag_out_2d[14],[PE_OUT_WIDTH*(i+1)-1:PE_OUT_WIDTH*i]tag_out_2d[15] }),  // comes from the top module // can have 16 different tags coming in at worst case // taking 16 bits at a time from each row
      .tag_in(tag_in_bus),
      .tag_vd(data_tag_vd[i]),
      .out_rd(sum_out_rd[i]),

      //.done  (done_top[i]), // connects to the top output signal done when finishes computation
      .psum_out_r(final_psum_2d_out[i]),
      //.tag_rec_rd(),
      .psum_tag_rd(psum_tag_rd[i]),
      .out_vd(sum_vd[i])
    ); 
end // MERGE_PE_CONNECTION
endgenerate

// converts the final psum and tag out from 2d to 3d format
generate
for(i=0;i<ROW_DIM;i=i+1)begin //FINAL 2D TO 3D CONVERION
	  assign sum_out_bus[(i+1)*PE_OUT_WIDTH*PE_DIM-1:i*PE_OUT_WIDTH*PE_DIM]=final_psum_2d_out[i];
      //assign tag_out_bus[(i+1)*NUM_NODES*PE_DIM-1:i*NUM_NODES*PE_DIM]=final_tag_2d_out[i]; 
end
endgenerate

endmodule




