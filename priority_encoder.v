module pri_encoder(
binary_out , //  4 bit binary output
encoder_in , //  16-bit input 
 enable       //  Enable for the encoder
);
 
 output [5:0] binary_out ;
 input  enable ; 
 input [63:0] encoder_in; 

//wire [3:0] binary_out ;
      
 assign  binary_out  = ( ! enable) ? 0 : (
 (encoder_in[0]) ? 0 : 
 (encoder_in[1]) ? 1 : 
 (encoder_in[2]) ? 2 : 
 (encoder_in[3]) ? 3 : 
 (encoder_in[4]) ? 4 : 
 (encoder_in[5]) ? 5 : 
 (encoder_in[6]) ? 6 : 
 (encoder_in[7]) ? 7 : 
 (encoder_in[8]) ? 8 : 
 (encoder_in[9]) ? 9 : 
 (encoder_in[10]) ? 10 : 
 (encoder_in[11]) ? 11 : 
 (encoder_in[12]) ? 12 : 
 (encoder_in[13]) ? 13 : 
 (encoder_in[14]) ? 14 : 
 (encoder_in[15]) ? 15 : 
 (encoder_in[16]) ? 16 : 
 (encoder_in[17]) ? 17 : 
 (encoder_in[18]) ? 18 : 
 (encoder_in[19]) ? 19 : 
 (encoder_in[20]) ? 20 : 
 (encoder_in[21]) ? 21 : 
 (encoder_in[22]) ? 22 : 
 (encoder_in[23]) ? 23 : 
 (encoder_in[24]) ? 24 : 
 (encoder_in[25]) ? 25 : 
 (encoder_in[26]) ? 26 : 
 (encoder_in[27]) ? 27 : 
 (encoder_in[28]) ? 28 : 
 (encoder_in[29]) ? 29 : 
 (encoder_in[30]) ? 30 : 
 (encoder_in[31]) ? 31 : 
 (encoder_in[32]) ? 32 : 
 (encoder_in[33]) ? 33 : 
 (encoder_in[34]) ? 34 : 
 (encoder_in[35]) ? 35 : 
 (encoder_in[36]) ? 36 : 
 (encoder_in[37]) ? 37 : 
 (encoder_in[38]) ? 38 : 
 (encoder_in[39]) ? 39 : 
 (encoder_in[40]) ? 40 : 
 (encoder_in[41]) ? 41 : 
 (encoder_in[42]) ? 42 : 
 (encoder_in[43]) ? 43 : 
 (encoder_in[44]) ? 44 : 
 (encoder_in[45]) ? 45 : 
 (encoder_in[46]) ? 46 : 
 (encoder_in[47]) ? 47 : 
 (encoder_in[48]) ? 48 : 
 (encoder_in[49]) ? 49 : 
 (encoder_in[50]) ? 50 : 
 (encoder_in[51]) ? 51 : 
 (encoder_in[52]) ? 52 : 
 (encoder_in[53]) ? 53 : 
 (encoder_in[54]) ? 54 : 
 (encoder_in[55]) ? 55 : 
 (encoder_in[56]) ? 56 : 
 (encoder_in[57]) ? 57 : 
 (encoder_in[58]) ? 58 : 
 (encoder_in[59]) ? 59 : 
 (encoder_in[60]) ? 60 : 
 (encoder_in[61]) ? 61 : 
 (encoder_in[62]) ? 62 : 63);
 endmodule 
