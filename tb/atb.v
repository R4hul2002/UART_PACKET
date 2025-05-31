`timescale 1ns / 1ps

module tb_async_fifo;

    parameter DATA_WIDTH = 8;
    parameter FIFO_DEPTH = 16;
    parameter ADDR_WIDTH = $clog2(FIFO_DEPTH);

    // DUT I/O
    reg wr_clk = 0, rd_clk = 0, rst = 1;
    reg [DATA_WIDTH-1:0] data_in = 0;
    reg write_en = 0, read_en = 0;
    wire [DATA_WIDTH-1:0] data_out;
    wire full, empty, data_valid;

    // Instantiate DUT
    async_fifo #(
        .DATA_WIDTH(DATA_WIDTH),
        .FIFO_DEPTH(FIFO_DEPTH)
    ) dut (
        .wr_clk(wr_clk),
        .rd_clk(rd_clk),
        .rst(rst),
        .data_in(data_in),
        .write_en(write_en),
        .read_en(read_en),
        .data_out(data_out),
        .full(full),
        .empty(empty),
        .data_valid(data_valid)
    );

    // Clock generation
    always #5 wr_clk = ~wr_clk;   // 100 MHz
    always #7 rd_clk = ~rd_clk;   // ~71.4 MHz

    // Test sequence
    integer i;
    reg [DATA_WIDTH-1:0] expected_data [0:FIFO_DEPTH-1];
    integer read_index = 0;

    initial begin
        $display("Starting full-featured testbench...");
        $dumpfile("async_fifo_tb.vcd");
        $dumpvars(0, tb_async_fifo);

        // Reset
        #15 rst = 1;
        #20 rst = 0;
        #20;

        // -------------------------------
        // TEST 1: Write until full
        // -------------------------------
        $display("Test 1: Write until full");
        i = 0;
        while (!full) begin
            @(posedge wr_clk);
            data_in <= i;
            expected_data[i] = i;
            write_en <= 1;
            i = i + 1;
        end
        @(posedge wr_clk);
        write_en <= 0;
        if (full) $display("PASS: FIFO reported FULL after %0d writes", i);
        else $display("FAIL: FIFO not full when expected");

        // -------------------------------
        // TEST 2: Extra write (should be ignored)
        // -------------------------------
        @(posedge wr_clk);
        data_in <= 8'hFF;
        write_en <= 1;
        @(posedge wr_clk);
        write_en <= 0;
        $display("Test 2: Write ignored on FULL - check manually in waveform");

        // -------------------------------
        // TEST 3: Read until empty
        // -------------------------------
        $display("Test 3: Read until empty");
        read_index = 0;
        while (!empty) begin
            @(posedge rd_clk);
            read_en <= 1;
            @(posedge rd_clk);
            if (data_valid) begin
                if (data_out !== expected_data[read_index]) begin
                    $display("FAIL: Mismatch at index %0d: expected %0h, got %0h", read_index, expected_data[read_index], data_out);
                end else begin
                    $display("PASS: Data[%0d] = %0h", read_index, data_out);
                end
                read_index = read_index + 1;
            end
        end
        read_en <= 0;
        if (empty) $display("PASS: FIFO reported EMPTY after reading all data");
        else $display("FAIL: FIFO not empty when expected");

        // -------------------------------
        // TEST 4: Extra read (should do nothing)
        // -------------------------------
        @(posedge rd_clk);
        read_en <= 1;
        @(posedge rd_clk);
        read_en <= 0;
        $display("Test 4: Read ignored on EMPTY - check manually in waveform");

        // -------------------------------
        // TEST 5: Simultaneous read/write
        // -------------------------------
        $display("Test 5: Simultaneous read/write");
        for (i = 0; i < FIFO_DEPTH; i = i + 1) begin
            @(posedge wr_clk);
            data_in <= i + 100;
            write_en <= 1;
        end
        @(posedge wr_clk) write_en <= 0;

        @(posedge rd_clk);
        for (i = 0; i < FIFO_DEPTH; i = i + 1) begin
            data_in <= i + 200;
            write_en <= 1;
            read_en <= 1;
            @(posedge wr_clk);  // push
            @(posedge rd_clk);  // pull
        end
        write_en <= 0;
        read_en <= 0;
        $display("PASS: Simultaneous read/write test complete - waveform should show interleaved access");

        // -------------------------------
        // TEST 6: Write only (overflow test)
        // -------------------------------
        $display("Test 6: Write without read - watch full assert");
        for (i = 0; i < FIFO_DEPTH + 4; i = i + 1) begin
            @(posedge wr_clk);
            if (!full) begin
                write_en <= 1;
                data_in <= i + 50;
            end else begin
                write_en <= 0;
            end
        end
        write_en <= 0;

        // -------------------------------
        // TEST 7: Read only (underflow test)
        // -------------------------------
        $display("Test 7: Read without write - watch empty assert");
        #100;
        for (i = 0; i < FIFO_DEPTH + 4; i = i + 1) begin
            @(posedge rd_clk);
            if (!empty)
                read_en <= 1;
            else
                read_en <= 0;
        end
        read_en <= 0;

        $display("All tests complete.");
        #100;
        $finish;
    end

endmodule
