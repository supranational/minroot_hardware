// Copyright Supranational LLC
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

//
// Polynomial square
//

module poly_sqr
  import mrt_pkg::*;
  #(
    parameter unsigned CpaBits = 16,
    parameter unsigned CpaCoeffs = 2 * NumCoeffs * WordBits / CpaBits
    )
  (
   input                                   poly_t a_i,
   output logic [NumBits2x-1:0]            product0_o,
   output logic [NumBits2x-1:0]            product1_o,
   output logic [CpaCoeffs-1:0][CpaBits:0] cpa_product_o
   );
  
  int k;
  
  tree_term_mul_t
    [NumCoeffs-1:0]
      [WordBits+3-1:0]
        csa_in;
  
  // Create matrix of partial products representing the multiplication to be
  // performed.  Do this for each combination of a_i[i] and a_i[j] coefficient
  // pair.  
  //
  // For i!=j each pair creates WordBits + 3 partial products as follows:
  //
  // {a_i[i][WordBits],a_i[i][WordBits-1:0]} * {a_i[j][WordBits],a_i[j][WordBits-1:0]}
  //
  // which with cross multiplication becomes:
  //
  // a_i[i][WordBits-1:0] * a_i[j][WordBits-1:0] yields WordBits partial products
  // a_i[i][WordBits]     * a_i[j][WordBits-1:0] yields 1 partial product
  // a_i[i][WordBits-1:0] * a_i[j][WordBits] yields 1 partial product
  // a_i[i][WordBits]     * a_i[j][WordBits] yields 1 partial product
  //
  //
  // a_i[i]*a_i[j]
  //   x,y,a for case i!=j
  //   z for case i==j
  //
  //                          ...xxxxxxxxyyyyyyyy00000000z    i=0, k=0
  //                         ...xxxxxxxxyyyyyyyy000000zz00    i=0
  //                        ...xxxxxxxxyyyyyyyy00000zzz000    i=0
  //                       ...xxxxxxxxyyyyyyyy0000zzzz0000    i=0
  //                      ...xxxxxxxxyyyyyyyy000zzzzz00000    i=0
  //                     ...xxxxxxxxyyyyyyyy00zzzzzz000000    i=0
  //                    ...xxxxxxxxyyyyyyyy0zzzzzzz0000000    i=0
  //                   ...xxxxxxxxyyyyyyyyzzzzzzzz00000000    i=0, k=WordBits-1
  //                   ...xxxxxxxxyyyyyyyyzzzzzzzz00000000    i=0, k=WordBits
  //                   ...xxxxxxxxyyyyyyyy0000000Z00000000    i=0 Z = put z here instead
  //                  ...x0000000y00000000z000000000000000    i=0
  //                  ...xxxxxxxxyyyyyyyy00000000Aaaaaaaa0    i=1 A = a,z collision, place a
  //                 ...xxxxxxxxyyyyyyyy000000zzaaaaaaaa00    i=1
  //                ...xxxxxxxxyyyyyyyy00000zzzaaaaaaaa000    i=1
  //               ...xxxxxxxxyyyyyyyy0000zzzzaaaaaaaa0000    i=1
  //              ...xxxxxxxxyyyyyyyy000zzzzzaaaaaaaa00000    i=1
  //             ...xxxxxxxxyyyyyyyy00zzzzzzaaaaaaaa000000    i=1
  //            ...xxxxxxxxyyyyyyyy0zzzzzzzaaaaaaaa0000000    i=1
  //           ...xxxxxxxxyyyyyyyyzzzzzzzzaaaaaaaa00000000    i=1, k=WordBits-1
  //           ...xxxxxxxxyyyyyyyyzzzzzzzzaaaaaaaa00000000    i=1, k=WordBits
  //           ...xxxxxxxxyyyyyyyy0000000Zaaaaaaaa00000000    i=1 Z = put z here instead
  //          ...x0000000y00000000z000000a0000000000000000    i=1
  //          ...xxxxxxxxyyyyyyyy00000000Aaaaaaaabbbbbbbb0    i=2 A = a,z collision, place a
  //         ...xxxxxxxxyyyyyyyy000000zzaaaaaaaabbbbbbbb00    i=2
  //        ...xxxxxxxxyyyyyyyy00000zzzaaaaaaaabbbbbbbb000    i=2
  //       ...xxxxxxxxyyyyyyyy0000zzzzaaaaaaaabbbbbbbb0000    i=2
  //      ...xxxxxxxxyyyyyyyy000zzzzzaaaaaaaabbbbbbbb00000    i=2
  //     ...xxxxxxxxyyyyyyyy00zzzzzzaaaaaaaabbbbbbbb000000    i=2
  //    ...xxxxxxxxyyyyyyyy0zzzzzzzaaaaaaaabbbbbbbb0000000    i=2
  //   ...xxxxxxxxyyyyyyyyzzzzzzzzaaaaaaaabbbbbbbb00000000    i=2
  //   ...xxxxxxxxyyyyyyyyzzzzzzzzaaaaaaaabbbbbbbb00000000    i=2
  //   ...xxxxxxxxyyyyyyyy00000000aaaaaaaabbbbbbbb00000000    i=2
  //  ...x0000000y00000000z000000a0000000b0000000000000000    i=2
  //

  logic [CoeffBits-1:0] m1x,m2x;
  
  always_comb begin
    csa_in = 0;
    for (int i = 0; i < NumCoeffs; i++) begin
      for (int j = 0; j <= i; j++) begin
        if (i==j) begin
          // a_i[i][WordBits-1:0] * a_i[i][WordBits-1:0]
          for (k = 0; k < WordBits; k++) begin
            m1x = (1'b1<<k);
            m2x = m1x - 1'b1;
            if (k!=0) begin
              csa_in[i][k][(i+j)*WordBits+k+1 +: WordBits]
                = a_i[i][k] ? (((a_i[i] & m1x)>>1) + (a_i[i] & m2x)) : 0;
            end else if (i!=0) begin
              csa_in[i-1][WordBits+1][(i+j)*WordBits] = a_i[i][0];
            end else begin
              csa_in[0][0][0] = a_i[0][0];
            end
          end   
          // 2 * a_i[i][WordBits] * a_i[i][WordBits-1:0]
          csa_in[i][WordBits+0][(i+j+1)*WordBits+1 +: WordBits]
            = a_i[i][WordBits] ? a_i[i][0 +: WordBits] : 0;
          // k++;
          // unused
          // k++;
          // a_i[i][WordBits] * a_i[i][WordBits]
          csa_in[i][WordBits+2][(i+j+2)*WordBits]
            = a_i[i][WordBits];
        end else begin
          // a_i[i][WordBits-1:0] * a_i[j][WordBits-1:0]
          for (k = 0; k < WordBits; k++) begin
            csa_in[i][k][(i+j)*WordBits+k+1 +: WordBits]
                   = a_i[i][k] ? a_i[j][0 +: WordBits] : 0;
          end   
          // a_i[i][WordBits] * a_i[j][WordBits-1:0]
          csa_in[i][WordBits+0][(i+j+1)*WordBits+1 +: WordBits]
            = a_i[i][WordBits] ? a_i[j][0 +: WordBits] : 0;
          //k++;
          // a_i[i][WordBits-1:0] * a_i[j][WordBits-1:0]
          csa_in[i][WordBits+1][(i+j+1)*WordBits+1 +: WordBits]
            = a_i[j][WordBits] ? a_i[i][0 +: WordBits] : 0;
          //k++;
          // a_i[i][WordBits] * a_i[j][WordBits]
          csa_in[i][WordBits+2][(i+j+2)*WordBits+1]
            = a_i[i][WordBits] & a_i[j][WordBits];
        end
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
      .OUT0(product0_o),
      .OUT1(product1_o)
      );


  // Create redundant coefficient form output from the two CSA tree outputs by
  // simple addition.
  
  always_comb begin
    cpa_product_o = 0;
    for (int i=0;i<CpaCoeffs;i++) begin
      cpa_product_o[i] = 
        product0_o[i*CpaBits +: CpaBits] +
        product1_o[i*CpaBits +: CpaBits];
    end
  end

endmodule
