# Zynq_CNN_Accelerator
Hardware-accelerated CNN inference on Xilinx Zynq SoC using custom AXI-Stream IP and AXI DMA. Implements a 3×3 convolution accelerator in FPGA fabric with ARM Cortex-A9 software control, enabling high-throughput edge image processing.

---
## Block Diagram

[<img width="450" height="900" alt="CNN_ip_block diagram drawio (4)" src="https://github.com/user-attachments/assets/2280f4ad-14f5-4292-bca8-10fd60e7f61d" />](screenshots/block_diagram.png)

- Window generator require 2 lines and 3 pixals in line 3 to send a valid 3x3 window. Hence , initial stall cycles = 2x64 + 2 = 130 cycles.
- After reaching stable state convolution produces a output once every cycle.

---
##  Need for Hardware Accelerator
Many modern applications like object detection and image processing require fast, real-time computation on embedded devices. Running Convolutional Neural Networks (CNNs entirely on a processor is often slow, especially on resource-limited systems, because convolution involves a large number of repetitive mathematical operations.

To overcome this, this project uses the FPGA fabric of a Xilinx Zynq SoC to accelerate the most compute-intensive parts of the CNN. The ARM Cortex-A9 processor manages data transfer system control and preprocessing while the FPGA performs the convolution and ReLU operations in hardware.

This hardware/software co-design significantly reduces processing time and CPU load, enabling faster inference and making the system suitable for edge vision applications where performance and efficiency are critical.

