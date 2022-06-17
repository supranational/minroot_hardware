// Copyright Supranational LLC
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

//
// Input: x, y, num_iterations
// Set i = one in montgomery form
// Loop num_iterations
//   temp = x + y      y = x + i      i++ (add one in montgomery form)
//   x = penta_root(temp)
// Output: x, y

module minroot_engine_i
  (
   input  logic                            clk_i,
   input  logic                            rst_ni,
   input  logic                            start_i,
   input  logic [mrt_pkg::IterBits - 1:0]  starting_iter_i,
   input  logic [mrt_pkg::IterBits - 1:0]  iters_i,
   input  mrt_pkg::poly_t                  x_i,
   input  mrt_pkg::poly_t                  y_i,
   output mrt_pkg::poly_t                  x_o,
   output mrt_pkg::poly_t                  y_o,
   output logic [mrt_pkg::IterBits - 1:0]  cur_iter_o,
   output logic                            iter_done_o,
   output logic                            pr_start_o,
   output mrt_pkg::poly_t                  pr_x_o,
   input  logic                            pr_done_i,
   input  logic                            pr_sync_i,
   input  mrt_pkg::poly_t                  pr_x_i
  );

  ///////////////////////////////////////////////////////////////////////////
  // Variable declarations
  ///////////////////////////////////////////////////////////////////////////

  logic [mrt_pkg::IterBits - 1:0]   iter, cur_iter_d;
  mrt_pkg::poly_t                   iter_mont;
  mrt_pkg::poly_t                   x, y, t, y_d;
  logic                             start_q;
  logic                             y_not_fully_reduced;

  ///////////////////////////////////////////////////////////////////////////
  // Reset controlled flops
  ///////////////////////////////////////////////////////////////////////////

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (rst_ni == 1'b0) begin
      y_o <= 'b0;
      cur_iter_o <= 'b0;
      start_q <= 'b0;
    end else begin
      y_o <= y_d;
      cur_iter_o <= cur_iter_d;
      start_q <= (start_i || start_q) && !pr_sync_i;
    end
  end

  ///////////////////////////////////////////////////////////////////////////
  // Combo logic
  ///////////////////////////////////////////////////////////////////////////

  always_comb begin

    iter_done_o = pr_done_i;
    x_o = pr_x_i;

    if (start_i || start_q) begin
      iter = starting_iter_i;
      x = x_i;
      y = y_i;
    end else begin
      iter = cur_iter_o;
      x = x_o;
      y = y_o;
    end

    pr_start_o = (start_i || start_q) && pr_sync_i || 
                 iter_done_o && (cur_iter_o <= iters_i);

    // Create iteration polynomial in Montgomery form
    // Since we are essentially adding R each iteration, we can use
    //  the integer count and shift up
    iter_mont = '{default:'0};
    for (int i = 0; i < mrt_pkg::IterCoeffs; i++) begin : iter_to_poly
      iter_mont[mrt_pkg::LowerCoeffs + i] = mrt_pkg::coeff_t'(
        iter[(i * mrt_pkg::WordBits) +: mrt_pkg::WordBits]);
    end

    pr_x_o = mrt_pkg::poly_add(x, y);


    y_not_fully_reduced = 1'b0;
    for (int i = 0; i < mrt_pkg::NumCoeffs-1; i++) begin
      y_not_fully_reduced = y_not_fully_reduced || 
                 |y_o[i][mrt_pkg::WordBits +: mrt_pkg::RedundantBits];
    end
    y_d = pr_start_o ? mrt_pkg::poly_add(x, iter_mont) : 
          y_not_fully_reduced ? mrt_pkg::poly_add(y_o,0) : y_o;

    cur_iter_d = pr_start_o ? (iter + 'b1) : cur_iter_o;

  end

  ///////////////////////////////////////////////////////////////////////////
  // Debug (needs mrt_tb_pkg so not used by default)
  ///////////////////////////////////////////////////////////////////////////

`ifdef NEVER
`ifndef SYNTHESIS

  always_ff @(posedge clk_i) begin
    if (pr_start_o) begin
      $display("PolyAdd0Check @ %d",cur_iter_o);
      $display("  poly  x: %x",x);
      mrt_tb_pkg::print_poly(x);
      $display("  poly  y: %x",y);
      mrt_tb_pkg::print_poly(y);
      $display("  poly  s: %x",pr_x_o);
      mrt_tb_pkg::print_poly(pr_x_o);
      $display("  int   x: %x",mrt_tb_pkg::poly_to_int(x));
      $display("  int   y: %x",mrt_tb_pkg::poly_to_int(y));
      $display("  int   s: %x",mrt_tb_pkg::poly_to_int(pr_x_o));
      $display("  int x+y: %x",mrt_tb_pkg::poly_to_int(x)+mrt_tb_pkg::poly_to_int(y));
    end
  end

  always_ff @(posedge clk_i) begin
    if (pr_start_o) begin
      $display("PolyAdd1Check @ %d",cur_iter_o);
      $display("  poly  x: %x",x);
      $display("  poly  i: %x",iter_mont);
      $display("  poly  s: %x",y_d);
      $display("  int   x: %x",mrt_tb_pkg::poly_to_int(x));
      $display("  int   y: %x",mrt_tb_pkg::poly_to_int(iter_mont));
      $display("  int   s: %x",mrt_tb_pkg::poly_to_int(y_d));
      $display("  int x+y: %x",mrt_tb_pkg::poly_to_int(x)+mrt_tb_pkg::poly_to_int(iter_mont));
    end
  end

  mrt_pkg::poly_t dbg_p_x_start, dbg_p_x_end;
  always_ff @(posedge clk_i) begin
    if (pr_done_i) begin
      dbg_p_x_end = pr_x_i;
      if (mrt_tb_pkg::calc_pow5(mrt_tb_pkg::from_mont(mrt_tb_pkg::poly_to_int(dbg_p_x_end)))
        !=mrt_tb_pkg::from_mont(mrt_tb_pkg::poly_to_int(dbg_p_x_start))) begin
        $display("PentaRootCheck @ %d ERROR",cur_iter_o);
      end else begin
        $display("PentaRootCheck @ %d ok",cur_iter_o);
      end
      $display("  poly x_start: %x",dbg_p_x_start);
      $display("  poly x_end:   %x",dbg_p_x_end);
      $display("  mont x_start: %x",mrt_tb_pkg::poly_to_int(dbg_p_x_start));
      $display("  mont x_end:   %x",mrt_tb_pkg::poly_to_int(dbg_p_x_end));
      $display("  int  x_start: %x",mrt_tb_pkg::from_mont(mrt_tb_pkg::poly_to_int(dbg_p_x_start)));
      $display("  int  x_end:   %x",mrt_tb_pkg::from_mont(mrt_tb_pkg::poly_to_int(dbg_p_x_end)));
      $display("  int  x_end^5: %x",mrt_tb_pkg::calc_pow5(mrt_tb_pkg::from_mont(mrt_tb_pkg::poly_to_int(dbg_p_x_end))));
    end
    if (pr_start_o) begin
      dbg_p_x_start = pr_x_o;
    end
  end

  always_ff @(posedge clk_i) begin
    if (iter_done_o) begin
      if (!mrt_tb_pkg::minroot_check
          (.x_i(x_i),
           .y_i(y_i),
           .x_o(x_o),
           .y_o(y_o),
           .iter(cur_iter_o),
           .starting_iter(starting_iter_i))) begin
        $display("MinrootCheck @ %d ERROR",cur_iter_o);
      end else begin
        $display("MinrootCheck @ %d ok",cur_iter_o);
      end
      $display("  poly x_i: %x",x_i);
      $display("  poly y_i: %x",y_i);
      $display("  poly x_o: %x",x_o);
      $display("  poly y_o: %x",y_o);
      $display("  mont x_i: %x",mrt_tb_pkg::poly_to_int(x_i));
      $display("  mont y_i: %x",mrt_tb_pkg::poly_to_int(y_i));
      $display("  mont x_o: %x",mrt_tb_pkg::poly_to_int(x_o));
      $display("  mont y_o: %x",mrt_tb_pkg::poly_to_int(y_o));
      $display("  int  x_i: %x",mrt_tb_pkg::from_mont(mrt_tb_pkg::poly_to_int(x_i)));
      $display("  int  y_i: %x",mrt_tb_pkg::from_mont(mrt_tb_pkg::poly_to_int(y_i)));
      $display("  int  x_o: %x",mrt_tb_pkg::from_mont(mrt_tb_pkg::poly_to_int(x_o)));
      $display("  int  y_o: %x",mrt_tb_pkg::from_mont(mrt_tb_pkg::poly_to_int(y_o)));
      $display("  cur_iter_o: %x",cur_iter_o);
      $display("  starting_iter_i: %x",starting_iter_i);
    end
  end

`endif
`endif

endmodule
