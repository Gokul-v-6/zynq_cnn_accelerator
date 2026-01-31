// tb_axis_fifo.v
`timescale 1ns/1ps

module tb_axis_fifo;

    localparam DATA_W = 32;
    localparam IMG_W  = 64;
    localparam IMG_H  = 64;
    localparam NPIX   = IMG_W * IMG_H;

    reg aclk;
    reg aresetn;

    // AXIS input
    reg  [DATA_W-1:0] s_axis_tdata;
    reg               s_axis_tvalid;
    wire              s_axis_tready;
    reg               s_axis_tlast;

    // AXIS output
    wire [DATA_W-1:0] m_axis_tdata;
    wire              m_axis_tvalid;
    reg               m_axis_tready;
    wire              m_axis_tlast;

    // Instantiate FIFO
    axis_fifo #(
        .DATA_W(DATA_W),
        .DEPTH(16)
    ) dut (
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

    // clock 100MHz
    initial begin
        aclk = 0;
        forever #5 aclk = ~aclk;
    end

    // deterministic pseudo random byte
    function [7:0] prand8(input integer seed);
        begin
            prand8 = (seed * 17 + 23) & 8'hFF;
        end
    endfunction

    // expected pattern
    reg [DATA_W-1:0] expected [0:NPIX-1];
    integer i;

    initial begin
        for (i = 0; i < NPIX; i = i + 1) begin
            integer x, y;
            reg [7:0] R, G, B;
            x = i % IMG_W;
            y = i / IMG_W;

            R = prand8(i);
            G = prand8(x + 50);
            B = prand8(y + 100);

            expected[i] = {8'h00, R, G, B};
        end
    end

    integer send_idx;
    integer recv_idx;
    integer errors;

    // reset/init
    initial begin
        aresetn = 0;
        s_axis_tdata  = 0;
        s_axis_tvalid = 0;
        s_axis_tlast  = 0;
        m_axis_tready = 0;
        errors = 0;
        send_idx = 0;
        recv_idx = 0;

        repeat(10) @(posedge aclk);
        aresetn = 1;

        repeat(5) @(posedge aclk);
    end

    // Randomly toggle output ready (simulate DMA stalls)
    always @(posedge aclk) begin
        if (!aresetn) begin
            m_axis_tready <= 0;
        end else begin
            // 75% ready, 25% stall
            if (($random % 4) != 0)
                m_axis_tready <= 1'b1;
            else
                m_axis_tready <= 1'b0;
        end
    end

    // Sender: may stall input sometimes too
    always @(posedge aclk) begin
        if (!aresetn) begin
            s_axis_tvalid <= 0;
            s_axis_tdata  <= 0;
            s_axis_tlast  <= 0;
        end else begin
            // If all sent, stop
            if (send_idx >= NPIX) begin
                s_axis_tvalid <= 1'b0;
                s_axis_tlast  <= 1'b0;
            end else begin
                // 80% chance to try sending
                if (($random % 10) < 8) begin
                    s_axis_tvalid <= 1'b1;
                    s_axis_tdata  <= expected[send_idx];
                    s_axis_tlast  <= (send_idx == NPIX-1);
                end else begin
                    // occasionally deassert valid
                    s_axis_tvalid <= 1'b0;
                    s_axis_tlast  <= 1'b0;
                end

                // Advance only when handshake occurs
                if (s_axis_tvalid && s_axis_tready) begin
                    send_idx <= send_idx + 1;
                end
            end
        end
    end

    // Receiver + checker
    always @(posedge aclk) begin
        if (!aresetn) begin
            recv_idx <= 0;
        end else begin
            if (m_axis_tvalid && m_axis_tready) begin
                if (m_axis_tdata !== expected[recv_idx]) begin
                    errors <= errors + 1;
                    if (errors < 10) begin
                        $display("[ERR] idx=%0d got=%h exp=%h", recv_idx, m_axis_tdata, expected[recv_idx]);
                    end
                end

                // TLAST check
                if (recv_idx == NPIX-1) begin
                    if (m_axis_tlast !== 1'b1) begin
                        errors <= errors + 1;
                        $display("[ERR] TLAST missing at final pixel!");
                    end
                end else begin
                    if (m_axis_tlast !== 1'b0) begin
                        errors <= errors + 1;
                        $display("[ERR] TLAST early at idx=%0d", recv_idx);
                    end
                end

                recv_idx <= recv_idx + 1;

                // Finish
                if (recv_idx == NPIX-1) begin
                    #50;
                    if (errors == 0)
                        $display("✅ PASS: FIFO output matches input. No errors.");
                    else
                        $display("❌ FAIL: errors=%0d", errors);

                    $finish;
                end
            end
        end
    end

endmodule
