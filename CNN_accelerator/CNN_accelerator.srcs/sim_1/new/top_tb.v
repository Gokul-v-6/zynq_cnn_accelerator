`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 29.01.2026 20:24:04
// Design Name: 
// Module Name: top_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


`timescale 1ns/1ps

module tb_cnn_accel;

    localparam IMG_W = 64;
    localparam IMG_H = 64;
    localparam NPIX  = IMG_W*IMG_H;

    reg aclk;
    reg aresetn;

    // AXI input
    reg  [31:0] s_axis_data;
    reg         s_axis_valid;
    wire        s_axis_ready;
    reg         s_axis_last;

    // AXI output
    wire [31:0] m_axis_data;
    wire        m_axis_valid;
    reg         m_axis_ready;
    wire        m_axis_last;

    cnn_accel_top dut (
        .aclk(aclk),
        .aresetn(aresetn),

        .s_axis_data(s_axis_data),
        .s_axis_valid(s_axis_valid),
        .s_axis_ready(s_axis_ready),
        .s_axis_last(s_axis_last),

        .m_axis_data(m_axis_data),
        .m_axis_valid(m_axis_valid),
        .m_axis_ready(m_axis_ready),
        .m_axis_last(m_axis_last)
    );

    // ---------------- Clock ----------------
    initial begin
        aclk = 0;
        forever #5 aclk = ~aclk;   // 100 MHz
    end

    // ---------------- Test image + golden ----------------
    reg [7:0] img [0:NPIX-1];
    integer   gold [0:NPIX-1];

    integer i;

    initial begin
        for (i=0;i<NPIX;i=i+1)
            img[i] = i[7:0];
    end

    task compute_golden;
        integer x,y;
        integer acc;
        begin
            for (y=0;y<IMG_H;y=y+1)
                for (x=0;x<IMG_W;x=x+1) begin
                    if (x<2 || y<2)
                        gold[y*IMG_W+x] = 0;
                    else begin
                        acc =
                          img[(y-2)*IMG_W+(x-2)] -
                          img[(y-2)*IMG_W+(x)]   +
                          img[(y-1)*IMG_W+(x-2)] -
                          img[(y-1)*IMG_W+(x)]   +
                          img[(y)*IMG_W+(x-2)]   -
                          img[(y)*IMG_W+(x)];

                        if (acc < 0) acc = 0;
                        gold[y*IMG_W+x] = acc;
                    end
                end
        end
    endtask

    integer send_idx;
    integer recv_idx;
    integer errors;
    integer start_cycle;
    integer first_out;
    integer end_cycle;
    integer cycles;

    // ---------------- Main stimulus ----------------
    initial begin
        compute_golden();

        // init
        aresetn = 0;
        s_axis_valid = 0;
        s_axis_data  = 0;
        s_axis_last  = 0;
        m_axis_ready = 1;

        recv_idx = 0;
        errors   = 0;

        // hold reset
        repeat(10) @(posedge aclk);
        aresetn = 1;

        // VERY IMPORTANT: wait one clean cycle after reset
        @(posedge aclk);

        start_cycle = $time;

        // send pixels (no fancy handshake - continuous stream)
        send_idx = 0;
        while (send_idx < NPIX) begin
            @(posedge aclk);
            s_axis_valid <= 1'b1;
            s_axis_data  <= {24'd0, img[send_idx]};
            s_axis_last  <= (send_idx == NPIX-1);
            send_idx = send_idx + 1;
        end

        @(posedge aclk);
        s_axis_valid <= 0;
        s_axis_last  <= 0;
    end

    // ---------------- Output checker ----------------
    always @(posedge aclk) begin
        if (m_axis_valid && m_axis_ready) begin

            if (recv_idx == 0)
                first_out = $time;

            if (m_axis_data[15:0] !== gold[recv_idx][15:0]) begin
                errors = errors + 1;
                if (errors < 10)
                    $display("ERR idx=%0d got=%0d exp=%0d",
                        recv_idx, m_axis_data[15:0], gold[recv_idx]);
            end

            recv_idx = recv_idx + 1;

            if (m_axis_last) begin
                end_cycle = $time;
                cycles = (end_cycle - start_cycle)/10;

                $display("===============================");
                if (errors==0)
                    $display("✅ PASS: RTL matches GOLDEN");
                else
                    $display("❌ FAIL errors=%0d", errors);

                $display("First output latency = %0d cycles",
                         (first_out-start_cycle)/10);
                $display("Total frame cycles  = %0d", cycles);
                $display("Throughput ≈ %f pixels/cycle",
                         recv_idx*1.0/cycles);
                $display("===============================");

                $finish;
            end
        end
    end

endmodule

