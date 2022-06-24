module handshake (
  `include "fifo_define.v"
  input  wire         source_wr_en,        
  input  wire         source_rd_en, 
  input  wire         terminal_wr_en,        
  input  wire         terminal_rd_en, 
  input  wire  [`width-1:0] wr_data,     
  input  wire         rstn,   
  input  wire         clk,


  output wire [`width-1:0]  rd_data,

  output wire         source_fifo_full,    
  output wire         source_fifo_empty,
  output wire         terminal_fifo_full,    
  output wire         terminal_fifo_empty
	); 
	wire ready,valid;
	wire [31:0]  data;
  source mst(
	  .wr_en(source_wr_en),
	  .rd_en(source_rd_en),
	  .source_data(data),
	  .wr_data(wr_data),
	  .clk(clk),
	  .rstn(rstn),
	  .fifo_full(source_fifo_full),
	  .fifo_empty(source_fifo_empty),
	  .source_valid(valid),
	  .source_ready(ready)
	  );
  terminal slv(
	  .wr_en(terminal_wr_en),
	  .rd_en(terminal_rd_en),
	  .wr_data(data),
	  .rd_data(rd_data),
	  .clk(clk),
	  .rstn(rstn),
	  .fifo_full(terminal_fifo_full),
	  .fifo_empty(terminal_fifo_empty),
	  .terminal_valid(valid),
	  .terminal_ready(ready)
	  );
  
  
endmodule