// Copyright Supranational LLC
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

//
// Polynomial reduction wrapper for multiplier
//

module poly_red
  import mrt_pkg::*;
  #(
    parameter unsigned CpaBits = 16,
    parameter unsigned CpaCoeffs = 2 * NumCoeffs * WordBits / CpaBits,
    parameter logic [CpaCoeffs-1:0] useCPA = 'h0
    )
 (
   input logic                            clk_i,
   input logic                            rst_ni,

   input logic [NumBits2x-1:0]            mul_product0_i,
   input logic [NumBits2x-1:0]            mul_product1_i,
   input logic [CpaCoeffs-1:0][CpaBits:0] mul_cpa_product_i,
   input                                  poly_t byp_i,
   output                                 poly_t mul_o,
   output                                 poly_t byp_o,

   input                                  poly_t x_i,
   input logic                            sel_x_i,
   input logic                            sel_mul_i,
   input logic                            adv_mul_i,
   input logic                            adv_byp_i
  );

  poly_t reduced_product, result;

  poly_reduce
    # ( .ForSquare (0),
        .CpaBits (CpaBits),
        .CpaCoeffs (CpaCoeffs),
        .useCPA ( useCPA ) )
  _poly_reduce
    ( .product0_i(mul_product0_i),
      .product1_i(mul_product1_i),
      .cpa_product_i(mul_cpa_product_i),
      .reduced_product_o(reduced_product) );

  always_comb begin
    result = sel_mul_i ? reduced_product : byp_i;
  end

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (rst_ni == 1'b0) begin
      mul_o <= 'b0;
      byp_o <= 'b0;
    end
    else begin
      if (adv_mul_i) mul_o <= result;
      if (adv_byp_i) byp_o <= sel_x_i ? x_i : result;
    end
  end

`ifndef SYNTHESIS

  //
  // On-the-fly checking of the reduce calculations
  //

  logic [NumBits2x+2:0] mul_product_act;
  logic [NumBits2x+2:0] mul_reduce_act_demont;
  logic [NumBits2x+2:0] reduce_demont;

  always @* begin
    mul_product_act = mul_product0_i + mul_product1_i;

    mul_reduce_act_demont = 0;
    for(int i=NumCoeffs-1;i>=0; i--) begin
      mul_reduce_act_demont <<= WordBits;
      mul_reduce_act_demont += reduced_product[i];
    end
    mul_reduce_act_demont %= Modulus;
    mul_reduce_act_demont *= RInv;
    mul_reduce_act_demont %= Modulus;

    reduce_demont = mul_product_act[LowerTriBits +: TargetBits];
    for(int i=0;i<LowerTriBits;i++) begin
      if (mul_product_act[i]) reduce_demont += MontRedTable[i];
    end
    for(int i=LowerTriBits+TargetBits;i<NumBits2x;i++) begin
      if (mul_product_act[i]) reduce_demont += UpperRedTable[i-LowerTriBits-TargetBits];
    end
    reduce_demont %= Modulus;
    reduce_demont *= RInv;
    reduce_demont %= Modulus;

  end

  always_ff @(posedge clk_i) begin
    if (reduce_demont !== mul_reduce_act_demont) begin
      $display("%m");
      $display("mul_reduce_act %x",mul_reduce_act_demont);
      $display("    reduce_act %x",reduce_demont);
      $display("mul_reduce NG\n");
    end
  end
  
`endif
endmodule
