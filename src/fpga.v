// XXX Untested since the introduction of top
module fpga(input  wire        clock_50_MHz,
            output wire        vga_hs,
            output wire        vga_vs,
            output wire [7:0]  vga_r,
            output wire [7:0]  vga_g,
            output wire [7:0]  vga_b,
            output wire        vga_sync_n,
            output wire        vga_blank_n);

   wire [7:0]                  vga_rgb;

   assign vga_r = {vga_rgb[5:4], 6'd0};
   assign vga_g = {vga_rgb[3:2], 6'd0};
   assign vga_b = {vga_rgb[1:0], 6'd0};
   assign vga_sync_n = 1;
   assign vga_blank_n = 1;

   pll pll_inst(.inclk0(clock_50_MHz), .c0(vga_clk));
   vga vga_inst(vga_clk, vga_hs, vga_vs, vga_rgb);
endmodule
