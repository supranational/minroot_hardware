`ifdef TRACE_FSDB
  initial begin
    $fsdbDumpvars;
    $fsdbDumpSVA;
    $fsdbDumpMDA;
  end
`endif
`ifdef TRACE_VPD
  initial begin
    $vcdplusfile("waves.vpd");
    $vcdpluson;
    $vcdplusdeltacycleon;
    $vcdplusglitchon;
    $vcdplusmemon;
  end
`endif
