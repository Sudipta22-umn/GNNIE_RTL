module serial_adder#(
    parameter NUM       =4,
    parameter bitwidth  =16
)(
    input [NUM-1:0]ctr,
    input [NUM*bitwidth-1:0]data_in,
    output [bitwidth-1:0]sum
);
//2d
wire [bitwidth-1:0]data[0:NUM-1];
genvar i;
generate
for(i=0;i<NUM;i=i+1)begin
  assign data[i]=data_in[i*bitwidth+bitwidth-1:i*bitwidth];
end
endgenerate 

wire [bitwidth-1:0]psum[0:NUM-1];
generate
for(i=0;i<NUM;i=i+1)begin
    if(i==0)begin
        assign psum[i]=ctr[i]?data[i]:0;
    end else begin
        assign psum[i]=ctr[i]?data[i]+psum[i-1]:psum[i-1];
    end
end
endgenerate 
assign sum=psum[NUM-1];
endmodule
           

