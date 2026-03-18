module sobel_edge #(
    parameter THRESHOLD = 30  // 先低阈值出边缘，后续可调50~80
)(
    input  wire        clk,
    input  wire        rst_n,
    input  wire        de_in,
    input  wire [7:0]  gray_in,
    output reg         de_out,
    output reg  [7:0]  edge_out
);
    // 3×3窗口行缓存，存储3行连续像素
    reg [7:0] line0[0:2], line1[0:2], line2[0:2];
    // 梯度计算寄存器，加宽位宽防溢出
    reg [9:0] gx_temp1, gx_temp2, gy_temp1, gy_temp2;
    reg [9:0] gx_abs, gy_abs;
    reg [10:0] mag;
    // 2拍延迟寄存器，和原代码完全一致
    reg de_d1, de_d2;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // 初始化所有寄存器，避免不定态
            {line0[0],line0[1],line0[2]} <= 24'd0;
            {line1[0],line1[1],line1[2]} <= 24'd0;
            {line2[0],line2[1],line2[2]} <= 24'd0;
            {de_d1, de_d2, de_out} <= 3'd0;
            {gx_temp1, gx_temp2, gy_temp1, gy_temp2} <= 40'd0;
            {gx_abs, gy_abs, mag, edge_out} <= 38'd0;
        end else begin
            // ********** 核心修复：正确3×3窗口移位 **********
            // line2=最新行，line1=上一行，line0=上上一行，左移补新像素
            if (de_in) begin
                line0 <= {line0[1], line0[2], line1[0]};
                line1 <= {line1[1], line1[2], line2[0]};
                line2 <= {line2[1], line2[2], gray_in};
            end

            // ********** 严格2拍延迟，和原代码一致 **********
            de_d1  <= de_in;
            de_d2  <= de_d1;
            de_out <= de_d2;

            // ********** Sobel梯度计算（仅de有效时）**********
            if (de_d2) begin
                // 水平梯度Gx = (上右+2*中右+下右) - (上左+2*中左+下左)
                gx_temp1 <= line0[2] + (line1[2] << 1) + line2[2];
                gx_temp2 <= line0[0] + (line1[0] << 1) + line2[0];
                // 垂直梯度Gy = (下左+2*下中+下右) - (上左+2*上中+上右)
                gy_temp1 <= line2[0] + (line2[1] << 1) + line2[2];
                gy_temp2 <= line0[0] + (line0[1] << 1) + line0[2];
                
                // 绝对值计算
                gx_abs <= (gx_temp1 >= gx_temp2) ? gx_temp1 - gx_temp2 : gx_temp2 - gx_temp1;
                gy_abs <= (gy_temp1 >= gy_temp2) ? gy_temp1 - gy_temp2 : gy_temp2 - gy_temp1;
                
                // 梯度幅值+防溢出（最大1023，不超11bit）
                mag    <= (gx_abs + gy_abs) > 1023 ? 1023 : (gx_abs + gy_abs);
                
                // 边缘输出：黑底白边（车牌识别最优），阈值判断
                edge_out <= (mag >= THRESHOLD) ? 8'd255 : 8'd0;
            end else begin
                edge_out <= 8'd0; // de无效时输出0
            end
        end
    end
endmodule