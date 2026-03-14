`timescale 1ns / 1ps

module cordic_cos_sin(
    input clk,
    input reset,
    input [15:0] angle, 
    output reg signed [15:0] cos, sin 
);
    localparam [15:0] GAIN = 16'd19890;
    localparam [15:0] ANG_90 = 16'h4000;
    localparam [15:0] ANG_180 = 16'h8000;
    localparam [15:0] ANG_270 = 16'hC000;
    
    reg [15:0] atan_lut [0:14];
    initial begin
        atan_lut[0]  = 16'h2000;
        atan_lut[1]  = 16'h12E4;
        atan_lut[2]  = 16'h09FB;
        atan_lut[3]  = 16'h0511;
        atan_lut[4]  = 16'h028B;
        atan_lut[5]  = 16'h0145;
        atan_lut[6]  = 16'h00A3;
        atan_lut[7]  = 16'h0051;
        atan_lut[8]  = 16'h0028;
        atan_lut[9]  = 16'h0014;
        atan_lut[10] = 16'h000A;
        atan_lut[11] = 16'h0005;
        atan_lut[12] = 16'h0003;
        atan_lut[13] = 16'h0001;
        atan_lut[14] = 16'h0001;
    end

    reg signed [15:0] x [0:15];
    reg signed [15:0] y [0:15];
    reg signed [15:0] z [0:15];

    integer i;
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            for (i = 0; i <= 15; i = i + 1) begin
                x[i] <= 0;
                y[i] <= 0; z[i] <= 0;
            end
            cos <= 0;
            sin <= 0;
        end else begin
            if (angle > ANG_90 && angle <= ANG_270) begin
                x[0] <= -GAIN;
                y[0] <= 0;
                z[0] <= angle - ANG_180;
            end else begin
                x[0] <= GAIN;
                y[0] <= 0;
                z[0] <= angle; 
            end

            for (i = 0; i < 15; i = i + 1) begin
                if (z[i][15] == 1'b0) begin
                    x[i+1] <= x[i] - (y[i] >>> i);
                    y[i+1] <= y[i] + (x[i] >>> i);
                    z[i+1] <= z[i] - atan_lut[i];
                end else begin
                    x[i+1] <= x[i] + (y[i] >>> i);
                    y[i+1] <= y[i] - (x[i] >>> i);
                    z[i+1] <= z[i] + atan_lut[i];
                end
            end
            
            cos <= x[15];
            sin <= y[15];
        end
    end
endmodule
