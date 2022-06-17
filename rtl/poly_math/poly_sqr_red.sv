// Copyright Supranational LLC
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

//
// Polynomial square and reduce
//

module poly_sqr_red
  import mrt_pkg::*;
  (
   input logic clk_i,
   input logic rst_ni,

   input       poly_t sqr_i,
   output      poly_t sqr_o,
   output      poly_t mul_o,

   input       poly_t x_i,
   input logic sel_x_i,
   input logic adv_sqr_i,
   input logic adv_mul_i
   );

  localparam CpaCoeffs = 2 * NumCoeffs * WordBits / SqrCpaBits;
  localparam [CpaCoeffs-1:0] useCPA = ((1<<CpaCoeffs)-(1<<(SqrCpaHi/SqrCpaBits))) | ((1<<(SqrCpaLo/SqrCpaBits))-1);

  logic [NumBits2x-1:0] product0;
  logic [NumBits2x-1:0] product1;
  logic [CpaCoeffs-1:0][SqrCpaBits:0] cpa_product;

  poly_t reduced_product;

  poly_sqr
    # ( .CpaBits (SqrCpaBits),
        .CpaCoeffs (CpaCoeffs) )
  _poly_sqr
    ( .a_i(sqr_i),
      .product0_o(product0),
      .product1_o(product1),
      .cpa_product_o(cpa_product) );

  poly_reduce
    # ( .ForSquare (1),
        .CpaBits (SqrCpaBits),
        .CpaCoeffs (CpaCoeffs),
        .useCPA ( useCPA ) )
  _poly_reduce
    ( .product0_i(product0),
      .product1_i(product1),
      .cpa_product_i(cpa_product),
      .reduced_product_o(reduced_product) );

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (rst_ni == 1'b0) begin
      sqr_o <= 'b0;
      mul_o <= 'b0;
    end
    else begin
      if (adv_sqr_i) sqr_o <= sel_x_i ? x_i : reduced_product;
      if (adv_mul_i) mul_o <= reduced_product;
    end
  end


`ifndef SYNTHESIS

  //
  // On-the-fly checking of the square and reduce calculations
  //

  logic [NumBits2x+2:0] sqr_x_int;
  logic [NumBits2x+2:0] sqr_product_exp, sqr_product_act;
  logic [NumBits2x+2:0] sqr_reduce_exp_demont, sqr_reduce_act_demont;
  logic [NumBits2x+2:0] reduce_demont;

  always @* begin
    sqr_x_int = 0;
    for(int i=NumCoeffs-1;i>=0; i--) begin
      sqr_x_int <<= WordBits;
      sqr_x_int += sqr_i[i];
    end
    sqr_product_exp = sqr_x_int * sqr_x_int;
    sqr_product_act = product0 + product1;
    
    sqr_x_int %= Modulus;
    sqr_x_int *= RInv;
    sqr_x_int %= Modulus;
    sqr_reduce_exp_demont = sqr_x_int * sqr_x_int;
    sqr_reduce_exp_demont %= Modulus;
    
    sqr_reduce_act_demont = 0;
    for(int i=NumCoeffs-1;i>=0; i--) begin
      sqr_reduce_act_demont <<= WordBits;
      sqr_reduce_act_demont += reduced_product[i];
    end
    sqr_reduce_act_demont %= Modulus;
    sqr_reduce_act_demont *= RInv;
    sqr_reduce_act_demont %= Modulus;

    reduce_demont = sqr_product_exp[LowerTriBits +: TargetBits];
    for(int i=0;i<LowerTriBits;i++) begin
      if (sqr_product_exp[i]) reduce_demont += MontRedTable[i];
    end
    for(int i=LowerTriBits+TargetBits;i<NumBits2x;i++) begin
      if (sqr_product_exp[i]) reduce_demont += UpperRedTable[i-LowerTriBits-TargetBits];
    end
    reduce_demont %= Modulus;
    reduce_demont *= RInv;
    reduce_demont %= Modulus;

  end

  always_ff @(posedge clk_i) begin
    if (sqr_product_exp !== sqr_product_act) begin
      $display("%m");
      $display("sqr_product_exp %x",sqr_product_exp);
      $display("sqr_product_act %x",sqr_product_act);
      $display("sqr_product NG\n");
    end
    if (sqr_reduce_exp_demont !== sqr_reduce_act_demont) begin
      $display("%m");
      $display("sqr_reduce_exp %x",sqr_reduce_exp_demont);
      $display("sqr_reduce_act %x",sqr_reduce_act_demont);
      $display("    reduce_act %x",reduce_demont);
      $display("sqr_reduce NG\n");
    end
  end
  
`endif

endmodule
