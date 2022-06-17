// Copyright Supranational LLC
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

//
// Penta root (5th root of x)
//
// This version of the Minroot 5th root engine implements a set of N 
// compute datapaths in a ring. The ring can handle N simulataneous 5th root
// calculations but is organized in such manner that a single 5th root
// operation rotates around the ring being computed by each of N compute
// datapaths in successive cycles.
//

module penta_root_x
  import mrt_pkg::*;
  #(
    parameter unsigned N     = 1,
    parameter bit      SYNC  = 0
    )
  (
   input  logic           clk_i,
   input  logic           rst_ni,
   input  logic  [N-1:0]  start_i,
   input  poly_t [N-1:0]  x_i,
   output poly_t [N-1:0]  x_o,
   output logic  [N-1:0]  done_o,
   output logic           sync_o
   );
  
  localparam CpaCoeffs = 2 * NumCoeffs * WordBits / MulCpaBits;
  localparam [CpaCoeffs-1:0] useCPA = ((1<<CpaCoeffs)-(1<<(MulCpaHi/MulCpaBits))) | ((1<<(MulCpaLo/MulCpaBits))-1);

  localparam NBITS = (N==1) ? 1 : $clog2(N);

  logic [NBITS-1:0] phase_q;
  logic [N-1:0] start;
  poly_t [N-1:0] x;

  poly_t [N-1:0] sqr2sqr_sqr;
  poly_t [N-1:0] sqr2mul_sqr;
  poly_t [N-1:0] red2mul_mul;
  poly_t [N-1:0] red2mul_byp;
  logic [N-1:0][NumBits2x-1:0] mul2red_mul_product0;
  logic [N-1:0][NumBits2x-1:0] mul2red_mul_product1;
  logic [N-1:0][CpaCoeffs-1:0][MulCpaBits:0] mul2red_mul_cpa_product;
  poly_t [N-1:0] mul2red_byp;

  logic [N-1:0][8:0] cycle_d, cycle_q;
  logic [N-1:0]      done_d, done_q;
  logic [N-1:0]      sqr_sel_x, sqr_adv_sqr, sqr_adv_mul;
  logic [N-1:0]      mul_sel_byp, mul_sel_1, mul_adv_mul, mul_adv_byp;
  logic [N-1:0]      red_sel_x, red_sel_mul, red_adv_mul, red_adv_byp;

`ifndef SYNTHESIS
  ASSERT_sync:  assert #0 (SYNC==0 || (258%N)==0)
    else $fatal(1, "SYNC must be 1 if N(=%d) is not a factor of 258",N);
`endif

  //
  //    
  // start_i           /---\___________________________________________________________/xxx\
  // done_o            ________________________________________________________________/---\
  //
  // cycle             | 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 |...|...|252|253|254|255|256|257| 0 |
  //
  // sqr active        ____/-------------------------------------------\____________________
  // sqr_sel_x         /---\________________________________________________________________
  // sqr_adv_sqr       /-------------------------------------------\________________________
  // sqr_adv_mul       ____/ Y   Y   Y   Y   Y   Y   Y   Y   Y   Y   Y \____________________
  //
  // cycle             | 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 |...|...|252|253|254|255|256|257| 0 |
  //
  // mul active        ________/ Y   Y   Y   Y   Y   Y   Y   Y   Y   Y   Y \___/---\________
  // mul_sel_byp       ____________________________________________________/---\____________
  // mul_sel_1         /---\________________________________________________________________
  // mul_adv_mul       ________/ Y   Y   Y   Y   Y   Y   Y   Y   Y   Y   Y \___/---\________
  // mul_adv_byp       /-------\!Y  !Y  !Y  !Y  !Y  !Y  !Y  !Y  !Y  !Y  !Y /---\____________
  //
  // cycle             | 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 |...|...|252|253|254|255|256|257| 0 |
  //
  // red active        ____________/ Y   Y   Y   Y   Y   Y   Y   Y   Y   Y   Y \___/---\____
  // red_sel_x         /---\________________________________________________________________
  // red_sel_mul       ____________/ Y   Y   Y   Y   Y   Y   Y   Y   Y   Y   Y \___/---\____
  // red_adv_mul       ____/ Y   Y   Y   Y   Y   Y   Y   Y   Y   Y   Y \___/---\____________
  // red_adv_byp       /---\!Y  !Y  !Y  !Y  !Y  !Y  !Y  !Y  !Y  !Y  !Y /---\_______/---\____
  //
  // where "Y .. Y" is Exponent[1], Exponent[2], ..., Exponent[253]  
  //

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (rst_ni == 1'b0) begin
      phase_q <= 'h0;
      sync_o <= 1'b1;
    end else begin
      phase_q <= (phase_q==N-1'b1) ? '0 : (phase_q + 1'b1);
      sync_o <= (phase_q==N-1'b1) ? 1'b1 : 1'b0;
    end
  end

  for(genvar gv_i=0;gv_i<N;gv_i++) begin : gen_gv_i

    // map input signals to approprate of the datapaths based on rotation phase
    if (SYNC) begin : sync_start
      always_comb begin
        start[gv_i] = start_i[gv_i] & sync_o;
        x[gv_i] = x_i[gv_i];
      end
    end else begin
      always_comb begin
        start[gv_i] = start_i[(gv_i+N-phase_q)%N];
        x[gv_i] = x_i[(gv_i+N-phase_q)%N];
      end
    end

    poly_sqr_red _poly_sqr_red
      (
       .clk_i,
       .rst_ni,   
            
       .sqr_i(sqr2sqr_sqr[gv_i]),
       .sqr_o(sqr2sqr_sqr[(gv_i+1)%N]),
       .mul_o(sqr2mul_sqr[(gv_i+1)%N]),
       
       .x_i(x[gv_i]),
       .sel_x_i(sqr_sel_x[gv_i]),   
       .adv_sqr_i(sqr_adv_sqr[gv_i]),
       .adv_mul_i(sqr_adv_mul[gv_i])
       );
    
    poly_mul 
      # ( .CpaBits (MulCpaBits),
          .CpaCoeffs (CpaCoeffs) )
    _poly_mul
      (
       .clk_i,
       .rst_ni,   
       
       .sqr_i(sqr2mul_sqr[gv_i]),
       .mul_i(red2mul_mul[gv_i]),
       .byp_i(red2mul_byp[gv_i]),
       .byp_p1_i(mul2red_byp[gv_i]),
       .mul_product0_o(mul2red_mul_product0[(gv_i+1)%N]),
       .mul_product1_o(mul2red_mul_product1[(gv_i+1)%N]),
       .mul_cpa_product_o(mul2red_mul_cpa_product[(gv_i+1)%N]),
       .byp_o(mul2red_byp[(gv_i+1)%N]),
       
       .sel_byp_i(mul_sel_byp[gv_i]),
       .sel_1_i(mul_sel_1[gv_i]),
       .adv_mul_i(mul_adv_mul[gv_i]),
       .adv_byp_i(mul_adv_byp[gv_i])
       );
    
    poly_red 
      # ( .CpaBits (MulCpaBits),
          .CpaCoeffs (CpaCoeffs),
          .useCPA ( useCPA ) )
    _poly_red
      (
       .clk_i,
       .rst_ni,   
       
       .mul_product0_i(mul2red_mul_product0[gv_i]),
       .mul_product1_i(mul2red_mul_product1[gv_i]),
       .mul_cpa_product_i(mul2red_mul_cpa_product[gv_i]),
       .byp_i(mul2red_byp[gv_i]),
       .mul_o(red2mul_mul[(gv_i+1)%N]),
       .byp_o(red2mul_byp[(gv_i+1)%N]),
       
       .x_i(x[gv_i]),
       .sel_x_i(red_sel_x[gv_i]),   
       .sel_mul_i(red_sel_mul[gv_i]),
       .adv_mul_i(red_adv_mul[gv_i]),
       .adv_byp_i(red_adv_byp[gv_i])
       );

    // control signal decode
    logic [$clog2(ExpoBits)-1:0] expo_index;

    always_comb begin
      expo_index = cycle_q[gv_i][$clog2(ExpoBits)-1:0];
      cycle_d[gv_i] = start[gv_i] ? 'd1 : cycle_q[gv_i]=='d257 
                ? '0 : (cycle_q[gv_i] + |cycle_q[gv_i]); 
      done_d[gv_i] = cycle_q[gv_i]=='d257;
      sqr_sel_x[gv_i] = start[gv_i];
      sqr_adv_sqr[gv_i] = start[gv_i] ||
                          cycle_q[gv_i]>'d0 && cycle_q[gv_i]<'d253;
      sqr_adv_mul[gv_i] = Exponent[expo_index] &&
                          cycle_q[gv_i]>='d1 && cycle_q[gv_i]<'d254;
      mul_sel_byp[(gv_i+1)%N] = cycle_q[gv_i]=='d255;
      mul_sel_1[gv_i] = start[gv_i];
      mul_adv_mul[gv_i] = Exponent[expo_index-1] &&
                          cycle_q[gv_i]>='d2 && cycle_q[gv_i]<'d255 
                          || cycle_q[gv_i]=='d256;
      mul_adv_byp[gv_i] = cycle_q[gv_i]<'d257 && !mul_adv_mul[gv_i];
      red_sel_x[gv_i] = start[gv_i];
      red_sel_mul[gv_i] = Exponent[expo_index-2] &&
                          cycle_q[gv_i]>='d3 && cycle_q[gv_i]<'d256 
                          || cycle_q[gv_i]=='d257;
      red_adv_mul[gv_i] = Exponent[expo_index] &&
                          cycle_q[gv_i]>='d1 && cycle_q[gv_i]<'d254 
                          || cycle_q[gv_i]=='d255;
      red_adv_byp[gv_i] = start[gv_i] ||
                          !Exponent[expo_index] &&
                          cycle_q[gv_i]>='d1 && cycle_q[gv_i]<'d254
                          || cycle_q[gv_i]=='d254 
                          || cycle_q[gv_i]=='d257; 
    end

    // control state
    always_ff @(posedge clk_i or negedge rst_ni) begin
      if (rst_ni == 1'b0) begin
        cycle_q[(gv_i+1)%N] <= 'd0;
        done_q[(gv_i+1)%N] <= 'b0;
      end else begin
        cycle_q[(gv_i+1)%N] <= cycle_d[gv_i];
        done_q[(gv_i+1)%N] <= done_d[gv_i];
      end
    end

    // map results from datapaths to outputs based on rotation phase
    if (SYNC) begin : sync_done
      always_comb begin
        done_o[gv_i] = done_q[gv_i];
        x_o[gv_i] = done_q[gv_i] ? red2mul_byp[gv_i] : 'h0;
      end
    end else begin
      always_comb begin
        done_o[gv_i] = done_q[(gv_i+phase_q)%N];
        x_o[gv_i] = done_q[(gv_i+phase_q)%N] ? 
                    red2mul_byp[(gv_i+phase_q)%N] : 'h0;
      end
    end

  end


`ifndef SYNTHESIS
  // Debug aid
  poly_t i0_sqr2sqr_sqr;
  poly_t i0_sqr2mul_sqr;
  poly_t i0_red2mul_mul;
  poly_t i0_red2mul_byp;
  logic [NumBits2x-1:0] i0_mul2red_mul_product0;
  logic [NumBits2x-1:0] i0_mul2red_mul_product1;
  logic [CpaCoeffs-1:0][MulCpaBits:0] i0_mul2red_mul_cpa_product;
  poly_t i0_mul2red_byp;

  logic [8:0] i0_cycle_q;
  logic i0_done_q;
  logic i0_sqr_sel_x, i0_sqr_adv_sqr, i0_sqr_adv_mul;
  logic i0_mul_sel_byp, i0_mul_sel_1, i0_mul_adv_mul, i0_mul_adv_byp;
  logic i0_red_sel_x, i0_red_sel_mul, i0_red_adv_mul, i0_red_adv_byp;
  always_comb begin
    i0_sqr2sqr_sqr = sqr2sqr_sqr[phase_q];
    i0_sqr2mul_sqr = sqr2mul_sqr[phase_q];
    i0_red2mul_mul = red2mul_mul[phase_q];
    i0_red2mul_byp = red2mul_byp[phase_q];
    i0_mul2red_mul_product0 = mul2red_mul_product0[phase_q];
    i0_mul2red_mul_product1 = mul2red_mul_product1[phase_q];
    i0_mul2red_mul_cpa_product = mul2red_mul_cpa_product[phase_q];
    i0_mul2red_byp = mul2red_byp[phase_q];
    i0_cycle_q = cycle_q[phase_q];
    i0_done_q = done_q[phase_q];
    i0_sqr_sel_x = sqr_sel_x[phase_q];
    i0_sqr_adv_sqr = sqr_adv_sqr[phase_q];
    i0_sqr_adv_mul = sqr_adv_mul[phase_q];
    i0_mul_sel_byp = mul_sel_byp[phase_q];
    i0_mul_sel_1 = mul_sel_1[phase_q];
    i0_mul_adv_mul = mul_adv_mul[phase_q];
    i0_mul_adv_byp = mul_adv_byp[phase_q];
    i0_red_sel_x = red_sel_x[phase_q];
    i0_red_sel_mul = red_sel_mul[phase_q];
    i0_red_adv_mul = red_adv_mul[phase_q];
    i0_red_adv_byp = red_adv_byp[phase_q];
  end
`endif


endmodule
