module clk_divider#( 
    parameter integer COUNT_MAX = 50_000_000)(   // # -- признак объявления параметров модуля (настраиваемых констант)
    input wire clk,
    input wire rst,
    output reg cr_new_gen
);
reg [27:0] counter; //счетчик тактов для отсчета времени
always @(posedge clk or posedge rst)begin
    if(rst)begin
        counter <= 28'd0;
        cr_new_gen <= 1'b0;
    end else  if(counter >= COUNT_MAX - 1)begin
        counter <= 28'd0;
        cr_new_gen <= 1'b1;
    end else begin
        counter <= counter + 1'd1;
        cr_new_gen <=  1'b0;
    end
end
endmodule

