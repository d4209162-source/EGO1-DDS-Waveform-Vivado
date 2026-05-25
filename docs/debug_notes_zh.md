\# Vivado DDS 项目调试记录



\## 问题 1：Vivado 仍然调用旧文件



\### 现象



明明修改了 `top\_dds\_wavegen.v` 或 `dds\_core.v`，但仿真结果没有变化。



\### 原因



Vivado 工程中可能混入了不同路径下的同名文件，例如：



```text

C:/Users/.../Desktop/old\_project/rtl/top\_dds\_wavegen.v

E:/new\_project/rtl/top\_dds\_wavegen.v





修改的是新文件，但 Vivado 实际仿真调用的是旧文件。



解决方法

新建干净工程。

所有文件统一放在一个目录。

Add Sources 时勾选 Copy sources into project。

检查 Tcl Console：

get\_files -of\_objects \[get\_filesets sources\_1]

get\_files -of\_objects \[get\_filesets sim\_1]



确认没有旧路径文件。



问题 2：方波显示成三角波

现象



wave\_led = 010 时，理论上应输出方波，但 Vivado 波形窗口看起来像三角波。



原因



dac\_data\[7:0] 是 8 位总线。如果使用 Analog 显示，Vivado 可能会把离散采样点用斜线连接起来，看起来像三角形。



解决方法



观察方波时，不要只看 Analog 显示。



可以：



将 dac\_data\[7:0] 改成 Hexadecimal。

单独观察 dac\_data\[7]。

检查方波阶段数据是否只在 8'hFF 和 8'h00 之间变化。

问题 3：三角波后面出现长高电平

现象



三角波后面出现一段长时间水平线。



原因



testbench 中按下了 key\_start，系统进入 HOLD 状态。此时 DDS 相位累加器停止，输出保持不变。



解决方法



报告截图时，将三角波截图和 HOLD 状态截图分开。



三角波截图：只截 wave\_led = 100 且状态仍为 RUN 的区域。

HOLD 截图：单独说明状态机暂停功能。

问题 4：仿真报 Spawn failed

现象



Vivado 报错：



Spawn failed: No error



或仿真临时文件被占用。



常见原因

上一次 xsim 仿真进程没有关闭

仿真缓存目录损坏

杀毒软件占用 Vivado 临时文件

解决方法

关闭 Vivado。

在任务管理器结束：

xsim.exe

xvlog.exe

xelab.exe

vivado.exe

删除工程中的仿真缓存：

\*.sim/

\*.cache/

.Xil/

重新打开工程并运行仿真。

问题 5：不需要上板时不要纠结 XDC



本项目主要用于代码和仿真验证，不需要上板时可以不添加 .xdc 约束文件。



如果后续需要上板，则必须根据 EGO1 原理图绑定：



时钟

按键

LED

数码管

DAC 输出或扩展口



否则只能完成仿真，不能保证硬件现象。

