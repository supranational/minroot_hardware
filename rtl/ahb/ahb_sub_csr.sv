// Copyright Supranational LLC
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

//
// AHB subordinate CSR bridge
//
// sub_valid: signals an access is ongoing.
// sub_ready: signals the access is complete, qualified by valid.
// sub_addr:  address of the access, qualified by valid.
// sub_write: 1=write access, 0=read access, qualified by valid.
// sub_wdata: write data, qualified by valid.
// sub_rdata: read data, qualified by valid AND ready.
//

module ahb_sub_csr
  import ahb_pkg::*;
  #(
    parameter type haddr_t   = logic [31:0],
    parameter type hdata_t   = logic [31:0],
    parameter bit  FLOP_RESP = 1
    )
  (
   input  logic      hclk_i,
   input  logic      hreset_ni,
   input  logic      hsel_i,
   input  haddr_t    haddr_i,
   input  htrans_e   htrans_i,
   input  hburst_e   hburst_i,
   input  hsize_t    hsize_i,
   input  hprot_t    hprot_i,
   input  logic      hmastlock_i,
   input  logic      hwrite_i,
   input  hdata_t    hwdata_i,
   output hdata_t    hrdata_o,
   output hresp_e    hresp_o,
   output logic      hready_o,

   output logic      sub_valid_o,
   input  logic      sub_ready_i,
   output haddr_t    sub_addr_o,
   output logic      sub_write_o,
   output hdata_t    sub_wdata_o,
   input  hdata_t    sub_rdata_i
   );

  // Encode such that bit 1 is the ready bit.
  localparam int READY_BIT = 0;
  enum logic [0:0] {
                    IDLE  = 1,
                    VALID = 0
                    } sub_state_q, sub_state_d;

  haddr_t sub_addr_q,   sub_addr_d;
  logic   sub_write_q,  sub_write_d;
  logic   ready_out;

  // Assign outputs.
  always_comb begin
    sub_addr_o  = sub_addr_q;
    sub_write_o = sub_write_q;
    sub_valid_o = sub_state_q == VALID;
    sub_wdata_o = hwdata_i;
  end

  // ----------------------------------------------------------------------
  // Flop addr, enable and write to subordinate for cleaner timing.

`ifndef SYNTHESIS 
  assert property (@(posedge hclk_i)
                   (sub_state_q === IDLE)
                   |->
                   hready_o);

  // Subordinate can only access AHB sizes matching the CSR width.
  assert property (@(posedge hclk_i)
                   (((hsel_i && ahb_xfer(htrans_i) && hready_o) === 1)
                    |->
                    (hsize_i == $clog2($bits(hdata_t)/8))));
`endif

  always_comb begin
    // Assume the subordinate is always ready for now.
    ready_out = 1'b1;

    // Address phase.
    if (hsel_i && ahb_xfer(htrans_i)) begin
      // Begin an access.
      sub_addr_d  = haddr_i;
      sub_write_d = hwrite_i;
      sub_state_d = VALID;
    end else begin
      // No access.
      sub_addr_d  = sub_addr_q;
      sub_write_d = sub_write_q;
      sub_state_d = IDLE;
    end

    // Data phase to this subordinate (who controls hready).
    if (sub_state_q == VALID) begin
      if (!sub_ready_i) begin
        // Subordinate isn't ready so keep the access going.
        sub_addr_d  = sub_addr_q;
        sub_write_d = sub_write_q;
        sub_state_d = sub_state_q;
        ready_out = 1'b0;
      end else if (FLOP_RESP) begin : gen_ready_state_true
        // Subordinate is ready and the response is flopped
        // so extend the access for one more cycle.
        sub_addr_d  = sub_addr_q;
        sub_write_d = sub_write_q;
        sub_state_d = IDLE;
      end
    end
  end

  always_ff @(posedge hclk_i or negedge hreset_ni) begin
    if (!hreset_ni) begin
      sub_addr_q  <= haddr_t'('1);
      sub_write_q <= '0;
      sub_state_q <= IDLE;
    end else begin
      sub_addr_q  <= sub_addr_d;
      sub_write_q <= sub_write_d;
      sub_state_q <= sub_state_d;
    end
  end

  // ----------------------------------------------------------------------
  // Read data and response flops are optional.

  // No error conditions possible.
  assign hresp_o = HRESP_OKAY;

  if (FLOP_RESP) begin : gen_flop_true

    hdata_t hrdata_q, hrdata_d;

    always_comb begin
      hready_o = sub_state_q[READY_BIT];
      hrdata_o = hrdata_q;

      if (sub_valid_o && sub_ready_i && !sub_write_q) begin
        hrdata_d = sub_rdata_i;
      end else begin
        hrdata_d = hrdata_q;
      end
    end

    always_ff @(posedge hclk_i or negedge hreset_ni) begin
      if (!hreset_ni) hrdata_q <= '0;
      else            hrdata_q <= hrdata_d;
    end

  end else begin : gen_flop_false

    always_comb begin
      hready_o = ready_out;

      if (sub_valid_o && sub_ready_i && !sub_write_q) begin
        hrdata_o = sub_rdata_i;
      end else begin
        hrdata_o = '0;
      end
    end

  end

endmodule
