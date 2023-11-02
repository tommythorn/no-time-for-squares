`default_nettype none
`timescale 1ns / 1ps

// XXX Untested since the introduction of top
module fpga(input  wire        clock_50_MHz,
            input  wire [3:0]  key,

            output wire        vga_clk,
            output wire        vga_hs,
            output wire        vga_vs,
            output wire [7:0]  vga_r,
            output wire [7:0]  vga_g,
            output wire [7:0]  vga_b,
            output wire        vga_sync_n,
            output wire        vga_blank_n,

            output wire [8:0]  ledg,
            output wire [17:0] ledr);

   assign vga_sync_n = 1;
   assign vga_blank_n = 1;

   wire [7:0]                  vga_rgb;

   assign vga_r = {vga_rgb[5:4], 6'd0};
   assign vga_g = {vga_rgb[3:2], 6'd0};
   assign vga_b = {vga_rgb[1:0], 6'd0};
   assign vga_sync_n = 1;
   assign vga_blank_n = 1;

   wire                        hour_button   = ~key[3];
   wire                        minute_button = ~key[2];
   wire [3:0]                  debug_sel     = {2 'd 0, ~key[1:0]};
   wire [7:0]                  debug_out;
   assign ledg = debug_out;
   assign ledr = {vga_hs, vga_vs, debug_out, debug_sel};

   pll pll_inst(.inclk0(clock_50_MHz), .c0(vga_clk));


   reg [3:0]                   reset_countdown = 15;
   always @(posedge vga_clk)
     if (reset_countdown != 0)
       reset_countdown <= reset_countdown - 1;

   clock clock_inst(vga_clk,
                    reset_countdown != 0,
                    hour_button,
                    minute_button,
                    debug_sel,

                    vga_hs,
                    vga_vs,
                    vga_rgb,
                    debug_out);

endmodule
