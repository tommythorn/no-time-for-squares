`timescale 1ns / 1ps

// https://www.mythtv.org/wiki/Modeline_Database#VESA_ModePool
// 640 	480 	75 Hz 	37.5 kHz 	ModeLine "640x480" 31.50 640 656 720 840 480 481 484 500 -HSync -VSync

module vga(input            clock_50_MHz,
           output reg       vga_hs = 0,
           output reg       vga_vs = 0,

           output wire      vga_clk,
           output reg [7:0] vga_r,
           output reg [7:0] vga_g,
           output reg [7:0] vga_b,
           output wire      vga_sync_n,
           output wire      vga_blank_n,

           output reg [7:0] ledg = 'h 55,
           output reg [17:0] ledr = 'h 55);

   assign vga_sync_n = 1;
   assign vga_blank_n = 1;

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
         vga_r <= x ^ y;
         vga_g <= (x >> 1) ^ y;
         vga_b <= x ^ (y >> 1);

         if (y < 160)
           {vga_r,vga_b,vga_g} <= {8'd0,8'd0,x[7:0]};
         else if (y < 320)
           {vga_r,vga_b,vga_g} <= {8'd0,x[7:0],8'd0};
         else
           {vga_r,vga_b,vga_g} <= {x[7:0],8'd0,8'd0};


         if (x == 0 || x == M1 - 1 || y == 0 || y == M5 - 1)
           {vga_r,vga_g,vga_b} <= 24'h00FFFF;

         if (boxa_x0[13:4] <= x && x < boxa_x1[13:4])
           {vga_r,vga_g,vga_b} <= 24'hFF0000;

         if (boxb_x0[13:4] <= x && x < boxb_x1[13:4])
           {vga_r,vga_g,vga_b} <= 24'h00FF00;

      end else
        {vga_r,vga_b,vga_g} <= 0;
   end
endmodule
