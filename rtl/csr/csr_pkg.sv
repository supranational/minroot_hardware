// Copyright Supranational LLC
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

// CSR related types and functions

package csr_pkg;

  localparam int S_ADDR_WIDTH = 16;

  typedef logic [31:0] csr_data_t;

  typedef logic [31:0] csr_addr_t;
  typedef enum csr_addr_t
               {
                `include "minroot_vdf_reg.svh"
                } csr_addr_e;

endpackage
