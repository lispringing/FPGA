module gray_convert (
    input             clk,
    input             rst_n,
    input             de_in,
    input      [7:0]  r_in,
    input      [7:0]  g_in,
    input      [7:0]  b_in,
    output reg        de_out,
    output reg [7:0]  gray_out
);

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        de_out   <= 0;
        gray_out <= 0;
    end else if (de_in) begin
        de_out   <= 1;
        // 标准加权灰度（人眼最敏感）
        gray_out <= (r_in * 77 + g_in * 150 + b_in * 29) >> 8;
    end else begin
        de_out   <= 0;
    end
end

endmodule