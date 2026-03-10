module Cordic_Pipelined (
    input clk,
    input signed [15:0] x_in,
    input signed [15:0] z_in,
    output signed [15:0] y_out
);

    // Arrays of registers to hold intermediate pipeline values
    reg signed [15:0] x [0:16];
    reg signed [15:0] y [0:16];
    reg signed [15:0] z [0:16];

    // Initialize registers to 0 for a clean simulation startup
    integer k;
    initial begin
        for (k = 0; k <= 16; k = k + 1) begin
            x[k] = 16'd0;
            y[k] = 16'd0;
            z[k] = 16'd0;
        end
    end

    // Stage 0: Latch the inputs into the very start of the pipeline
    always @(posedge clk) begin
        x[0] <= x_in;
        y[0] <= 16'd0;
        z[0] <= z_in;
    end

    // Stages 1 to 16: The Pipelined Math Unrolled
    genvar i;
    generate
        for (i = 0; i < 16; i = i + 1) begin : cordic_stages
            
            // Protect signed math by casting the constant at compile time
            wire signed [15:0] z_shift = $signed(16'h4000 >> i);

            always @(posedge clk) begin
                if (z[i] >= 0) begin
                    x[i+1] <= x[i];
                    y[i+1] <= y[i] + (x[i] >>> i);
                    z[i+1] <= z[i] - z_shift; 
                end else begin
                    x[i+1] <= x[i];
                    y[i+1] <= y[i] - (x[i] >>> i);
                    z[i+1] <= z[i] + z_shift;
                end
            end
        end
    endgenerate

    // The final product emerges at the end of the pipeline
    assign y_out = y[16];

endmodule