module sobel_edge (
    input             clk,
    input             rst_n,
    input             de_in,
    input      [7:0]  gray_in,
    output reg        de_out,
    output reg [7:0]  edge_out
);

reg [7:0] line0[2:0], line1[2:0], line2[2:0]; // 3ĞĞ»º´æ
reg [10:0] gx, gy;                            // Sobel Ìİ¶È
reg        de_d1, de_d2;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        line0[0] <= 0; line0[1] <= 0; line0[2] <= 0;
        line1[0] <= 0; line1[1] <= 0; line1[2] <= 0;
        line2[0] <= 0; line2[1] <= 0; line2[2] <= 0;
        gx <= 0; gy <= 0;
        de_out <= 0; edge_out <= 0;
        de_d1 <= 0; de_d2 <= 0;
    end else begin
        // ĞĞ»º´æÒÆÎ»
        if (de_in) begin
            line0[0] <= line0[1]; line0[1] <= line0[2]; line0[2] <= line1[0];
            line1[0] <= line1[1]; line1[1] <= line1[2]; line1[2] <= line2[0];
            line2[0] <= line2[1]; line2[1] <= line2[2]; line2[2] <= gray_in;
        end
        
        // Sobel ¼ÆËã£¨ÑÓ³Ù 2 ÅÄ£©
        de_d1 <= de_in;
        de_d2 <= de_d1;
        de_out <= de_d2;
        
        if (de_d2) begin
            gx <= (line0[2] + line1[2]*2 + line2[2]) - (line0[0] + line1[0]*2 + line2[0]);
            gy <= (line0[0] + line0[1]*2 + line0[2]) - (line2[0] + line2[1]*2 + line2[2]);
            edge_out <= (gx[10] ? -gx[9:0] : gx[9:0]) + (gy[10] ? -gy[9:0] : gy[9:0]) > 8 ? 255 : 0;
        end else begin
            edge_out <= 0;
        end
    end
end

endmodule