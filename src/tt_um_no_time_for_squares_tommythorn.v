`default_nettype none
`timescale 1ns / 1ps

module tt_um_no_time_for_squares_tommythorn
  (input  wire [7:0] ui_in,    // Dedicated inputs
   output wire [7:0] uo_out,   // Dedicated outputs
   input  wire [7:0] uio_in,   // IOs: Input path -- UNUSED in this design.
   output wire [7:0] uio_out,  // IOs: Output path
   output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
   input  wire       ena,      // will go high when the design is enabled
   input  wire       clk,      // clock
   input  wire       rst_n     // reset_n - low to reset
   );

   // use bidirectionals as outputs
   assign uio_oe = 8'b11111111;
   assign uio_out [7:0] = 8'd0; // XXX TBD

   wire       vga_clk     = clk;
   wire       hour_button = ui_in[7];
   wire       min_button  = ui_in[6];
   wire [3:0] debugsel    = ui_in[3:0];

   wire       vga_hs;
   wire       vga_vs;
   wire [7:0] vga_r;
   wire [7:0] vga_g;
   wire [7:0] vga_b;
   wire       vga_sync_n;
   wire       vga_blank_n;

    // https://tinytapeout.com/specs/pinouts/#common-peripherals
   assign uo_out[0] = vga_r[7];
   assign uo_out[1] = vga_g[7];
   assign uo_out[2] = vga_b[7];
   assign uo_out[3] = vga_vs;
   assign uo_out[4] = vga_r[6];
   assign uo_out[5] = vga_g[6];
   assign uo_out[6] = vga_b[6];
   assign uo_out[7] = vga_hs;

   wire [7:0]  ledg;
   wire [17:0] ledr;

   vga vga_inst(vga_clk,
                vga_hs,
                vga_vs,
                vga_r,
                vga_g,
                vga_b,
                vga_sync_n,
                vga_blank_n,

                ledg,
                ledr);
endmodule
