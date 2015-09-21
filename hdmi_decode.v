module hdmi_decode (hdmi_Clk_pos,hdmi_Clk_neg,blue_data_pos, green_data_pos,red_data_pos,blue_data_neg,green_data_neg,red_data_neg,exrst,reset,pclk,hsync,vsync,de, rgb_data);    
    
  input  wire hdmi_Clk_pos;      // tmds clock
  input  wire hdmi_Clk_neg;      // tmds clock
  input  wire blue_data_pos;         // Blue data in
  input  wire green_data_pos;        // Green data in
  input  wire red_data_pos;          // Red data in
  input  wire blue_data_neg;         // Blue data in
  input  wire green_data_neg;        // Green data in
  input  wire red_data_neg;          // Red data in
  input  wire exrst;          // external reset input, e.g. reset button

  output wire reset;          // rx reset
  output wire pclk;          // regenerated pixel clock
  output wire hsync;        // hsync data
  output wire vsync;          // vsync data
  output wire de;          // data enable
  output wire [24:0] rgb_data;  
  

  //output wire [29:0] dout_ser;
  //output wire [7:0] red;// pixel data out
  //output wire [7:0] green;// pixel data out
  //output wire [7:0] blue;    // pixel data out
  wire doublepclk;         // double rate pixel clock
  wire x10pclk;     // 10x pixel as IOCLK
  wire x10pllclk;        // send x10pllclk out so it can be fed into a different BUFPLL
  wire rpllclk;      // PLL x1 output
  wire x2pllclk;        // PLL x2 output

  wire pll_lckd;       // send pll_lckd out so it can be fed into a different BUFPLL
  wire serdesstrobe;   // BUFPLL serdesstrobe output
  wire hdmi_clk;        // TMDS cable clock
  //wire [9:0] sdout_blue, sdout_green, sdout_red;
  wire de_b, de_g, de_r;
  wire blue_psalgnerr, green_psalgnerr, red_psalgnerr;
  wire rxclkint;
  wire rxclk;wire bufpll_lock;
  wire vld_bluech;
  wire vld_greench;
  wire vld_redch;
  wire rdy_bluech;
  wire rdy_greench;
  wire rdy_redch; 
  wire err_phaliign;

  // Send TMDS clock to a differential buffer and then a BUFIO2
  // This is a required path in Spartan-6 feed a PLL CLKIN
  //
  
  IBUFDS  #(.IOSTANDARD("TMDS_33"), .DIFF_TERM("FALSE")) ibuf_rxclk (.I(hdmi_Clk_pos), .IB(hdmi_Clk_neg), .O(rxclkint));
  BUFIO2 #(.DIVIDE_BYPASS("TRUE"), .DIVIDE(1))bufio_tmdsclk (.DIVCLK(rxclk), .IOCLK(), .SERDESSTROBE(), .I(rxclkint));
  BUFG tmdsclk_bufg (.I(rxclk), .O(hdmi_clk));

  //
  // PLL is used to generate three clocks:
  // 1. pclk:    same rate as TMDS clock
  // 2. doublepclk:  double rate of pclk used for 5:10 soft gear box and ISERDES DIVCLK
  // 3. x10pclk: 10x rate of pclk used as IO clock
  //
  PLL_BASE # (.CLKIN_PERIOD(10),.CLKFBOUT_MULT(10),.CLKOUT0_DIVIDE(1),.CLKOUT1_DIVIDE(10),.CLKOUT2_DIVIDE(5),.COMPENSATION("INTERNAL")) PLL_ISERDES (.CLKFBOUT(clkfbout),
    .CLKOUT0(x10pllclk),.CLKOUT1(rpllclk),.CLKOUT2(x2pllclk),.CLKOUT3(),.CLKOUT4(),.CLKOUT5(),.LOCKED(pll_lckd),.CLKFBIN(clkfbout),.CLKIN(rxclk),.RST(exrst));
   
  //
  // Pixel Rate clock buffer
  //
  BUFG pclkbufg (.I(rpllclk), .O(pclk));

  //////////////////////////////////////////////////////////////////
  // 2x pclk is going to be used to drive IOSERDES2 DIVCLK
  //////////////////////////////////////////////////////////////////
  BUFG pclkx2bufg (.I(x2pllclk), .O(doublepclk));

  //////////////////////////////////////////////////////////////////
  // 10x pclk is used to drive IOCLK network so a bit rate reference
  // can be used by IOSERDES2
  //////////////////////////////////////////////////////////////////
  
  
  BUFPLL #(.DIVIDE(5)) ioclk_buf (.PLLIN(x10pllclk), .GCLK(doublepclk), .LOCKED(pll_lckd),.IOCLK(x10pclk), .SERDESSTROBE(serdesstrobe), .LOCK(bufpll_lock));

  

  decode dec_b (
    .reset        (reset),
    .pclk         (pclk),
    .doublepclk       (doublepclk),
    .x10pclk      (x10pclk),
    .serdesstrobe (serdesstrobe),
    .din_p        (blue_data_pos),
    .din_n        (blue_data_neg),
    .other_ch0_rdy(rdy_greench),
    .other_ch1_rdy(rdy_redch),
    .other_ch0_vld(vld_greench),
    .other_ch1_vld(vld_redch),

    .iamvld       (vld_bluech),
    .iamrdy       (rdy_bluech),
    .err_phaliign    (blue_psalgnerr),
    .c0           (hsync),
    .c1           (vsync),
    .de           (de_b),
    .dout_ser        (sdout_blue),
    .dout         (blue)) ;

  decode dec_g (
    .reset        (reset),
    .pclk         (pclk),
    .doublepclk       (doublepclk),
    .x10pclk      (x10pclk),
    .serdesstrobe (serdesstrobe),
    .din_p        (green_data_pos),
    .din_n        (green_data_neg),
    .other_ch0_rdy(rdy_bluech),
    .other_ch1_rdy(rdy_redch),
    .other_ch0_vld(vld_bluech),
    .other_ch1_vld(vld_redch),

    .iamvld       (vld_greench),
    .iamrdy       (rdy_greench),
    .err_phaliign    (green_psalgnerr),
    .c0           (),
    .c1           (),
    .de           (de_g),
    .dout_ser        (sdout_green),
    .dout         (green)) ;
    
  decode dec_r (
    .reset        (reset),
    .pclk         (pclk),
    .doublepclk       (doublepclk),
    .x10pclk      (x10pclk),
    .serdesstrobe (serdesstrobe),
    .din_p        (red_data_pos),
    .din_n        (red_data_neg),
    .other_ch0_rdy(rdy_bluech),
    .other_ch1_rdy(rdy_greench),
    .other_ch0_vld(vld_bluech),
    .other_ch1_vld(vld_greench),

    .iamvld       (vld_redch),
    .iamrdy       (rdy_redch),
    .err_phaliign    (red_psalgnerr),
    .c0           (),
    .c1           (),
    .de           (de_r),
    .dout_ser        (sdout_red),
    .dout         (red)) ;

  //assign dout_ser = {sdout_red[9:5], sdout_green[9:5], sdout_blue[9:5], sdout_red[4:0], sdout_green[4:0], sdout_blue[4:0]};
  assign de = de_b; assign reset = ~bufpll_lock;
  assign err_phaliign = red_psalgnerr | blue_psalgnerr | green_psalgnerr;
  assign rgb_data = {red,green, blue};

endmodule