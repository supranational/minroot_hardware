// Copyright Supranational LLC
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

//
// Polynomial reduction 
//

module poly_reduce
  import mrt_pkg::*;
  #(
    parameter unsigned ForSquare = 1,
    parameter unsigned CpaBits = 16,
    parameter unsigned CpaCoeffs = 2 * NumCoeffs * WordBits / CpaBits,
    parameter logic [CpaCoeffs-1:0] useCPA = 'h0
    )
  (
   input logic [NumBits2x-1:0]            product0_i,
   input logic [NumBits2x-1:0]            product1_i,
   input logic [CpaCoeffs-1:0][CpaBits:0] cpa_product_i,
   output                                 poly_t reduced_product_o
   );

  function automatic bit [16+3-1:0] GetConfig();

    logic [15:0] n;
    logic cpaLsbs, cpaMsbs, csaBits;

    cpaLsbs = 0;
    cpaMsbs = 0;
    csaBits = 0;
    n = 0;

    for(int i = 0; i < CpaCoeffs ; i++) begin
      if (useCPA[i]) begin
        
        //
        // use CPA for this coeff
        //
      
        // CPA bits
        if (i*CpaBits < LowerTriBits) begin
          n += CpaBits;
        end else if (i*CpaBits < UpperTriStart) begin
          if (!cpaLsbs) begin
            n += 1; 
            cpaLsbs = 1; 
          end
        end else begin
          n += CpaBits;
        end

        // carry bit
        if ((i+1)*CpaBits < LowerTriBits) begin
          n += 1;
        end else if ((i+1)*CpaBits < UpperTriStart) begin
          if (!cpaMsbs) begin
            n += 1; 
            cpaMsbs = 1;
          end
        end else begin
          n += 1;
        end

      end else begin
      
        //
        // use CSA for this coeff
        //

        if (i*CpaBits < LowerTriBits) begin
          n += (unsigned'(2))*CpaBits;  // Cast to get rid of synthesis warning
        end else if (i*CpaBits < UpperTriStart) begin
          if (!csaBits) begin
            n += 2; 
            csaBits = 1; 
          end
        end else begin
          n += (unsigned'(2))*CpaBits; // Cast to get rid of synthesis warning
        end

      end
    end

    return { csaBits, cpaMsbs, cpaLsbs, n };

  endfunction

  localparam unsigned N_TERMS = GetConfig() & 'hffff;
  localparam unsigned cpaLsbs = (GetConfig() >> 16) & 1;
  localparam unsigned cpaMsbs = (GetConfig() >> 17) & 1;
  localparam unsigned csaBits = (GetConfig() >> 18) & 1;

  tree_term_red_t [N_TERMS - 1:0] csa_in;

  tree_term_red_t [1:0] csa_out;

  typedef logic [$clog2(N_TERMS)-1:0] n_terms_t;
  n_terms_t k;

   // Create matrix of reduction terms to be summed.  We have 3 regions to
   // consider:
   //
   // lower bits - product bits lookup terms from Montgomery table 
   // middle bits - target output range, product bits used directly
   // upper bits - product bits lookup terms in standard reduction table

  always_comb begin

    csa_in = 0;
    
    // middle bits
    k = 0;
    if (csaBits) begin
      for (int i = LowerTriBits/CpaBits; i < UpperTriStart/CpaBits; i++) begin
        if (!useCPA[i]) begin
          csa_in[n_terms_t'(k+0)][i*CpaBits-LowerTriBits +: CpaBits] 
            = product0_i[i*CpaBits +: CpaBits];
          csa_in[n_terms_t'(k+1)][i*CpaBits-LowerTriBits +: CpaBits] 
            = product1_i[i*CpaBits +: CpaBits];
        end
      end      
      k+=2;
    end
    if (cpaLsbs) begin
      for (int i = LowerTriBits/CpaBits; i < UpperTriStart/CpaBits; i++) begin
        if (useCPA[i]) begin
          csa_in[k][i*CpaBits-LowerTriBits +: CpaBits]
            = cpa_product_i[i][0 +: CpaBits];
        end
      end    
      k++;
    end
    if (cpaMsbs) begin
      for (int i = LowerTriBits/CpaBits-1; i < UpperTriStart/CpaBits-1; i++) begin
        if (useCPA[i]) begin
          csa_in[k][i*CpaBits-LowerTriBits + CpaBits]
            = cpa_product_i[i][CpaBits];
        end
      end
      k++;
    end
    
    // lower bits, Montgomery table
    for (int i = 0; i < LowerTriBits/CpaBits; i++) begin
      if (useCPA[i]) begin
        for (int j = 0; j < CpaBits+1; j++) begin
          if ( (CpaBits*i + j) < LowerTriBits ) begin
            if (cpa_product_i[i][j]) begin
              csa_in[k] = tree_term_red_t'(MontRedTable[CpaBits*i + j]);
            end
            k++;
          end
        end
      end else begin
        for (int j = 0; j < CpaBits; j++) begin
          if (product0_i[CpaBits*i + j]) begin
            csa_in[n_terms_t'(k+0)] = tree_term_red_t'(MontRedTable[CpaBits*i + j]);
          end
          if (product1_i[CpaBits*i + j]) begin
            csa_in[n_terms_t'(k+1)] = tree_term_red_t'(MontRedTable[CpaBits*i + j]);
          end
          k+=2;
        end
      end
    end
    
    // upper bits, standard reduction table
    for (int i = UpperTriStart/CpaBits-1; i < CpaCoeffs; i++) begin
      if (useCPA[i]) begin
        for (int j = 0; j < CpaBits+1; j++) begin
          if ((CpaBits * i + j) >= UpperTriStart) begin
            if (cpa_product_i[i][j]) begin
              csa_in[k] = tree_term_red_t'(
                UpperRedTable[CpaBits*i + j - UpperTriStart]);
            end
            k++;
          end
        end
      end else begin
        for (int j = 0; j < CpaBits; j++) begin
          if ((CpaBits * i + j) >= UpperTriStart) begin
            if (product0_i[CpaBits*i + j]) begin
              csa_in[n_terms_t'(k+0)] = tree_term_red_t'(
                UpperRedTable[CpaBits*i + j - UpperTriStart]);
            end
            if (product1_i[CpaBits*i + j]) begin
              csa_in[n_terms_t'(k+1)] = tree_term_red_t'(
                UpperRedTable[CpaBits*i + j - UpperTriStart]);
            end
            k += 2;
          end
        end
      end
    end
    
  end

  tree 
    #(
      .num_inputs(N_TERMS),
      .input_width(NumBits),
      .verif_en('0)
      )
  _tree
     (
      .INPUT(csa_in),
      .OUT0(csa_out[0]),
      .OUT1(csa_out[1])
      );

  
  // Create redundant coefficient form output from the two CSA tree outputs.  
  // Again, this is the only carry lookahead adder required to achieve the 
  // reduction.
  
  always_comb begin
    for (int i=0;i<NumCoeffs;i++) begin
      reduced_product_o[i] = 
               csa_out[0][i*WordBits +: WordBits] +
               csa_out[1][i*WordBits +: WordBits];
    end
  end
  
endmodule
