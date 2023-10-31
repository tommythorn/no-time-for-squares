`timescale 1ns / 1ps

// https://www.mythtv.org/wiki/Modeline_Database#VESA_ModePool
// 640 	480 	75 Hz 	37.5 kHz 	ModeLine "640x480" 31.50 640 656 720 840 480 481 484 500 -HSync -VSync

module vga(input wire        clock_50_MHz,
           output reg        vga_hs = 0,
           output reg        vga_vs = 0,

           output wire       vga_clk,
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

   pll pll_inst(.inclk0(clock_50_MHz),
                .c0(vga_clk));

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

   reg [13:0]      boxa_x0, boxa_x1;
   reg [13:0]      boxb_x0, boxb_x1;

   wire [1:0] command =
	      y == M5 ? 1 : // restart
	      x == M1 ? 2 : // stepy
	      x < M1 && y < M5 ? 3 : // stepx
	      0;

   wire	      hour_hit, min_hit, sec_hit;

   tile hour_tile(clock_50_MHz, command, 54'h3ff7dfffb00097, 54'h3ff9d000880041, 54'h10bacff0ab114c, hour_hit);
   tile min_tile(clock_50_MHz, command, 54'h3ffd3000980007, 54'hfc00013ff00, 54'h35daff3e68f8d3, min_hit);
   tile sec_tile(clock_50_MHz, command, 54'hccffff7ff37, 54'h3ff8efffec0077, 54'h36e9e0217c8e55, sec_hit);

   always @(posedge vga_clk) begin
      vga_hs <= hs_neg ^ (M2 <= x && x < M3);
      vga_vs <= vs_neg ^ (M6 <= y && y < M7);

      if (x == M4 - 1) begin
         x <= 0;

         if (y == 50) begin
            boxa_x0 <= 423;
            boxa_x1 <= 603;
         end else if (50 < y && y < 90) begin
            boxa_x0 <= boxa_x0 + 14;
            boxa_x1 <= boxa_x1 + 11;
         end else begin
            boxa_x0 <= 0;
            boxa_x1 <= 0;
         end

         if (y == 40) begin
            boxb_x0 <= 600;
            boxb_x1 <= 700;
         end else if (40 < y && y < 90) begin
            boxb_x0 <= boxb_x0 - 10;
            boxb_x1 <= boxb_x1 - 9;
         end else begin
            boxb_x0 <= 0;
            boxb_x1 <= 0;
         end

         if (y == M8 - 1) begin
            y <= 0;
            {ledr,ledg} <= {ledr,ledg} + 1;
         end else
           y <= y + 1;
      end else
        x <= x + 1;

      if (x < M1 && y < M5) begin
         if (y < 120) begin
            vga_rgb[5:4] <= x ^ y;
            vga_rgb[3:2] <= (x >> 1) ^ y;
            vga_rgb[1:0] <= x ^ (y >> 1);
         end else if (y < 240)
           vga_rgb <= x[8:3];
         else if (y < 360)
           vga_rgb <= {x[6:3],x[8:7]};
         else
           vga_rgb <= x[7:2] ^ y[7:2];


         if (x == 0 || x == M1 - 1 || y == 0 || y == M5 - 1)
           vga_rgb <= 6'b001111;

         if (boxa_x0[13:4] <= x && x < boxa_x1[13:4])
           vga_rgb <= 6'b110000;

         if (boxb_x0[13:4] <= x && x < boxb_x1[13:4])
           vga_rgb <= 6'b001100;

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
