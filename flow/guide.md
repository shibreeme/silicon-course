# 同一个点积核的两次实现
将 dot4.sv 放在 labs 目录，将三个 Tcl 脚本放在同级 flow 目录。下面从这两个目录的父目录运行。先通过课程中的自检仿真，再做技术映射。

## FPGA 独立模块实现
在 Vivado 命令行运行：
```
vivado -mode batch -source flow/fpga.tcl -tclargs labs/dot4.sv dot4 clk xc7a35tcsg324-1 10 out/fpga
```
目标器件为 Artix-7，时钟周期为 10 ns。脚本为非时钟输入和全部输出分别预留 20% 周期的最大接口延迟，最小延迟设为零；这是教学预算，接入真实系统时应按发送端、接收端和互连替换。重点检查操作数端口到输出寄存器的 setup 路径，另查输出 ready 到输入 ready 的组合反压路径；仅设置时钟会漏掉这些路径。打开 timing.rpt，核对实际时钟与约束，然后记录寄存器间的 WNS、TNS 及最差路径上的逻辑级数。打开 routing.rpt 确认布线完成，使用 utilization.rpt 记录 DSP、LUT 和触发器。调整周期到 8 ns，改用新的输出目录，比较布线延迟与资源变化。若关键路径跨过乘法器和加法树，尝试增加流水级，同时为整条流水线传播停顿，重新验证反压下的数据顺序。

这里采用独立模块实现。上板时需要板级顶层、板卡引脚及 I/O 电平约束、时钟与复位电路，将输入向量加载到片上存储器，利用 ILA 同时观察输入和输出两侧的握手，再按已握手事务对照黄金向量。

## ASIC 标准单元映射与静态时序
在配有 Yosys、OpenSTA 和目标工艺 Liberty 库的 Linux 环境执行。替换实际库路径，并选择与设计目标一致的工艺角及工作电压、温度。
```sh
export LIBERTY=/absolute/path/to/cells.lib
yosys -l synth.log -c flow/asic.tcl -- labs/dot4.sv dot4 "$LIBERTY" out/asic
export NETLIST=out/asic/mapped.v RTL_TOP=dot4 CLOCK_PORT=clk PERIOD_NS=10
sta flow/timing.tcl
```
检查 synth.log 的单元与面积统计、未映射单元和警告。检查 STA 的时钟、未约束端点、建立与保持路径。此例给出核心时钟约束；完整接口预算还需根据上下游器件设置输入延迟、输出延迟、驱动强度和负载。综合后时序用于早期估算。

## 走向物理实现
在 OpenROAD-flow-scripts 中选择带工艺 LEF、单元 LEF、Liberty 和布线规则的平台。以 dot4 为 DESIGN_NAME，传入 RTL 和对应 SDC。依次检查布局规划中的利用率与供电网络、全局布局拥塞、时钟树偏斜、详细布线的 DRC 数量。提取寄生参数，使用实际时钟网络复查建立与保持裕量，再按工艺要求开展 LVS、DRC 和多角时序检查。保留平台版本、库角、约束、时序与面积报告，使下一次架构调整可以复现并比较。


## 本次 FPGA 实测
Vivado 2023.2 在上述器件、10 ns 周期和 2 ns 最大接口延迟下完成布线，379 条网络完成布线，布线错误为 0。资源为 307 个 LUT、20 个寄存器和 0 个 DSP。建立时间 WNS 为 −1.427 ns，TNS 为 −7.229 ns，9 个端点违例；保持时间 WHS 为 −0.314 ns，20 个端点违例。因此本版尚未达到 100 MHz 的接口时序目标。请分别检查 setup 与 hold 路径，比较流水化和调整真实接口预算之后的报告。ASIC 命令需在配置标准单元库的工具环境中验证。
