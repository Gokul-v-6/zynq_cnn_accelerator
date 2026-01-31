`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 29.01.2026 20:11:26
// Design Name: 
// Module Name: conv_top
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


module conv_top #(
    parameter IMG_W = 64,
    parameter IMG_H = 64
)(
    input  wire        aclk,
    input  wire        aresetn,

    // AXI stream input grayscale pixels
    input  wire [31:0] s_axis_data,
    input  wire        s_axis_valid,
    output wire        s_axis_ready,
    input  wire        s_axis_last,

    // AXI stream output conv results
    output wire [31:0] m_axis_data,
    output wire        m_axis_valid,
    input  wire        m_axis_ready,
    output wire        m_axis_last
);

    // window wires
    wire [7:0] w0,w1,w2,w3,w4,w5,w6,w7,w8;
    wire win_valid, win_last;

    axis_window #(
        .IMG_W(IMG_W),
        .IMG_H(IMG_H)
    ) u_win (
        .aclk(aclk),
        .aresetn(aresetn),

        .s_axis_data(s_axis_data),
        .s_axis_valid(s_axis_valid),
        .s_axis_ready(s_axis_ready),
        .s_axis_last(s_axis_last),

        .w0(w0),.w1(w1),.w2(w2),
        .w3(w3),.w4(w4),.w5(w5),
        .w6(w6),.w7(w7),.w8(w8),

        .win_valid(win_valid),
        .win_last(win_last)
    );

    conv3x3_relu u_conv (
        .aclk(aclk),
        .aresetn(aresetn),

        .w0(w0),.w1(w1),.w2(w2),
        .w3(w3),.w4(w4),.w5(w5),
        .w6(w6),.w7(w7),.w8(w8),
        .win_valid(win_valid),
        .win_last(win_last),

        .m_axis_data(m_axis_data),
        .m_axis_valid(m_axis_valid),
        .m_axis_ready(m_axis_ready),
        .m_axis_last(m_axis_last)
    );

endmodule

