// 灰度化模块 - 适配你的MES50HP工程 | 2拍延迟 | RGB32输入 | 8bit灰度输出
module gray_convert (
    input  wire        clk,        // 时钟：对接pix_clk_in
    input  wire        rst_n,      // 复位：对接ddr_ip_rst_n && ddr_init_done
    input  wire        de_in,      // 输入数据有效：对接zoom_de_out
    input  wire [7:0]  r_in,       // 红通道：对接zoom_data_out[31:24]
    input  wire [7:0]  g_in,       // 绿通道：对接zoom_data_out[21:14]
    input  wire [7:0]  b_in,       // 蓝通道：对接zoom_data_out[11:4]
    output reg         de_out,     // 输出数据有效：给fifo1的video1_de_in
    output reg  [7:0]  gray_out    // 8bit灰度输出：给gray_rgb32
);

// 内部寄存器：加宽位宽防溢出
reg [19:0] gray_temp;  // 灰度计算中间值 (77*255+150*255+29*255=64770 < 20bit)
reg de_d1;             // 使能1拍延迟寄存器

// 时序逻辑：1拍计算，1拍输出，严格2拍延迟
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        // 复位状态：所有寄存器清零
        gray_temp <= 20'd0;
        de_d1     <= 1'b0;
        de_out    <= 1'b0;
        gray_out  <= 8'd0;
    end else begin
        // 第1拍：计算灰度中间值
        if (de_in) begin
            // ITU-R BT.601标准：Gray = 0.299R + 0.587G + 0.114B
            // 整数近似：77/256≈0.299, 150/256≈0.587, 29/256≈0.114
            gray_temp <= (r_in * 77) + (g_in * 150) + (b_in * 29);
        end else begin
            gray_temp <= 20'd0; // de无效时清零，避免残留值
        end
        de_d1 <= de_in; // 使能信号第1拍延迟

        // 第2拍：归一化输出最终灰度值
        gray_out <= gray_temp[15:8]; // 取高8位，相当于右移8位÷256，精准归一化
        de_out   <= de_d1;            // 使能信号第2拍延迟，总延迟2拍
    end
end

endmodule