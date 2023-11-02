`default_nettype none
`timescale 1ns / 1ps

// Edge equation <x1,y1>, <x2,y2> -> <a, b, c>
// where
//    a = y1 - y2;
//    b = x2 - x1;
//    c = -(a * (x1 + x2) + b * (y1 + y2)) / 2;

`define W 18

`ifdef SIM
module tb;

   reg clock = 1;

   always #5 clock = 1 - clock;

   reg trigger = 0;

   wire valid;
   wire [`W-1:0] a, b, c;

   reg [10:0]    x1, y1, x2, y2;
   edgeeqn inst(clock, trigger, x1, y1, x2, y2, valid, a, b, c);

   initial begin
      $dumpfile("edgeeqn.vcd");
      $dumpvars(0, inst);

      x1 = 249; y1 = 116; x2 = 347; y2 = 247;
      @(negedge clock) trigger = 1;
      @(negedge clock) trigger = 0;
      wait (valid);
      if ($signed(a) != -131 || $signed(b) != 98 || $signed(c) != 21251) begin
         $display("FAILURE: %d %d %d %d", valid, a, b, c);
         $finish;
      end

      x1 = 347; y1 = 247; x2 = 313; y2 = 267;
      @(negedge clock) trigger = 1;
      @(negedge clock) trigger = 0;
      wait (valid);
      if ($signed(a) != -20 || $signed(b) != -34 || $signed(c) != 15338) begin
         $display("FAILURE: %d %d %d %d", valid, a, b, c);
         $finish;
      end

      x1 = 313; y1 = 267; x2 = 249; y2 = 116;
      @(negedge clock) trigger = 1;
      @(negedge clock) trigger = 0;
      wait (valid);
      if ($signed(a) != 151 || $signed(b) != -64 || $signed(c) != -30175) begin
         $display("FAILURE: %d %d %d %d", valid, a, b, c);
         $finish;
      end



      $display("ALL TEST PASS");
      $finish;
   end
endmodule
`endif

module edgeeqn(input wire          clock,
               input wire          trigger,
               input wire [9:0]    x1,
               input wire [9:0]    y1,
               input wire [9:0]    x2,
               input wire [9:0]    y2,

               output wire         valid,
               output reg [`W-1:0] a, // That's actually three signed 18-bit values
               output reg [`W-1:0] b,
               output reg [`W-1:0] c);

   reg [`W:0]                      t1, t2;
   reg [2:0]                       state = 0;
   assign valid = state == 0;

   always @(posedge clock)
     $display("%05d  trigger %d t1 %d t2 %d   a %d b %d  c %d valid %d", $time,
              trigger, $signed(t1), $signed(t2), $signed(a), $signed(b), $signed(c), valid);


   always @(posedge clock)
     case (state)
       0: if (trigger) begin
          a <= y1 - y2;
          b <= x2 - x1;
          t1 <= x1 + x2;
          t2 <= y1 + y2;
          state <= 1;
       end
       1: begin
          t1 <= $signed(a) * $signed(t1);
          t2 <= $signed(b) * $signed(t2);
          state <= 2;
       end
       2: state <= 3;
       3: begin
          c <= -(t1 + t2)/2;
          state <= 0;
       end
     endcase
endmodule
