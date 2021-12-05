with Ada.Text_IO;    use Ada.Text_IO;
with Ada.Real_Time;  use Ada.Real_Time;
with System;

with Webots_API;   use Webots_API;

package body Tasks is
	-- Defining protected object to share event status
	-- Provide interrupt service without interrupts

	-- motorControl object will calculate final motor speeds based on information from various tasks
	-- it also informs motor control task with the latest calculated motor speed values
	protected motorControl is
		entry getRequiredSpeed(reqSpeed : out speedArray); -- entry to inform motor control task
		procedure setSpeedLimit(limit : in Float); -- speed limit is set buy the distance task
		procedure takeTurn(leftTurn : in Boolean; -- line follower task will determine what turn to take and when
						rightTurn : in Boolean;
						withCare : in Boolean);
	private
		turnSpeed : Integer := 10; -- speed of minor turns to adjust direction
		finalSpeed : speedArray := (defaultSpeed, defaultSpeed); -- motor speeds for left and right motors
		signalled : Boolean := False;
		speedLimit : Float := 1.0; -- final speed is reduced by a factor of speedLimit
	end motorControl;
	
	protected body motorControl is
		entry getRequiredSpeed (reqSpeed : out speedArray) when signalled is
		begin
			reqSpeed := finalSpeed;
			signalled := False;
		end getRequiredSpeed;

		-- speed limit is determined buy the distance task and is applied here
		procedure setSpeedLimit(limit : in Float) is
		begin
			finalSpeed(LeftMotor) := Integer(Float(defaultSpeed) * limit);
			finalSpeed(RightMotor) := Integer(Float(defaultSpeed) * limit);
			speedLimit := limit; -- remembering locally to be used to takeTurn procedure
			signalled := true;
		end setSpeedLimit;

		procedure takeTurn(leftTurn : in Boolean; rightTurn : in Boolean; withCare : in Boolean) is
			speedFactor : Float := 1.0;
		begin
			-- 'withCare' -> go slow and turn fast if two of the three light sensors are outside the line
			if withCare then
				turnSpeed := 20;
				speedFactor := 0.8;
				-- put_line("Turning with caution...");
			else
				turnSpeed := 10;
				speedFactor := 1.0;
			end if;

			-- Turn left by increasing speed of right motor
			if leftTurn then
				finalSpeed(RightMotor) := Integer(Float(finalSpeed(RightMotor)) * speedFactor) + Integer(Float(turnSpeed) * speedLimit);
				-- put_line("Turning Left...");
			else
				finalSpeed(RightMotor) := Integer(Float(defaultSpeed) * speedLimit * speedFactor);
			end if;

			-- Turn right by increasing speed of left motor
			if rightTurn then
				-- put_line("Turning Right...");
				finalSpeed(LeftMotor) := Integer(Float(finalSpeed(LeftMotor)) * speedFactor) + Integer(Float(turnSpeed) * speedLimit);
			else
				finalSpeed(LeftMotor) := Integer(Float(defaultSpeed) * speedLimit  * speedFactor);
			end if;

			signalled := true;
		end takeTurn;
	end motorControl;

	-------------
	--  Tasks  --
	-------------   
	task lineFollowingTask is
		pragma Priority (System.Default_Priority);
	end lineFollowingTask;

	task body lineFollowingTask is
		Next_Time : Time := Time_Zero;
		lineLimit : Integer := 350;
		reset : Boolean := True;
		lastTurn : Boolean := True;
	begin  
		-- task body starts here ---
		loop
			-- read sensors and print (have a look at webots_api.ads) ----
			-- put_line("Light Sensor Values: " & Integer'Image(read_light_sensor(LS1)) & ", " & Integer'Image(read_light_sensor(LS2)) & ", " & Integer'Image(read_light_sensor(LS3)));

			if (read_light_sensor(LS1) > lineLimit and read_light_sensor(LS2) > lineLimit) or (read_light_sensor(LS2) > lineLimit and read_light_sensor(LS3) > lineLimit) then
				-- if two of the three sensors are outside then turn in the opposite direction
				motorControl.takeTurn(not lastTurn, lastTurn, read_light_sensor(LS2) > lineLimit);
			elsif (read_light_sensor(LS1) > lineLimit or read_light_sensor(LS2) > lineLimit or read_light_sensor(LS3) > lineLimit) then
				-- take left turn if LS3 crossed the line and right if LS1 crossed the line
				motorControl.takeTurn((read_light_sensor(LS3) > lineLimit), (read_light_sensor(LS1) > lineLimit), read_light_sensor(LS2) > lineLimit);
				
				-- determine which is the last turn. True -> Left; False -> Right
				if (read_light_sensor(LS3) > lineLimit) then
					lastTurn := True;
				end if;

				if (read_light_sensor(LS1) > lineLimit) then
					lastTurn := False;
				end if;

				reset := True;
			else
				-- reset the "steering" once when the puck is in-line
				if reset then
					motorControl.takeTurn(False, False, False);
					reset := false;
				end if;
			end if;
			
			Next_Time := Next_Time + sigPeriod;
			delay until Next_Time;

			exit when simulation_stopped;
		end loop;
	end lineFollowingTask;


	task distanceTask is
		-- define its priority higher than the main procedure --
		-- main procedure priority is declared at main.adb:9
		pragma Priority (System.Default_Priority);

	end distanceTask;

	task body distanceTask is
		Next_Time : Time := Time_Zero;
		distanceLimit : Integer := 120; -- Distance to stop
		slowLimit : Integer := 80; -- Distance to slow
		currDist : Integer;
		reset : Boolean := True;
	begin  
		-- task body starts here ---
		loop
			currDist := read_distance_sensor;
			-- put_line("Distance to Obstacle: " & Integer'Image(currDist));

			if currDist > distanceLimit then
				motorControl.setSpeedLimit(0.0);
				-- put_line("Distance to Obstacle: " & Integer'Image(currDist));
				reset := true;
			elsif currDist > slowLimit then
				motorControl.setSpeedLimit(Float(abs(currDist - slowLimit)) / Float(currDist));
				reset := true;
				-- put_line("Distance to Obstacle: " & Integer'Image(currDist));
			else
				if reset then
					motorControl.setSpeedLimit(Float(1));
					reset := False;
				end if;
			end if;

			Next_Time := Next_Time + sigPeriod;
			delay until Next_Time;

			exit when simulation_stopped;
		end loop;
	end distanceTask;

	task motorControlTask is
		pragma Priority (System.Priority'Last);
	end motorControlTask;

	task body motorControlTask is
		rcvSpeed : speedArray;
		maxSpeed : Integer := 950;
	begin
		loop
			motorControl.getRequiredSpeed(rcvSpeed);

			-- limit the maximum speed value sent to motors
			if (rcvSpeed(LeftMotor) > maxSpeed) then
				rcvSpeed(LeftMotor) := maxSpeed;
			end if;

			if (rcvSpeed(RightMotor) > maxSpeed) then
				rcvSpeed(RightMotor) := maxSpeed;
			end if;
		
			set_motor_speed (LeftMotor, rcvSpeed(LeftMotor));
			set_motor_speed (RightMotor, rcvSpeed(RightMotor));
			
			exit when simulation_stopped;

		end loop;
	end motorControlTask;

	-- Background procedure required for package
	procedure Background is begin
		while not simulation_stopped loop
		delay 0.25;
		end loop;
	end Background;

end Tasks;
