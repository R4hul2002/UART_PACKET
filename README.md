

## **Goal:** Convert parallel packets into serial UART-compatible packets with FIFO buffering and flow control.

**Modules:**
#### RTL Design Files
- `packetizer_fsm.v` - Wraps input data into a packet structure.
- `async_fifo.v` - Buffers data asynchronously between domains.
- `uart_packetizer_top.v` - Top-level wrapper connecting all submodules.
#### Testbench 
- `tb.v`  - Testbench top file with all the functionality covered 
- `ftb.v` - Testbench for FSM 
- `atb.v` - Testbench for Async FIFO

### Constraints

- `const.xdc` - The clock frequency constraints are given here 

---

## 🛠️ Prerequisites

| Tool/Software         | Version or Higher |
|-----------------------|-------------------|
| **Vivado**            | **2020.2 +**      |
| **Ubuntu**            | **2020.04 + with LTS**|
| **part or SoC**       | **Kintex**    |
---

## 🧪 Running the Files


### make synthesis 
```bash
make clean    # Clean previous builds
make          # Run full implementation
make report   # View key metrics
```
### Simulate
```bash
make sim
```



### NOTE : If the build script fails to open please do it manully. Else connect with me Wil guide you with the issue. The issue raise due to several factor mis match in the OS release to cause trouble 