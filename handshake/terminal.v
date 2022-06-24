module terminal (
  `include "fifo_define.v"
  input  wire         wr_en,        
  input  wire         rd_en,     
  input  wire  [`width-1:0] wr_data, 
  input  wire 	 	  terminal_valid,
  input  wire         rstn,   
  input  wire         clk,


  output reg [`width-1:0]  rd_data,      // APB read data
  output wire   	  terminal_ready,
  output wire         fifo_full,     // Watchdog interrupt
  output wire         fifo_empty);    // Watchdog timeout reset
  integer i ;
  
  	reg  [`width-1:0] fifo [`depth-1:0]; 
  	reg  [`addr-1:0] rd_addr,wr_addr;
	reg  [`addr-1:0] cnt;
  	
  	always @ (posedge clk or negedge rstn)
    begin : cnt_judge
      // process p_LockSeq
      if (rstn == 1'b0) begin
        // asynchronous reset (active low)
        cnt <= 'b0;
	  end
      else if(wr_en && terminal_valid && rd_en && (cnt == `depth-1)) begin
        cnt <= cnt -1;
      end
      else if(wr_en && terminal_valid && rd_en && (cnt == 0)) begin
        cnt <= cnt +1;
      end
      else if(wr_en && terminal_valid && !rd_en && (cnt != `depth-1)) begin
        cnt <= cnt +1;
      end
      else if(!wr_en && rd_en && (cnt != 0)) begin
        cnt <= cnt -1;
      end
      else begin
        cnt <= cnt;
      end
    end                                     //cnt shows the margin of the fifo
  	
  	always @ (posedge clk or negedge rstn)
    begin : write
    // asynchronous reset (active low)
      if (rstn == 1'b0) begin
	    for(i=0;i<`depth;i=i+1) fifo[i] <= 'b0;
        wr_addr <= 1'b0;
	  end
      else if (wr_en && terminal_valid && !fifo_full) begin
	      fifo[wr_addr] <= wr_data;
          wr_addr <= wr_addr + 1;
      end
      else begin
	  	  wr_addr <= wr_addr;
	      fifo[wr_addr] <= fifo[wr_addr];
	  end
    end                         
    
    always @ (posedge clk or negedge rstn)
    begin : read
    // asynchronous reset (active low)
      if (rstn == 1'b0) begin
        rd_addr <= 1'b0;
	  end
      else if (rd_en && !fifo_empty) begin
	      rd_data <= fifo[rd_addr];
          rd_addr <= rd_addr + 1;
      end
      else begin
	  	  rd_addr <= rd_addr;
	  end
    end
   	assign fifo_full = (cnt==`depth-1)? 1 : 0;
    assign terminal_ready = !fifo_full && wr_en;
  	assign fifo_empty = (cnt==0)? 1 : 0;
endmodule