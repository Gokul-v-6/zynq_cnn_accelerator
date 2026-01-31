`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 18.01.2026 13:56:15
// Design Name: 
// Module Name: axis_fifo
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


module axis_fifo #(
    parameter DATA_W = 32,
    parameter DEPTH  = 128
)(
    input  wire               aclk,
    input  wire               aresetn,

    input  wire [DATA_W-1:0]  s_axis_data,
    input  wire               s_axis_valid,
    output wire               s_axis_ready,
    input  wire               s_axis_last,

    output reg  [DATA_W-1:0]  m_axis_data,
    output reg                m_axis_valid,
    input  wire               m_axis_ready,
    output reg                m_axis_last
);

    localparam PTR_W = $clog2(DEPTH);

    reg [DATA_W-1:0] mem [0:DEPTH-1];
    reg              mem_last [0:DEPTH-1];

    reg [PTR_W-1:0] wr_ptr;
    reg [PTR_W-1:0] rd_ptr;
    reg [PTR_W:0]   count;

    integer i;

    wire fifo_full  = (count == DEPTH);
    wire fifo_empty = (count == 0);

    assign s_axis_ready = !fifo_full;

    wire push = s_axis_valid && s_axis_ready;
    wire pop  = m_axis_ready && m_axis_valid;

    always @(posedge aclk) begin
        if (!aresetn) begin
            wr_ptr <= 0;
            rd_ptr <= 0;
            count  <= 0;

            m_axis_valid <= 0;
            m_axis_data  <= 0;
            m_axis_last  <= 0;

            for (i=0;i<DEPTH;i=i+1) begin
                mem[i] <= 0;
                mem_last[i] <= 0;
            end

        end else begin

            // PUSH
            if (push) begin
                mem[wr_ptr] <= s_axis_data;
                mem_last[wr_ptr] <= s_axis_last;
                wr_ptr <= wr_ptr + 1'b1;
            end

            // POP
            if (!fifo_empty && (!m_axis_valid || pop)) begin
                m_axis_data  <= mem[rd_ptr];
                m_axis_last  <= mem_last[rd_ptr];
                m_axis_valid <= 1'b1;
                rd_ptr <= rd_ptr + 1'b1;
            end else if (pop) begin
                m_axis_valid <= 0;
            end

            // COUNT
            case ({push,pop})
                2'b10: count <= count + 1'b1;
                2'b01: count <= count - 1'b1;
                default: count <= count;
            endcase
        end
    end
endmodule
