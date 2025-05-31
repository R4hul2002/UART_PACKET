`timescale 1ns / 1ps

module uart_packetizer_top #(
    parameter BAUD_RATE = 115200,
    parameter CLK_FREQ = 50_000_000,
    parameter FIFO_DEPTH = 16,
    parameter DATA_WIDTH = 8
)(
    input wire clk,
    input wire rst,
    
    // AXI-Stream Interface for input data
    input wire [DATA_WIDTH-1:0] s_axis_tdata,
    input wire s_axis_tvalid,
    output wire s_axis_tready,
    
    // UART Interface
    output wire serial_out,
    input wire tx_ready,
    output wire tx_busy,
    
    // FIFO Status
    output wire fifo_full,
    output wire fifo_empty
);

    // Internal signals
    wire [DATA_WIDTH-1:0] fifo_data_out;
    wire fifo_read_en;
    wire fifo_write_en;
    wire fifo_data_valid;
    
    // FIFO write enable is controlled by AXI-Stream handshake
    assign fifo_write_en = s_axis_tvalid & s_axis_tready;
    
    // Instantiate FIFO
    async_fifo #(
        .DATA_WIDTH(DATA_WIDTH),
        .FIFO_DEPTH(FIFO_DEPTH)
    ) fifo_inst (
        .wr_clk(clk),
        .rd_clk(clk),
        .rst(rst),
        .data_in(s_axis_tdata),
        .write_en(fifo_write_en),
        .read_en(fifo_read_en),
        .data_out(fifo_data_out),
        .full(fifo_full),
        .empty(fifo_empty),
        .data_valid(fifo_data_valid)
    );
    
    // AXI-Stream ready is when FIFO is not full
    assign s_axis_tready = ~fifo_full;
    
    // Instantiate Packetizer FSM
    packetizer_fsm #(
        .BAUD_RATE(BAUD_RATE),
        .CLK_FREQ(CLK_FREQ),
        .DATA_WIDTH(DATA_WIDTH)
    ) fsm_inst (
        .clk(clk),
        .rst(rst),
        .fifo_data(fifo_data_out),
        .fifo_empty(fifo_empty),
        .fifo_data_valid(fifo_data_valid),
        .fifo_read_en(fifo_read_en),
        .tx_ready(tx_ready),
        .serial_out(serial_out),
        .tx_busy(tx_busy)
    );

endmodule