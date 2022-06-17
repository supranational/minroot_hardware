# Example: make vcs

# ----------------------------------------------------------------------
# Should not need to modify below here.

TOP            ?= tb
WAVES          ?= 1
LOGFILE        ?= sim.log
V_FILES         = -F files.f

# VCS three step flow.
# Analyze (AN)
V_AN_CMD        = vlogan
V_AN_SWITCHES   = -full64 -sverilog -timescale=1ps/1ps -assert svaext
V_AN_DEFINES    =

ifeq ($(WAVES), 1)
  V_AN_DEFINES  := ${V_AN_DEFINES} +define+TRACE_VPD
endif

# Elaborate (EL)
V_EL_CMD        = vcs
V_EL_SWITCHES   = -full64 -debug_access+all  +vcs+lic+wait \
		  -suppress=TBIFASL

# Simulate (SM)
V_SM_CMD        = ./simv
V_SM_SWITCHES   = -l $(LOGFILE) +vcs+lic+wait

vcs:
	$(V_AN_CMD) $(V_AN_SWITCHES) $(V_AN_DEFINES) $(V_FILES)
	$(V_EL_CMD) $(V_EL_SWITCHES) $(TOP)
	$(V_SM_CMD) $(V_SM_SWITCHES)

clean:
	rm -f simv ucli.key
	rm -rf simv.daidir
	rm -rf csrc
	rm -rf AN.DB
	rm -f vc_hdrs.h
	rm -rf DVEfiles

real_clean: clean
	rm -f *.vpd
	rm -f xprop.log
	rm -f $(LOGFILE)
