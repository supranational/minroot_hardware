// Copyright Supranational LLC
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

module minroot_vdf_x
  import ahb_pkg::*;
  import csr_pkg::*;
  #(
    parameter unsigned   N = 3,
    parameter type haddr_t = csr_addr_e,
    parameter type hdata_t = csr_data_t
    )
  (
   input  logic            hclk_i,
   input  logic            hreset_ni,
   input  logic    [N-1:0] hsel_i,
   input  haddr_t  [N-1:0] haddr_i,
   input  htrans_e         htrans_i,
   input  hburst_e         hburst_i,
   input  hsize_t          hsize_i,
   input  hprot_t          hprot_i,
   input  logic            hmastlock_i,
   input  logic            hwrite_i,
   input  hdata_t          hwdata_i,
   output hdata_t  [N-1:0] hrdata_o,
   output hresp_e  [N-1:0] hresp_o,
   output logic    [N-1:0] hready_o,

   input  logic            alarm_i,
   input  logic            clk_i
   );

  logic [N-1:0]                            mr_rst_n;
  logic [N-1:0]                            mr_clk_en;
  logic [N-1:0]                            mr_start;
  logic [N-1:0][mrt_pkg::IterBits - 1:0]   mr_starting_iter;
  logic [N-1:0][mrt_pkg::IterBits - 1:0]   mr_iters;
  mrt_pkg::poly_t [N-1:0]                  mr_x_begin;
  mrt_pkg::poly_t [N-1:0]                  mr_y_begin;
  mrt_pkg::poly_t [N-1:0]                  mr_x_end;
  mrt_pkg::poly_t [N-1:0]                  mr_y_end;
  logic [N-1:0][mrt_pkg::IterBits - 1:0]   mr_cur_iter;
  logic [N-1:0]                            mr_iter_done;
  
  for (genvar gv_i=0; gv_i<N; gv_i++) begin : gen_minroot_vdf_i
    minroot_vdf_i _minroot_vdf_i
      (
       .hclk_i,
       .hreset_ni,
       .hsel_i(hsel_i[gv_i]),
       .haddr_i(haddr_i[gv_i]),
       .htrans_i,
       .hburst_i,
       .hsize_i,
       .hprot_i,
       .hmastlock_i,
       .hwrite_i,
       .hwdata_i,
       .hrdata_o(hrdata_o[gv_i]),
       .hresp_o(hresp_o[gv_i]),
       .hready_o(hready_o[gv_i]),

       .alarm_i,
       .clk_i,

       .mr_rst_no(mr_rst_n[gv_i]),
       .mr_clk_en_o(mr_clk_en[gv_i]),
       .mr_start_o(mr_start[gv_i]),
       .mr_starting_iter_o(mr_starting_iter[gv_i]),
       .mr_iters_o(mr_iters[gv_i]),
       .mr_x_begin_o(mr_x_begin[gv_i]),
       .mr_y_begin_o(mr_y_begin[gv_i]),
       .mr_x_end_i(mr_x_end[gv_i]),
       .mr_y_end_i(mr_y_end[gv_i]),
       .mr_cur_iter_i(mr_cur_iter[gv_i]),
       .mr_iter_done_i(mr_iter_done[gv_i])
       );
  end


  // For the clock and reset of the de-denseified pipeline we
  // will use the reset/clk_en for instance 0.

  logic engine_clk;
  clk_gate _engine_clk
    (
     .clk_i,
     .test_i(1'b0),
     .en_i(mr_clk_en[0]),
     .clk_o(engine_clk)
     );

  logic engine_rst_n;
  assign engine_rst_n = mr_rst_n[0];

  minroot_engine_x #(.N(N)) _minroot_engine_x 
    (
     .clk_i(engine_clk),
     .rst_ni(engine_rst_n),
     .start_i(mr_start),
     .starting_iter_i(mr_starting_iter),
     .iters_i(mr_iters),
     .x_i(mr_x_begin),
     .y_i(mr_y_begin),
     .x_o(mr_x_end),
     .y_o(mr_y_end),
     .cur_iter_o(mr_cur_iter),
     .iter_done_o(mr_iter_done)
     );

endmodule
