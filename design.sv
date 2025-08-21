module intrpt_cntrl(

//processor interface
clk,rstn,pwrite,penable,paddr,pwdata,psel,intrt_servised,pready,perror,prdata,intrt_to_be_servised,intrt_valid,

//slave interface
  intrt_active);
  
  parameter data_width=4; 
  parameter num_slave=16;
  parameter width=$clog2(num_slave);
  
  parameter s_no_intrt                   =3'b001;
  parameter s_active_intrt_given_to_proc =3'b010;
  parameter s_wait_for_intrt_servised    =3'b100;
  
  input clk,rstn,pwrite,penable;
  input [width-1:0]paddr;
  input [data_width-1:0]pwdata;
  input [2:0]psel;
  input intrt_servised;
  output reg pready;
  output reg perror;
  output reg [width-1:0]prdata;
  output reg [width-1:0]intrt_to_be_servised;
  output reg intrt_valid=0;
    
  input [num_slave-1:0]intrt_active;
  
  //register to store the priority register
  reg [width-1:0]pri_reg[num_slave-1:0];
  integer i;
  reg [2:0] state,next_state;
  
  //Giving Priority values to the interrupts
  
  always@(posedge clk)begin
    if(!rstn)begin
      pready=0;
      perror=0;
      prdata=0;
      intrt_to_be_servised=0;
      intrt_valid=0;
      for(i=0;i<num_slave;i=i+1)pri_reg[i]=0;
      state=s_no_intrt;
      next_state=s_no_intrt;
    end
    else begin
      if(penable==1)begin
        pready=1;
        if(pwrite==1)begin
          pri_reg[paddr]=pwdata;
        end
        else begin
          prdata=pri_reg[paddr];
        end
      end
      else if(penable==0)begin
        pready=0;
      end
    end
  end
  
  //Handeling the interrupt using the priority values
  
  integer curr_high_pri;
  reg [3:0]slave_with_high_pri=0;
  
  always@(posedge clk)begin
    if(rstn)begin
      case(state)
        s_no_intrt:begin
          if(intrt_active!=0)begin
            next_state=s_active_intrt_given_to_proc;
            curr_high_pri=0;
            slave_with_high_pri=0;
          end
        end
        
        s_active_intrt_given_to_proc:begin
          for(i=0;i<num_slave;i=i+1)begin
            if(intrt_active[i]==1)begin
            if(curr_high_pri<=pri_reg[i])begin
              curr_high_pri=pri_reg[i];
              $display("curre high pri=%0d",curr_high_pri);
              slave_with_high_pri=i;
              $display("slave with high pri=%0d",slave_with_high_pri);
            end
            else begin
              curr_high_pri=curr_high_pri;
              slave_with_high_pri=slave_with_high_pri;
            end
            end
          end
          intrt_valid=1;
          intrt_to_be_servised=slave_with_high_pri;
          next_state=s_wait_for_intrt_servised;
        end
        
        s_wait_for_intrt_servised:begin
          if(intrt_servised==1)begin
            intrt_valid=0;
            if(intrt_active!=0)begin
              next_state=s_active_intrt_given_to_proc;
              $display("next_state=%b",next_state);
              curr_high_pri=0;
              slave_with_high_pri=0;
              
            end
            else begin
              next_state=s_no_intrt;
            end
          end
        end
      endcase
    end
  end
  
  always@(next_state)state=next_state;
        
endmodule
