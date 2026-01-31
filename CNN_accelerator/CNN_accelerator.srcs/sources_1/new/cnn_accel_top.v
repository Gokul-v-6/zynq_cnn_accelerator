`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 29.01.2026 20:19:37
// Design Name: 
// Module Name: cnn_accel_top
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


module cnn_accel_top #(
    parameter IMG_W = 64,
    parameter IMG_H = 64,
    parameter FIFO_DEPTH = 128
)(
    input  wire        aclk,
    input  wire        aresetn,

    // AXI-Stream input (grayscale pixels packed in [7:0])
    input  wire [31:0] s_axis_data,
    input  wire        s_axis_valid,
    output wire        s_axis_ready,
    input  wire        s_axis_last,

    // AXI-Stream output (conv results in [15:0])
    output wire [31:0] m_axis_data,
    output wire        m_axis_valid,
    input  wire        m_axis_ready,
    output wire        m_axis_last
);

    // ---------------- Input FIFO ----------------
    wire [31:0] ififo_data;
    wire        ififo_valid;
    wire        ififo_ready;
    wire        ififo_last;

    axis_fifo #(
        .DATA_W(32),
        .DEPTH(FIFO_DEPTH)
    ) u_in_fifo (
        .aclk(aclk),
        .aresetn(aresetn),

        .s_axis_data(s_axis_data),
        .s_axis_valid(s_axis_valid),
        .s_axis_ready(s_axis_ready),
        .s_axis_last(s_axis_last),

        .m_axis_data(ififo_data),
        .m_axis_valid(ififo_valid),
        .m_axis_ready(ififo_ready),
        .m_axis_last(ififo_last)
    );

    // ---------------- Window Generator ----------------
    wire [7:0] w0,w1,w2,w3,w4,w5,w6,w7,w8;
    wire       win_valid;
    wire       win_last;

    axis_window #(
        .IMG_W(IMG_W),
        .IMG_H(IMG_H)
    ) u_window (
        .aclk(aclk),
        .aresetn(aresetn),

        .s_axis_data(ififo_data),
        .s_axis_valid(ififo_valid),
        .s_axis_ready(ififo_ready),
        .s_axis_last(ififo_last),

        
        .w0(w0),.w1(w1),.w2(w2),
        .w3(w3),.w4(w4),.w5(w5),
        .w6(w6),.w7(w7),.w8(w8),

        .win_valid(win_valid),
        .win_last(win_last)
    );

    // ---------------- Pipelined Conv ----------------
    wire [31:0] conv_data;
    wire        conv_valid;
    wire        conv_ready;
    wire        conv_last;

    conv3x3_relu u_conv (
        .aclk(aclk),
        .aresetn(aresetn),

        .w0(w0),.w1(w1),.w2(w2),
        .w3(w3),.w4(w4),.w5(w5),
        .w6(w6),.w7(w7),.w8(w8),
        .win_valid(win_valid),
        .win_last(win_last),

        .m_axis_data(conv_data),
        .m_axis_valid(conv_valid),
        .m_axis_ready(conv_ready),
        .m_axis_last(conv_last)
    );

    // ---------------- Output FIFO ----------------
    axis_fifo #(
        .DATA_W(32),
        .DEPTH(FIFO_DEPTH)
    ) u_out_fifo (
        .aclk(aclk),
        .aresetn(aresetn),

        .s_axis_data(conv_data),
        .s_axis_valid(conv_valid),
        .s_axis_ready(conv_ready),
        .s_axis_last(conv_last),

        .m_axis_data(m_axis_data),
        .m_axis_valid(m_axis_valid),
        .m_axis_ready(m_axis_ready),
        .m_axis_last(m_axis_last)
    );

endmodule
