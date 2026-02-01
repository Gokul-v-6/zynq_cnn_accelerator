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

---
## High-Level Flow
<img width="879" height="232" alt="Screenshot 2026-01-31 213502" src="https://github.com/user-attachments/assets/a2062933-0005-4edd-b67f-29cb9099dda3" />

- The ARM Cortex-A9 processor runs bare-metal C code and controls data movement.
- Input image pixels are stored in DDR memory.
- AXI DMA streams the image from DDR into the FPGA-based CNN accelerator using AXI4-Stream.

- Inside the accelerator:
    - An input FIFO (32 × 32-bit) buffers incoming pixels.
    - A window generator forms 3×3 neighborhoods using two line buffers.
    - A 3×3 convolution + ReLU block performs multiply–accumulate and activation.
    - An output FIFO (32 × 32-bit) buffers the results.
- The processed pixels are streamed back to DDR through AXI DMA.
- The ARM processor reads the output and can display or further process the results.

---
## CNN Model Features 
- **3x3 Convolution Core** - Uses a single 3x3 kernal optimized for streaming operation.
-  **Greyscale Input** - Operates on 8-bit grayscale pixles to reduce bandwidthand hardware complexity.
-  **AXI4-Stream** - Processes pixels as continuous stream, enabling low-latency operation without frame-level buffering.
-  **Hardware ReLU Activation** - Applies ReLU directly in FPGA logic (max(0,x)), removing negative values with miimal overhead.
-  **Input and Output FIFOs** - 128 entry, 32-bit FIFOs decouple DMA bursts from compute, absorbing short-term rate mismatchs and preventing stalls.
-  **Window Generator with line buffers** - Builds 3×3 neighborhoods using two line buffers and shift registers, producing one valid window per clock after initial stall.
  
