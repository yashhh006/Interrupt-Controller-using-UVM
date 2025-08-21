module intrpt_cntrl_tb;
  parameter data_width=4; 
  parameter num_slave=16;
  parameter width=$clog2(num_slave);
  
  reg clk,rstn,pwrite,penable;
  reg [width-1:0]paddr;
  reg [data_width-1:0]pwdata;
  reg [2:0]psel;
  reg intrt_servised;
  reg pready;
  wire perror;
  wire [width-1:0]prdata;
  reg [width-1:0]intrt_to_be_servised;
  wire intrt_valid;
    
  reg [num_slave-1:0]intrt_active;
  
  intrpt_cntrl #(.width(width),.data_width(data_width),.num_slave(num_slave)) dut(.*);
  
  reg [40*8:0]testcase;
  integer i,j,k;
  reg[data_width-1:0] array[num_slave-1];
  
  initial begin
    clk=0;
    forever #5 clk=~clk;
  end
  
  task rstn_logic();
    begin
      @(posedge clk);
      penable=0;
      pready=0;
      pwrite=0;
      paddr=0;
    end
  endtask
  
  task write(input [width-1:0]addr, input [data_width-1:0]data);
    begin
      @(posedge clk);
      paddr=addr;
      pwdata=data;
      penable=1;
      pwrite=1;
      wait(pready==1);
    end
  endtask
  
  task random();
    reg [width-1:0]addr;
    reg [width-1:0]arr [num_slave-1:0];
    for(j=0;j<num_slave;j=j+1)begin
      @(posedge clk);
      paddr=j;
      arr[j]=$urandom_range(0,15);
      for(k=0;k<j;k=k+1)begin
        if(arr[k]==arr[j])
          arr[j]=$urandom_range(0,15);
      end
      pwdata=arr[j];
      penable=1;
      pwrite=1;
      wait(pready==1);
    end
  endtask
  
  initial begin
    rstn=0;
    pwrite=0;
    penable=0;
    paddr=0;
    pwdata=0;
    psel=0;
    intrt_servised=0;
    intrt_active=0;
    
    @(posedge clk);
    @(posedge clk);
    rstn=1;
    
    
    if($value$plusargs("testcase=%s",testcase))begin
      case(testcase)
        "low_periph_low_prior":begin
          for(i=0;i<num_slave;i=i+1)begin
            write(i,i);
          end
          rstn_logic();
        end
        
        "low_periph_high_prior":begin
          for(i=0;i<num_slave;i=i+1)begin
            write(i,num_slave-i);
          end
          rstn_logic();
        end
        
        "random_prior":begin
          random();
          rstn_logic();
        end
      endcase
      intrt_active=$random;
    end
    else begin
      $display("no argurement passed");
      random();
      rstn_logic();
    end
  end
  
  //reg [3:0]slave_with_high_pri;
  
  always@(posedge intrt_valid)begin
    #12
    intrt_servised=1;
    intrt_active[intrt_to_be_servised]=0;
    //@(posedge clk);
    //intrt_servised=0;
  end
  
  initial begin
    $dumpfile("dump.vcd"); 
    $dumpvars(0, intrpt_cntrl_tb);
  end
  
  initial begin
    #500
    $finish;
  end
endmodule
  
  
