// Copyright Supranational LLC
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

module minroot_engine_x
  #(
    parameter unsigned N = 1
    )
  (
   input  logic                                  clk_i,
   input  logic                                  rst_ni,
   input  logic [N-1:0]                          start_i,
   input  logic [N-1:0][mrt_pkg::IterBits - 1:0] starting_iter_i,
   input  logic [N-1:0][mrt_pkg::IterBits - 1:0] iters_i,
   input  mrt_pkg::poly_t [N-1:0]                x_i,
   input  mrt_pkg::poly_t [N-1:0]                y_i,
   output mrt_pkg::poly_t [N-1:0]                x_o,
   output mrt_pkg::poly_t [N-1:0]                y_o,
   output logic [N-1:0][mrt_pkg::IterBits - 1:0] cur_iter_o,
   output logic [N-1:0]                          iter_done_o
  );

  logic [N-1:0]           pr_start;
  mrt_pkg::poly_t [N-1:0] pr_x_begin;
  logic [N-1:0]           pr_done;
  logic                   pr_sync;
  mrt_pkg::poly_t [N-1:0] pr_x_end;
  
  for (genvar i=0; i<N; i++) begin : gen_minroot_engine_i
    minroot_engine_i _minroot_engine_i
       (
        .clk_i,
        .rst_ni,
        .start_i(start_i[i]),
        .starting_iter_i(starting_iter_i[i]),
        .iters_i(iters_i[i]),
        .x_i(x_i[i]),
        .y_i(y_i[i]),
        .cur_iter_o(cur_iter_o[i]),
        .x_o(x_o[i]),
        .y_o(y_o[i]),
        .iter_done_o(iter_done_o[i]),
        .pr_start_o(pr_start[i]),
        .pr_x_o(pr_x_begin[i]),
        .pr_done_i(pr_done[i]),
        .pr_sync_i(pr_sync),
        .pr_x_i(pr_x_end[i])
        );
  end

  penta_root_x 
    #(
      .N(N),
      .SYNC(1)
      ) 
  i_penta_root_x 
    (
     .clk_i,
     .rst_ni,
     .start_i(pr_start),
     .x_i(pr_x_begin),
     .x_o(pr_x_end),
     .done_o(pr_done),
     .sync_o(pr_sync)
     );

endmodule
