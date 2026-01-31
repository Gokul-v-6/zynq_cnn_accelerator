`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 19.01.2026 21:42:09
// Design Name: 
// Module Name: axis_window
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
/*this module uses shiting operation similat to shift register with 2 line buffers

*/

module axis_window #(
    parameter IMG_W = 64,
    parameter IMG_H = 64
)(
    input  wire        aclk,
    input  wire        aresetn,

    input  wire [31:0] s_axis_data,
    input  wire        s_axis_valid,
    output wire        s_axis_ready,
    input  wire        s_axis_last,

    output reg  [7:0]  w0,w1,w2,
    output reg  [7:0]  w3,w4,w5,
    output reg  [7:0]  w6,w7,w8,

    output reg         win_valid,
    output reg         win_last
);

    assign s_axis_ready = 1'b1;
    wire in_fire = s_axis_valid;

    wire [7:0] pix = s_axis_data[7:0];

    reg [7:0] line1 [0:IMG_W-1];
    reg [7:0] line2 [0:IMG_W-1];

    reg [7:0] sr0,sr1,sr3,sr4,sr6,sr7;

    integer x,y,i;

    always @(posedge aclk) begin
        if(!aresetn) begin
            x<=0; y<=0;
            win_valid<=0; win_last<=0;
            sr0<=0;sr1<=0;sr3<=0;sr4<=0;sr6<=0;sr7<=0;

            for(i=0;i<IMG_W;i=i+1) begin
                line1[i]<=0;
                line2[i]<=0;
            end

        end else begin
            win_valid<=0;
            win_last<=0;

            if(in_fire) begin

                // output window
                w0<=sr0; w1<=sr1; w2<=line2[x];
                w3<=sr3; w4<=sr4; w5<=line1[x];
                w6<=sr6; w7<=sr7; w8<=pix;

                // shift registers
                sr0<=sr1;
                sr1<=line2[x];
                sr3<=sr4;
                sr4<=line1[x];
                sr6<=sr7;
                sr7<=pix;

                // update line buffers
                line2[x]<=line1[x];
                line1[x]<=pix;

                if (x >= 2 && y >= 2) begin
                    win_valid <= 1'b1;
                    win_last  <= s_axis_last;
                end
                

                if(x==IMG_W-1) begin
                    x<=0;
                    y<=y+1;
                end else
                    x<=x+1;
            end
        end
    end
endmodule

