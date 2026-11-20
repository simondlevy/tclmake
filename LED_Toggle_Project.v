module LED_Toggle_Project
 (input  sysclk,
  input  btn0,
  output led0_b);
                             
  reg r_LED_1    = 1'b0;
  reg r_Switch_1 = 1'b0;
  
  // Purpose: Toggle LED output when btn0 is released.
  always @(posedge sysclk)
  begin
    r_Switch_1 <= btn0;  // Creates a Register
 
    // This conditional expression looks for a falling edge on btn0.
    // Here, the current value (btn0) is low, but the previous value
    // (r_Switch_1) is high.  This means that we found a falling edge.
    if (btn0 == 1'b0 && r_Switch_1 == 1'b1)
    begin
      r_LED_1 <= ~r_LED_1;   // Toggle LED output
    end
  end
 
  assign led0_b = r_LED_1;
 
endmodule
