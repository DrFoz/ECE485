//Tyson Fosdick
//ECE 485 Fall 2019
//Homework #1 Traffic light controller
//

module fsm(Clock, Reset, S1, S2, S3, L1, L2, L3);
input Clock;
input Reset;
input 			// sensors for approaching vehicles
S1, 			// Northbound on SW 4th Avenue
S2,		 	// Eastbound on SW Harrison Street
S3; 			// Westbound on SW Harrison Street

output reg [1:0]	// outputs for controlling traffic lights
L1, 			// light for NB SW 4th Avenue
L2, 			// light for EB SW Harrison Street
L3; 			// light for WB SW Harrison Street

//timer variables
wire
	timer_ng,
	timer_ewg,
	timer_yellow,
	timer_red;

wire reset, load, decr, value;	//Output wires to control counter modules

//Declare states, and assign values. Using one-hot encoding

parameter
	FS	= 6'b000001,
	REDL	= 6'b000010,
	NG	= 6'b000100,
	NY	= 6'b001000,
	EWG	= 6'b010000,
	EWY	= 6'b100000;

//Control parameters for outputs to lights

parameter
	FAIL	= 2'b00,
	GREEN	= 2'b01,
	YELLOW	= 2'b10,
	RED	= 2'b11;

reg [5:0] state;
reg [5:0] next_state;

//Counter instatiations

counter timerNG(
		.clk(Clock),
		.reset(reset),
		.load(load),
		.decr(decr),
		.timeup(timer_ng),
		.value(value));
		

counter timerEWG(
		.clk(Clock),
		.reset(reset),
		.load(load),
		.decr(decr),
		.timeup(timer_ewg));

counter timerYEL(
		.clk(Clock),
		.reset(reset),
		.load(load),
		.decr(decr),
		.timeup(timer_yellow));

counter timerRED(
		.clk(Clock),
		.reset(reset),
		.load(load),
		.decr(decr),
		.timeup(timer_red));

//State changes and resets

always @(posedge Clock, posedge Reset)
begin
	if(Reset)
		state <= FS; 		//Controller always starts in fail-safe
	else
		state <= next_state;	//state change
end

always @(state)
begin
	
	
	case(state)
		FS:	begin
			L1 = FAIL;			//starts in fail-safe
			L2 = FAIL;
			L3 = FAIL;
			end

		REDL:	begin		//All lights red
			L1 = RED;			
			L2 = RED;
			L3 = RED;
			end

		NG:	begin		//4th ave green, Harrison red
			L1 = GREEN;			
			L2 = RED;
			L3 = RED;
			end


		NY:	begin		//4th ave yellow, Harrison red
			L1 = YELLOW;			
			L2 = RED;
			L3 = RED;
			end


		EWG:	begin		//4th ave red, Harrison green
			L1 = RED;			
			L2 = GREEN;
			L3 = GREEN;
			end

		EWY:	begin		//4th ave red, Harrison yellow
			L1 = RED;			
			L2 = YELLOW;
			L3 = YELLOW;
			end
	endcase
end

//State transition block

always @(state, next_state)				//May need to add timers to sensitivity list
begin
	case(state)
					

		REDL:	begin
			if(timer_red && S1)		//4th has priority so S2, S3 are don't cares
				next_state = NG;	//State changes on counter timeup

			else if(timer_red && ~S1 && (S2 || S3))	//No cars on 4th and at least one on Harrison
				next_state = EWG;

			else
				next_state = REDL;	//Stay in red state counter not finished
			end
	 
		NG:	begin
			if(timer_ng && S1 && ~S2 && ~S3)	//Traffic on 4th, no traffic on Harrison so stay green
				next_state = NG;
			
			else if(timer_ng && ~S1 && (S2 || S3)) 	//No traffic on 4th, traffic on Harrison change to yellow
				next_state = NY;
			
			else
				next_state = NG;	//Wait for counter
			end


		NY:	begin
			if(timer_yellow)
				next_state = REDL;
			else
				next_state = NY;
			end


		EWG:	begin
			if(timer_ewg && ~S1 && (S2 || S3))	//No traffic on 4th, so Harrison so stay green
				next_state = EWG;
			
			else if(timer_ewg && S1) 		//traffic on 4th, Harrison change to yellow
				next_state = EWY;
			
			else
				next_state = EWY;	//Wait for counter
			end

		EWY:	begin
			if(timer_yellow)
				next_state = REDL;

			else
				next_state = EWY;
			end 
		
	endcase
end

endmodule
