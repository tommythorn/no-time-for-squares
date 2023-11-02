`timescale 1ns / 1ps

// https://www.mythtv.org/wiki/Modeline_Database#VESA_ModePool
// 640 	480 	75 Hz 	37.5 kHz 	ModeLine "640x480" 31.50 640 656 720 840 480 481 484 500 -HSync -VSync

module vga(input  wire       vga_clk,
           output reg        vga_hs = 0,
           output reg        vga_vs = 0,
           output wire [7:0] vga_r,
           output wire [7:0] vga_g,
           output wire [7:0] vga_b,
           output wire       vga_sync_n,
           output wire       vga_blank_n,

           output reg [7:0]  ledg = 'h 55,
           output reg [17:0] ledr = 'h 55);

   assign vga_sync_n = 1;
   assign vga_blank_n = 1;

   // Ultimately, Tiny VGA has but 6b color
   reg [5:0]                 vga_rgb;
   assign vga_r = vga_rgb[5:4] << 6;
   assign vga_g = vga_rgb[3:2] << 6;
   assign vga_b = vga_rgb[1:0] << 6;

   parameter      M1 = 12 'd 640;
   parameter      M2 = 12 'd 656;
   parameter      M3 = 12 'd 720;
   parameter      M4 = 12 'd 840;

   parameter      M5 = 12 'd 480;
   parameter      M6 = 12 'd 481;
   parameter      M7 = 12 'd 484;
   parameter      M8 = 12 'd 500;
   parameter      hs_neg = 1'd 1;
   parameter      vs_neg = 1'd 1;

   reg [9:0]      x;
   reg [9:0]      y;

   wire [1:0] command =
	      y == M5 ? 1 : // restart
	      x == M1 ? 2 : // stepy
	      x < M1 && y < M5 ? 3 : // stepx
	      0;

   wire	      hour_hit, min_hit, sec_hit;

   tile hour_tile(vga_clk, 54'h3ff7dfffb00097, 54'h3ff9d000880041, 54'h10bacff0ab114c, command, hour_hit);
   tile min_tile(vga_clk, 54'h3ffd3000980007, 54'hfc00013ff00, 54'h35daff3e68f8d3, command, min_hit);
   tile sec_tile(vga_clk, 54'hccffff7ff37, 54'h3ff8efffec0077, 54'h36e9e0217c8e55, command, sec_hit);

   always @(posedge vga_clk) begin
      vga_hs <= hs_neg ^ (M2 <= x && x < M3);
      vga_vs <= vs_neg ^ (M6 <= y && y < M7);

      if (x == M4 - 1) begin
         x <= 0;
         if (y == M8 - 1) begin
            y <= 0;
            {ledr,ledg} <= {ledr,ledg} + 1;
         end else
           y <= y + 1;
      end else
        x <= x + 1;

      if (x < M1 && y < M5) begin
         vga_rgb[5:4] <= 1;
         vga_rgb[3:2] <= 1;
         vga_rgb[1:0] <= 1;

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
