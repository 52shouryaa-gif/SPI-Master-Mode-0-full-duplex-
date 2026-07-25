module spidesign #(
    parameter clock_per_half_bit  = 4
)(
    input wire clk,
    input wire rst_n,
    // spi interface
    input wire [7:0]tx_data,
    input wire tx_valid,
    output reg [7:0] rx_data,
    output reg rx_valid,
    output reg busy,
    // spi wire 
    output reg spi_mosi,
    output reg spi_clk,
    input wire spi_miso,
    output reg spi_cs_n
);

localparam idle = 2'b00;
localparam transfer = 2'b01;
localparam done = 2'b10;

reg [7:0] tx_shift_reg;
reg [7:0] rx_shift_reg;
reg [2:0] bit_count;
reg [$clog2(clock_per_half_bit*2)-1:0] clk_count;
reg [1:0] state;
reg spi_clk_reg;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        state <= idle;
        spi_clk <= 1'b0;
        spi_cs_n <= 1'b1;
        busy <= 1'b0;
        rx_data<= 8'd0;
        rx_valid <= 1'b0;
        spi_mosi <= 1'b0;
        bit_count <= 3'd7;
        spi_clk_reg <= 1'b0;
        clk_count <= 0;
    end

    else begin
    case (state) 
     idle: begin
        spi_clk <= 1'b0;
        busy <= 1'b0;
        spi_cs_n <= 1'b1;
        rx_valid <= 1'b0;

        if(tx_valid) begin
        busy <= 1'b1;
        spi_mosi <= tx_data[7];
        tx_shift_reg <= tx_data;
        spi_clk_reg <= 1'b0;
        spi_cs_n <= 1'b0;
        bit_count <= 3'd7;
        clk_count <= 0;
        state <= transfer;
        end

     end
    transfer: begin
        if(clk_count == clock_per_half_bit - 1) begin
            clk_count <= 0; 
            spi_clk_reg <= ~spi_clk_reg;
            spi_clk <= ~spi_clk_reg;
        
            if(~spi_clk_reg) begin
                rx_shift_reg[bit_count] <= spi_miso;
            end
            else begin
                if(bit_count != 0) begin
                    spi_mosi <= tx_shift_reg[bit_count - 1];
                    bit_count <= bit_count - 1;
                end
                else begin
                    state <= done;
                end
            end
        end 
        else begin 
            clk_count <= clk_count + 1; 
        end
     end
     done:begin

        spi_clk <= 0;

        if(clk_count == clock_per_half_bit - 1) begin

            spi_cs_n <= 1'b1;
            rx_data <= rx_shift_reg;
            busy <= 1'b0;
            rx_valid <= 1'b1;
            state <= idle;

        end

        else begin 

        clk_count <= clk_count + 1;
        
        end
     end
     default: state <= idle; 
    endcase
    end
end
endmodule
