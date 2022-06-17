// Copyright Supranational LLC
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

  // ----------------------------------------------------------------------
  // MinRoot engine operation

  localparam CMD_X_n = (MINROOT_VDF_CMD_Y_0 - MINROOT_VDF_CMD_X_0)/4;
  localparam CMD_Y_n = (MINROOT_VDF_CMD_START - MINROOT_VDF_CMD_Y_0)/4;
  
  task automatic test();

    logic [N_MINROOT-1:0][31:0] cmd_job_id;
    logic [N_MINROOT-1:0][1:0][31:0] cmd_start_iter;
    logic [N_MINROOT-1:0][1:0][31:0] cmd_iter_count;
    logic [N_MINROOT-1:0][CMD_X_n-1:0][31:0] cmd_x;
    logic [N_MINROOT-1:0][CMD_Y_n-1:0][31:0] cmd_y;
    logic [N_MINROOT-1:0] running;

    logic [1:0][31:0] status_iter;
    logic [9:0][31:0] status_x, status_y;
    csr_data_t cmd[$];
    csr_data_t status[$];
    int ii,j,n,done;
    int err, error=0;

    if (N_MINROOT==0) begin
      $display("No MinRoot engines .. can't run MinRoot test");
      $finish;
    end

    // run each engine twice to ensure we can start a 2nd time
    for(int k=0;k<2;k++) begin

      // 
      // Random settings for each engine
      //

      for(int j=0;j<N_MINROOT;j++) begin
        cmd_job_id[j] = $random();
        {cmd_start_iter[j][1],cmd_start_iter[j][0]} = 1;
        {cmd_iter_count[j][1],cmd_iter_count[j][0]} = 128 + ($random() & 63);
        cmd_x[j] = mrt_tb_pkg::rand_poly();
        cmd_y[j] = mrt_tb_pkg::rand_poly();
      end


      for (int j=0;j<N_MINROOT;j++) begin
        // remove reset
        csr_wr(get_minroot_reg_addr(j,MINROOT_VDF_CONTROL), 0);
        // enable clock
        csr_wr(get_minroot_reg_addr(j,MINROOT_VDF_CONTROL), 1); 
      end

      //
      // Load parameters and startup the engines
      //

      for (int j=0;j<N_MINROOT;j++) begin

        // populate CMD_* regs and initiate with write to CMD_START
        cmd = {};
        cmd.push_back(cmd_job_id[j]);
        for(int i=0;i<2;i++) cmd.push_back(cmd_iter_count[j][i]);
        for(int i=0;i<2;i++) cmd.push_back(cmd_start_iter[j][i]);
        for(int i=0;i<CMD_X_n;i++) cmd.push_back(cmd_x[j][i]);
        for(int i=0;i<CMD_Y_n;i++) cmd.push_back(cmd_y[j][i]);
        cmd.push_back(0); // START

        $display("starting MINROOT%0d @ %x:",j,get_minroot_reg_addr(j,MINROOT_VDF_CMD_JOB_ID));
        $display("  cmd_job_id: %x",cmd_job_id[j]);
        $display("  cmd_iter_count: %x",cmd_iter_count[j]);
        $display("  cmd_start_iter: %x",cmd_start_iter[j]);
        $display("  cmd_x: %x",cmd_x[j]);
        $display("  cmd_y: %x",cmd_y[j]);
        running[j] = 1;

        csr_wr_n(get_minroot_reg_addr(j,MINROOT_VDF_CMD_JOB_ID),cmd);

      end


      //
      // Monitor progress, checking results, until all engines have
      // completed their jobs.
      //

      do begin
        
        n = N_MINROOT * (MINROOT_VDF_STATUS_END - MINROOT_VDF_STATUS_JOB_ID)/4;
        status.delete();
        for (int i=0; i<n; i++) status.push_back(0);
        csr_rd_n(MINROOT_VDF_STATUS_JOB_ID,status);
        
        done = 1;
        for (int j=0;j<N_MINROOT;j++) begin
          $display("MINROOT%d",j);
          for (int i=0;i<(MINROOT_VDF_STATUS_END - MINROOT_VDF_STATUS_JOB_ID)/4;i++) begin
            ii = i + j*(MINROOT_VDF_STATUS_END - MINROOT_VDF_STATUS_JOB_ID)/4;
            case (MINROOT_VDF_STATUS_JOB_ID + i*4) inside
              [MINROOT_VDF_STATUS_JOB_ID:MINROOT_VDF_STATUS_JOB_ID]: begin
                err = !(status[ii]==cmd_job_id[j]);
                $display("  STATUS_JOB_ID: %x %s",status[ii],err?"E":"");
              end
              [MINROOT_VDF_STATUS_ITER_0:MINROOT_VDF_STATUS_ITER_1]: begin
                status_iter[i-(MINROOT_VDF_STATUS_ITER_0-MINROOT_VDF_STATUS_JOB_ID)/4] 
                  = status[ii];
                $display("  STATUS_ITER_%0d: %x",
                         i-(MINROOT_VDF_STATUS_ITER_0-MINROOT_VDF_STATUS_JOB_ID)/4,
                         status[ii]);
              end
              [MINROOT_VDF_STATUS_X_0:MINROOT_VDF_STATUS_X_9]: begin
                status_x[i-(MINROOT_VDF_STATUS_X_0-MINROOT_VDF_STATUS_JOB_ID)/4] 
                  = status[ii];
                $display("  STATUS_X_%0d: %x",
                         i-(MINROOT_VDF_STATUS_X_0-MINROOT_VDF_STATUS_JOB_ID)/4,
                         status[ii]);
              end            
              [MINROOT_VDF_STATUS_Y_0:MINROOT_VDF_STATUS_Y_9]: begin
                status_y[i-(MINROOT_VDF_STATUS_Y_0-MINROOT_VDF_STATUS_JOB_ID)/4] 
                  = status[ii];
                $display("  STATUS_Y_%0d: %x",
                         i-(MINROOT_VDF_STATUS_Y_0-MINROOT_VDF_STATUS_JOB_ID)/4,
                         status[ii]);
              end
              default: ;
            endcase
            error |= err;
          end
          if (!mrt_tb_pkg::minroot_check
              (.x_i(cmd_x[j]),
               .y_i(cmd_y[j]),
               .x_o(status_x),
               .y_o(status_y),
               .iter(status_iter),
               .starting_iter(cmd_start_iter[j]))) begin
            $display("  STATUS_X / STATUS_Y incorrect");
            error |= 1;
          end
          if ({status_iter[1],status_iter[0]} < 
              ({cmd_iter_count[j][1],cmd_iter_count[j][0]} + 
               {cmd_start_iter[j][1],cmd_start_iter[j][0]})) begin
            $display("  state = running");
            done = 0;
          end else begin
            $display("  state = complete");
            if (running[j]) begin
              running[j] = 0;
            end
          end
        end
      end while (!done);


      for (int j=0;j<N_MINROOT;j++) begin
        // disable clock
        csr_wr(get_minroot_reg_addr(j,MINROOT_VDF_CONTROL), 'h00);
        // apply reset
        csr_wr(get_minroot_reg_addr(j,MINROOT_VDF_CONTROL), 'h10);
      end

    end

    status.delete();
    $display("minroot_test %s",error ? "FAIL" : "PASS");
    if (error) $finish;

  endtask

