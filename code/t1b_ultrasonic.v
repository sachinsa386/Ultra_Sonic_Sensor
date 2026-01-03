/*
Module HC_SR04 Ultrasonic Sensor

This module will detect objects present in front of the range, and give the distance in mm.

Input:  clk_50M - 50 MHz clock
        reset   - reset input signal (Use negative reset)
        echo_rx - receive echo from the sensor

Output: trig    - trigger sensor for the sensor
        op     -  output signal to indicate object is present.
        distance_out - distance in mm, if object is present.
*/

// module Declaration

module t1b_ultrasonic(
    input clk_50M, reset, echo_rx,
    output reg trig,
    output op,
    output wire [15:0] distance_out
);

initial begin
    trig = 0;
end
//////////////////DO NOT MAKE ANY CHANGES ABOVE THIS LINE //////////////////

/*
Add your logic here
*/

     // Internal registers with deterministic initial values to avoid X propagation
    reg [15:0] distance_out_reg = 16'b0;
    reg        op_reg           = 1'b0;
//    assign distance_out = distance_out_reg;
    assign op           = op_reg;
    assign distance_out = distance_out_reg;
    // State encoding
    localparam IDLE      = 3'b000;
    localparam TRIG_HIGH = 3'b001;
    localparam WAIT_ECHO = 3'b010;
    localparam MEASURE   = 3'b011;
    localparam DONE      = 3'b100;

    reg [2:0] state = IDLE;
    reg [2:0] next_state = IDLE;

    // Using wider counters to cover useful ranges (32-bit chosen for safety)
    reg [31:0] counter = 32'b0;
    reg [31:0] echo_counter = 32'b0;

    // Trigger pulse length: 10 us @50 MHz -> 10e-6 / 20e-9 = 500 cycles
    localparam [31:0] TRIG_CYCLES = 32'd500;

    // Timeout while waiting for echo (prevents infinite wait)
    localparam [31:0] WAIT_TIMEOUT = 32'd1500000; // adjust if needed

	 initial begin
				state            <= IDLE;
            counter          <= 32'b0;
            echo_counter     <= 32'b0;
            trig             <= 1'b0;
            op_reg           <= 1'b0;
            distance_out_reg <= 16'b0;
	 end
		
    always @(posedge clk_50M or negedge reset) begin
        if (!reset) begin
            // active-low reset (clear)
            state            <= IDLE;
            counter          <= 32'b0;
            echo_counter     <= 32'b0;
            trig             <= 1'b0;
            op_reg           <= 1'b0;
            distance_out_reg <= 16'b0;
        end else begin
//            state <= next_state;
            case (state)
                IDLE: begin
							
						  if(counter<50) counter<=counter+32'b1;
						  else begin
						    state<=TRIG_HIGH;
							 counter<=32'b0;
//                    trig <= 1'b0;
//                    counter <= 32'd0;
                    echo_counter <= 32'b0;
                    // leave distance_out_reg/op_reg unchanged here (updated in DONE)
							end
					 end
                TRIG_HIGH: begin
						  
                    trig <= 1'b1;
                    if(counter<500)counter <= counter + 1'b1;
						  else begin
								echo_counter<=32'b0;
								trig<=1'b0;
								counter<=32'b0;
								state<=WAIT_ECHO;
						  end
								
                end

                WAIT_ECHO: begin
                    trig <= 1'b0;
                    if (counter<600052) begin
								counter <= counter + 1'b1;
								if (echo_rx)
                        echo_counter <= echo_counter + 1'b1;
								else if(!echo_rx)
									//if(echo_counter!=32'b0)
									distance_out_reg<=echo_counter*34/10000;
									
								end
							else begin
								state<=TRIG_HIGH;
//								echo_counter<=32'b0;
								counter<=32'b0;
							
                    // keep echo_counter as is until MEASURE
						  end
                end  
					 

                default: begin
                    trig <= 1'b0;
                end
            endcase
				
        end
    end
//////////////////DO NOT MAKE ANY CHANGES BELOW THIS LINE //////////////////
	 

endmodule