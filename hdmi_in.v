/*Stereoscopic Vision System
Senior Design Project - Team 11
California State University, Sacramento
Spring 2015 / Fall 2015
----------------------------------------
HDMI_In Top Level
Authors:  Miad Rouhani
Description:
  TMDS TMDSdecoder
*/`timescale 1 ns / 1 ps

//`define DIRECTPASS

module hdmi_in (
  input wire        rstbtn_n,    //The pink reset button
  input wire        clk100,      //100 MHz osicallator
  input wire [3:0]  RX0_TMDS,
  input wire [3:0]  RX0_TMDSB,
  input wire [3:0]  RX1_TMDS,
  input wire [3:0]  RX1_TMDSB,

  output wire [3:0] TX0_TMDS,
  output wire [3:0] TX0_TMDSB,
  output wire [3:0] TX1_TMDS,
  output wire [3:0] TX1_TMDSB,

  input  wire [1:0] SW,

   output wire [7:0] LED,
   output DDR2CLK_P,
	output DDR2CLK_N,
	output DDR2CKE,
	output DDR2RASN,
	output DDR2CASN,
	output DDR2WEN,
	inout DDR2RZQ,
	inout DDR2ZIO,
	output [2:0] DDR2BA, // With the exception of these three. I changed the UCF file to do DDR2BA[0] etc., which is neater

	output [12:0] DDR2A,
	inout [15:0] DDR2DQ,

	inout DDR2UDQS_P,
	inout DDR2UDQS_N,
	inout DDR2LDQS_P,
	inout DDR2LDQS_N,
	output DDR2LDM,
	output DDR2UDM,
	output DDR2ODT,

	input clk, // 100 MHz oscillator = 10ns period (top level pin)

	input wire [2:0] c3_p0_cmd_instr,
	input wire [5:0] c3_p0_cmd_bl,
	input wire [29:0] c3_p0_cmd_byte_addr,
	input wire [3:0] c3_p0_wr_mask,
	input wire [31:0] c3_p0_wr_data,
	output wire [6:0] c3_p0_wr_count,
	output wire [31:0] c3_p0_rd_data,
	output wire [6:0] c3_p0_rd_count  ,
	input wire c3_p0_rd_en,
	output wire c3_p0_rd_empty,
	input wire c3_p0_wr_en,

	input wire c3_p0_cmd_en,

	output wire c3_calib_done,
	input wire reset
	);

	wire c3_rst0; // It's an output
	wire c3_clk0; // 32 MHz clock generated by PLL. Actually, this should be 78 MHz! Investigate 
);

 
  wire clk25, clk25m;

  BUFIO2 #(.DIVIDE_BYPASS("FALSE"), .DIVIDE(5))
  sysclk_div (.DIVCLK(clk25m), .IOCLK(), .SERDESSTROBE(), .I(clk100));

  BUFG clk25_buf (.I(clk25m), .O(clk25));

  wire [1:0] sws;

  synchro #(.INITIALIZE("LOGIC0"))
  synchro_sws_0 (.async(SW[0]),.sync(sws[0]),.clk(clk25));

  synchro #(.INITIALIZE("LOGIC0"))
  synchro_sws_1 (.async(SW[1]),.sync(sws[1]),.clk(clk25));

  wire [1:0] select = sws;

  reg [1:0] select_q = 2'b00;
  reg [1:0] switch = 2'b00;
  always @ (posedge clk25) begin
    select_q <= select;

    switch[0] = select[0] ^ select_q[0];
    switch[1] = select[1] ^ select_q[1];
  end

  /////////////////////////
  //
  // Input Port 0
  //
  /////////////////////////
  wire rx0_pclk;
  wire rx0_reset; 
  wire rx0_hsync;         
  wire rx0_vsync;          
  wire rx0_de;             

  wire [24:0] rgb_data;


  hdmi_decode hdmi_dec (
    //These are input ports
    .hdmi_Clk_pos   (RX0_TMDS[3]),
    .hdmi_Clk_neg   (RX0_TMDSB[3]),
    .blue_data_pos      (RX0_TMDS[0]),
    .green_data_pos     (RX0_TMDS[1]),
    .red_data_pos       (RX0_TMDS[2]),
    .blue_data_neg      (RX0_TMDSB[0]),
    .green_data_neg     (RX0_TMDSB[1]),
    .red_data_neg       (RX0_TMDSB[2]),
    .exrst       (~rstbtn_n),
 
    //These are output ports
    .reset       (rx0_reset),
    .pclk        (rx0_pclk),
    .hsync       (rx0_hsync),
    .vsync       (rx0_vsync),
    .de          (rx0_de),
	 .rgb_data (rgb_data)); 
	 
	 wire ramInput
	 always @ (posedge pclk)
	 begin
			c3_p0_wr_data<=rgb_data;
	 
	 end 

// Ram instantiation for the atlys ddr2 Ram 

 ddr2Ram # (
    .C3_P0_MASK_SIZE(4),
    .C3_P0_DATA_PORT_SIZE(32),
    .C3_P1_MASK_SIZE(4),
    .C3_P1_DATA_PORT_SIZE(32),
    .DEBUG_EN(0),
    .C3_MEMCLK_PERIOD(3200),
    .C3_CALIB_SOFT_IP("TRUE"),
    .C3_SIMULATION("FALSE"),
    .C3_RST_ACT_LOW(0),
    .C3_INPUT_CLK_TYPE("SINGLE_ENDED"),
    .C3_MEM_ADDR_ORDER("ROW_BANK_COLUMN"),
    .C3_NUM_DQ_PINS(16),
    .C3_MEM_ADDR_WIDTH(13),
    .C3_MEM_BANKADDR_WIDTH(3)
)
u_ddr2 (

    .c3_sys_clk           (c3_sys_clk),
  .c3_sys_rst_n           (c3_sys_rst_n),                        

  .mcb3_dram_dq           (mcb3_dram_dq),  
  .mcb3_dram_a            (mcb3_dram_a),  
  .mcb3_dram_ba           (mcb3_dram_ba),
  .mcb3_dram_ras_n        (mcb3_dram_ras_n),                        
  .mcb3_dram_cas_n        (mcb3_dram_cas_n),                        
  .mcb3_dram_we_n         (mcb3_dram_we_n),                          
  .mcb3_dram_odt          (mcb3_dram_odt),
  .mcb3_dram_cke          (mcb3_dram_cke),                          
  .mcb3_dram_ck           (mcb3_dram_ck),                          
  .mcb3_dram_ck_n         (mcb3_dram_ck_n),       
  .mcb3_dram_dqs          (mcb3_dram_dqs),                          
  .mcb3_dram_dqs_n        (mcb3_dram_dqs_n),
  .mcb3_dram_udqs         (mcb3_dram_udqs),    // for X16 parts                        
  .mcb3_dram_udqs_n       (mcb3_dram_udqs_n),  // for X16 parts
  .mcb3_dram_udm          (mcb3_dram_udm),     // for X16 parts
  .mcb3_dram_dm           (mcb3_dram_dm),
    .c3_clk0		        (c3_clk0),
  .c3_rst0		        (c3_rst0),
	
 
  .c3_calib_done          (c3_calib_done),
     .mcb3_rzq               (rzq3),
               
     .mcb3_zio               (zio3),
               
     .c3_p0_cmd_clk                          (c3_p0_cmd_clk),
   .c3_p0_cmd_en                           (c3_p0_cmd_en),
   .c3_p0_cmd_instr                        (c3_p0_cmd_instr),
   .c3_p0_cmd_bl                           (c3_p0_cmd_bl),
   .c3_p0_cmd_byte_addr                    (c3_p0_cmd_byte_addr),
   .c3_p0_cmd_empty                        (c3_p0_cmd_empty),
   .c3_p0_cmd_full                         (c3_p0_cmd_full),
   .c3_p0_wr_clk                           (c3_p0_wr_clk),
   .c3_p0_wr_en                            (c3_p0_wr_en),
   .c3_p0_wr_mask                          (c3_p0_wr_mask),
   .c3_p0_wr_data                          (c3_p0_wr_data),
   .c3_p0_wr_full                          (c3_p0_wr_full),
   .c3_p0_wr_empty                         (c3_p0_wr_empty),
   .c3_p0_wr_count                         (c3_p0_wr_count),
   .c3_p0_wr_underrun                      (c3_p0_wr_underrun),
   .c3_p0_wr_error                         (c3_p0_wr_error),
   .c3_p0_rd_clk                           (c3_p0_rd_clk),
   .c3_p0_rd_en                            (c3_p0_rd_en),
   .c3_p0_rd_data                          (c3_p0_rd_data),
   .c3_p0_rd_full                          (c3_p0_rd_full),
   .c3_p0_rd_empty                         (c3_p0_rd_empty),
   .c3_p0_rd_count                         (c3_p0_rd_count),
   .c3_p0_rd_overflow                      (c3_p0_rd_overflow),
   .c3_p0_rd_error                         (c3_p0_rd_error),
   .c3_p1_cmd_clk                          (c3_p1_cmd_clk),
   .c3_p1_cmd_en                           (c3_p1_cmd_en),
   .c3_p1_cmd_instr                        (c3_p1_cmd_instr),
   .c3_p1_cmd_bl                           (c3_p1_cmd_bl),
   .c3_p1_cmd_byte_addr                    (c3_p1_cmd_byte_addr),
   .c3_p1_cmd_empty                        (c3_p1_cmd_empty),
   .c3_p1_cmd_full                         (c3_p1_cmd_full),
   .c3_p1_wr_clk                           (c3_p1_wr_clk),
   .c3_p1_wr_en                            (c3_p1_wr_en),
   .c3_p1_wr_mask                          (c3_p1_wr_mask),
   .c3_p1_wr_data                          (c3_p1_wr_data),
   .c3_p1_wr_full                          (c3_p1_wr_full),
   .c3_p1_wr_empty                         (c3_p1_wr_empty),
   .c3_p1_wr_count                         (c3_p1_wr_count),
   .c3_p1_wr_underrun                      (c3_p1_wr_underrun),
   .c3_p1_wr_error                         (c3_p1_wr_error),
   .c3_p1_rd_clk                           (c3_p1_rd_clk),
   .c3_p1_rd_en                            (c3_p1_rd_en),
   .c3_p1_rd_data                          (c3_p1_rd_data),
   .c3_p1_rd_full                          (c3_p1_rd_full),
   .c3_p1_rd_empty                         (c3_p1_rd_empty),
   .c3_p1_rd_count                         (c3_p1_rd_count),
   .c3_p1_rd_overflow                      (c3_p1_rd_overflow),
   .c3_p1_rd_error                         (c3_p1_rd_error)
);
 
endmodule


