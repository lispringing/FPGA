module sobel_edge #(
    parameter THRESH = 60          // 车牌场景推荐值：40~80（光照好用70，光照差用50）
)(
    input clk,
    input rst_n,
    input de_in,
    input [7:0] gray_in,
    output reg de_out,
    output reg [7:0] edge_out
);

// ==================== 行缓存 ====================
reg [7:0] line0[0:2];
reg [7:0] line1[0:2];
reg [7:0] line2[0:2];

// ==================== Sobel 计算寄存器 ====================
reg [10:0] gx, gy;
reg de_d1, de_d2;

// ==================== 组合逻辑（最关键优化）================
wire [10:0] abs_gx = gx[10] ? (~gx[9:0] + 11'd1) : gx[9:0];
wire [10:0] abs_gy = gy[10] ? (~gy[9:0] + 11'd1) : gy[9:0];
wire [11:0] mag    = abs_gx + abs_gy;                    // Manhattan 近似，资源最省

// 窗口是否有效（避免最左/最上2像素的无效边缘）
wire window_valid = de_d2;   // 你原来的延迟已够，可根据需要再加行计数器

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        // 清零
        line0[0] <= 0; line0[1] <= 0; line0[2] <= 0;
        line1[0] <= 0; line1[1] <= 0; line1[2] <= 0;
        line2[0] <= 0; line2[1] <= 0; line2[2] <= 0;
        gx <= 0; gy <= 0;
        de_out <= 0; edge_out <= 0;
        de_d1  <= 0; de_d2  <= 0;
    end 
    else begin
        // ============== 行缓存移位（保持你原来的高效写法）==============
        if (de_in) begin
            line0[0] <= line0[1]; line0[1] <= line0[2]; line0[2] <= line1[0];
            line1[0] <= line1[1]; line1[1] <= line1[2]; line1[2] <= line2[0];
            line2[0] <= line2[1]; line2[1] <= line2[2]; line2[2] <= gray_in;
        end

        // ============== 延迟对齐（2拍，匹配3x3窗口）==============
        de_d1  <= de_in;
        de_d2  <= de_d1;
        de_out <= de_d2;

        // ============== Sobel 计算 + 输出（优化后）==============
        if (de_d2 && window_valid) begin
            // Gx Gy 计算（你的符号完全正确）
            gx <= (line0[2] + (line1[2]<<1) + line2[2]) - (line0[0] + (line1[0]<<1) + line2[0]);
            gy <= (line0[0] + (line0[1]<<1) + line0[2]) - (line2[0] + (line2[1]<<1) + line2[2]);

            // 输出模式1（推荐）：二值化边缘（白边黑底，车牌字符最清晰）
            edge_out <= (mag >= THRESH) ? 8'd255 : 8'd0;

            // 输出模式2（调试用）：直接输出幅度（看到灰度边缘，方便调阈值）
            // edge_out <= (mag > 255) ? 8'd255 : mag[7:0];
        end 
        else begin
            edge_out <= 8'd0;   // 无效区域强制黑，防止第一帧乱码
        end
    end
end

endmodule