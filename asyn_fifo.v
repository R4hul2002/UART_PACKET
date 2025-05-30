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

    // Memory array
    reg [DATA_WIDTH-1:0] mem [0:FIFO_DEPTH-1];
    
    // Pointers
    reg [ADDR_WIDTH:0] wr_ptr, rd_ptr;
    wire [ADDR_WIDTH:0] wr_ptr_gray, rd_ptr_gray;
    reg [ADDR_WIDTH:0] wr_ptr_gray_sync, rd_ptr_gray_sync;
    reg [ADDR_WIDTH:0] wr_ptr_gray_sync_rd, rd_ptr_gray_sync_wr;
    
    // Full and empty signals
    assign full = (wr_ptr[ADDR_WIDTH] != rd_ptr_gray_sync_wr[ADDR_WIDTH]) && 
                 (wr_ptr[ADDR_WIDTH-1:0] == rd_ptr_gray_sync_wr[ADDR_WIDTH-1:0]);
    assign empty = (wr_ptr_gray_sync_rd == rd_ptr_gray);
    
    // Gray code conversion
    function [ADDR_WIDTH:0] bin2gray;
        input [ADDR_WIDTH:0] bin;
        begin
            bin2gray = bin ^ (bin >> 1);
        end
    endfunction
    
    // Synchronizers
    always @(posedge wr_clk or posedge rst) begin
        if (rst) begin
            rd_ptr_gray_sync_wr <= 0;
        end else begin
            rd_ptr_gray_sync_wr <= rd_ptr_gray;
        end
    end
    
    always @(posedge rd_clk or posedge rst) begin
        if (rst) begin
            wr_ptr_gray_sync_rd <= 0;
        end else begin
            wr_ptr_gray_sync_rd <= wr_ptr_gray;
        end
    end
    
    // Write logic
    always @(posedge wr_clk or posedge rst) begin
        if (rst) begin
            wr_ptr <= 0;
        end else if (write_en && !full) begin
            mem[wr_ptr[ADDR_WIDTH-1:0]] <= data_in;
            wr_ptr <= wr_ptr + 1;
        end
    end
    
    assign wr_ptr_gray = bin2gray(wr_ptr);
    
    // Read logic
    always @(posedge rd_clk or posedge rst) begin
        if (rst) begin
            rd_ptr <= 0;
            data_out <= 0;
            data_valid <= 0;
        end else begin
            data_valid <= 0;
            if (read_en && !empty) begin
                data_out <= mem[rd_ptr[ADDR_WIDTH-1:0]];
                rd_ptr <= rd_ptr + 1;
                data_valid <= 1;
            end
        end
    end
    
    assign rd_ptr_gray = bin2gray(rd_ptr);

endmodule