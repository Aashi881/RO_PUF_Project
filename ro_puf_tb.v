`timescale 1ns / 1ps

module ro_puf_tb;

    reg clk;
    reg rst;
    reg enable;
    wire [3:0] puf_response;

    ro_puf_top DUT (
        .clk(clk),
        .rst(rst),
        .enable(enable),
        .puf_response(puf_response)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        rst = 1;
        enable = 0;

        #20 rst = 0;
        #20 enable = 1;

        #1000 enable = 0;
        #200 $finish;
    end

endmodule
