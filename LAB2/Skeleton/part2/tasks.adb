with Ada.Text_IO;    use Ada.Text_IO;
with Ada.Real_Time;  use Ada.Real_Time;
with System;

with Webots_API;   use Webots_API;

package body Tasks is

-- Defining protected object to share event status
-- Provide interrupt service without interrupts
protected Event is
	entry Wait(id : out eventID);
	procedure Signal(id : in eventID);
private
	currentID : eventID;
	signalled : Boolean := False; 
end Event;

protected body Event is
	entry Wait (id : out eventID) when signalled is
	begin
		id := currentID;
		signalled := False;
	end Wait;

	procedure Signal(id : in eventID) is
	begin
		currentID := id;
		signalled := true;
	end Signal;
end Event;

-------------
--  Tasks  --
-------------   
task eventDispatcherTask is
	-- define its priority higher than the main procedure --
	-- main procedure priority is declared at main.adb:9
	pragma Priority (System.Default_Priority);

end eventDispatcherTask;

task body eventDispatcherTask is
	Next_Time : Time := Time_Zero;
	type eventArray is array (ButtonID) of Boolean;
	prevStatus : eventArray := (False, False, False, False);
	lineFound : Boolean := False;
	lineLimit : Integer := 400;
begin      
	-- task body starts here ---
	loop
	-- read sensors and print (have a look at webots_api.ads) ----
	-- Put_Line("Light Sensor Values: " & Integer'Image(read_light_sensor(LS1)) & ", " & Integer'Image(read_light_sensor(LS2)) & ", " & Integer'Image(read_light_sensor(LS3)));
		-- put_line("Distance to Obstacle: " & Integer'Image(read_distance_sensor));
	if ((read_light_sensor(LS1) < lineLimit or read_light_sensor(LS2) < lineLimit or read_light_sensor(LS3) < lineLimit) and lineFound = False) then
		lineFound := True;
		Event.signal(onLine);
	elsif (read_light_sensor(LS1) > lineLimit and read_light_sensor(LS2) > lineLimit and read_light_sensor(LS3) > lineLimit and lineFound = True) then
		lineFound := False;
		Event.signal(offLine);
	end if;

	if (button_pressed(UpButton) = True and prevStatus(UpButton) = False) then
		prevStatus(UpButton) := True;
		Event.signal(upPressed);
	elsif (button_pressed(UpButton) = False and prevStatus(UpButton) = True) then
		prevStatus(UpButton) := False;
		Event.signal(upReleased);
	end if;
	
	if (button_pressed(DownButton) = True and prevStatus(DownButton) = False) then
		prevStatus(DownButton) := True;
		Event.signal(downPressed);
	elsif (button_pressed(DownButton) = False and prevStatus(DownButton) = True) then
		prevStatus(DownButton) := False;
		Event.signal(downReleased);
	end if;

	if (button_pressed(LeftButton) = True and prevStatus(LeftButton) = False) then
		prevStatus(LeftButton) := True;
		Event.signal(leftPressed);
	elsif (button_pressed(LeftButton) = False and prevStatus(LeftButton) = True) then
		prevStatus(LeftButton) := False;
		Event.signal(leftReleased);
	end if;
	
	if (button_pressed(RightButton) = True and prevStatus(RightButton) = False) then
		prevStatus(RightButton) := True;
		Event.signal(rightPressed);
	elsif (button_pressed(RightButton) = False and prevStatus(RightButton) = True) then
		prevStatus(RightButton) := False;
		Event.signal(rightReleased);
	end if;

	Next_Time := Next_Time + sigPeriod;
	delay until Next_Time;

	exit when simulation_stopped;
	end loop;
end eventDispatcherTask;

task motorControlTask is
	pragma Priority (System.Priority'Last);
end motorControlTask;

task body motorControlTask is
	rcvEvent : eventID;
	type speedArray is array (MotorID) of Integer;   
	type buttonArray is array (ButtonID) of Boolean;
	finalSpeed : speedArray := (0,0);
	speedStep : Integer := 450;
	buttonStatus : buttonArray := (False, False, False, False);
begin
	loop
	Event.Wait(rcvEvent);
	case rcvEvent is
		when upPressed =>
			finalSpeed(LeftMotor) := finalSpeed(LeftMotor) + speedStep;
			finalSpeed(RightMotor) := finalSpeed(RightMotor) + speedStep;
			put_line("Going Front...");
			buttonStatus(UpButton) := True;
		when upReleased =>
			if buttonStatus(UpButton) then
				finalSpeed(LeftMotor) := finalSpeed(LeftMotor) - speedStep;
				finalSpeed(RightMotor) := finalSpeed(RightMotor) - speedStep;
				put_line("Not Going Front...");
				buttonStatus(UpButton) := False;
			end if;
		when downReleased =>
			if buttonStatus(DownButton) then
				finalSpeed(LeftMotor) := finalSpeed(LeftMotor) + speedStep;
				finalSpeed(RightMotor) := finalSpeed(RightMotor) + speedStep;
				put_line("Going Back...");
				buttonStatus(DownButton) := False;
			end if;
		when downPressed =>
			finalSpeed(LeftMotor) := finalSpeed(LeftMotor) - speedStep;
			finalSpeed(RightMotor) := finalSpeed(RightMotor) - speedStep;
			put_line("Not Going Back..."); 
			buttonStatus(DownButton) := True;
		when leftPressed =>
			finalSpeed(RightMotor) := finalSpeed(RightMotor) + speedStep;
			put_line("Turning Left...");
			buttonStatus(LeftButton) := True;
		when leftReleased =>
			if buttonStatus(LeftButton) then
				finalSpeed(RightMotor) := finalSpeed(RightMotor) - speedStep;
				put_line("Not Turning Left...");
				buttonStatus(LeftButton) := False;
			end if;
		when rightPressed =>
			finalSpeed(LeftMotor) := finalSpeed(LeftMotor) + speedStep;
			put_line("Turning Right...");
			buttonStatus(RightButton) := True;
		when rightReleased =>
			if buttonStatus(RightButton) then
				finalSpeed(LeftMotor) := finalSpeed(LeftMotor) - speedStep;
				put_line("Not Turning Right...");
				buttonStatus(RightButton) := False;
			end if;
		when onLine =>
			finalSpeed(LeftMotor) := finalSpeed(LeftMotor) - (2 * finalSpeed(LeftMotor));
			finalSpeed(RightMotor) := finalSpeed(RightMotor) - (2 * finalSpeed(RightMotor));
			put_line("Reversing");
		when offLine =>
			finalSpeed(LeftMotor) := finalSpeed(LeftMotor) - finalSpeed(LeftMotor);
			finalSpeed(RightMotor) := finalSpeed(RightMotor) - finalSpeed(RightMotor);
			put_line("Stopping");
			buttonStatus := (False, False, False, False);
	end case;

	set_motor_speed (LeftMotor, finalSpeed(LeftMotor));
	set_motor_speed (RightMotor, finalSpeed(RightMotor));

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
