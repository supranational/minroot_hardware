// Copyright Supranational LLC
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

//
// Simple behavioral implementation of a Wallace tree compressor
//

module tree
  #( 
     parameter num_inputs = 2,
     parameter input_width = 8,
     parameter verif_en = 0
     )
  (
   input logic [num_inputs-1:0][input_width-1:0] INPUT,
   output logic [input_width-1:0] OUT0,
   output logic [input_width-1:0] OUT1
   );

  always_comb begin
    OUT0 = 0;
    OUT1 = 0;
    for(int i=0;i<num_inputs;i++) begin
      if (i & 1)
        OUT1 += INPUT[i];
      else
        OUT0 += INPUT[i];
    end
  end

endmodule
