/* Stereoscopic Vision System
Senior Design Project - Team 11
California State University, Sacramento
Spring 2015 / Fall 2015
----------------------------------------
TMDS Encoder
Authors:  Miad Rouhani
Description:
  TMDS TMDSdecoder
*/

module decode (
  input  wire reset,            
  input  wire pclk,             
  input  wire doublepclk,           
  input  wire x10pclk,          
  input  wire serdesstrobe,     
  input  wire din_p,           
  input  wire din_n,            
  input  wire other_ch0_vld,    
  input  wire other_ch1_vld,   
  input  wire other_ch0_rdy,    
  input  wire other_ch1_rdy,    

  output wire iamvld,           
  output wire iamrdy,           
  output wire err_phaliign,        
  output reg  c0,
  output reg  c1,
  output reg  de,     
  output reg [9:0] dout_ser,
  output reg [7:0] dout);


  wire flipgear;
  reg flipgearx2;

  always @ (posedge doublepclk) begin
    flipgearx2 <=#1 flipgear;
  end

  reg toggle = 1'b0;

  always @ (posedge doublepclk or posedge reset)
    if (reset == 1'b1) begin
      toggle <= 1'b0 ;
    end else begin
      toggle <=#1 ~toggle;
    end
  
  wire rx_toggle;

  assign rx_toggle = toggle ^ flipgearx2; //reverse hi-lo position

  wire [4:0] raw5bit;
  reg [4:0] raw5bit_q;
  reg [9:0] rawword;

  always @ (posedge doublepclk) begin
    raw5bit_q    <=#1 raw5bit;

    if(rx_toggle) 
      rawword <=#1 {raw5bit, raw5bit_q};
  end


  reg bitslipx2 = 1'b0;
  reg bitslip_q = 1'b0;
  wire bitslip;

  always @ (posedge doublepclk) begin
    bitslip_q <=#1 bitslip;
    bitslipx2 <=#1 bitslip & !bitslip_q;
  end 


  serdes_1_to_5_diff_data # (
    .DIFF_TERM("FALSE"),
    .BITSLIP_ENABLE("TRUE")
  ) des_0 (
    .use_phase_detector(1'b1),
    .datain_p(din_p),
    .datain_n(din_n),
    .rxioclk(x10pclk),
    .rxserdesstrobe(serdesstrobe),
    .reset(reset),
    .gclk(doublepclk),
    .bitslip(bitslipx2),
    .data_out(raw5bit)
  );


  wire [9:0] rawdata = rawword;


  phsaligner phsalgn_0 (
     .rst(reset),
     .clk(pclk),
     .sdata(rawdata),
     .bitslip(bitslip),
     .flipgear(flipgear),
     .psaligned(iamvld)
   );

  assign err_phaliign = 1'b0;

  
  wire [9:0] sdata;
  chnlbond cbnd (
    .clk(pclk),
    .rawdata(rawdata),
    .iamvld(iamvld),
    .other_ch0_vld(other_ch0_vld),
    .other_ch1_vld(other_ch1_vld),
    .other_ch0_rdy(other_ch0_rdy),
    .other_ch1_rdy(other_ch1_rdy),
    .iamrdy(iamrdy),
    .sdata(sdata)
  );



  parameter CTRLTOKEN0 = 10'b1101010100;
  parameter CTRLTOKEN1 = 10'b0010101011;
  parameter CTRLTOKEN2 = 10'b0101010100;
  parameter CTRLTOKEN3 = 10'b1010101011;

  wire [7:0] data;
  assign data = (sdata[9]) ? ~sdata[7:0] : sdata[7:0]; 

  always @ (posedge pclk) begin
    if(iamrdy && other_ch0_rdy && other_ch1_rdy) begin
      case (sdata) 
        CTRLTOKEN0: begin
          c0 <=#1 1'b0;
          c1 <=#1 1'b0;
          de <=#1 1'b0;
        end

        CTRLTOKEN1: begin
          c0 <=#1 1'b1;
          c1 <=#1 1'b0;
          de <=#1 1'b0;
        end

        CTRLTOKEN2: begin
          c0 <=#1 1'b0;
          c1 <=#1 1'b1;
          de <=#1 1'b0;
        end
        
        CTRLTOKEN3: begin
          c0 <=#1 1'b1;
          c1 <=#1 1'b1;
          de <=#1 1'b0;
        end
        
        default: begin 
          dout[0] <=#1 data[0];
          dout[1] <=#1 (sdata[8]) ? (data[1] ^ data[0]) : (data[1] ~^ data[0]);
          dout[2] <=#1 (sdata[8]) ? (data[2] ^ data[1]) : (data[2] ~^ data[1]);
          dout[3] <=#1 (sdata[8]) ? (data[3] ^ data[2]) : (data[3] ~^ data[2]);
          dout[4] <=#1 (sdata[8]) ? (data[4] ^ data[3]) : (data[4] ~^ data[3]);
          dout[5] <=#1 (sdata[8]) ? (data[5] ^ data[4]) : (data[5] ~^ data[4]);
          dout[6] <=#1 (sdata[8]) ? (data[6] ^ data[5]) : (data[6] ~^ data[5]);
          dout[7] <=#1 (sdata[8]) ? (data[7] ^ data[6]) : (data[7] ~^ data[6]);

          de <=#1 1'b1;
        end                                                                      
      endcase                                                                    

      dout_ser <=#1 sdata;
    end else begin
      c0 <= 1'b0;
      c1 <= 1'b0;
      de <= 1'b0;
      dout <= 8'h0;
      dout_ser <= 10'h0;
    end
  end
endmodule
