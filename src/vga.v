`default_nettype none
`timescale 1ns / 1ps

// https://www.mythtv.org/wiki/Modeline_Database#VESA_ModePool
// 640 	480 	75 Hz 	37.5 kHz 	ModeLine "640x480" 31.50 640 656 720 840 480 481 484 500 -HSync -VSync

// The implementation of the VGA timing signals is very naive, but
// this way is easy to understand and immediately relatable to the
// ModeLine parameters.
module vga(input  wire      vga_clk,
           output reg       vga_hs,
           output reg       vga_vs,
           output reg [5:0] vga_rgb);

   parameter      M1 = 10 'd 640;
   parameter      M2 = 10 'd 656;
   parameter      M3 = 10 'd 720;
   parameter      M4 = 10 'd 840;
   parameter      M5 = 10 'd 480;
   parameter      M6 = 10 'd 481;
   parameter      M7 = 10 'd 484;
   parameter      M8 = 10 'd 500;
   parameter      hs_neg = 1'd 1;
   parameter      vs_neg = 1'd 1;

   reg [9:0]      x, y;

   wire [1:0] command =
	      y == M5 ? 1 : // restart
	      x == M1 ? 2 : // stepy
	      x < M1 && y < M5 ? 3 : // stepx
	      0;

   wire	      hour_hit, min_hit, sec_hit;

   // Three precomputed triangles; XXX get edgeeqn integrated
   tile hour_tile(vga_clk, 54'h3ff7dfffb00097, 54'h3ff9d000880041, 54'h10bacff0ab114c, command, hour_hit);
   tile min_tile(vga_clk, 54'h3ffd3000980007, 54'hfc00013ff00, 54'h35daff3e68f8d3, command, min_hit);
   tile sec_tile(vga_clk, 54'hccffff7ff37, 54'h3ff8efffec0077, 54'h36e9e0217c8e55, command, sec_hit);

   always @(posedge vga_clk) begin
      vga_hs <= hs_neg ^ (M2 <= x && x < M3); // XXX we can eliminate the relations
      vga_vs <= vs_neg ^ (M6 <= y && y < M7);

      if (x == M4 - 1) begin
         x <= 0;
         if (y == M8 - 1)
            y <= 0;
         else
           y <= y + 1;
      end else
        x <= x + 1;

      if (x < M1 && y < M5) begin // XXX we can eliminate the relations
         vga_rgb <= 6'b010101; // grey

	 // XXX this is a delayed signal, will fix later
	 if (sec_hit)
	   vga_rgb <= 6'b111111; // white
	 else if (hour_hit)
	   vga_rgb <= 6'b110000; // red
	 else if (min_hit)
	   vga_rgb <= 6'b111100; // yellow?

      end else
        vga_rgb <= 0;
   end
endmodule
