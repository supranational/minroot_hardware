// Copyright Supranational LLC
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

// Register Package auto-generated by `reggen` containing data structure

package minroot_vdf_reg_pkg;

  // Address widths within the block
  localparam int BlockAw = 22;

  ////////////////////////////
  // Typedefs for registers //
  ////////////////////////////

  typedef struct packed {
    struct packed {
      logic        q;
    } clk_enable;
    struct packed {
      logic        q;
    } reset;
  } minroot_vdf_reg2hw_control_reg_t;

  typedef struct packed {
    logic [31:0] q;
  } minroot_vdf_reg2hw_cmd_job_id_reg_t;

  typedef struct packed {
    logic [31:0] q;
  } minroot_vdf_reg2hw_cmd_iter_count_mreg_t;

  typedef struct packed {
    logic [31:0] q;
  } minroot_vdf_reg2hw_cmd_start_iter_mreg_t;

  typedef struct packed {
    logic [31:0] q;
  } minroot_vdf_reg2hw_cmd_x_mreg_t;

  typedef struct packed {
    logic [31:0] q;
  } minroot_vdf_reg2hw_cmd_y_mreg_t;

  typedef struct packed {
    logic        q;
    logic        qe;
  } minroot_vdf_reg2hw_cmd_start_reg_t;

  typedef struct packed {
    logic [31:0] q;
    logic        qe;
    logic        re;
  } minroot_vdf_reg2hw_status_job_id_reg_t;

  typedef struct packed {
    logic [31:0] q;
  } minroot_vdf_reg2hw_status_iter_mreg_t;

  typedef struct packed {
    logic [31:0] q;
  } minroot_vdf_reg2hw_status_x_mreg_t;

  typedef struct packed {
    logic [31:0] q;
  } minroot_vdf_reg2hw_status_y_mreg_t;

  typedef struct packed {
    logic        q;
    logic        qe;
    logic        re;
  } minroot_vdf_reg2hw_status_end_reg_t;

  typedef struct packed {
    logic [31:0] q;
  } minroot_vdf_reg2hw_rw_reg_t;

  typedef struct packed {
    logic [31:0] d;
  } minroot_vdf_hw2reg_status_job_id_reg_t;

  typedef struct packed {
    logic [31:0] d;
  } minroot_vdf_hw2reg_status_iter_mreg_t;

  typedef struct packed {
    logic [31:0] d;
  } minroot_vdf_hw2reg_status_x_mreg_t;

  typedef struct packed {
    logic [31:0] d;
  } minroot_vdf_hw2reg_status_y_mreg_t;

  typedef struct packed {
    logic        d;
  } minroot_vdf_hw2reg_status_end_reg_t;

  // Register -> HW type
  typedef struct packed {
    minroot_vdf_reg2hw_control_reg_t control; // [1576:1575]
    minroot_vdf_reg2hw_cmd_job_id_reg_t cmd_job_id; // [1574:1543]
    minroot_vdf_reg2hw_cmd_iter_count_mreg_t [1:0] cmd_iter_count; // [1542:1479]
    minroot_vdf_reg2hw_cmd_start_iter_mreg_t [1:0] cmd_start_iter; // [1478:1415]
    minroot_vdf_reg2hw_cmd_x_mreg_t [9:0] cmd_x; // [1414:1095]
    minroot_vdf_reg2hw_cmd_y_mreg_t [9:0] cmd_y; // [1094:775]
    minroot_vdf_reg2hw_cmd_start_reg_t cmd_start; // [774:773]
    minroot_vdf_reg2hw_status_job_id_reg_t status_job_id; // [772:739]
    minroot_vdf_reg2hw_status_iter_mreg_t [1:0] status_iter; // [738:675]
    minroot_vdf_reg2hw_status_x_mreg_t [9:0] status_x; // [674:355]
    minroot_vdf_reg2hw_status_y_mreg_t [9:0] status_y; // [354:35]
    minroot_vdf_reg2hw_status_end_reg_t status_end; // [34:32]
    minroot_vdf_reg2hw_rw_reg_t rw; // [31:0]
  } minroot_vdf_reg2hw_t;

  // HW -> register type
  typedef struct packed {
    minroot_vdf_hw2reg_status_job_id_reg_t status_job_id; // [736:705]
    minroot_vdf_hw2reg_status_iter_mreg_t [1:0] status_iter; // [704:641]
    minroot_vdf_hw2reg_status_x_mreg_t [9:0] status_x; // [640:321]
    minroot_vdf_hw2reg_status_y_mreg_t [9:0] status_y; // [320:1]
    minroot_vdf_hw2reg_status_end_reg_t status_end; // [0:0]
  } minroot_vdf_hw2reg_t;

  // Register offsets
  import csr_pkg::csr_addr_t;
  localparam csr_addr_t MINROOT_VDF_CONTROL_OFFSET = csr_addr_t'('h200000);
  localparam csr_addr_t MINROOT_VDF_CMD_JOB_ID_OFFSET = csr_addr_t'('h201000);
  localparam csr_addr_t MINROOT_VDF_CMD_ITER_COUNT_0_OFFSET = csr_addr_t'('h201004);
  localparam csr_addr_t MINROOT_VDF_CMD_ITER_COUNT_1_OFFSET = csr_addr_t'('h201008);
  localparam csr_addr_t MINROOT_VDF_CMD_START_ITER_0_OFFSET = csr_addr_t'('h20100c);
  localparam csr_addr_t MINROOT_VDF_CMD_START_ITER_1_OFFSET = csr_addr_t'('h201010);
  localparam csr_addr_t MINROOT_VDF_CMD_X_0_OFFSET = csr_addr_t'('h201014);
  localparam csr_addr_t MINROOT_VDF_CMD_X_1_OFFSET = csr_addr_t'('h201018);
  localparam csr_addr_t MINROOT_VDF_CMD_X_2_OFFSET = csr_addr_t'('h20101c);
  localparam csr_addr_t MINROOT_VDF_CMD_X_3_OFFSET = csr_addr_t'('h201020);
  localparam csr_addr_t MINROOT_VDF_CMD_X_4_OFFSET = csr_addr_t'('h201024);
  localparam csr_addr_t MINROOT_VDF_CMD_X_5_OFFSET = csr_addr_t'('h201028);
  localparam csr_addr_t MINROOT_VDF_CMD_X_6_OFFSET = csr_addr_t'('h20102c);
  localparam csr_addr_t MINROOT_VDF_CMD_X_7_OFFSET = csr_addr_t'('h201030);
  localparam csr_addr_t MINROOT_VDF_CMD_X_8_OFFSET = csr_addr_t'('h201034);
  localparam csr_addr_t MINROOT_VDF_CMD_X_9_OFFSET = csr_addr_t'('h201038);
  localparam csr_addr_t MINROOT_VDF_CMD_Y_0_OFFSET = csr_addr_t'('h20103c);
  localparam csr_addr_t MINROOT_VDF_CMD_Y_1_OFFSET = csr_addr_t'('h201040);
  localparam csr_addr_t MINROOT_VDF_CMD_Y_2_OFFSET = csr_addr_t'('h201044);
  localparam csr_addr_t MINROOT_VDF_CMD_Y_3_OFFSET = csr_addr_t'('h201048);
  localparam csr_addr_t MINROOT_VDF_CMD_Y_4_OFFSET = csr_addr_t'('h20104c);
  localparam csr_addr_t MINROOT_VDF_CMD_Y_5_OFFSET = csr_addr_t'('h201050);
  localparam csr_addr_t MINROOT_VDF_CMD_Y_6_OFFSET = csr_addr_t'('h201054);
  localparam csr_addr_t MINROOT_VDF_CMD_Y_7_OFFSET = csr_addr_t'('h201058);
  localparam csr_addr_t MINROOT_VDF_CMD_Y_8_OFFSET = csr_addr_t'('h20105c);
  localparam csr_addr_t MINROOT_VDF_CMD_Y_9_OFFSET = csr_addr_t'('h201060);
  localparam csr_addr_t MINROOT_VDF_CMD_START_OFFSET = csr_addr_t'('h201064);
  localparam csr_addr_t MINROOT_VDF_STATUS_JOB_ID_OFFSET = csr_addr_t'('h202000);
  localparam csr_addr_t MINROOT_VDF_STATUS_ITER_0_OFFSET = csr_addr_t'('h202004);
  localparam csr_addr_t MINROOT_VDF_STATUS_ITER_1_OFFSET = csr_addr_t'('h202008);
  localparam csr_addr_t MINROOT_VDF_STATUS_X_0_OFFSET = csr_addr_t'('h20200c);
  localparam csr_addr_t MINROOT_VDF_STATUS_X_1_OFFSET = csr_addr_t'('h202010);
  localparam csr_addr_t MINROOT_VDF_STATUS_X_2_OFFSET = csr_addr_t'('h202014);
  localparam csr_addr_t MINROOT_VDF_STATUS_X_3_OFFSET = csr_addr_t'('h202018);
  localparam csr_addr_t MINROOT_VDF_STATUS_X_4_OFFSET = csr_addr_t'('h20201c);
  localparam csr_addr_t MINROOT_VDF_STATUS_X_5_OFFSET = csr_addr_t'('h202020);
  localparam csr_addr_t MINROOT_VDF_STATUS_X_6_OFFSET = csr_addr_t'('h202024);
  localparam csr_addr_t MINROOT_VDF_STATUS_X_7_OFFSET = csr_addr_t'('h202028);
  localparam csr_addr_t MINROOT_VDF_STATUS_X_8_OFFSET = csr_addr_t'('h20202c);
  localparam csr_addr_t MINROOT_VDF_STATUS_X_9_OFFSET = csr_addr_t'('h202030);
  localparam csr_addr_t MINROOT_VDF_STATUS_Y_0_OFFSET = csr_addr_t'('h202034);
  localparam csr_addr_t MINROOT_VDF_STATUS_Y_1_OFFSET = csr_addr_t'('h202038);
  localparam csr_addr_t MINROOT_VDF_STATUS_Y_2_OFFSET = csr_addr_t'('h20203c);
  localparam csr_addr_t MINROOT_VDF_STATUS_Y_3_OFFSET = csr_addr_t'('h202040);
  localparam csr_addr_t MINROOT_VDF_STATUS_Y_4_OFFSET = csr_addr_t'('h202044);
  localparam csr_addr_t MINROOT_VDF_STATUS_Y_5_OFFSET = csr_addr_t'('h202048);
  localparam csr_addr_t MINROOT_VDF_STATUS_Y_6_OFFSET = csr_addr_t'('h20204c);
  localparam csr_addr_t MINROOT_VDF_STATUS_Y_7_OFFSET = csr_addr_t'('h202050);
  localparam csr_addr_t MINROOT_VDF_STATUS_Y_8_OFFSET = csr_addr_t'('h202054);
  localparam csr_addr_t MINROOT_VDF_STATUS_Y_9_OFFSET = csr_addr_t'('h202058);
  localparam csr_addr_t MINROOT_VDF_STATUS_END_OFFSET = csr_addr_t'('h20205c);
  localparam csr_addr_t MINROOT_VDF_RW_OFFSET = csr_addr_t'('h20fff8);
  localparam csr_addr_t MINROOT_VDF_END_OF_RANGE_OFFSET = csr_addr_t'('h20fffc);

  // Reset values for hwext registers and their fields
  localparam logic [0:0] MINROOT_VDF_CMD_START_RESVAL = 1'h 0;
  localparam logic [31:0] MINROOT_VDF_STATUS_JOB_ID_RESVAL = 32'h 0;
  localparam logic [31:0] MINROOT_VDF_STATUS_ITER_0_RESVAL = 32'h 0;
  localparam logic [31:0] MINROOT_VDF_STATUS_ITER_1_RESVAL = 32'h 0;
  localparam logic [31:0] MINROOT_VDF_STATUS_X_0_RESVAL = 32'h 0;
  localparam logic [31:0] MINROOT_VDF_STATUS_X_1_RESVAL = 32'h 0;
  localparam logic [31:0] MINROOT_VDF_STATUS_X_2_RESVAL = 32'h 0;
  localparam logic [31:0] MINROOT_VDF_STATUS_X_3_RESVAL = 32'h 0;
  localparam logic [31:0] MINROOT_VDF_STATUS_X_4_RESVAL = 32'h 0;
  localparam logic [31:0] MINROOT_VDF_STATUS_X_5_RESVAL = 32'h 0;
  localparam logic [31:0] MINROOT_VDF_STATUS_X_6_RESVAL = 32'h 0;
  localparam logic [31:0] MINROOT_VDF_STATUS_X_7_RESVAL = 32'h 0;
  localparam logic [31:0] MINROOT_VDF_STATUS_X_8_RESVAL = 32'h 0;
  localparam logic [31:0] MINROOT_VDF_STATUS_X_9_RESVAL = 32'h 0;
  localparam logic [31:0] MINROOT_VDF_STATUS_Y_0_RESVAL = 32'h 0;
  localparam logic [31:0] MINROOT_VDF_STATUS_Y_1_RESVAL = 32'h 0;
  localparam logic [31:0] MINROOT_VDF_STATUS_Y_2_RESVAL = 32'h 0;
  localparam logic [31:0] MINROOT_VDF_STATUS_Y_3_RESVAL = 32'h 0;
  localparam logic [31:0] MINROOT_VDF_STATUS_Y_4_RESVAL = 32'h 0;
  localparam logic [31:0] MINROOT_VDF_STATUS_Y_5_RESVAL = 32'h 0;
  localparam logic [31:0] MINROOT_VDF_STATUS_Y_6_RESVAL = 32'h 0;
  localparam logic [31:0] MINROOT_VDF_STATUS_Y_7_RESVAL = 32'h 0;
  localparam logic [31:0] MINROOT_VDF_STATUS_Y_8_RESVAL = 32'h 0;
  localparam logic [31:0] MINROOT_VDF_STATUS_Y_9_RESVAL = 32'h 0;
  localparam logic [0:0] MINROOT_VDF_STATUS_END_RESVAL = 1'h 0;

  // Register index
`ifdef CSR_PKG_INCLUDE
  typedef enum csr_addr_t {
    MINROOT_VDF_CONTROL = csr_addr_t'('h200000),//csr-pkg-include
    MINROOT_VDF_CMD_JOB_ID = csr_addr_t'('h201000),//csr-pkg-include
    MINROOT_VDF_CMD_ITER_COUNT_0 = csr_addr_t'('h201004),//csr-pkg-include
    MINROOT_VDF_CMD_ITER_COUNT_1 = csr_addr_t'('h201008),//csr-pkg-include
    MINROOT_VDF_CMD_START_ITER_0 = csr_addr_t'('h20100c),//csr-pkg-include
    MINROOT_VDF_CMD_START_ITER_1 = csr_addr_t'('h201010),//csr-pkg-include
    MINROOT_VDF_CMD_X_0 = csr_addr_t'('h201014),//csr-pkg-include
    MINROOT_VDF_CMD_X_1 = csr_addr_t'('h201018),//csr-pkg-include
    MINROOT_VDF_CMD_X_2 = csr_addr_t'('h20101c),//csr-pkg-include
    MINROOT_VDF_CMD_X_3 = csr_addr_t'('h201020),//csr-pkg-include
    MINROOT_VDF_CMD_X_4 = csr_addr_t'('h201024),//csr-pkg-include
    MINROOT_VDF_CMD_X_5 = csr_addr_t'('h201028),//csr-pkg-include
    MINROOT_VDF_CMD_X_6 = csr_addr_t'('h20102c),//csr-pkg-include
    MINROOT_VDF_CMD_X_7 = csr_addr_t'('h201030),//csr-pkg-include
    MINROOT_VDF_CMD_X_8 = csr_addr_t'('h201034),//csr-pkg-include
    MINROOT_VDF_CMD_X_9 = csr_addr_t'('h201038),//csr-pkg-include
    MINROOT_VDF_CMD_Y_0 = csr_addr_t'('h20103c),//csr-pkg-include
    MINROOT_VDF_CMD_Y_1 = csr_addr_t'('h201040),//csr-pkg-include
    MINROOT_VDF_CMD_Y_2 = csr_addr_t'('h201044),//csr-pkg-include
    MINROOT_VDF_CMD_Y_3 = csr_addr_t'('h201048),//csr-pkg-include
    MINROOT_VDF_CMD_Y_4 = csr_addr_t'('h20104c),//csr-pkg-include
    MINROOT_VDF_CMD_Y_5 = csr_addr_t'('h201050),//csr-pkg-include
    MINROOT_VDF_CMD_Y_6 = csr_addr_t'('h201054),//csr-pkg-include
    MINROOT_VDF_CMD_Y_7 = csr_addr_t'('h201058),//csr-pkg-include
    MINROOT_VDF_CMD_Y_8 = csr_addr_t'('h20105c),//csr-pkg-include
    MINROOT_VDF_CMD_Y_9 = csr_addr_t'('h201060),//csr-pkg-include
    MINROOT_VDF_CMD_START = csr_addr_t'('h201064),//csr-pkg-include
    MINROOT_VDF_STATUS_JOB_ID = csr_addr_t'('h202000),//csr-pkg-include
    MINROOT_VDF_STATUS_ITER_0 = csr_addr_t'('h202004),//csr-pkg-include
    MINROOT_VDF_STATUS_ITER_1 = csr_addr_t'('h202008),//csr-pkg-include
    MINROOT_VDF_STATUS_X_0 = csr_addr_t'('h20200c),//csr-pkg-include
    MINROOT_VDF_STATUS_X_1 = csr_addr_t'('h202010),//csr-pkg-include
    MINROOT_VDF_STATUS_X_2 = csr_addr_t'('h202014),//csr-pkg-include
    MINROOT_VDF_STATUS_X_3 = csr_addr_t'('h202018),//csr-pkg-include
    MINROOT_VDF_STATUS_X_4 = csr_addr_t'('h20201c),//csr-pkg-include
    MINROOT_VDF_STATUS_X_5 = csr_addr_t'('h202020),//csr-pkg-include
    MINROOT_VDF_STATUS_X_6 = csr_addr_t'('h202024),//csr-pkg-include
    MINROOT_VDF_STATUS_X_7 = csr_addr_t'('h202028),//csr-pkg-include
    MINROOT_VDF_STATUS_X_8 = csr_addr_t'('h20202c),//csr-pkg-include
    MINROOT_VDF_STATUS_X_9 = csr_addr_t'('h202030),//csr-pkg-include
    MINROOT_VDF_STATUS_Y_0 = csr_addr_t'('h202034),//csr-pkg-include
    MINROOT_VDF_STATUS_Y_1 = csr_addr_t'('h202038),//csr-pkg-include
    MINROOT_VDF_STATUS_Y_2 = csr_addr_t'('h20203c),//csr-pkg-include
    MINROOT_VDF_STATUS_Y_3 = csr_addr_t'('h202040),//csr-pkg-include
    MINROOT_VDF_STATUS_Y_4 = csr_addr_t'('h202044),//csr-pkg-include
    MINROOT_VDF_STATUS_Y_5 = csr_addr_t'('h202048),//csr-pkg-include
    MINROOT_VDF_STATUS_Y_6 = csr_addr_t'('h20204c),//csr-pkg-include
    MINROOT_VDF_STATUS_Y_7 = csr_addr_t'('h202050),//csr-pkg-include
    MINROOT_VDF_STATUS_Y_8 = csr_addr_t'('h202054),//csr-pkg-include
    MINROOT_VDF_STATUS_Y_9 = csr_addr_t'('h202058),//csr-pkg-include
    MINROOT_VDF_STATUS_END = csr_addr_t'('h20205c),//csr-pkg-include
    MINROOT_VDF_RW = csr_addr_t'('h20fff8),//csr-pkg-include
    MINROOT_VDF_END_OF_RANGE = csr_addr_t'('h20fffc)//csr-pkg-include
  } minroot_vdf_csr_addr_e;
`else
  typedef enum int {
    MINROOT_VDF_CONTROL,
    MINROOT_VDF_CMD_JOB_ID,
    MINROOT_VDF_CMD_ITER_COUNT_0,
    MINROOT_VDF_CMD_ITER_COUNT_1,
    MINROOT_VDF_CMD_START_ITER_0,
    MINROOT_VDF_CMD_START_ITER_1,
    MINROOT_VDF_CMD_X_0,
    MINROOT_VDF_CMD_X_1,
    MINROOT_VDF_CMD_X_2,
    MINROOT_VDF_CMD_X_3,
    MINROOT_VDF_CMD_X_4,
    MINROOT_VDF_CMD_X_5,
    MINROOT_VDF_CMD_X_6,
    MINROOT_VDF_CMD_X_7,
    MINROOT_VDF_CMD_X_8,
    MINROOT_VDF_CMD_X_9,
    MINROOT_VDF_CMD_Y_0,
    MINROOT_VDF_CMD_Y_1,
    MINROOT_VDF_CMD_Y_2,
    MINROOT_VDF_CMD_Y_3,
    MINROOT_VDF_CMD_Y_4,
    MINROOT_VDF_CMD_Y_5,
    MINROOT_VDF_CMD_Y_6,
    MINROOT_VDF_CMD_Y_7,
    MINROOT_VDF_CMD_Y_8,
    MINROOT_VDF_CMD_Y_9,
    MINROOT_VDF_CMD_START,
    MINROOT_VDF_STATUS_JOB_ID,
    MINROOT_VDF_STATUS_ITER_0,
    MINROOT_VDF_STATUS_ITER_1,
    MINROOT_VDF_STATUS_X_0,
    MINROOT_VDF_STATUS_X_1,
    MINROOT_VDF_STATUS_X_2,
    MINROOT_VDF_STATUS_X_3,
    MINROOT_VDF_STATUS_X_4,
    MINROOT_VDF_STATUS_X_5,
    MINROOT_VDF_STATUS_X_6,
    MINROOT_VDF_STATUS_X_7,
    MINROOT_VDF_STATUS_X_8,
    MINROOT_VDF_STATUS_X_9,
    MINROOT_VDF_STATUS_Y_0,
    MINROOT_VDF_STATUS_Y_1,
    MINROOT_VDF_STATUS_Y_2,
    MINROOT_VDF_STATUS_Y_3,
    MINROOT_VDF_STATUS_Y_4,
    MINROOT_VDF_STATUS_Y_5,
    MINROOT_VDF_STATUS_Y_6,
    MINROOT_VDF_STATUS_Y_7,
    MINROOT_VDF_STATUS_Y_8,
    MINROOT_VDF_STATUS_Y_9,
    MINROOT_VDF_STATUS_END,
    MINROOT_VDF_RW,
    MINROOT_VDF_END_OF_RANGE
  } minroot_vdf_id_e;
`endif

  // Register width information to check illegal writes
  localparam logic [3:0] MINROOT_VDF_PERMIT [53] = '{
    4'b 0001, // index[ 0] MINROOT_VDF_CONTROL
    4'b 1111, // index[ 1] MINROOT_VDF_CMD_JOB_ID
    4'b 1111, // index[ 2] MINROOT_VDF_CMD_ITER_COUNT_0
    4'b 1111, // index[ 3] MINROOT_VDF_CMD_ITER_COUNT_1
    4'b 1111, // index[ 4] MINROOT_VDF_CMD_START_ITER_0
    4'b 1111, // index[ 5] MINROOT_VDF_CMD_START_ITER_1
    4'b 1111, // index[ 6] MINROOT_VDF_CMD_X_0
    4'b 1111, // index[ 7] MINROOT_VDF_CMD_X_1
    4'b 1111, // index[ 8] MINROOT_VDF_CMD_X_2
    4'b 1111, // index[ 9] MINROOT_VDF_CMD_X_3
    4'b 1111, // index[10] MINROOT_VDF_CMD_X_4
    4'b 1111, // index[11] MINROOT_VDF_CMD_X_5
    4'b 1111, // index[12] MINROOT_VDF_CMD_X_6
    4'b 1111, // index[13] MINROOT_VDF_CMD_X_7
    4'b 1111, // index[14] MINROOT_VDF_CMD_X_8
    4'b 1111, // index[15] MINROOT_VDF_CMD_X_9
    4'b 1111, // index[16] MINROOT_VDF_CMD_Y_0
    4'b 1111, // index[17] MINROOT_VDF_CMD_Y_1
    4'b 1111, // index[18] MINROOT_VDF_CMD_Y_2
    4'b 1111, // index[19] MINROOT_VDF_CMD_Y_3
    4'b 1111, // index[20] MINROOT_VDF_CMD_Y_4
    4'b 1111, // index[21] MINROOT_VDF_CMD_Y_5
    4'b 1111, // index[22] MINROOT_VDF_CMD_Y_6
    4'b 1111, // index[23] MINROOT_VDF_CMD_Y_7
    4'b 1111, // index[24] MINROOT_VDF_CMD_Y_8
    4'b 1111, // index[25] MINROOT_VDF_CMD_Y_9
    4'b 0001, // index[26] MINROOT_VDF_CMD_START
    4'b 1111, // index[27] MINROOT_VDF_STATUS_JOB_ID
    4'b 1111, // index[28] MINROOT_VDF_STATUS_ITER_0
    4'b 1111, // index[29] MINROOT_VDF_STATUS_ITER_1
    4'b 1111, // index[30] MINROOT_VDF_STATUS_X_0
    4'b 1111, // index[31] MINROOT_VDF_STATUS_X_1
    4'b 1111, // index[32] MINROOT_VDF_STATUS_X_2
    4'b 1111, // index[33] MINROOT_VDF_STATUS_X_3
    4'b 1111, // index[34] MINROOT_VDF_STATUS_X_4
    4'b 1111, // index[35] MINROOT_VDF_STATUS_X_5
    4'b 1111, // index[36] MINROOT_VDF_STATUS_X_6
    4'b 1111, // index[37] MINROOT_VDF_STATUS_X_7
    4'b 1111, // index[38] MINROOT_VDF_STATUS_X_8
    4'b 1111, // index[39] MINROOT_VDF_STATUS_X_9
    4'b 1111, // index[40] MINROOT_VDF_STATUS_Y_0
    4'b 1111, // index[41] MINROOT_VDF_STATUS_Y_1
    4'b 1111, // index[42] MINROOT_VDF_STATUS_Y_2
    4'b 1111, // index[43] MINROOT_VDF_STATUS_Y_3
    4'b 1111, // index[44] MINROOT_VDF_STATUS_Y_4
    4'b 1111, // index[45] MINROOT_VDF_STATUS_Y_5
    4'b 1111, // index[46] MINROOT_VDF_STATUS_Y_6
    4'b 1111, // index[47] MINROOT_VDF_STATUS_Y_7
    4'b 1111, // index[48] MINROOT_VDF_STATUS_Y_8
    4'b 1111, // index[49] MINROOT_VDF_STATUS_Y_9
    4'b 0001, // index[50] MINROOT_VDF_STATUS_END
    4'b 1111, // index[51] MINROOT_VDF_RW
    4'b 0001  // index[52] MINROOT_VDF_END_OF_RANGE
  };

endpackage

