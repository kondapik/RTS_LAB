with Ada.Real_Time;       use Ada.Real_Time;
-- Add required sensor and actuator package --

package Tasks is
  procedure Background;
private

  --  Define periods and times  --
  sigPeriod : Time_Span := Milliseconds(10); 
  Time_Zero      : Time := Clock;
      
  --  Other specifications  --
  type eventID is (upPressed, downPressed, leftPressed, rightPressed, upReleased, downReleased, leftReleased, rightReleased, onLine, offLine);

end Tasks;
