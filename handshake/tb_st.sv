`timescale 1ns/1ns

interface mst_intf(input clk, input rstn);
  logic [31:0] wr_data;
  logic        wr_en;
  logic        rd_en;
  logic 	   fifo_full;
  logic        fifo_empty;
  clocking drv_ck @(posedge clk);
    default input #1ns output #1ns;
    output wr_data, fifo_full, fifo_empty;
    input wr_en, rd_en;
  endclocking
endinterface

interface slv_intf(input clk, input rstn);
  logic [31:0] rd_data;
  logic        wr_en;
  logic        rd_en;
  logic 	   fifo_full;
  logic        fifo_empty;
  clocking drv_ck @(posedge clk);
    default input #1ns output #1ns;
    output  fifo_full, fifo_empty;
    input wr_en, rd_en, rd_data;
  endclocking
endinterface

interface bus_intf(input clk, input rstn);
  logic [31:0] data;
  logic        valid;
  logic        ready;

endinterface


module tb_st();
`include "fifo_define.v"
    
   bit         rstn;   
   bit         clk;  
  int i,j,count,count_error;
     
    handshake dut(
    .source_wr_en   (mst_if.wr_en),
    .source_rd_en   (mst_if.rd_en),
    .terminal_wr_en   (slv_if.wr_en),
    .terminal_rd_en   (slv_if.rd_en),
    .clk   	 (clk),
    .rstn    (rstn),
    .wr_data (mst_if.wr_data),
    .rd_data (slv_if.rd_data),
    .source_fifo_full (mst_if.fifo_full),
    .source_fifo_empty (mst_if.fifo_empty),
    .terminal_fifo_full (slv_if.fifo_full),
    .terminal_fifo_empty (slv_if.fifo_empty)
	    );
	
  mst_intf  mst_if(.*);
  slv_intf  slv_if(.*);
  bus_intf  bus_if(.*);
    
    assign bus_if.data = dut.data;
	assign bus_if.ready = dut.ready;
	assign bus_if.valid = dut.valid;
    
initial begin
    fork
      begin 
        forever #5ns clk = !clk;
      end
      begin
        #100ns;
        rstn <= 1'b1;
        #100ns;
        rstn <= 1'b0;
        #100ns;
        rstn <= 1'b1;
      end
    join_none
  end

		mailbox #(int) indata;
		mailbox #(int) busdata;
		mailbox #(int) outdata;

initial begin
		indata = new();
		busdata = new();
		outdata = new();
	@(posedge rstn);
    @(negedge rstn);
    @(posedge rstn);
	mst_if.wr_en = 0;
	mst_if.rd_en = 1;
	slv_if.wr_en = 1;
	slv_if.rd_en = 0;
    fork
	data_check();
    begin
	for(i=0;i<=60;i++) begin
		@(posedge clk);
        if(mst_if.fifo_full==1) begin
        mst_if.wr_en = 0;
        wait(mst_if.fifo_full==0);
        mst_if.wr_en = 1;
        @(posedge clk);
        end
		mst_if.wr_en = 1;
		mst_if.wr_data = i;
        indata.put(mst_if.wr_data);
	end
    mst_if.wr_en = 0;
	repeat(10) @(posedge clk);
	for(i=0;i<=10;i++) begin
		@(posedge clk);
        if(mst_if.fifo_full==1) begin
        mst_if.wr_en = 0;
        wait(mst_if.fifo_full==0);
        mst_if.wr_en = 1;
        @(posedge clk);
        end
		mst_if.wr_en = 1;
		mst_if.wr_data = i;
        indata.put(mst_if.wr_data);
	end
	mst_if.wr_en = 0;
    end
    begin
    wait(slv_if.fifo_full==1);
    @(posedge clk);
	for(j=0;j<=40;j++) begin
		@(posedge clk);
        if(slv_if.fifo_empty==1) 
        begin
        slv_if.rd_en = 0;
        wait(slv_if.fifo_empty==0);
        end
		slv_if.rd_en = 1;
	end
    slv_if.rd_en = 0;
	repeat(10) @(posedge clk);
	for(j=0;j<=20;j++) begin
		@(posedge clk);
        if(slv_if.fifo_empty==1) 
        begin
        slv_if.rd_en = 0;
        wait(slv_if.fifo_empty==0);
        end
		slv_if.rd_en = 1;
	end
    slv_if.rd_en = 0;
	repeat(10) @(posedge clk);
	$finish();
    end
    join
end
	task data_check();
		int in_data, bus_data, out_data;
		/*mailbox #(int) indata;
		mailbox #(int) busdata;
		mailbox #(int) outdata;
		indata = new();
		busdata = new();
		outdata = new();*/

		fork
			forever begin
				@(posedge clk);
				//if(mst_if.fifo_full == 0 & mst_if.wr_en) indata.put(mst_if.wr_data);
				if(slv_if.fifo_empty == 0 & slv_if.rd_en) begin
					#1ns;
					outdata.put(slv_if.rd_data);
					end
			end
			forever begin
			@(posedge clk);
			if(bus_if.valid & bus_if.ready) begin
					busdata.put(bus_if.data);
			end
			end
			forever begin
				@(posedge clk);
				outdata.get(out_data);
				indata.get(in_data);
				busdata.get(bus_data);
				if ( out_data == bus_data & out_data == in_data ) begin
					$display( "compare succeed, out data = %d. " ,out_data );
					count++;
				end
				if ( out_data != bus_data | out_data != in_data ) begin
					$display( "compare error, out data = %d, bus data = %d, in data = %d. " ,out_data ,bus_data, in_data );
					count++;
					count_error++;
					end
			end
		join
		
	endtask
    
    endmodule