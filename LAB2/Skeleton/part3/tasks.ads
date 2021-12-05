with Ada.Real_Time;       use Ada.Real_Time;
-- Add required sensor and actuator package --
with Webots_API;   use Webots_API;

package Tasks is
procedure Background;
private
	--  Define periods and times  --
	sigPeriod : Time_Span := Milliseconds(10); 
	Time_Zero      : Time := Clock;
		
	--  Other specifications  --
	type eventID is (onLine, offLine);
	type speedArray is array (MotorID) of Integer;
	defaultSpeed : Integer := 500;

end Tasks;
