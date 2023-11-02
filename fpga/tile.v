`timescale 1ns / 1ps

// Basic "Render me a triangle" render
// Every clock one of three things can happen:
// - restart
// - stepy
// - stepx
// Only the latter produces a pixel

`define W 18

module tile(input wire clock,
	    // Render equation parameters; changing them should be followed by a restart
	    input wire [`W*3-1:0] a, // That's actually three signed 18-bit values
	    input wire [`W*3-1:0] b,
	    input wire [`W*3-1:0] c,

	    input wire [1:0]  command, // 0 nop, 1 restart, 2 stepy, 3 stepx

	    output wire	      inside_triangle);

   reg [`W*3-1:0]	      e0, e;

   assign inside_triangle = !(e[`W-1] | e[`W*2-1] | e[`W*3-1]); // If all values in e are positive

   always @(posedge clock)
     if (command == 1) begin
	e0 <= c;
	e <= c;
     end else if (command == 2) begin
	// CSE works, right?
	e0 <= {e0[`W*3-1:`W*2] + b[`W*3-1:`W*2], e0[`W*2-1:`W] + b[`W*2-1:`W], e0[`W-1:0] + b[`W-1:0]};
	e <= {e0[`W*3-1:`W*2] + b[`W*3-1:`W*2], e0[`W*2-1:`W] + b[`W*2-1:`W], e0[`W-1:0] + b[`W-1:0]};
     end else if (command == 3) begin
	e <= {e[`W*3-1:`W*2] + a[`W*3-1:`W*2], e[`W*2-1:`W] + a[`W*2-1:`W], e[`W-1:0] + a[`W-1:0]};
     end
endmodule


`ifdef SIM
// FINE!  I'll simulate this

module tb;
   reg clock = 1;
   always #5 clock = 1 - clock;

   reg [1:0] command = 0;
   wire      hour_hit;

   tile hour_tile(clock, 54'h3ff7dfffb00097, 54'h3ff9d000880041, 54'h10bacff0ab114c, command, hour_hit);
   initial begin
      $monitor(clock, command, hour_hit);

      #10 command = 1;
      @(posedge clock);
      command = 0;

      #10 command = 3;
      @(posedge clock);
      @(posedge clock);
      @(posedge clock);
      @(posedge clock);
      command = 0;
      #100 $finish;
   end
endmodule
`endif
