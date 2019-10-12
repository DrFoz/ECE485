//Tyson Fosdick
//ECE 485 Fall 2019
//Homework #1 Traffic light controller
//

module fsm(Clock, Reset, S1, S2, S3, L1, L2, L3);
//Input and output assignments
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

//Instantiate counter
counter timerNG(
		.clk(Clock),
		.reset(Reset),
		.load(load),
		.decr(decr),
		.timeup(timeup),
		.value(value));

//Instantiate traffic light controller
trafficlightcntr fourthHarrison(
				.Clock(Clock),
				.reset(Reset), 
				.S1(S1), 
				.S2(S2), 
				.S3(S3), 
				.L1(L1), 
				.L2(L2), 
				.L3(L3), 
				.load(load), 
				.decr(decr), 
				.value(value), 
				.timeup(timeup));

endmodule



//Traffic light Controller module
module trafficlightcntr(Clock, Reset, S1, S2, S3, L1, L2, L3, load, decr, value, timeup)
//Input and output assignments
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

output reg [7:0]  value;	//register to set timer duration

	
wire load, decr;	//Output wires to control counter module

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



//State changes and resets

always @(posedge Clock, posedge Reset)
begin
	if(Reset) 
	begin
		state = FS; 		//Controller always starts in fail-safe
		value = 1'b1;		//Load value for red light
		load = 1'b1;		//Assert bit to load timer
	end

	else
	begin
		load = 1'b0;		//De-assert load bit
		if(timerup)
			decr <= 1'b0;
		state <= next_state;	//state change
	end
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

always @(state or next_state)				
begin
	case(state)
					

		REDL:	begin
				if(timerup && S1)		//4th has priority so S2, S3 are don't cares
				begin
					value = 8'b00101101;	//load greenlight timer value
					load = 1'b1;		//Assert load bit
					next_state = NG;	//State changes on counter timeup
				end
				

			`	else
				begin
					decr <= 1'b1;		//Assert decrement bit for timer
					next_state = REDL;	//Stay in red state counter not finished
				end
			end
	 
		NG:	begin
				if(timerup && S1 && ~S2 && ~S3)	//Traffic on 4th, no traffic on Harrison so stay green
				begin	
					load = 1'b1; 		//Assert load bit to reload value
					next_state = NG;
				end
			
				else if(timerup && ~S1 && (S2 || S3)) 	//No traffic on 4th, traffic on Harrison change to yellow
				begin
					value = 8'b00000101;	//load greenlight timer value
					load = 1'b1;		//Assert load bit
					next_state = NY;
			
				else
				begin
					decr <= 1b'1;		//Assert decrement
					next_state = NG;	//Stay in current state
				end
			end


		NY:	begin
				if(timer_yellow)
				begin
					value = 8'b00000001;	//load greenlight Harrison timer value
					load = 1'b1;
					next_state = REDL;
				end
	
				else
				begin
					decr <= 1'b1;
					next_state = NY;
				end
				end


		EWG:	begin
			if(timer_ewg)	 		//traffic on 4th, Harrison change to yellow
			begin
				value = 8'b00000101;	//load greenlight timer value
				load = 1'b1;
				next_state = EWY;
			end
			
			else
			begin
				decr <= 1'b1;
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
