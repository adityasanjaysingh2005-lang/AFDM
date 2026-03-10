module Cordic_HardCoded (
    input  signed [15:0] x_in,
    input  signed [15:0] z_in,
    output signed [15:0] y_out
);

    // Arrays resized to hold 10 values (index 0 for input, plus 9 stages)
    reg signed [15:0] x [0:9];
    reg signed [15:0] y [0:9];
    reg signed [15:0] z [0:9];

    integer i;

    // Purely combinational logic (0 clock cycles of latency)
    always @(*) begin
        // Stage 0: Feed inputs into the top of the logic cascade
        x[0] = x_in;
        y[0] = 16'd0;
        z[0] = z_in;

        // The synthesizer unrolls this loop into exactly 9 sequential adders/subtractors
        for (i = 0; i < 9; i = i + 1) begin
            
            if (z[i] >= 0) begin
                x[i+1] = x[i];
                y[i+1] = y[i] + (x[i] >>> i);
                z[i+1] = z[i] - $signed(16'h4000 >> i); // 16'h4000 is 2^0 in Q2.14
            end else begin
                x[i+1] = x[i];
                y[i+1] = y[i] - (x[i] >>> i);
                z[i+1] = z[i] + $signed(16'h4000 >> i);
            end
        end
    end

    // The final answer is tapped directly from the 9th stage
    assign y_out = y[9];

endmodule