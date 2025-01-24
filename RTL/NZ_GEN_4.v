
`timescale 1ns/1ps
`include "log2.vh"
module NZ_GEN_4 #(
  parameter integer  DIM                          = 4,
  parameter integer  FEAT_WIDTH                   = 1, // input fetaure bit width
  parameter integer  SPAD_WIDTH                   = 64, // fetaure and weight spad width; max lenght of the k-subvector that can be assigned to a PE
  parameter integer  ADDR_WIDTH                   = `C_LOG_2(SPAD_WIDTH)
) (
    //inputs
    input             clk,
    input             reset,
    input             [FEAT_WIDTH*SPAD_WIDTH-1:0]data_bus, 
    //input             start,
    output  reg           [ADDR_WIDTH*DIM-1:0]non_zero_add_bus, // required for each of 16 subvectors fed to each PE in arow 6*4=24
    output  reg          [FEAT_WIDTH*SPAD_WIDTH-1:0]data_out, 
    output            done
);
wire [ADDR_WIDTH*DIM-1:0]non_zero_add_bus_pre; // required for each of 16 subvectors fed to each PE in arow 6*4=24
wire [FEAT_WIDTH*SPAD_WIDTH-1:0]data_out_pre;

wire [5:0]addr_0;
pri_encoder(
    .binary_out(addr_0), //  6 bit binary output
    .encoder_in(data_bus), //  64-bit input 
    .enable(1'b1)       //  Enable for the encoder
);

reg [FEAT_WIDTH*SPAD_WIDTH-1:0]data_bus_1;
always@(*)begin
    data_bus_1 =  data_bus;
    data_bus_1[addr_0] = 0;    
end

wire [5:0]addr_1;
pri_encoder(
    .binary_out(addr_1), //  6 bit binary output
    .encoder_in(data_bus_1), //  64-bit input 
    .enable(1'b1)       //  Enable for the encoder
);

reg [FEAT_WIDTH*SPAD_WIDTH-1:0]data_bus_2;
always@(*)begin
    data_bus_2 =  data_bus_1;
    data_bus_2[addr_0] = 0;    
end

wire [5:0]addr_2;
pri_encoder(
    .binary_out(addr_2), //  6 bit binary output
    .encoder_in(data_bus), //  64-bit input 
    .enable(1'b1)       //  Enable for the encoder
);

reg [FEAT_WIDTH*SPAD_WIDTH-1:0]data_bus_3;
always@(*)begin
    data_bus_3 =  data_bus_2;
    data_bus_3[addr_0] = 0;    
end

wire [5:0]addr_3;
pri_encoder(
    .binary_out(addr_3), //  6 bit binary output
    .encoder_in(data_bus_3), //  64-bit input 
    .enable(1'b1)       //  Enable for the encoder
);

reg [FEAT_WIDTH*SPAD_WIDTH-1:0]data_bus_4;
always@(*)begin
    data_bus_4 =  data_bus_3;
    data_bus_4[addr_0] = 0;    
end

assign done = data_bus_4==64'd0;
assign non_zero_add_bus_pre = {addr_0,addr_1,addr_2,addr_3};
assign data_out_pre=data_bus;
always @(posedge clk or posedge reset)begin
    if (reset)begin
        non_zero_add_bus<=0;
        data_out<=0;
    end else begin
        non_zero_add_bus<=non_zero_add_bus_pre;
        data_out<=data_out_pre;
    end
end

endmodule


 

