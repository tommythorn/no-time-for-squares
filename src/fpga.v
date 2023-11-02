// XXX Untested since the introduction of top
module fpga(input  wire        clock_50_MHz,
            output wire        vga_hs,
            output wire        vga_vs,
            output wire [7:0]  vga_r,
            output wire [7:0]  vga_g,
            output wire [7:0]  vga_b,
            output wire        vga_sync_n,
            output wire        vga_blank_n,

            output wire [7:0]  ledg,
            output wire [17:0] ledr);


   pll pll_inst(.inclk0(clock_50_MHz),
                .c0(vga_clk));

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
