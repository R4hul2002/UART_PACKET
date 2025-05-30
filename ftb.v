module packetizer_fsm_tb;

    parameter BAUD_RATE = 115200;
    parameter CLK_FREQ = 50000000;
    parameter DATA_WIDTH = 8;
    parameter BAUD_COUNT = CLK_FREQ / BAUD_RATE;

    reg clk;
    reg rst;
    reg [DATA_WIDTH-1:0] fifo_data;
    reg fifo_empty;
    reg fifo_data_valid;
    reg tx_ready;
    wire serial_out;
    wire fifo_read_en;
    wire tx_busy;
    wire [2:0] debug_state;

    packetizer_fsm #(
        .BAUD_RATE(BAUD_RATE),
        .CLK_FREQ(CLK_FREQ),
        .DATA_WIDTH(DATA_WIDTH)
    ) dut (
        .clk(clk),
        .rst(rst),
        .fifo_data(fifo_data),
        .fifo_empty(fifo_empty),
        .fifo_data_valid(fifo_data_valid),
        .fifo_read_en(fifo_read_en),
        .tx_ready(tx_ready),
        .serial_out(serial_out),
        .tx_busy(tx_busy),
        .debug_state(debug_state)
    );

    // Clock
    always #10 clk = ~clk;

    // Baud tick wait task
    task wait_baud_ticks(input integer count);
        integer i;
        for (i = 0; i < count; i = i + 1) begin
            #(BAUD_COUNT * 20);  // 20ns * BAUD_COUNT = 1 baud period
        end
    endtask

    // Flags to track state visits
    reg visited_IDLE;
    reg visited_WAIT_TX_READY;
    reg visited_READ_FIFO;
    reg visited_SEND_START;
    reg visited_SEND_DATA;
    reg visited_SEND_STOP;
    reg visited_DONE;

    initial begin
        clk = 0;
        rst = 1;
        fifo_data = 8'h00;
        fifo_empty = 1;
        fifo_data_valid = 0;
        tx_ready = 0;

        visited_IDLE = 0;
        visited_WAIT_TX_READY = 0;
        visited_READ_FIFO = 0;
        visited_SEND_START = 0;
        visited_SEND_DATA = 0;
        visited_SEND_STOP = 0;
        visited_DONE = 0;

        #100;
        rst = 0;

        // Send first byte
        fifo_data = 8'hA5;
        fifo_data_valid = 1;
        fifo_empty = 0;
        tx_ready = 1;

        #100;

        wait_baud_ticks(1);  // Start
        wait_baud_ticks(8);  // Data
        wait_baud_ticks(1);  // Stop

        #100;

        // Second byte
        fifo_data = 8'h3C;
        fifo_data_valid = 1;
        fifo_empty = 0;
        tx_ready = 1;

        #100;

        wait_baud_ticks(1);
        wait_baud_ticks(8);
        wait_baud_ticks(1);

        #100;

        // Third with delay in tx_ready
        fifo_data = 8'h7E;
        fifo_data_valid = 1;
        fifo_empty = 0;
        tx_ready = 0;

        #200;
        tx_ready = 1;

        wait_baud_ticks(1);
        wait_baud_ticks(8);
        wait_baud_ticks(1);

        #200;

        // Check visited states
        if (!(visited_IDLE &&
              visited_WAIT_TX_READY &&
              visited_READ_FIFO &&
              visited_SEND_START &&
              visited_SEND_DATA &&
              visited_SEND_STOP &&
              visited_DONE)) begin
            $display("❌ ERROR: Not all states were visited!");
            $stop;
        end else begin
            $display("✅ SUCCESS: All FSM states were verified.");
        end

        $stop;
    end

    // State tracking
    always @(posedge clk) begin
        case (debug_state)
            3'd0: visited_IDLE          = 1;
            3'd1: visited_WAIT_TX_READY = 1;
            3'd2: visited_READ_FIFO     = 1;
            3'd3: visited_SEND_START    = 1;
            3'd4: visited_SEND_DATA     = 1;
            3'd5: visited_SEND_STOP     = 1;
            3'd6: visited_DONE          = 1;
        endcase
    end

endmodule
