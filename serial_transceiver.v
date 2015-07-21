`timescale 10ns/1ns

module serial_transceiver(
    output dout,
    output reg [7:0] a,
    output reg [7:0] b,
    output ready,
    input din,
    input [7:0] result,
    input tx_en,
    input clk,
    input reset_n
);

parameter BAUD_RATE = 9600,
          SAMPLE_RATIO = 16,
          CLK_FREQUENCY = 100_000_000,
          LED_SCAN_RATE = 1000;

// If BAUD_RATE = 9600, then
//     SAMPLE_CLK_RATIO = 651,
//     SEND_CLK_RATIO = 10416,
//     real baud rate = 9600.61,
//     error = 0.00064%.
localparam SAMPLE_CLK_RATIO = CLK_FREQUENCY / BAUD_RATE / SAMPLE_RATIO,
           SEND_CLK_RATIO = SAMPLE_CLK_RATIO * SAMPLE_RATIO,
           LED_SCAN_RATIO = CLK_FREQUENCY / LED_SCAN_RATE;

localparam WAIT_A = 2'd0,
           WAIT_B = 2'd1,
           READY  = 2'd2,
           SEND   = 2'd3;

// Build clocks.
wire sample_clk, send_clk;
watchmaker #(SAMPLE_CLK_RATIO) sample_watch(sample_clk, clk);
watchmaker #(SEND_CLK_RATIO) send_watch(send_clk, clk);

// Receiver.
wire [7:0] rx_data;
wire rx_status;
receiver receiver1(rx_data, rx_status, din, clk, sample_clk);

// Sender.
sender sender1(dout, , result, tx_en, clk, send_clk);


// Calculate next states.
reg [1:0] state, next_state;
wire [7:0] next_a, next_b;

always @(*) begin
    case (state)
        WAIT_A:
            next_state = rx_status ? WAIT_B : WAIT_A;
        WAIT_B:
            next_state = rx_status ? READY : WAIT_B;
        READY:
            next_state = tx_en ? WAIT_A : READY;
        default:
            next_state = WAIT_A;
    endcase
end

assign next_a = (state == WAIT_A && rx_status) ? rx_data : a,
       next_b = (state == WAIT_B && rx_status) ? rx_data : b;

// States transfer.
always @(posedge clk or negedge reset_n) begin
    if(~reset_n) begin
        state <= 0;
        a <= 0;
        b <= 0;
    end else begin
        state <= next_state;
        a <= next_a;
        b <= next_b;
    end
end

// Output.
assign ready = (state == READY);

endmodule
