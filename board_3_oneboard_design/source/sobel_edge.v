module sobel_edge #(
    parameter SOBEL_THRESHOLD = 64   // 官方默认值，车牌场景推荐 50~80（光照好用70，光照差用50）
)(
    input  wire        clk,
    input  wire        rst_n,
    input  wire        de_in,
    input  wire [7:0]  gray_in,
    output reg         de_out,
    output reg  [7:0]  edge_out
);

    // ==================== 3x3 行缓存（保持你原来的结构） ====================
    reg [7:0] line0[0:2];
    reg [7:0] line1[0:2];
    reg [7:0] line2[0:2];

    // ==================== 官方计算寄存器 ====================
    reg [9:0] gx_temp1, gx_temp2;
    reg [9:0] gy_temp1, gy_temp2;
    reg [9:0] gx_data, gy_data;
    reg [11:0] sobel_data_reg;

    // ==================== 延迟对齐（官方 3 拍流水线） ====================
    reg [2:0] de_d;
    reg [2:0] vs_d;   // 如果你顶层没用 vs，可忽略

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            line0[0]<=0; line0[1]<=0; line0[2]<=0;
            line1[0]<=0; line1[1]<=0; line1[2]<=0;
            line2[0]<=0; line2[1]<=0; line2[2]<=0;
            de_d <= 0;
            edge_out <= 0; de_out <= 0;
            gx_temp1<=0; gx_temp2<=0; gy_temp1<=0; gy_temp2<=0;
            gx_data<=0; gy_data<=0; sobel_data_reg<=0;
        end else begin
            // 行缓存移位（你的原逻辑）
            if (de_in) begin
                line0[0] <= line0[1]; line0[1] <= line0[2]; line0[2] <= line1[0];
                line1[0] <= line1[1]; line1[1] <= line1[2]; line1[2] <= line2[0];
                line2[0] <= line2[1]; line2[1] <= line2[2]; line2[2] <= gray_in;
            end

            // 延迟打拍（官方 3 拍）
            de_d <= {de_d[1:0], de_in};
            de_out <= de_d[2];

            // ============== 官方 Step1：卷积计算 ==============
            if (de_in) begin
                gx_temp1 <= line0[2] + (line1[2]<<1) + line2[2];      // 右列
                gx_temp2 <= line0[0] + (line1[0]<<1) + line2[0];      // 左列
                gy_temp1 <= line2[0] + (line2[1]<<1) + line2[2];      // 下行
                gy_temp2 <= line0[0] + (line0[1]<<1) + line0[2];      // 上行
            end

            // ============== 官方 Step2：取绝对值（避免负数） ==============
            if (de_d[0]) begin
                gx_data <= (gx_temp1 >= gx_temp2) ? (gx_temp1 - gx_temp2) : (gx_temp2 - gx_temp1);
                gy_data <= (gy_temp1 >= gy_temp2) ? (gy_temp1 - gy_temp2) : (gy_temp2 - gy_temp1);
            end

            // ============== 官方 Step3：幅度 + 阈值判断 ==============
            if (de_d[1]) begin
                sobel_data_reg <= gx_data + gy_data;   // |Gx| + |Gy|
                edge_out       <= (sobel_data_reg > SOBEL_THRESHOLD) ? 8'd0 : 8'd255;  // 黑底白边（官方做法）
            end
        end
    end

endmodule