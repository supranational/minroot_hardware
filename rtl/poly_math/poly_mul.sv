// Copyright Supranational LLC
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

//
// Polynomial Multiplication
//

module poly_mul
  import mrt_pkg::*;
  #(
    parameter unsigned CpaBits = 16,
    parameter unsigned CpaCoeffs = 2 * NumCoeffs * WordBits / CpaBits
    )
  (
   input logic                             clk_i,
   input logic                             rst_ni,

   input                                   poly_t sqr_i,
   input                                   poly_t mul_i,
   input                                   poly_t byp_i,
   input                                   poly_t byp_p1_i,
   output logic [NumBits2x-1:0]            mul_product0_o,
   output logic [NumBits2x-1:0]            mul_product1_o,
   output logic [CpaCoeffs-1:0][CpaBits:0] mul_cpa_product_o,
   output                                  poly_t byp_o,

   input logic                             sel_byp_i,
   input logic                             sel_1_i,
   input logic                             adv_mul_i,
   input logic                             adv_byp_i
   );

  int k;
  logic [NumBits2x-1:0] product0;
  logic [NumBits2x-1:0] product1;
  logic [CpaCoeffs-1:0][CpaBits:0] cpa_product;

  poly_t reduced_product;

  logic byp_q;
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (rst_ni == 1'b0) begin
      byp_q <= 1'b0;
    end else begin
      byp_q <= sel_byp_i;
    end
  end

  poly_t a, b;
  always_comb begin
    a = byp_q ? byp_p1_i : sqr_i;
    b = mul_i;
  end

   // Create matrix of partial products representing the multiplication to be
   // performed.  Do this for each combination of a_i and b_i coefficient
   // pair.  Each pair creates WordBits + 3 partial products as follows:
   //
   //  {a_i_[WordBits],a_i[WordBits-1:0]} * {b_i_[WordBits],b_i[WordBits-1:0]}
   //
   // which with cross multiplication becomes:
   //
   // a_i[WordBits-1:0] * b_i[WordBits-1:0] yields WordBits partial products
   // a_i[WordBits] * b_i[WordBits-1:0] yields 1 partial product
   // b_i[WordBits] * a_i[WordBits-1:0] yields 1 partial product
   // a_i[WordBits] * b_i[WordBits] yields 1 partial product
  
  tree_term_mul_t
    [NumCoeffs-1:0]
      [WordBits+3-1:0]
        csa_in;
  
  always_comb begin
    csa_in = 0;
    for (int i = 0; i < NumCoeffs; i++) begin
         for (int j = 0; j < NumCoeffs; j++) begin
           // a[WordBits-1:0] * b[WordBits-1:0]
           for (k = 0; k < WordBits; k++) begin
             csa_in[i][k][(i+j)*WordBits+k +: WordBits]
               = a[i][k] ? b[j][0 +: WordBits] : 0;
           end
           // a[WordBits] * b[WordBits-1:0]
           csa_in[i][WordBits][(i+j+1)*WordBits +: WordBits]
             = a[i][WordBits] ? b[j][0 +: WordBits] : 0;
           // b[WordBits] * a[WordBits-1:0]
           csa_in[i][WordBits+1][(i+j+1)*WordBits +: WordBits]
             = b[i][WordBits] ? a[j][0 +: WordBits] : 0;
           // a[WordBits] * b[WordBits]
           csa_in[i][WordBits+2][(i+j+2)*WordBits]
             = b[i][WordBits] & a[j][WordBits];
         end
    end
  end
  
  tree 
    #(
      .num_inputs(NumCoeffs * (WordBits+3)),
      .input_width(NumBits2x),
      .verif_en('0)
      )
  _tree
     (
      .INPUT(csa_in),
      .OUT0(product0),
      .OUT1(product1)
      );


  // Create redundant coefficient form output from the two CSA tree outputs by
  // simple addition.
  
  always_comb begin
    cpa_product = 0;
    for (int i=0;i<CpaCoeffs;i++) begin
      cpa_product[i] = 
        product0[i*CpaBits +: CpaBits] +
        product1[i*CpaBits +: CpaBits];
    end
  end

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (rst_ni == 1'b0) begin
      mul_product0_o <= 'b0;
      mul_product1_o <= 'b0;
      mul_cpa_product_o <= 'b0;
      byp_o <= 'b0;
    end else begin
      if (adv_mul_i) begin
        mul_product0_o <= product0;
        mul_product1_o <= product1;
        mul_cpa_product_o <= cpa_product;
      end
      if (adv_byp_i) byp_o <= sel_1_i ? poly_t'(1<<(LowerCoeffs*CoeffBits)) : byp_i;
    end
  end

`ifndef SYNTHESIS

  //
  // On-the-fly checking of the multiply calculations
  //

  logic [NumBits2x+2:0] mul_a_int, mul_b_int;
  logic [NumBits2x+2:0] mul_product_exp, mul_product_act;

  always @* begin
    mul_a_int = 0;
    mul_b_int = 0;
    for(int i=NumCoeffs-1;i>=0; i--) begin
      mul_a_int <<= WordBits;
      mul_b_int <<= WordBits;
      mul_a_int += a[i];
      mul_b_int += b[i];
    end
    mul_product_exp = mul_a_int * mul_b_int;
    mul_product_act = product0 + product1;
  end

  always_ff @(posedge clk_i) begin
    if (mul_product_exp !== mul_product_act) begin
      $display("%m");
      $display("mul_product_exp %x",mul_product_exp);
      $display("mul_product_act %x",mul_product_act);
      $display("mul_product NG\n");
    end
  end
  
`endif

endmodule
