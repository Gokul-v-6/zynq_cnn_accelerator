`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 17.01.2026 23:13:25
// Design Name: 
// Module Name: axi_s_passthrough
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

//This module acts as a wrapper for CNN model

module axis_passthrough #(parameter DATA_WIDTH = 32)(
    input aclk,
    input aresetn,
    //read stream. Processor to CNN
    input [DATA_WIDTH-1:0]s_axis_data,
    input s_axis_valid,
    output s_axis_ready,
    input s_axis_last,
    //write stream. CNN to procerrsor
    output reg [DATA_WIDTH-1:0]m_axis_data,
    output reg m_axis_valid,
    input m_axis_ready,
    output reg m_axis_last
    );
    //We will be able to read if our current data channel register is not valid (This is to precharge axi slave)
   // 2nd case when write op is going on,i.e, m_axis_ready
 assign s_axis_ready = (m_axis_ready || !m_axis_valid);
 always @(posedge aclk) begin
        if(!aresetn) begin
            m_axis_data<=0;
            m_axis_valid<=0;
            m_axis_last<=0;
        end
        else begin
            if(s_axis_valid && s_axis_ready) begin
                m_axis_data<=s_axis_data;
                m_axis_valid<=s_axis_last;
            end
            else if(m_axis_valid && m_axis_ready) begin
                m_axis_valid <= 0;
                m_axis_last<=0;
            end            
        end
 end 
endmodule
