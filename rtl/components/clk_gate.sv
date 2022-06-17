// Copyright Supranational LLC
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

// Clock gating module

module clk_gate
  (
   input  logic clk_i,
   input  logic test_i,
   input  logic en_i,
   output logic clk_o
   );

`ifdef FPGA

  // FPGAs cannot use fine-grain clock gating.
  assign clk_o = clk_i;

`else

  logic clk_en_q;

  always_latch begin
    if (!clk_i) begin
      clk_en_q <= en_i || test_i;
    end
  end

  assign clk_o = clk_i && clk_en_q;

`endif

endmodule
