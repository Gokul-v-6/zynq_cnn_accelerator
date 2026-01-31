`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 18.01.2026 11:13:31
// Design Name: 
// Module Name: tb_axis_passthrough
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


// tb_axis_passthrough.v
`timescale 1ns/1ps

module tb_axis_passthrough;

    localparam DATA_W = 32;
    localparam IMG_W  = 64;
    localparam IMG_H  = 64;
    localparam NPIX   = IMG_W * IMG_H;

    reg aclk;
    reg aresetn;

    // DUT input stream
    reg  [DATA_W-1:0] s_axis_tdata;
    reg               s_axis_tvalid;
    wire              s_axis_tready;
    reg               s_axis_tlast;

    // DUT output stream
    wire [DATA_W-1:0] m_axis_tdata;
    wire              m_axis_tvalid;
    reg               m_axis_tready;
    wire              m_axis_tlast;

    // Instantiate DUT
    axis_passthrough #(.DATA_W(DATA_W)) dut (
        .aclk(aclk),
        .aresetn(aresetn),

        .s_axis_data(s_axis_tdata),
        .s_axis_valid(s_axis_tvalid),
        .s_axis_ready(s_axis_tready),
        .s_axis_last(s_axis_tlast),

        .m_axis_data(m_axis_tdata),
        .m_axis_valid(m_axis_tvalid),
        .m_axis_ready(m_axis_tready),
        .m_axis_last(m_axis_tlast)
    );

    // Clock: 100 MHz (10 ns period)
    initial begin
        aclk = 0;
        forever #5 aclk = ~aclk;
    end

    // Simple pseudo-random function (deterministic)
    function [7:0] prand8(input integer seed);
        begin
            prand8 = (seed * 13 + 7) & 8'hFF;
        end
    endfunction

    // Scoreboard memory
    reg [DATA_W-1:0] expected [0:NPIX-1];
    integer wr_idx, rd_idx;
    integer errors;

    // Prepare expected frame
// Scoreboard memory
reg [DATA_W-1:0] expected [0:NPIX-1];
integer wr_idx;
integer x, y;
reg [7:0] R, G, B;

initial begin
    for (wr_idx = 0; wr_idx < NPIX; wr_idx = wr_idx + 1) begin
        // Compute x,y from index
        x = wr_idx % IMG_W;
        y = wr_idx / IMG_W;

        // RGB pattern
        R = prand8(wr_idx);
        G = prand8(x + 50);
        B = prand8(y + 100);

        expected[wr_idx] = {8'h00, R, G, B};
    end
end


    // Drive reset + init signals
    initial begin
        aresetn = 0;
        s_axis_tdata  = 0;
        s_axis_tvalid = 0;
        s_axis_tlast  = 0;
        m_axis_tready = 0;
        errors = 0;

        // Reset for a few cycles
        repeat(10) @(posedge aclk);
        aresetn = 1;

        // Enable output readiness after reset
        repeat(2) @(posedge aclk);
        m_axis_tready = 1;
    end

    // Random stalls on output to test backpressure
    // (This is VERY important. Real DMA can stall.)
    always @(posedge aclk) begin
        if (!aresetn) begin
            m_axis_tready <= 0;
        end else begin
            // 80% chance ready=1, 20% chance ready=0
            if (($random % 10) < 8)
                m_axis_tready <= 1'b1;
            else
                m_axis_tready <= 1'b0;
        end
    end

    // Sender process: streams full frame
    integer send_idx;
    initial begin
        // Wait until reset is released
        @(posedge aresetn);
        repeat(5) @(posedge aclk);

        send_idx = 0;
        s_axis_tvalid = 1'b0;

        while (send_idx < NPIX) begin
            @(posedge aclk);
            if (s_axis_tready) begin
                s_axis_tdata  <= expected[send_idx];
                s_axis_tvalid <= 1'b1;
                s_axis_tlast  <= (send_idx == NPIX-1);
                send_idx      <= send_idx + 1;
            end else begin
                // hold valid/data stable until ready
                s_axis_tvalid <= s_axis_tvalid;
                s_axis_tdata  <= s_axis_tdata;
                s_axis_tlast  <= s_axis_tlast;
            end
        end

        // done sending
        @(posedge aclk);
        s_axis_tvalid <= 1'b0;
        s_axis_tlast  <= 1'b0;

        $display("[TB] Finished sending %0d pixels", NPIX);
    end

    // Receiver/Checker process
    initial begin
        rd_idx = 0;
        @(posedge aresetn);

        forever begin
            @(posedge aclk);

            if (m_axis_tvalid && m_axis_tready) begin
                // Check data
                if (m_axis_tdata !== expected[rd_idx]) begin
                    errors = errors + 1;
                    if (errors < 10) begin
                        $display("[ERR] idx=%0d got=%h exp=%h", rd_idx, m_axis_tdata, expected[rd_idx]);
                    end
                end

                // Check TLAST only on last
                if (rd_idx == NPIX-1) begin
                    if (m_axis_tlast !== 1'b1) begin
                        errors = errors + 1;
                        $display("[ERR] TLAST not asserted on last pixel!");
                    end
                end else begin
                    if (m_axis_tlast !== 1'b0) begin
                        errors = errors + 1;
                   
                    end
                end

                rd_idx = rd_idx + 1;

                if (rd_idx == NPIX) begin
                    // We received the full frame
                    #20;
                    
                   $finish;
                end
            end
        end
    end

endmodule

