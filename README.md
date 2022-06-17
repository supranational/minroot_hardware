# MinRoot VDF Hardware Engine

System Verilog implementation of the [MinRoot](https://khovratovich.github.io/MinRoot/minroot.pdf) VDF using the [Pasta Curves](https://electriccoin.co/blog/the-pasta-curves-for-halo-2-and-beyond/). The intended usage is within an ASIC to be developed for the Ethereum 2 and Filecoin protocols.

# Contents

**doc**
Command and status register (CSR) details in html format

**rtl**
- ahb - AHB subordinate CSR bridge
- components - primitive components (synchronizer, clock gate, compression tree)
- csr - primitives and specific CSRs for minroot, utilized [reggen](https://github.com/lowRISC/opentitan/tree/master/util/reggen) from the [OpenTitan](https://opentitan.org/) project
- minroot_engine - main engine performing minroot over pasta curves
- top - top level 

**tb**
Basic testbench to demonstrate functionality

# Test

The environment is currently setup for [VCS](https://www.synopsys.com/verification/simulation/vcs.html). No other simulators have been attempted. 

To run the test:
```
cd tb
make
```

# License
This repository is licensed under the [Apache License Version 2.0](LICENSE) software license.
