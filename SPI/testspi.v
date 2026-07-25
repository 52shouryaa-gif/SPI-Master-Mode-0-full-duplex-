`timescale 1ns / 1ps

module testspi();

    // 1. Declare Testbench Signals
    reg clk;
    reg rst_n;
    
    // Host interface signals
    reg [7:0] tx_data;
    reg tx_valid;
    wire [7:0] rx_data;
    wire rx_valid;
    wire busy;
    
    // SPI interface signals
    wire spi_clk;
    wire spi_mosi;
    reg spi_miso;
    wire spi_cs_n;

    // 2. Instantiate the Unit Under Test (UUT)
    spidesign #(
        .clock_per_half_bit(4)
    ) uut (
        .clk(clk),
        .rst_n(rst_n),
        .tx_data(tx_data),
        .tx_valid(tx_valid),
        .rx_data(rx_data),
        .rx_valid(rx_valid),
        .busy(busy),
        .spi_clk(spi_clk),
        .spi_mosi(spi_mosi),
        .spi_miso(spi_miso),
        .spi_cs_n(spi_cs_n)
    );

    // 3. Generate System Clock (100 MHz -> 10ns period)
    always #5 clk = ~clk;

    // Dummy data that our "fake slave" will send back to the master
    reg [7:0] simulated_slave_data = 8'b1010_0101; // Hex: 0xA5
    integer i;

    // 4. Main Simulation Sequence
initial begin
        // VCD Dump commands ko time = 0 par sabse upar likho
        $dumpfile("gtkwave.vcd");
        $dumpvars(0, testspi);

        // Initialize Inputs
        clk = 0;
        rst_n = 0;
        tx_data = 0;
        tx_valid = 0;
        spi_miso = 0;

        // Apply Reset
        #20;
        rst_n = 1; 
        #20;

    
        tx_data = 8'hC3;
        tx_valid = 1;
        #10;         
        tx_valid = 0; 

        wait (busy == 0);
        
        // Give it a little buffer time after completion
        #50; 

        // Check if the Master successfully received the slave's data
        if (rx_data == 8'hA5)
            $display("SUCCESS: Master received correct data from slave (0x%h)", rx_data);
        else
            $display("ERROR: Expected 0xA5, got 0x%h", rx_data);
           
        // End simulation
        $finish;
    end
    // 5. Simulate the External SPI Slave (MISO Logic)
    // SPI Mode 0: Slave drives data on the falling edge of the SPI clock.
    always @(negedge spi_clk or negedge spi_cs_n) begin
        if (!spi_cs_n) begin
            for (i = 7; i >= 0; i = i - 1) begin
                spi_miso = simulated_slave_data[i];
                @(negedge spi_clk); // Wait for the next falling edge to shift the next bit
            end
        end
    end

endmodule