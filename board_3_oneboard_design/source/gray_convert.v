module gray_convert (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        de_in,
    input  wire [7:0]  r_in,
    input  wire [7:0]  g_in,
    input  wire [7:0]  b_in,
    output reg         de_out,
    output reg  [7:0]  gray_out
);

    reg         de_d1;
    reg [15:0]  gray_temp;   // 足够容纳 255*256 = 65280

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            de_out    <= 1'b0;
            gray_out  <= 8'd0;
            de_d1     <= 1'b0;
            gray_temp <= 16'd0;
        end else begin
            // 第一拍：计算灰度（寄存器化，防时序问题）
            if (de_in) begin
                gray_temp <= (r_in * 77) + (g_in * 150) + (b_in * 29);  // BT.601 标准权重
            end

            // 第二拍：严格对齐输出
            de_d1  <= de_in;
            de_out <= de_d1;

            if (de_d1) begin
                // 饱和截断（防止溢出）
                gray_out <= (gray_temp >= 255) ? 8'd255 : gray_temp[7:0];
            end else begin
                gray_out <= 8'd0;
            end
        end
    end

endmodule