// Copyright Supranational LLC
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

// Minroot engine global parameters

package mrt_pkg;
  ///////////////////////////////////////////////////////////////////////////
  // Programmable parameters
  ///////////////////////////////////////////////////////////////////////////
  `ifdef MRT_PKG__TARGET_BITS_CMD_LINE_DEFINE
    localparam unsigned TargetBits    = `MRT_PKG__TARGET_BITS_CMD_LINE_DEFINE;
  `else
    localparam unsigned TargetBits    = 256;
  `endif

  `ifdef MRT_PKG__WORD_BITS_CMD_LINE_DEFINE
    localparam unsigned WordBits      = `MRT_PKG__WORD_BITS_CMD_LINE_DEFINE;
  `else
    localparam unsigned WordBits      = 16;
  `endif

  `ifdef MRT_PKG__REDUNDANT_BITS_CMD_LINE_DEFINE
    localparam unsigned RedundantBits = `MRT_PKG__REDUNDANT_BITS_CMD_LINE_DEFINE;
  `else
    localparam unsigned RedundantBits = 1;
  `endif

  `ifdef MRT_PKG__EXTRA_COEFFS_CMD_LINE_DEFINE
    localparam unsigned ExtraCoeffs   = `MRT_PKG__EXTRA_COEFFS_CMD_LINE_DEFINE;
  `else
    localparam unsigned ExtraCoeffs   = 1;
  `endif

  `ifdef MRT_PKG__MODULUS_CMD_LINE_DEFINE
    localparam bit [TargetBits - 1:0] Modulus = `MRT_PKG__MODULUS_CMD_LINE_DEFINE;
  `else
    localparam bit [TargetBits - 1:0] Modulus =
      (TargetBits == 256) ?
        256'h40000000000000000000000000000000224698fc094cf91b992d30ed00000001 :
       //256'h40000000000000000000000000000000224698fc0994a8dd8c46eb2100000001 :
      (TargetBits == 128) ?  128'h224698fc094cf91b992d30ed00000001 :
      (TargetBits == 64)  ?   64'h992d30ed00000001 :
      {TargetBits{1'b0}};
  `endif

  // Pasta curves
  // Pallas: 40000000000000000000000000000000224698fc094cf91b992d30ed00000001  
  // Vesta:  40000000000000000000000000000000224698fc0994a8dd8c46eb2100000001

  ///////////////////////////////////////////////////////////////////////////
  // Fixed parameters
  ///////////////////////////////////////////////////////////////////////////
  localparam unsigned TargetCoeffs      = TargetBits / WordBits;
  localparam unsigned NumCoeffs         = TargetCoeffs + ExtraCoeffs;
  localparam unsigned CoeffBits         = WordBits + RedundantBits;
  localparam unsigned NumCoeffsMul      = NumCoeffs * 2;

  localparam unsigned LowerTriBits      = TargetBits / 2;
  localparam unsigned LowerCoeffs       = TargetCoeffs / 2;
  localparam unsigned UpperTriBits      = RedundantBits +
                                          (NumCoeffsMul * WordBits) -
                                          (TargetBits + LowerTriBits);
  localparam unsigned UpperCoeffs       = NumCoeffsMul -
                                          (TargetCoeffs + LowerCoeffs);

  localparam unsigned NumBits           = CoeffBits +
                                          (WordBits * (NumCoeffs - 1));
  localparam unsigned NumBits2x         = CoeffBits +
                                          (WordBits * ((NumCoeffs * 2) - 1));

  localparam unsigned UpperTriStart     = LowerTriBits + TargetBits;

  localparam unsigned MulCpaBits        = 4;
  localparam unsigned MulCpaLo          = 128;
  localparam unsigned MulCpaHi          = NumBits2x - MulCpaLo;
  localparam unsigned SqrCpaBits        = 4;
  localparam unsigned SqrCpaLo          = 128;
  localparam unsigned SqrCpaHi          = NumBits2x - SqrCpaLo;

  // Note: this is currently hard coded for Pasta curves
  localparam unsigned NumCmds           = 282;
  localparam unsigned CmdBits           = $clog2(NumCmds);

  localparam unsigned IterBits          = 48;
  localparam unsigned IterCoeffs        = IterBits / WordBits;

  localparam unsigned ExpoBits          = 254;
  localparam unsigned RTLCtrBits        = $clog2(ExpoBits);

  // R = b^n
  localparam bit [LowerTriBits:0] BtoTheN   = {{1'b1}, {LowerTriBits{1'b0}}};

  // Fifth root exponent
  localparam bit [ExpoBits - 1:0] Exponent =
    (Modulus ==
     256'h40000000000000000000000000000000224698fc094cf91b992d30ed00000001) ?
    254'h333333333333333333333333333333334e9ee0c9a10a60e2e0f0f3f0cccccccd :
    (Modulus ==
     256'h40000000000000000000000000000000224698fc0994a8dd8c46eb2100000001) ?
    254'h333333333333333333333333333333334e9ee0c9a143ba4ad69f2280cccccccd :
    '0;

  ///////////////////////////////////////////////////////////////////////////
  // Types
  ///////////////////////////////////////////////////////////////////////////
  typedef logic [CoeffBits - 1:0] coeff_t;
  typedef coeff_t [NumCoeffs - 1:0] poly_t;
  typedef coeff_t [(NumCoeffs * 2) - 1:0] poly_2x_t;

  typedef logic [NumBits2x - 1:0] tree_term_mul_t;
  typedef logic [NumBits - 1:0] tree_term_red_t;

  typedef logic [TargetBits - 1:0] mont_red_table_t[LowerTriBits];
  typedef logic [TargetBits - 1:0] upper_red_table_t[UpperTriBits];

  typedef enum logic {
    Sqr, Mul
  } op_e;

  typedef enum logic [3:0] {
    XOut, X1, X10, X110, X11, X101, X111, X1001,
    X1111, X110011X4, X110011X8, XTmp, NumVars
  } x_vars_e;

  typedef struct {
    op_e     op;
    x_vars_e out;
    x_vars_e a;
    x_vars_e b;
  } mul_cmd_t;

  typedef mul_cmd_t mul_cmd_seq_t [NumCmds];

  ///////////////////////////////////////////////////////////////////////////
  // Modular multiplicative inverse
  ///////////////////////////////////////////////////////////////////////////
  // Input a, m
  // Output z where az = 1 mod m
  function automatic [TargetBits - 1:0] mod_inverse(
    input [TargetBits - 1:0] a_i,
    input [TargetBits - 1:0] m_i
  );
    logic [(TargetBits * 2) - 1:0] z;
    logic [(TargetBits * 2) - 1:0] next_z;
    logic [(TargetBits * 2) - 1:0] tmp_z;
    logic [(TargetBits * 2) - 1:0] x;
    logic [(TargetBits * 2) - 1:0] next_x;
    logic [(TargetBits * 2) - 1:0] tmp_x;
    logic [(TargetBits * 2) - 1:0] q;

    z         = '0;
    next_z    = '0;
    next_z[0] = 1'b1;
    x         = {{TargetBits{1'b0}}, m_i};
    next_x    = {{TargetBits{1'b0}}, a_i};

    while (next_x != '0) begin
      q      = x / next_x;

      tmp_z  = next_z;
      next_z = z - $bits(z)'(q * next_z);
      z      = tmp_z;

      tmp_x  = next_x;
      next_x = x - $bits(x)'(q * next_x);
      x      = tmp_x;
    end

    // Check if z < 0
    if (z[(TargetBits * 2) - 1] == 1'b1) begin
      z += m_i;
    end

    return z[TargetBits - 1:0];
  endfunction

  // For the Pasta curve modulus we need to hard code since mod_inverse is not
  //   working during elaboration with these inputs
  localparam bit [LowerTriBits - 1:0] Mu =
    (Modulus ==
     256'h40000000000000000000000000000000224698fc094cf91b992d30ed00000001) ?
    128'h69c760bd82a13db2992d30ecffffffff :
    (Modulus ==
     256'h40000000000000000000000000000000224698fc0994a8dd8c46eb2100000001) ?
    128'hd6c83a9183930e9c8c46eb20ffffffff :
    mod_inverse(Modulus, {{((TargetBits - LowerTriBits) - 1){1'b0}}, BtoTheN});

  ///////////////////////////////////////////////////////////////////////////
  // Montgomery reduction table
  ///////////////////////////////////////////////////////////////////////////
  function automatic mont_red_table_t mont_reduction_table();
    mont_red_table_t ret_table;

    for (int i = 0; i < LowerTriBits; i++) begin
      logic [TargetBits * 2:0]    tmp;
      logic [LowerTriBits - 1:0]  T1;
      logic [LowerTriBits - 1:0]  T2;
      logic [TargetBits * 2:0]    T3;
      logic [TargetBits - 1:0]    T4;

      T1    = '0;
      T1[i] = 1'b1;
      tmp   = T1 * Mu;
      T2    = tmp[LowerTriBits - 1:0];
      T3    = T2 * Modulus;
      tmp   = ((T3 >> LowerTriBits) + 1);
      T4    = tmp[TargetBits - 1:0];

      ret_table[i] = T4;
    end

    return ret_table;
  endfunction

  ///////////////////////////////////////////////////////////////////////////
  // Pre-calculated reduction table
  ///////////////////////////////////////////////////////////////////////////
  function automatic upper_red_table_t upper_reduction_table();
    upper_red_table_t ret_table;

    for (int i = 0; i < UpperTriBits; i++) begin
      logic [(UpperTriBits + TargetBits) - 1:0]  cur_weight;
      cur_weight = '0;
      cur_weight[i + TargetBits] = 1'b1;
      ret_table[i] = cur_weight % Modulus;
    end

    return ret_table;
  endfunction

  ///////////////////////////////////////////////////////////////////////////
  // Polynomial Addition
  ///////////////////////////////////////////////////////////////////////////
  function automatic poly_t poly_add (
    input poly_t poly_a_i,
    input poly_t poly_b_i
  );
    poly_t poly_o;

    poly_o[0] = poly_a_i[0][0 +: WordBits] + poly_b_i[0][0 +: WordBits];
    for (int i = 1; i < NumCoeffs - 1; i++) begin
      poly_o[i] = poly_a_i[i - 1][WordBits +: RedundantBits] +
                  poly_a_i[i][0 +: WordBits] +
                  poly_b_i[i - 1][WordBits +: RedundantBits] +
                  poly_b_i[i][0 +: WordBits];
    end

    poly_o[NumCoeffs - 1] = poly_a_i[NumCoeffs - 2][WordBits +: RedundantBits] +
                            poly_a_i[NumCoeffs - 1] +
                            poly_b_i[NumCoeffs - 2][WordBits +: RedundantBits] +
                            poly_b_i[NumCoeffs - 1];

    return poly_o;
  endfunction

  ///////////////////////////////////////////////////////////////////////////
  // Calculated parameters
  ///////////////////////////////////////////////////////////////////////////
  // For the Pasta curve modulus we need to hard code since mod_inverse is not
  //   working during elaboration with these inputs
  localparam bit [TargetBits - 1:0] RInv =
    (Modulus ==
     256'h40000000000000000000000000000000224698fc094cf91b992d30ed00000001) ?
    256'h1a71d82f60a84f6ca64b4c3b3fffffffce29a69424b6b2eaa0cd79c640dd966a :
    (Modulus ==
     256'h40000000000000000000000000000000224698fc0994a8dd8c46eb2100000001) ?
    256'h35b20ea460e4c3a72311bac83fffffffdcc1d2e1af2d5301df9a668efebc83b2 :
    mod_inverse({{((TargetBits - LowerTriBits) - 1){1'b0}}, BtoTheN}, Modulus);

  localparam mont_red_table_t MontRedTable = mont_reduction_table();

  localparam upper_red_table_t UpperRedTable = upper_reduction_table();

endpackage
