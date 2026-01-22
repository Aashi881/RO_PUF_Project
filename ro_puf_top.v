`timescale 1ns / 1ps

module ro_puf_top #
(
    parameter NUM_RO    = 8,
    parameter COUNT_MAX = 50
)
(
    input  wire clk,
    input  wire rst,
    input  wire enable,
    output reg  [NUM_RO/2-1:0] puf_response
);

    // FSM states
    parameter IDLE    = 2'b00;
    parameter MEASURE = 2'b01;
    parameter COMPARE = 2'b10;
    parameter DONE    = 2'b11;

    reg [1:0] state;

    // Internal signals
    reg [NUM_RO-1:0] ro;
    reg [7:0]  div [0:NUM_RO-1];     // divider for frequency difference
    reg [15:0] counter [0:NUM_RO-1];
    reg [7:0]  measure_cnt;

    integer i;

    // -------------------------------------------------
    // Ring Oscillators with DIFFERENT FREQUENCIES
    // -------------------------------------------------
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            ro <= 0;
            for (i = 0; i < NUM_RO; i = i + 1)
                div[i] <= i + 1;   // DIFFERENT speed
        end
        else if (enable) begin
            for (i = 0; i < NUM_RO; i = i + 1) begin
                if (div[i] == (i + 1)) begin
                    ro[i]  <= ~ro[i];
                    div[i] <= 0;
                end else
                    div[i] <= div[i] + 1;
            end
        end
    end

    // -------------------------------------------------
    // FSM
    // -------------------------------------------------
    always @(posedge clk or posedge rst) begin
        if (rst)
            state <= IDLE;
        else begin
            case (state)
                IDLE:    if (enable) state <= MEASURE;
                MEASURE: if (measure_cnt >= COUNT_MAX) state <= COMPARE;
                COMPARE: state <= DONE;
                DONE:    state <= IDLE;
            endcase
        end
    end

    // Measurement window
    always @(posedge clk or posedge rst) begin
        if (rst)
            measure_cnt <= 0;
        else if (state == MEASURE)
            measure_cnt <= measure_cnt + 1;
        else
            measure_cnt <= 0;
    end

    // Frequency counters
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            for (i = 0; i < NUM_RO; i = i + 1)
                counter[i] <= 0;
        end
        else if (state == MEASURE) begin
            for (i = 0; i < NUM_RO; i = i + 1)
                counter[i] <= counter[i] + ro[i];
        end
    end

    // -------------------------------------------------
    // Comparison ? PUF output
    // -------------------------------------------------
    always @(posedge clk or posedge rst) begin
        if (rst)
            puf_response <= 0;
        else if (state == COMPARE) begin
            for (i = 0; i < NUM_RO/2; i = i + 1) begin
                if (counter[2*i] > counter[2*i + 1])
                    puf_response[i] <= 1'b1;
                else
                    puf_response[i] <= 1'b0;
            end
        end
    end

endmodule
