//======================================================================================================
// A GHRD for QMTECH Cyclone 5 SoC NANO Board, with Dual SDRAM chips
//======================================================================================================

module QMTECH_C5SOC_NANO_GHRD(

	// ============= CLOCKs ===================
	input               FPGA_CLK1_50,
	input               FPGA_CLK2_50,
	input               FPGA_CLK3_50,

	// ============== FPGA ===================
	// BUTTONs (active-low)
	input    [ 1: 0]    KEY,
	// LED output(s) (active-high)
	output              LED,
    // Toggle (DIP) Switches
	input    [ 3: 0]    DIPSW,

	// ================= HPS ===================
	// SD-Card
	output              HPS_SD_CLK,
	inout               HPS_SD_CMD,
	inout    [ 3: 0]    HPS_SD_DATA,
	// DDR3 Memory
	output   [14: 0]    HPS_DDR3_ADDR,
	output   [ 2: 0]    HPS_DDR3_BA,
	output        	   	HPS_DDR3_CAS_N,
	output        	   	HPS_DDR3_CKE,
	output        	   	HPS_DDR3_CK_N,
	output        	   	HPS_DDR3_CK_P,
	output        	   	HPS_DDR3_CS_N,
	output   [ 3: 0]    HPS_DDR3_DM,
	inout    [31: 0]    HPS_DDR3_DQ,
	inout    [ 3: 0]    HPS_DDR3_DQS_N,
	inout    [ 3: 0]    HPS_DDR3_DQS_P,
	output        		  HPS_DDR3_ODT,
	output              HPS_DDR3_RAS_N,
	output              HPS_DDR3_RESET_N,
	input               HPS_DDR3_RZQ,
	output              HPS_DDR3_WE_N,
    // USB-Host Port (Peripherals)
	input               HPS_USB_CLKOUT,
  inout    [ 7: 0]    HPS_USB_DATA,
  input               HPS_USB_DIR,
  input               HPS_USB_NXT,
  output              HPS_USB_STP,
	// UART - Serial Console (UBoot/Linux-Shell) 
	input               HPS_UART_RX,
  output              HPS_UART_TX,
	// Ethernet Port 
	output              HPS_ENET_GTX_CLK,
  inout               HPS_ENET_INT_N,
  output              HPS_ENET_MDC,
  inout               HPS_ENET_MDIO,
  input               HPS_ENET_RX_CLK,
  input    [ 3: 0]    HPS_ENET_RX_DATA,
  input               HPS_ENET_RX_DV,
  output   [ 3: 0]    HPS_ENET_TX_DATA,
  output              HPS_ENET_TX_EN,
  // I2C Buses
  inout               HPS_I2C0_SCLK,
  inout               HPS_I2C0_SDAT,
  inout               HPS_I2C1_SCLK,
  inout               HPS_I2C1_SDAT,
	// SPI Buses
	output              HPS_SPIM_CLK,
  input               HPS_SPIM_MISO,
  output              HPS_SPIM_MOSI,
  inout               HPS_SPIM_SS,
	// GPIOs 
  inout               HPS_KEY,
  inout               HPS_LED
);



//=======================================================
//  LOGIC/WIRE declarations
//=======================================================
wire           hps_fpga_reset_n;
wire  [ 1: 0]  fpga_debounced_buttons; // [0] - KEY[0] ; [1] - KEY[1]
wire           fpga_led_internal;
wire  [ 2: 0]  hps_reset_req; // [0] - HPS cold reset; [1] - HPS warm reset; [2] - HPS debug reset
wire           hps_cold_reset;
wire           hps_warm_reset;
wire           hps_debug_reset;
wire  [27: 0]  stm_hw_events;
wire           fpga_clk_50;
// connection to internal logics
assign LED         = fpga_led_internal; // there is only a single led 
assign fpga_clk_50 = FPGA_CLK1_50;
assign stm_hw_events = {{21{1'b0}}, DIPSW, fpga_led_internal, fpga_debounced_buttons}; // This is active-high input


//=======================================================
//  Structural coding
//=======================================================
soc_system CV_SOC_SYSTEM_INST(
  // Clock & Reset:
  .in_clk_clk                         (fpga_clk_50),         //                  in_clk.clk
  .in_reset_reset_n                   (hps_fpga_reset_n),    //                in_reset.reset_n

  // HPS-Internals Partition:
  .hps_h2f_reset_reset_n              (hps_fpga_reset_n),     
  .hps_f2h_cold_reset_req_reset_n     (~hps_cold_reset),     //  hps_f2h_cold_reset_req.reset_n
  .hps_f2h_warm_reset_req_reset_n     (~hps_warm_reset),     //  hps_f2h_warm_reset_req.reset_n
  .hps_f2h_debug_reset_req_reset_n    (~hps_debug_reset),    //  hps_f2h_debug_reset_req.reset_n
  .hps_f2h_stm_hw_events_stm_hwevents (stm_hw_events),       //  hps_f2h_stm_hw_events.stm_hwevents
  
  // HPS-SD Card Partition: 
  .hps_io_hps_io_sdio_inst_CMD        (HPS_SD_CMD),             //                        .hps_io_sdio_inst_CMD
  .hps_io_hps_io_sdio_inst_D0         (HPS_SD_DATA[0]),         //                        .hps_io_sdio_inst_D0
  .hps_io_hps_io_sdio_inst_D1         (HPS_SD_DATA[1]),         //                        .hps_io_sdio_inst_D1
  .hps_io_hps_io_sdio_inst_CLK        (HPS_SD_CLK),             //                        .hps_io_sdio_inst_CLK
  .hps_io_hps_io_sdio_inst_D2         (HPS_SD_DATA[2]),         //                        .hps_io_sdio_inst_D2
  .hps_io_hps_io_sdio_inst_D3         (HPS_SD_DATA[3]),         //                        .hps_io_sdio_inst_D3

  // HPS-DDR3 Partition:
  .hps_memory_mem_a                   (HPS_DDR3_ADDR),          //              hps_memory.mem_a
  .hps_memory_mem_ba                  (HPS_DDR3_BA),            //                        .mem_ba
  .hps_memory_mem_ck                  (HPS_DDR3_CK_P),          //                        .mem_ck
  .hps_memory_mem_ck_n                (HPS_DDR3_CK_N),          //                        .mem_ck_n
  .hps_memory_mem_cke                 (HPS_DDR3_CKE),           //                        .mem_cke
  .hps_memory_mem_cs_n                (HPS_DDR3_CS_N),          //                        .mem_cs_n
  .hps_memory_mem_ras_n               (HPS_DDR3_RAS_N),         //                        .mem_ras_n
  .hps_memory_mem_cas_n               (HPS_DDR3_CAS_N),         //                        .mem_cas_n
  .hps_memory_mem_we_n                (HPS_DDR3_WE_N),          //                        .mem_we_n
  .hps_memory_mem_reset_n             (HPS_DDR3_RESET_N),       //                        .mem_reset_n
  .hps_memory_mem_dq                  (HPS_DDR3_DQ),            //                        .mem_dq
  .hps_memory_mem_dqs                 (HPS_DDR3_DQS_P),         //                        .mem_dqs
  .hps_memory_mem_dqs_n               (HPS_DDR3_DQS_N),         //                        .mem_dqs_n
  .hps_memory_mem_odt                 (HPS_DDR3_ODT),           //                        .mem_odt
  .hps_memory_mem_dm                  (HPS_DDR3_DM),            //                        .mem_dm
  .hps_memory_oct_rzqin               (HPS_DDR3_RZQ),           //                        .oct_rzqin

  // HPS-UART (Serial-8N1 Shell Console) Partition:
  .hps_io_hps_io_uart0_inst_RX        (HPS_UART_RX),            //                        .hps_io_uart0_inst_RX
  .hps_io_hps_io_uart0_inst_TX        (HPS_UART_TX),            //                        .hps_io_uart0_inst_TX

  // HPS-USB Partition
  .hps_io_hps_io_usb1_inst_D0         (HPS_USB_DATA[0]),        //                        .hps_io_usb1_inst_D0
  .hps_io_hps_io_usb1_inst_D1         (HPS_USB_DATA[1]),        //                        .hps_io_usb1_inst_D1
  .hps_io_hps_io_usb1_inst_D2         (HPS_USB_DATA[2]),        //                        .hps_io_usb1_inst_D2
  .hps_io_hps_io_usb1_inst_D3         (HPS_USB_DATA[3]),        //                        .hps_io_usb1_inst_D3
  .hps_io_hps_io_usb1_inst_D4         (HPS_USB_DATA[4]),        //                        .hps_io_usb1_inst_D4
  .hps_io_hps_io_usb1_inst_D5         (HPS_USB_DATA[5]),        //                        .hps_io_usb1_inst_D5
  .hps_io_hps_io_usb1_inst_D6         (HPS_USB_DATA[6]),        //                        .hps_io_usb1_inst_D6
  .hps_io_hps_io_usb1_inst_D7         (HPS_USB_DATA[7]),        //                        .hps_io_usb1_inst_D7
  .hps_io_hps_io_usb1_inst_CLK        (HPS_USB_CLKOUT),         //                        .hps_io_usb1_inst_CLK
  .hps_io_hps_io_usb1_inst_STP        (HPS_USB_STP),            //                        .hps_io_usb1_inst_STP
  .hps_io_hps_io_usb1_inst_DIR        (HPS_USB_DIR),            //                        .hps_io_usb1_inst_DIR
  .hps_io_hps_io_usb1_inst_NXT        (HPS_USB_NXT), 

  // HPS-Ethernet Partition:
  .hps_io_hps_io_emac1_inst_TX_CLK    (HPS_ENET_GTX_CLK),       //                  hps_io.hps_io_emac1_inst_TX_CLK
  .hps_io_hps_io_emac1_inst_TXD0      (HPS_ENET_TX_DATA[0]),    //                        .hps_io_emac1_inst_TXD0
  .hps_io_hps_io_emac1_inst_TXD1      (HPS_ENET_TX_DATA[1]),    //                        .hps_io_emac1_inst_TXD1
  .hps_io_hps_io_emac1_inst_TXD2      (HPS_ENET_TX_DATA[2]),    //                        .hps_io_emac1_inst_TXD2
  .hps_io_hps_io_emac1_inst_TXD3      (HPS_ENET_TX_DATA[3]),    //                        .hps_io_emac1_inst_TXD3
  .hps_io_hps_io_emac1_inst_MDIO      (HPS_ENET_MDIO),          //                        .hps_io_emac1_inst_MDIO
  .hps_io_hps_io_emac1_inst_MDC       (HPS_ENET_MDC),           //                        .hps_io_emac1_inst_MDC
  .hps_io_hps_io_emac1_inst_TX_CTL    (HPS_ENET_TX_EN),         //                        .hps_io_emac1_inst_TX_CTL
  .hps_io_hps_io_emac1_inst_RX_CTL    (HPS_ENET_RX_DV),         //                        .hps_io_emac1_inst_RX_CTL
  .hps_io_hps_io_emac1_inst_RX_CLK    (HPS_ENET_RX_CLK),        //                        .hps_io_emac1_inst_RX_CLK
  .hps_io_hps_io_emac1_inst_RXD0      (HPS_ENET_RX_DATA[0]),    //                        .hps_io_emac1_inst_RXD0
  .hps_io_hps_io_emac1_inst_RXD1      (HPS_ENET_RX_DATA[1]),    //                        .hps_io_emac1_inst_RXD1
  .hps_io_hps_io_emac1_inst_RXD2      (HPS_ENET_RX_DATA[2]),    //                        .hps_io_emac1_inst_RXD2
  .hps_io_hps_io_emac1_inst_RXD3      (HPS_ENET_RX_DATA[3]),    //                        .hps_io_emac1_inst_RXD3 

  // HPS-SPI Partition:
  .hps_io_hps_io_spim1_inst_CLK       (HPS_SPIM_CLK),           //                        .hps_io_spim1_inst_CLK
  .hps_io_hps_io_spim1_inst_MOSI      (HPS_SPIM_MOSI),          //                        .hps_io_spim1_inst_MOSI
  .hps_io_hps_io_spim1_inst_MISO      (HPS_SPIM_MISO),          //                        .hps_io_spim1_inst_MISO
  .hps_io_hps_io_spim1_inst_SS0       (HPS_SPIM_SS),            //                        .hps_io_spim1_inst_SS0

  .hps_io_hps_io_i2c0_inst_SDA        (HPS_I2C0_SDAT),          //                        .hps_io_i2c0_inst_SDA
  .hps_io_hps_io_i2c0_inst_SCL        (HPS_I2C0_SCLK),          //                        .hps_io_i2c0_inst_SCL
  .hps_io_hps_io_i2c1_inst_SDA        (HPS_I2C1_SDAT),          //                        .hps_io_i2c1_inst_SDA
  .hps_io_hps_io_i2c1_inst_SCL        (HPS_I2C1_SCLK),          //                        .hps_io_i2c1_inst_SCL

  // HPS-External I/O Partition:
  .hps_io_hps_io_gpio_inst_GPIO35     (HPS_ENET_INT_N),         //                        .hps_io_gpio_inst_GPIO35  
  .hps_io_hps_io_gpio_inst_GPIO54     (HPS_KEY),                //                        .hps_io_gpio_inst_GPIO54
  .hps_io_hps_io_gpio_inst_GPIO53     (HPS_LED),                //                        .hps_io_gpio_inst_GPIO53
 
  // FPGA Partition:
  .button_pio_ext_export       (fpga_debounced_buttons), //   cv_soc_button_pio_ext.export
  .led_pio_ext_export          (fpga_led_internal),      //      cv_soc_led_pio_ext.export
  .dipsw_pio_ext_export        (DIPSW)                   //    cv_soc_dipsw_pio_ext.export
);

// Debounce logic to clean out glitches within 1 [ms]
debounce 
#(
  .WIDTH(2),
  .POLARITY("LOW"),
  .TIMEOUT(50000),   // at 50Mhz this is a debounce time of 1 [ms]
  .TIMEOUT_WIDTH(16) // ceil(log2(TIMEOUT))
)DEBOUNCE_INST(
  .clk(fpga_clk_50),
  .reset_n(hps_fpga_reset_n),
  .data_in(KEY),
  .data_out(fpga_debounced_buttons)
);

// Use Altsource_probe megawizard IP instance, to allow a designer to manually trigger HPS (Hard Processor System) signals - in this case resets - via the Quartus JTAG interface.
hps_reset HPS_RESET_INST(
  .source_clk(fpga_clk_50),
  .source(hps_reset_req)
);

// HPS - Cold reset (edge pulse driver)
altera_edge_detector
#(
  .PULSE_EXT(6),
  .EDGE_TYPE(1),
  .IGNORE_RST_WHILE_BUSY(1)
) HPS_COLD_RESET_PULSE(
  .clk(fpga_clk_50),
  .rst_n(hps_fpga_reset_n),
  .signal_in(hps_reset_req[0]),
  .pulse_out(hps_cold_reset)
);

// HPS - Warm reset (edge pulse driver)
altera_edge_detector
#(
  .PULSE_EXT(6),
  .EDGE_TYPE(1),
  .IGNORE_RST_WHILE_BUSY(1)
) HPS_WARM_RESET_PULSE(
  .clk(fpga_clk_50),
  .rst_n(hps_fpga_reset_n),
  .signal_in(hps_reset_req[1]),
  .pulse_out(hps_warm_reset)
);

// HPS - Debug reset (edge pulse driver)
altera_edge_detector
#(
  .PULSE_EXT(6),
  .EDGE_TYPE(1),
  .IGNORE_RST_WHILE_BUSY(1)
) HPS_DEBUG_RESET_PULSE(
  .clk(fpga_clk_50),
  .rst_n(hps_fpga_reset_n),
  .signal_in(hps_reset_req[2]),
  .pulse_out(hps_debug_reset)
);

// A simple LED counter, that will blink a single LED - hearbeat 
// logic [25: 0] counter;
// logic led_level;
// always @(posedge fpga_clk_50 or negedge hps_fpga_reset_n) begin
//     if (~hps_fpga_reset_n) begin
//         counter <= 0;
//         led_level <= 0;
//     end
//
//     else if (counter == 24999999) begin
//         counter <= 0;
//         led_level <= ~led_level;
//     end
//     else
//         counter <= counter + 1'b1;
// end

// assign LED = led_level;

endmodule
