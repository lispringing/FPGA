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
    // 加宽位宽防溢出，77*255+150*255+29*255=64770 < 20bit
    reg [19:0] gray_temp;
    // 2拍延迟寄存器，和原代码完全一致
    reg de_d1;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            de_d1    <= 1'b0;
            de_out   <= 1'b0;
            gray_out <= 8'b0;
            gray_temp<= 20'b0;
        end else begin
            // 第1拍：计算灰度值（ITU-R BT.601），仅de_in有效时计算
            if (de_in) begin
                gray_temp <= (r_in * 77) + (g_in * 150) + (b_in * 29);
            end else begin
                gray_temp <= 20'b0;
            end
            de_d1 <= de_in; // de信号第1拍延迟

            // 第2拍：归一化输出（右移8位=÷256），de同步第2拍延迟
            gray_out <= gray_temp[15:8]; // 取高8位，标准8bit灰度值
            de_out   <= de_d1;           // de_out比de_in晚2拍，和原代码一致
        end
    end
endmodule