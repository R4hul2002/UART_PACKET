`timescale 1ns / 1ps

module tb_uart_packetizer();

    // Parameters
    parameter CLK_PERIOD = 20; // 50 MHz
    parameter BAUD_PERIOD = 8680; // 115200 baud
    
    // Signals
    reg clk;
    reg rst;
    reg [7:0] s_axis_tdata;
    reg s_axis_tvalid;
    wire s_axis_tready;
    wire serial_out;
    reg tx_ready;
    wire tx_busy;
    wire fifo_full;
    wire fifo_empty;
    
    // Instantiate DUT
    uart_packetizer_top #(
        .BAUD_RATE(115200),
        .CLK_FREQ(50_000_000)
    ) dut (
        .clk(clk),
        .rst(rst),
        .s_axis_tdata(s_axis_tdata),
        .s_axis_tvalid(s_axis_tvalid),
        .s_axis_tready(s_axis_tready),
        .serial_out(serial_out),
        .tx_ready(tx_ready),
        .tx_busy(tx_busy),
        .fifo_full(fifo_full),
        .fifo_empty(fifo_empty)
    );
    
    // Clock generation
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end
    
    // Reset generation
    initial begin
        rst = 1;
        #100;
        rst = 0;
    end
    
    // Test stimulus
    initial begin
        // Initialize
        s_axis_tdata = 0;
        s_axis_tvalid = 0;
        tx_ready = 1;
        
        // Wait for reset
        #200;
        
        // Test case 1: Send single packet
        $display("Test case 1: Send single packet");
        send_byte(8'h55);
        wait_for_tx_done();
        
        // Test case 2: Send multiple packets
        $display("Test case 2: Send multiple packets");
        send_byte(8'hAA);
        send_byte(8'hF0);
        send_byte(8'h0F);
        wait_for_tx_done();
        
        // Test case 3: FIFO full condition
        $display("Test case 3: FIFO full condition");
        tx_ready = 0; // Block transmission
        repeat(20) begin
            send_byte($random);
            #(CLK_PERIOD*10);
        end
        tx_ready = 1; // Resume transmission
        wait_for_tx_done();
        
        // Test case 4: Back-to-back transmission
        $display("Test case 4: Back-to-back transmission");
        repeat(5) begin
            send_byte($random);
            #(CLK_PERIOD*10);
        end
        wait_for_tx_done();
        
        // Finish simulation
        #1000;
        $display("Simulation completed");
        $finish;
    end
    
    // Task to send a byte
    task send_byte;
        input [7:0] data;
        begin
            wait(s_axis_tready);
            s_axis_tdata = data;
            s_axis_tvalid = 1;
            @(posedge clk);
            s_axis_tvalid = 0;
            $display("Sent byte: 0x%h", data);
        end
    endtask
    
    // Task to wait for transmission to complete
    task wait_for_tx_done;
        begin
            wait(!tx_busy);
            #100;
        end
    endtask
    
    // Monitor serial output
    reg [7:0] received_data;
    integer bit_count;
    initial begin
        received_data = 0;
        bit_count = 0;
        forever begin
            @(negedge serial_out); // Wait for start bit
            
            // Wait for middle of start bit
            #(BAUD_PERIOD*1.5);
            
            // Sample data bits
            for (bit_count = 0; bit_count < 8; bit_count = bit_count + 1) begin
                #(BAUD_PERIOD);
                received_data[bit_count] = serial_out;
            end
            
            // Wait for stop bit
            #(BAUD_PERIOD);
            
            $display("Received byte: 0x%h", received_data);
        end
    end
    
    // Dump VCD for waveform viewing
    initial begin
        $dumpfile("uart_packetizer.vcd");
        $dumpvars(0, tb_uart_packetizer);
    end

endmodule