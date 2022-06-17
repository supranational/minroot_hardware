// Copyright Supranational LLC
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0
//
// Minroot engine testbench utilities

package mrt_tb_pkg;
  ///////////
  // Types //
  ///////////
  parameter type int_t     = logic [mrt_pkg::NumBits - 1:0];
  parameter type int_2x_t  = logic [mrt_pkg::NumBits2x - 1:0];

  ////////////////////////////////////////////
  // Polynomial <-> Integer Transformations //
  ////////////////////////////////////////////
  function automatic mrt_pkg::poly_t int_to_poly (
    input logic [mrt_pkg::NumBits - 1:0] int_i
  );
    mrt_pkg::poly_t poly_o;

    // Break integer down into polynomial
    for (int i = 0; i < mrt_pkg::NumCoeffs - 1; i++) begin
      poly_o[i] = {'0, int_i[(i * mrt_pkg::WordBits) +: mrt_pkg::WordBits]};
    end
    poly_o[mrt_pkg::NumCoeffs - 1] =
      int_i[(mrt_pkg::NumBits - 1) -: mrt_pkg::CoeffBits];

    return poly_o;
  endfunction

  function automatic logic [mrt_pkg::NumBits - 1:0] poly_to_int (
    input mrt_pkg::poly_t poly_i
  );
    logic [mrt_pkg::NumBits - 1:0] int_o = '0;

    for (int i = mrt_pkg::NumCoeffs - 1; i >= 0; i--) begin
      int_o <<= mrt_pkg::WordBits; // left shift by word
      int_o += poly_i[i];
    end

    return int_o;
  endfunction

  function automatic logic [mrt_pkg::NumBits2x - 1:0] poly_to_int_2x (
    input mrt_pkg::poly_2x_t poly_i
  );
    logic [mrt_pkg::NumBits2x - 1:0] int_o = '0;

    for (int i = (mrt_pkg::NumCoeffs * 2) - 1; i >= 0; i--) begin
      int_o <<= mrt_pkg::WordBits; // left shift by word
      int_o += poly_i[i];
    end

    return int_o;
  endfunction

  ///////////////////////
  // Random Polynomial //
  ///////////////////////
  function automatic mrt_pkg::poly_t rand_poly();
    mrt_pkg::poly_t res;
    localparam int MAX = mrt_pkg::NumCoeffs;
    //do begin
      res = '0;
      for (int i = 0; i < MAX; i++) begin
        logic [mrt_pkg::WordBits-1:0] word;
        std::randomize(word);
        res[i][0 +: mrt_pkg::WordBits] = word;
      end

      // Cannot have MSB of top coeff set since could set top redundant bit
      //  when added together
      res[mrt_pkg::NumCoeffs - 1][0 +: mrt_pkg::WordBits] &=
        2**(mrt_pkg::WordBits -1) - 1;

      //$display("Rand X: 0x%x", res);
      //$display("Int X:  0x%x", mrt_tb_pkg::poly_to_int_x(res));
    //end while (!(mrt_tb_pkg::poly_to_int(res) inside {[X_MIN:X_MAX]}));
    return res;
  endfunction

  ///////////////////////
  // Print  Polynomial //
  ///////////////////////
  function automatic print_poly (
    input mrt_pkg::poly_t poly_i
  );
    for (int i = mrt_pkg::NumCoeffs - 1; i >= 0; i--) begin
      $write("0x%x ", poly_i[i]);
    end
    $write("\n");
  endfunction

  function automatic print_poly_2x (
    input mrt_pkg::poly_2x_t poly_i
  );
    for (int i = (mrt_pkg::NumCoeffs * 2) - 1; i >= 0; i--) begin
      $write("0x%x ", poly_i[i]);
    end
    $write("\n");
  endfunction


  function automatic logic [mrt_pkg::NumBits - 1:0] from_mont 
    (
     input [mrt_pkg::NumBits - 1:0] in
     );
    logic [mrt_pkg::NumBits - 1:0]  int_1x;
    logic [mrt_pkg::NumBits2x - 1:0] int_2x;

    int_2x = in % mrt_pkg::Modulus;
    int_2x *= mrt_pkg::RInv;
    int_1x = int_2x % mrt_pkg::Modulus;

    return int_1x;
  endfunction

  function automatic logic [mrt_pkg::NumBits - 1:0] calc_pow5 
    (
     input [mrt_pkg::NumBits - 1:0] in
     );
    logic [mrt_pkg::NumBits - 1:0]  int_1x;
    logic [mrt_pkg::NumBits2x - 1:0] int_2x;
    
    int_2x = in * in;
    int_2x %= mrt_pkg::Modulus;
    int_2x *= in;
    int_2x %= mrt_pkg::Modulus;
    int_2x *= in;
    int_2x %= mrt_pkg::Modulus;
    int_2x *= in;
    int_2x %= mrt_pkg::Modulus;
    
    int_1x = int_2x;
    return int_1x;
  endfunction
  
  // x = y_out - i
  // y = x_out^5 - x
  function reverse
    ( 
      input [mrt_pkg::NumBits - 1:0] x_o,
      input [mrt_pkg::NumBits - 1:0] y_o,
      output [mrt_pkg::NumBits - 1:0]  x_i,
      output [mrt_pkg::NumBits - 1:0]  y_i,
      input [mrt_pkg::IterBits - 1:0] iter
      );
    logic [mrt_pkg::NumBits - 1:0]  pow5_1x;

    x_i = (y_o - (iter - 1)) % mrt_pkg::Modulus;
    pow5_1x = calc_pow5(x_o);
    if (pow5_1x < x_i)
      y_i = (pow5_1x - x_i) + mrt_pkg::Modulus;
    else
      y_i = (pow5_1x - x_i) % mrt_pkg::Modulus;
  endfunction

  function logic minroot_check
    ( 
      input logic [10-1:0][31:0] x_i,
      input logic [10-1:0][31:0] y_i,
      input logic [10-1:0][31:0] x_o,
      input logic [10-1:0][31:0] y_o,
      input logic [1:0][31:0] iter,
      input logic [1:0][31:0] starting_iter
      );

    mrt_tb_pkg::int_t x_o_int, y_o_int;
    mrt_tb_pkg::int_t x_i_int, y_i_int;
    mrt_tb_pkg::int_t x_nm1_int, y_nm1_int;
    logic [mrt_pkg::IterBits - 1:0] i;

    x_o_int = mrt_tb_pkg::from_mont(mrt_tb_pkg::poly_to_int(x_o));
    y_o_int = mrt_tb_pkg::from_mont(mrt_tb_pkg::poly_to_int(y_o));
    x_i_int = mrt_tb_pkg::from_mont(mrt_tb_pkg::poly_to_int(x_i));
    y_i_int = mrt_tb_pkg::from_mont(mrt_tb_pkg::poly_to_int(y_i));

    for(int i=iter;i>starting_iter;i--) begin

      mrt_tb_pkg::reverse
              ( .x_o(x_o_int),
                .y_o(y_o_int),
                .x_i(x_nm1_int),
                .y_i(y_nm1_int),
                .iter(i) );

      x_o_int = x_nm1_int;
      y_o_int = y_nm1_int;

    end

    return (x_o_int==x_i_int && y_o_int==y_i_int || iter == '0) ? 1'b1 : 1'b0;
  endfunction

endpackage
