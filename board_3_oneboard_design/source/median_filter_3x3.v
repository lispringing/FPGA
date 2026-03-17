module median_filter_3x3 (
    input wire clk,
    input wire rst_n,
    input wire de_in,              // 数据有效
    input wire [7:0] gray_in,      // 灰度输入
    output reg de_out,
    output reg [7:0] gray_out      // 滤波后灰度输出
);

    // 3行 × 3列 窗口（和 Sobel 复用类似结构）
    reg [7:0] line0 [0:2];
    reg [7:0] line1 [0:2];
    reg [7:0] line2 [0:2];

    // 延迟对齐（中值需要 2 拍延迟，与 Sobel 类似）
    reg de_d1, de_d2;

    // 9 个像素值，用于排序找中值
    wire [7:0] p [0:8];
    assign p[0] = line0[0];
    assign p[1] = line0[1];
    assign p[2] = line0[2];
    assign p[3] = line1[0];
    assign p[4] = line1[1];
    assign p[5] = line1[2];
    assign p[6] = line2[0];
    assign p[7] = line2[1];
    assign p[8] = line2[2];

    // 排序网络：找第 5 大值（中值），资源消耗可接受（9 值排序）
    // 这里用简单冒泡排序风格的组合逻辑（FPGA 能并行展开）
    reg [7:0] sorted [0:8];
    integer i, j;
    always @(*) begin
        // 先复制
        for (i = 0; i < 9; i = i + 1) sorted[i] = p[i];

        // 冒泡排序（9 次比较，FPGA 会优化成并行比较树）
        for (i = 0; i < 8; i = i + 1) begin
            for (j = 0; j < 8 - i; j = j + 1) begin
                if (sorted[j] > sorted[j+1]) begin
                    sorted[j]   <= sorted[j+1];
                    sorted[j+1] <= sorted[j];
                end
            end
        end
    end

    // 中值是 sorted[4]（0~8 的第 5 个）
    wire [7:0] median = sorted[4];

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            line0[0] <= 0; line0[1] <= 0; line0[2] <= 0;
            line1[0] <= 0; line1[1] <= 0; line1[2] <= 0;
            line2[0] <= 0; line2[1] <= 0; line2[2] <= 0;
            de_out   <= 0;
            gray_out <= 0;
            de_d1    <= 0;
            de_d2    <= 0;
        end else begin
            // 行缓存移位
            if (de_in) begin
                line0[0] <= line0[1]; line0[1] <= line0[2]; line0[2] <= line1[0];
                line1[0] <= line1[1]; line1[1] <= line1[2]; line1[2] <= line2[0];
                line2[0] <= line2[1]; line2[1] <= line2[2]; line2[2] <= gray_in;
            end

            // 延迟对齐
            de_d1  <= de_in;
            de_d2  <= de_d1;
            de_out <= de_d2;

            // 输出中值（只在窗口有效时输出）
            if (de_d2) begin
                gray_out <= median;
            end else begin
                gray_out <= 0;
            end
        end
    end

endmodule