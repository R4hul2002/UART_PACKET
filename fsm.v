`timescale 1ns / 1ps

module packetizer_fsm #(
    parameter BAUD_RATE = 115200,
    parameter CLK_FREQ = 50000000,
    parameter DATA_WIDTH = 8,
    parameter BAUD_COUNT = CLK_FREQ / BAUD_RATE
)(
    input wire clk,
    input wire rst,
    input wire [DATA_WIDTH-1:0] fifo_data,
    input wire fifo_empty,
    input wire fifo_data_valid,
    output reg fifo_read_en,
    input wire tx_ready,
    output reg serial_out,
    output reg tx_busy,
    output reg [2:0] debug_state  
);

    // States - using parameters instead of typedef enum
    parameter IDLE         = 3'd0;
    parameter WAIT_TX_READY = 3'd1;
    parameter READ_FIFO    = 3'd2;
    parameter SEND_START   = 3'd3;
    parameter SEND_DATA    = 3'd4;
    parameter SEND_STOP    = 3'd5;
    parameter DONE         = 3'd6;
    
    reg [2:0] state, next_state;
    reg [3:0] bit_count;
    reg [DATA_WIDTH-1:0] shift_reg;
    reg [31:0] baud_counter;
    reg baud_tick;
    
    // State transition
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
        end else begin
            state <= next_state;
        end
    end
    
    // Baud rate generator
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            baud_counter <= 0;
            baud_tick <= 0;
        end else begin
            if (state != IDLE && state != WAIT_TX_READY && state != READ_FIFO) begin
                if (baud_counter == BAUD_COUNT - 1) begin
                    baud_counter <= 0;
                    baud_tick <= 1;
                end else begin
                    baud_counter <= baud_counter + 1;
                    baud_tick <= 0;
                end
            end else begin
                baud_counter <= 0;
                baud_tick <= 0;
            end
        end
    end
    
    // Next state logic
    always @(*) begin
        next_state = state;
        fifo_read_en = 0;
        tx_busy = 1;
        
        case (state)
            IDLE: begin
                tx_busy = 0;
                if (!fifo_empty) begin
                    next_state = WAIT_TX_READY;
                end
            end
            
            WAIT_TX_READY: begin
                if (tx_ready) begin
                    next_state = READ_FIFO;
                end
            end
            
            READ_FIFO: begin
                fifo_read_en = 1;
                next_state = SEND_START;
            end
            
            SEND_START: begin
                if (baud_tick) begin
                    next_state = SEND_DATA;
                end
            end
            
            SEND_DATA: begin
                if (baud_tick && bit_count == DATA_WIDTH - 1) begin
                    next_state = SEND_STOP;
                end
            end
            
            SEND_STOP: begin
                if (baud_tick) begin
                    next_state = DONE;
                end
            end
            
            DONE: begin
                next_state = IDLE;
            end
            
            default: begin
                next_state = IDLE;
            end
        endcase
    end
    
    // Data path
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            shift_reg <= 0;
            bit_count <= 0;
            serial_out <= 1;
        end else begin
            case (state)
                IDLE: begin
                    serial_out <= 1;
                end
                
                READ_FIFO: begin
                    if (fifo_data_valid) begin
                        shift_reg <= fifo_data;
                    end
                end
                
                SEND_START: begin
                    serial_out <= 0;
                    bit_count <= 0;
                end
                
                SEND_DATA: begin
                    if (baud_tick) begin
                        serial_out <= shift_reg[bit_count];
                        bit_count <= bit_count + 1;
                    end
                end
                
                SEND_STOP: begin
                    serial_out <= 1;
                end
                
                default: begin
                    serial_out <= 1;
                end
            endcase
        end
         debug_state <= state;
    end

endmodule
