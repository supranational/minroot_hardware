// Copyright Supranational LLC
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

//
// AHB types package
//

package ahb_pkg;

  typedef logic [1:0] htrans_t;
  typedef enum htrans_t { HTRANS_IDLE,
                          HTRANS_BUSY,
                          HTRANS_NONSEQ,
                          HTRANS_SEQ
                          } htrans_e;

  typedef logic [2:0] hburst_t;
  typedef enum hburst_t { HBURST_SINGLE,
                          HBURST_INCR,
                          HBURST_WRAP4,
                          HBURST_INCR4,
                          HBURST_WRAP8,
                          HBURST_INCR8,
                          HBURST_WRAP16,
                          HBURST_INCR16
                          } hburst_e;

  typedef logic [1:0] hresp_t;
  typedef enum hresp_t { HRESP_OKAY,
                         HRESP_ERROR,
                         HRESP_RETRY,
                         HRESP_SPLIT
                         } hresp_e;

  typedef logic [2:0] hsize_t;
  typedef logic [3:0] hprot_t;

  function automatic logic ahb_xfer(input htrans_e htrans);
    return htrans inside {HTRANS_NONSEQ, HTRANS_SEQ};
  endfunction

endpackage
