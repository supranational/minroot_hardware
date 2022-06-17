// Copyright Supranational LLC
//

module tb;

  localparam int HCLK_HALF_PERIOD = 5000;
  localparam int CLK_HALF_PERIOD  = 500;

  import ahb_pkg::*;
  import csr_pkg::*;

  localparam bit FLOP_RESP  = 1;
  localparam bit WAIT_STATE = 1;

  logic            hclk;
  logic            hreset_n;
  logic            hsel;
  csr_addr_e       haddr;
  htrans_e         htrans;
  hburst_e         hburst;    // Unused
  hsize_t          hsize;     // Unused
  hprot_t          hprot;     // Unused
  logic            hmastlock; // Unused
  logic            hwrite;
  csr_data_t       hwdata;
  csr_data_t       hrdata;
  hresp_e          hresp;
  logic            hready;
  logic            alarm;
  logic            clk;

  csr_data_t       rdata;

  csr_addr_e       addr;
  csr_data_t       hwdata_ap;

  // ----------------------------------------------------------------------
  // Pull in the engine configuration info

  localparam int N_MINROOT           = 1;//FIXME
  localparam int N_MINROOT_PER_GROUP = 1;//FIXME

  function automatic csr_addr_e get_minroot_reg_addr
    (int i, csr_addr_e offset);
    get_minroot_reg_addr = csr_addr_e'((i << S_ADDR_WIDTH) + offset);
  endfunction

  // ----------------------------------------------------------------------
  // DUT instance.

  minroot_vdf_x #(.N(N_MINROOT_PER_GROUP)) dut
    (
     .hclk_i(hclk),
     .hreset_ni(hreset_n),
     .hsel_i(hsel),
     .haddr_i(haddr),
     .htrans_i(htrans),
     .hburst_i(hburst),
     .hsize_i(hsize),
     .hprot_i(hprot),
     .hmastlock_i(hmastlock),
     .hwrite_i(hwrite),
     .hwdata_i(hwdata),
     .hrdata_o(hrdata),
     .hresp_o(hresp),
     .hready_o(hready),
     .alarm_i(alarm),
     .clk_i(clk)
     );

  // ----------------------------------------------------------------------
  // AHB driver.

  default clocking sub @(posedge hclk);
    output hreset_n,
           hwdata_ap,
           hsize, hprot, hmastlock, hburst,
           hsel, haddr, htrans, hwrite, hwdata;
    input  hrdata, hresp, hready;
  endclocking

  task ahb_write
    (
     input  csr_addr_e addr,
     ref    csr_data_t wdata[$]
     );
    begin
      foreach (wdata[i]) begin
        do ##1; while (!sub.hready);
        sub.hsel      <= 1'b1;
        sub.haddr     <= addr;
        sub.hwrite    <= 1'b1;
        sub.htrans    <= i == 0 ? HTRANS_NONSEQ : HTRANS_SEQ;
        sub.hwdata    <= hwdata_ap;
        sub.hwdata_ap <= wdata[i];
        addr = addr.next;
      end
    end
  endtask

  task ahb_read
    (
     input  csr_addr_e addr,
     ref    csr_data_t rdata[$]
     );
    begin
      foreach (rdata[i]) begin
        do ##1; while (!sub.hready);
        sub.hsel      <= 1'b1;
        sub.haddr     <= addr;
        sub.hwrite    <= 1'b0;
        sub.htrans    <= i == 0 ? HTRANS_NONSEQ : HTRANS_SEQ;
        sub.hwdata    <= hwdata_ap;
        sub.hwdata_ap <= 'x;
        if (i >= 2) rdata[i-2] = hrdata;
        addr = addr.next;
      end
      do ##1; while (!sub.hready);
      sub.hsel      <= 1'b0;
      sub.haddr     <= csr_addr_e'('x);
      sub.hwrite    <= 'x;
      sub.htrans    <= HTRANS_IDLE;
      sub.hwdata    <= hwdata_ap;
      sub.hwdata_ap <= 'x;
      if (rdata.size() >= 2) rdata[rdata.size()-2] = hrdata;
      do ##1; while (!sub.hready);
      if (rdata.size() >= 1) rdata[rdata.size()-1] = hrdata;
    end
  endtask

  task ahb_idle
    (
     input int num_idle=1
     );
    begin
      do ##1; while (!sub.hready);
      sub.hsel      <= 1'b0;
      sub.haddr     <= csr_addr_e'('x);
      sub.hwrite    <= 'x;
      sub.htrans    <= HTRANS_IDLE;
      sub.hwdata    <= hwdata_ap;
      sub.hwdata_ap <= 'x;
      for (int i = 1; i < num_idle; i++) begin
        do ##1; while (!sub.hready);
        sub.hwdata  <= 'x;
      end
    end
  endtask

  // ----------------------------------------------------------------------
  // CSR helpers tasks.

  task automatic csr_wr
    (
     input  csr_addr_e addr,
     input  csr_data_t data
     );
    begin
      csr_data_t wdata[$] = {data};
      ahb_write(addr, wdata);
    end
  endtask

  task automatic csr_wr_n
    (
     input  csr_addr_e addr,
     ref    csr_data_t wdata[$]
     );
    ahb_write(addr, wdata);
  endtask

  task automatic csr_rd
    (
     input  csr_addr_e addr,
     output csr_data_t data
     );
    begin
      csr_data_t rdata[$];
      rdata.push_front(8'hff);
      ahb_read(addr, rdata);
      data = rdata.pop_front();
    end
  endtask

  task automatic csr_rd_n
    (
     input  csr_addr_e addr,
     ref    csr_data_t rdata[$]
     );
    ahb_read(addr, rdata);
  endtask

  task automatic csr_poll
    (
     input  csr_addr_e addr,
     input  csr_data_t data,
     input  csr_data_t mask
     );
    begin
      csr_data_t rdata;
      do begin
        csr_rd(addr, rdata);
      end while ((mask & rdata) != (mask & data));
    end
  endtask

  // ----------------------------------------------------------------------
  // Waves.

  `include "trace.svh"

  // ----------------------------------------------------------------------
  // Clock generation.

  initial hclk = 1'b0;
  always #HCLK_HALF_PERIOD hclk = !hclk;

  initial clk = 1'b0;
  always #CLK_HALF_PERIOD clk = !clk;

  // ----------------------------------------------------------------------
  // Stimulus code.

  `include "minroot_test.svh"

  initial begin

    // Starting values for all outputs.
    alarm     = '0;
    hsel      = '0;
    haddr     = csr_addr_e'('x);
    hwrite    = 'x;
    hwdata    = 'x;
    hwdata_ap = 'x;
    htrans    = HTRANS_IDLE;
    hburst    = HBURST_INCR;
    hsize     = $clog2($bits(csr_data_t)/8);
    hprot     = '0;
    hmastlock = '0;
    hreset_n  = '0;

    // Deassert reset.
    ##10 sub.hreset_n <= '1;
    ##10;

    test();

    $finish;
  end

endmodule
