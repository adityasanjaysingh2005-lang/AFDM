`timescale 1ns / 1ps

module cordic_cos_sin(
    input clk,
    input reset,
    input [15:0] angle, // Input 0 to 65535 representing 0 to 360 degrees
    output reg signed [15:0] cos, sin 
);
    
    // Scale: 16'h4000 = 90 deg, 16'h8000 = 180 deg, 16'hC000 = 270 deg
    localparam [15:0] GAIN = 16'd19898; 
    localparam [15:0] ANG_90 = 16'h4000;
    localparam [15:0] ANG_180 = 16'h8000;
    localparam [15:0] ANG_270 = 16'hC000;
    
    reg [15:0] atan_lut [0:14];
    initial begin
        atan_lut[0]  = 16'h2000; // 45.0 degrees
        atan_lut[1]  = 16'h12E4; // 26.565
        atan_lut[2]  = 16'h09FB; // 14.036
        atan_lut[3]  = 16'h0511; // 7.125
        atan_lut[4]  = 16'h028B; // 3.576
        atan_lut[5]  = 16'h0145; // 1.790
        atan_lut[6]  = 16'h00A3; // 0.895
        atan_lut[7]  = 16'h0051; // 0.448
        atan_lut[8]  = 16'h0028; // 0.224
        atan_lut[9]  = 16'h0014; // 0.112
        atan_lut[10] = 16'h000A; // 0.056
        atan_lut[11] = 16'h0005; // 0.028
        atan_lut[12] = 16'h0003; // 0.014
        atan_lut[13] = 16'h0001; // 0.007
        atan_lut[14] = 16'h0001; 
    end

    reg signed [15:0] x [0:15];
    reg signed [15:0] y [0:15];
    reg signed [15:0] z [0:15];
    reg q2_q3_reg [0:15]; // Pipeline registers to track if we were in Q2/Q3

    integer i;
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            for (i = 0; i <= 15; i = i + 1) begin
                x[i] <= 0; y[i] <= 0; z[i] <= 0; q2_q3_reg[i] <= 0;
            end
            cos <= 0; sin <= 0;
        end else begin
            // --- Step 1: Quadrant Mapping (Input Pre-processing) ---
            // If angle is in Q2 or Q3 (90 to 270), rotate by 180 degrees
            if (angle > ANG_90 && angle <= ANG_270) begin
                x[0] <= -GAIN; // Effective rotation by 180 degrees
                y[0] <= 0;
                z[0] <= angle - ANG_180;
                q2_q3_reg[0] <= 1'b1;
            end else begin
                x[0] <= GAIN;
                y[0] <= 0;
                // Handle Q4 wrap-around to keep z within convergence range
                z[0] <= (angle > ANG_270) ? (angle - 16'hFFFF) : angle;
                q2_q3_reg[0] <= 1'b0;
            end

            // --- Step 2: Standard CORDIC Pipeline ---
            for (i = 0; i < 15; i = i + 1) begin
                q2_q3_reg[i+1] <= q2_q3_reg[i]; // Shift the quadrant flag
                if (z[i][15] == 1'b0) begin // Check if positive
                    x[i+1] <= x[i] - (y[i] >>> i);
                    y[i+1] <= y[i] + (x[i] >>> i);
                    z[i+1] <= z[i] - atan_lut[i];
                end else begin
                    x[i+1] <= x[i] + (y[i] >>> i);
                    y[i+1] <= y[i] - (x[i] >>> i);
                    z[i+1] <= z[i] + atan_lut[i];
                end
            end
            
            // --- Step 3: Final Output ---
            cos <= x[15];
            sin <= y[15];
        end
    end
endmodule