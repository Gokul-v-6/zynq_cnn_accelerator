`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 29.01.2026 19:39:03
// Design Name: 
// Module Name: conv3x3_relu
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


module conv3x3_relu#(
    // Sobel vertical kernel by default
    parameter signed [7:0] W0 =  1,
    parameter signed [7:0] W1 =  0,
    parameter signed [7:0] W2 = -1,
    parameter signed [7:0] W3 =  1,
    parameter signed [7:0] W4 =  0,
    parameter signed [7:0] W5 = -1,
    parameter signed [7:0] W6 =  1,
    parameter signed [7:0] W7 =  0,
    parameter signed [7:0] W8 = -1
)(
    input  wire        aclk,
    input  wire        aresetn,

    // 3x3 window
    input  wire [7:0]  w0,w1,w2,
    input  wire [7:0]  w3,w4,w5,
    input  wire [7:0]  w6,w7,w8,
    input  wire        win_valid,
    input  wire        win_last,

    // AXI-stream output
    output reg  [31:0] m_axis_data,
    output reg         m_axis_valid,
    input  wire        m_axis_ready,
    output reg         m_axis_last
);

    wire out_fire = m_axis_valid && m_axis_ready;

    // accept new window when output reg free
    wire accept = win_valid && (!m_axis_valid || out_fire);

    // signed pixels
    wire signed [8:0] p0 = {1'b0,w0};
    wire signed [8:0] p1 = {1'b0,w1};
    wire signed [8:0] p2 = {1'b0,w2};
    wire signed [8:0] p3 = {1'b0,w3};
    wire signed [8:0] p4 = {1'b0,w4};
    wire signed [8:0] p5 = {1'b0,w5};
    wire signed [8:0] p6 = {1'b0,w6};
    wire signed [8:0] p7 = {1'b0,w7};
    wire signed [8:0] p8 = {1'b0,w8};

    // full MAC in one cycle (combinational)
    wire signed [23:0] acc =
          p0*W0 + p1*W1 + p2*W2
        + p3*W3 + p4*W4 + p5*W5
        + p6*W6 + p7*W7 + p8*W8;

    wire [15:0] relu = (acc > 0) ? acc[15:0] : 16'd0;

    always @(posedge aclk) begin
        if (!aresetn) begin
            m_axis_valid <= 0;
            m_axis_data  <= 0;
            m_axis_last  <= 0;
        end else begin

            if (accept) begin
                m_axis_data  <= {16'd0, relu};
                m_axis_valid <= 1'b1;
                m_axis_last  <= win_last;
            end
            else if (out_fire) begin
                m_axis_valid <= 0;
                m_axis_last  <= 0;
            end
        end
    end

endmodule

