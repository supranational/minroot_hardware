// Copyright Supranational LLC
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

module minroot_vdf_i
  import ahb_pkg::*;
  import csr_pkg::*;
  #(
    parameter type haddr_t = csr_addr_e,
    parameter type hdata_t = csr_data_t
    )
  (
   input  logic                             hclk_i,
   input  logic                             hreset_ni,
   input  logic                             hsel_i,
   input  haddr_t                           haddr_i,
   input  htrans_e                          htrans_i,
   input  hburst_e                          hburst_i,
   input  hsize_t                           hsize_i,
   input  hprot_t                           hprot_i,
   input  logic                             hmastlock_i,
   input  logic                             hwrite_i,
   input  hdata_t                           hwdata_i,
   output hdata_t                           hrdata_o,
   output hresp_e                           hresp_o,
   output logic                             hready_o,

   input  logic                             alarm_i,
   input  logic                             clk_i,

   output logic                             mr_rst_no,
   output logic                             mr_clk_en_o,
   output logic                             mr_start_o,
   output logic [mrt_pkg::IterBits - 1:0]   mr_starting_iter_o,
   output logic [mrt_pkg::IterBits - 1:0]   mr_iters_o,
   output mrt_pkg::poly_t                   mr_x_begin_o,
   output mrt_pkg::poly_t                   mr_y_begin_o,
   input  mrt_pkg::poly_t                   mr_x_end_i,
   input  mrt_pkg::poly_t                   mr_y_end_i,
   input  logic [mrt_pkg::IterBits - 1:0]   mr_cur_iter_i,
   input  logic                             mr_iter_done_i

   );

  // ----------------------------------------------------------------------
  // CSRs.

  minroot_vdf_reg_pkg::minroot_vdf_reg2hw_t reg2hw;
  minroot_vdf_reg_pkg::minroot_vdf_hw2reg_t hw2reg;

  minroot_vdf_reg_top _csr
    (
     .clk_i(hclk_i),
     .rst_ni(hreset_ni),
     .hsel_i,
     .haddr_i,
     .htrans_i,
     .hburst_i,
     .hsize_i,
     .hprot_i,
     .hmastlock_i,
     .hwrite_i,
     .hwdata_i,
     .hrdata_o,
     .hresp_o,
     .hready_o,
     .reg2hw,
     .hw2reg
     );

  //
  // Pass CMD_* values from the CSR interface to the engine.  Software should
  // write all CMD_* values other than CMD_START with desired values and then
  // write the CMD_START register.  The write of CMD_START will initiate a full
  // handshake with the engine to initiate the operation.
  //

  logic               start_req_q, start_ack_sync, start_ack;
  
  always_ff @(posedge hclk_i or negedge hreset_ni) begin
    if (!hreset_ni) begin
      start_req_q <= 0;
    end else begin
      start_req_q <= (start_req_q || reg2hw.cmd_start.qe) && !start_ack_sync;
    end
  end

  logic [mrt_pkg::IterBits - 1:0]   cmd_start_iter;
  logic [mrt_pkg::IterBits - 1:0]   cmd_iter_count;
  mrt_pkg::poly_t                   cmd_x;
  mrt_pkg::poly_t                   cmd_y;

  // sanity check that # of multiregs matches size of poly signals
`ifndef SYNTHESIS
  initial begin
    assert($size(reg2hw.cmd_iter_count) == (($bits(cmd_iter_count)+31)/32));
    assert($size(reg2hw.cmd_start_iter) == (($bits(cmd_start_iter)+31)/32));
    assert($size(reg2hw.cmd_x) == (($bits(cmd_x)+31)/32));
    assert($size(reg2hw.cmd_y) == (($bits(cmd_y)+31)/32));
  end
`endif

  // reorg values from multireg structs to simple signals
  always_comb begin

    cmd_start_iter = $bits(cmd_start_iter)'(reg2hw.cmd_start_iter);
    cmd_iter_count = $bits(cmd_iter_count)'(reg2hw.cmd_iter_count);
    cmd_x = $bits(cmd_x)'(reg2hw.cmd_x);
    cmd_y = $bits(cmd_y)'(reg2hw.cmd_y);

  end

  cdc_sync _start_ack_sync
    (
     .clk_i(hclk_i),
     .rst_ni(hreset_ni),
     .i(start_ack),
     .o(start_ack_sync)
     );

  //
  // Pass STATUS_* values from the engine back to the CSR interface.  A full 
  // handshake on status_{req,ack} qualifies a flopping of the engine clock 
  // domain STATUS_* values on the CSR clock domain.  This occurs whenever the 
  // engine has a result, final or intermediate, to return.  Asychronously, the 
  // host will read STATUS_* values via the CSR interface.  To ensure STATUS_* 
  // read is atomic, a snapshot of STATUS_* values is taken when STATUS_JOB_ID 
  // is read.  These snapshotted values will be returned for reads of other 
  // STATUS_* values until STATUS_JOB_ID is read again and another snapshot is 
  // taken.
  //

  logic status_req_sync, status_req_sync_p1q, status_req, status_ack_q;
  logic status_req_sync_p2q;
  logic [mrt_pkg::IterBits - 1:0] status_iter, status_iter_q;
  mrt_pkg::poly_t status_x, status_x_q;
  mrt_pkg::poly_t status_y, status_y_q;

  // sanity check that # of multiregs matches size of poly signals
`ifndef SYNTHESIS
  initial begin
    assert($size(hw2reg.status_x) == (($bits(status_x)+31)/32));
    assert($size(hw2reg.status_y) == (($bits(status_y)+31)/32));
  end
`endif

  cdc_sync _status_req_sync
    (
     .clk_i(hclk_i),
     .rst_ni(hreset_ni),
     .i(status_req),
     .o(status_req_sync)
     );

  // flop STATUS_* values from engine onto CSR clock domain
  always_ff @(posedge hclk_i or negedge hreset_ni) begin
    if (!hreset_ni) begin
      status_req_sync_p1q <= '0;
      status_req_sync_p2q <= '0;
      status_iter_q <= '0;
      status_x_q <= '0;
      status_y_q <= '0;
    end else if (reg2hw.control.reset.q) begin
      status_req_sync_p1q <= '0;
      status_req_sync_p2q <= '0;
      status_iter_q <= '0;
      status_x_q <= '0;
      status_y_q <= '0;
    end else begin
      status_req_sync_p1q <= status_req_sync;
      status_req_sync_p2q <= status_req_sync_p1q;
      if (status_req_sync_p1q && !status_req_sync_p2q) begin
        status_iter_q <= status_iter;
        status_x_q <= status_x;
        status_y_q <= status_y;
      end
    end
  end

  always_ff @(posedge hclk_i or negedge hreset_ni) begin
    if (!hreset_ni) begin
      status_ack_q <= 0;
    end else begin
      status_ack_q <= status_req_sync;
    end
  end

  // snapshot CSR domain STATUS_* values on read of STATUS_JOB_ID
  always_ff @(posedge hclk_i or negedge hreset_ni) begin
    if (!hreset_ni) begin
      for(int i=0;i<$size(hw2reg.status_iter);i=i+1)
        hw2reg.status_iter[i].d <= 0;
      for(int i=0;i<$size(hw2reg.status_x);i=i+1)
        hw2reg.status_x[i].d <= 0;
      for(int i=0;i<$size(hw2reg.status_y);i=i+1)
        hw2reg.status_y[i].d <= 0;
    end
    else if (reg2hw.status_job_id.re) begin
      for(int i=0;i<$size(hw2reg.status_iter);i=i+1)
        hw2reg.status_iter[i].d <= status_iter_q >> (i*32);
      for(int i=0;i<$size(hw2reg.status_x);i=i+1)
        hw2reg.status_x[i].d <= status_x_q >> (i*32);
      for(int i=0;i<$size(hw2reg.status_y);i=i+1)
        hw2reg.status_y[i].d <= status_y_q >> (i*32);
    end
  end
  always_comb begin
    hw2reg.status_job_id.d = reg2hw.cmd_job_id.q;
    hw2reg.status_end.d    = '0;
  end



  // ----------------------------------------------------------------------
  // Instantiate the high-speed stuff.
  // No hclk_i (100MHz-ish) stuff beyond this point.

`ifdef FPGA
  // Synchronize reset into the high speed domain
  cdc_sync #(.RANK(4), .RESET(0)) _square_rst_sync
    (
     .clk_i,
     .rst_ni(1'b1),
     .i(hreset_ni && !reg2hw.control.reset.q),
     .o(mr_rst_no)
     );
`else
  assign mr_rst_no = hreset_ni && !reg2hw.control.reset.q;
`endif

  cdc_sync #(.RANK(4)) _engine_clk_enable_sync
    (
     .clk_i,
     .rst_ni(mr_rst_no),
     .i(reg2hw.control.clk_enable.q && !alarm_i),
     .o(mr_clk_en_o)
     );

  logic engine_clk;
  clk_gate _engine_clk
    (
     .clk_i,
     .test_i(1'b0),
     .en_i(mr_clk_en_o),
     .clk_o(engine_clk)
     );

  //
  // Incoming CMD_* register handoff to engine clock domain.  Broadside capture 
  // input CMD_* values on engine clock domain in response to start req/ack 
  // cross domain handshake
  //
  
  logic start_req_sync, start_req_sync_q;
  
  cdc_sync #(.RANK(4)) _start_sync
    (
     .clk_i(engine_clk),
     .rst_ni(mr_rst_no),
     .i(start_req_q),
     .o(start_req_sync)
     );
  
  always_ff @(posedge engine_clk or negedge mr_rst_no) begin
    if (!mr_rst_no) begin
      start_req_sync_q <= '0;
      mr_starting_iter_o <= '0;
      mr_iters_o <= '0;
      mr_x_begin_o <= '0;
      mr_y_begin_o <= '0;
    end else begin
      start_req_sync_q <= start_req_sync;
      if (start_req_sync && !start_req_sync_q) begin
        mr_starting_iter_o <= cmd_start_iter;
        mr_iters_o <= cmd_iter_count;
        mr_x_begin_o <= cmd_x;
        mr_y_begin_o <= cmd_y;
      end
    end
  end

  always_ff @(posedge engine_clk or negedge mr_rst_no) begin
    if (!mr_rst_no) begin
      mr_start_o <= 0;
      start_ack <= 1'b0;
    end
    else begin
      mr_start_o <= start_req_sync && !start_req_sync_q;
      start_ack <= start_req_sync;
    end
  end


  //
  // Outgoing STATUS_* handoff to bus clock domain full handshake.  Also
  // sample outputs of engine to ensure they are remain unchanged until
  // the next iteration is complete.
  //
  
  logic iter_done, status_ack_sync;
  mrt_pkg::poly_t x;
  mrt_pkg::poly_t y;
  logic [mrt_pkg::IterBits - 1:0] cur_iter;
  
  always_ff @(posedge engine_clk or negedge mr_rst_no) begin
    if (!mr_rst_no) begin
      status_req <= 1'b0;
    end
    else begin
      status_req <= (mr_iter_done_i || status_req) && !status_ack_sync;
    end
  end
  
  cdc_sync #(.RANK(4)) _status_ack
    (
     .clk_i(engine_clk),
     .rst_ni(mr_rst_no),
     .i(status_ack_q),
     .o(status_ack_sync)
     );

  always_ff @(posedge engine_clk or negedge mr_rst_no) begin
    if (!mr_rst_no) begin
      status_iter <= '0;
      status_x <= '0;
      status_y <= '0;
    end else begin
      if (mr_iter_done_i) begin
        status_iter <= mr_cur_iter_i;
        status_x <= mr_x_end_i;
        status_y <= mr_y_end_i;
      end
    end
  end
  
endmodule



