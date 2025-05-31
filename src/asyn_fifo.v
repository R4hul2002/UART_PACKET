`timescale 1ns / 1ps

module async_fifo #(
    parameter DATA_WIDTH = 8,
    parameter FIFO_DEPTH = 16,
    parameter ADDR_WIDTH = $clog2(FIFO_DEPTH)
)(
    input wire wr_clk,
    input wire rd_clk,
    input wire rst,
    input wire [DATA_WIDTH-1:0] data_in,
    input wire write_en,
    input wire read_en,
    output reg [DATA_WIDTH-1:0] data_out,
    output wire full,
    output wire empty,
    output reg data_valid
);

    // Memory
    reg [DATA_WIDTH-1:0] mem [0:FIFO_DEPTH-1];

    // Binary and Gray pointers
    reg  [ADDR_WIDTH:0] wr_ptr_bin = 0, rd_ptr_bin = 0;
    wire [ADDR_WIDTH:0] wr_ptr_gray, rd_ptr_gray;
    reg  [ADDR_WIDTH:0] wr_ptr_gray_rdclk = 0, rd_ptr_gray_wrclk = 0;
    reg  [ADDR_WIDTH:0] wr_ptr_gray_rdclk_sync1 = 0, wr_ptr_gray_rdclk_sync2 = 0;
    reg  [ADDR_WIDTH:0] rd_ptr_gray_wrclk_sync1 = 0, rd_ptr_gray_wrclk_sync2 = 0;

    // Gray code conversion
    function [ADDR_WIDTH:0] bin2gray(input [ADDR_WIDTH:0] bin);
        bin2gray = bin ^ (bin >> 1);
    endfunction

    function [ADDR_WIDTH:0] gray2bin(input [ADDR_WIDTH:0] gray);
        integer i;
        begin
            gray2bin = 0;
            for (i = ADDR_WIDTH; i >= 0; i = i - 1)
                gray2bin[i] = ^(gray >> i);
        end
    endfunction

    assign wr_ptr_gray = bin2gray(wr_ptr_bin);
    assign rd_ptr_gray = bin2gray(rd_ptr_bin);

    // Write domain: Sync read pointer
    always @(posedge wr_clk or posedge rst) begin
        if (rst) begin
            rd_ptr_gray_wrclk_sync1 <= 0;
            rd_ptr_gray_wrclk_sync2 <= 0;
        end else begin
            rd_ptr_gray_wrclk_sync1 <= rd_ptr_gray;
            rd_ptr_gray_wrclk_sync2 <= rd_ptr_gray_wrclk_sync1;
        end
    end

    // Read domain: Sync write pointer
    always @(posedge rd_clk or posedge rst) begin
        if (rst) begin
            wr_ptr_gray_rdclk_sync1 <= 0;
            wr_ptr_gray_rdclk_sync2 <= 0;
        end else begin
            wr_ptr_gray_rdclk_sync1 <= wr_ptr_gray;
            wr_ptr_gray_rdclk_sync2 <= wr_ptr_gray_rdclk_sync1;
        end
    end

    // Full and Empty
    wire [ADDR_WIDTH:0] rd_ptr_bin_sync = gray2bin(rd_ptr_gray_wrclk_sync2);
    wire [ADDR_WIDTH:0] wr_ptr_bin_sync = gray2bin(wr_ptr_gray_rdclk_sync2);

    assign full  = (wr_ptr_bin[ADDR_WIDTH]     != rd_ptr_bin_sync[ADDR_WIDTH]) &&
                   (wr_ptr_bin[ADDR_WIDTH-1:0] == rd_ptr_bin_sync[ADDR_WIDTH-1:0]);

    assign empty = (rd_ptr_bin == wr_ptr_bin_sync);

    // Write logic
    always @(posedge wr_clk or posedge rst) begin
        if (rst)
            wr_ptr_bin <= 0;
        else if (write_en && !full) begin
            mem[wr_ptr_bin[ADDR_WIDTH-1:0]] <= data_in;
            wr_ptr_bin <= wr_ptr_bin + 1;
        end
    end

    // Read logic
    always @(posedge rd_clk or posedge rst) begin
        if (rst) begin
            rd_ptr_bin <= 0;
            data_out <= 0;
            data_valid <= 0;
        end else begin
            data_valid <= 0;
            if (read_en && !empty) begin
                data_out <= mem[rd_ptr_bin[ADDR_WIDTH-1:0]];
                rd_ptr_bin <= rd_ptr_bin + 1;
                data_valid <= 1;
            end
        end
    end

endmodule
