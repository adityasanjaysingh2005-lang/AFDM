`timescale 1ns / 1ps

module matrix_element_generator #(parameter N = 16) (
    input wire clk,
    input wire reset,
    input wire enable,
    input wire [15:0] phase_step,
    output wire signed [15:0] matrix_real,
    output wire signed [15:0] matrix_imag,
    output wire block_done,
    output wire data_valid
);
    localparam COUNTER_WIDTH = $clog2(N);

    reg [15:0] phase_acc;
    reg [COUNTER_WIDTH-1:0] n_counter;
    
    reg [16:0] valid_shift_reg;
    reg [16:0] done_shift_reg;

    wire raw_block_done = (enable && (n_counter == N - 1));
    wire signed [15:0] cordic_sin_out;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            phase_acc <= 16'd0;
            n_counter <= 0;
            valid_shift_reg <= 17'd0;
            done_shift_reg <= 17'd0;
        end else begin
            valid_shift_reg <= {valid_shift_reg[15:0], enable};
            done_shift_reg <= {done_shift_reg[15:0], raw_block_done};
            
            if (enable) begin
                if (n_counter == N - 1) begin
                    n_counter <= 0;
                    phase_acc <= 16'd0;
                end else begin
                    n_counter <= n_counter + 1;
                    phase_acc <= phase_acc + phase_step;
                end
            end
        end
    end

    cordic_cos_sin u_cordic (
        .clk(clk),
        .reset(reset),
        .angle(phase_acc),
        .cos(matrix_real),
        .sin(cordic_sin_out)
    );

    assign matrix_imag = -cordic_sin_out;

    assign data_valid = valid_shift_reg[16];
    assign block_done = done_shift_reg[16];

endmodule