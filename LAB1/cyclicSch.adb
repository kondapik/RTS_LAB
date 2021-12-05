with Ada.Calendar, Ada.Text_IO,  Ada.Numerics.Float_Random;
use Ada.Calendar, Ada.Text_IO,  Ada.Numerics.Float_Random;

procedure cyclicSch is
    Message: constant String := "Cyclic scheduler";
    d: Duration := 1.0;
	Start_Time,  loopStart: Time := Clock;
	s: Integer := 0; -- Count the seconds to trigger F3 everyother second
	rnd, rnd1: float; -- Random execution times
	Gen : Ada.Numerics.Float_Random.Generator;

	procedure f1 (eTime : Float) is 
		Message: constant String := "f1 executing, time is now";
	begin
		Put(Message);
		Put_Line(Duration'Image(Clock - Start_Time));
		delay (Duration(eTime)); -- wait for the recieved execution time
	end f1;

	procedure f2 (eTime : Float) is 
		Message: constant String := "f2 executing, time is now";
	begin
		Put(Message);
		Put_Line(Duration'Image(Clock - Start_Time));
		delay (Duration(eTime));  -- wait for the recieved execution time
	end f2;

	procedure f3 (eTime : Float) is 
		Message: constant String := "f3 executing, time is now";
	begin
		Put(Message);
		Put_Line(Duration'Image(Clock - Start_Time));
		delay (Duration(eTime)); -- wait for the recieved execution time
	end f3;

	begin
        loop
			-- Randomly  generating the execution time for all procedures
			rnd := Ada.Numerics.Float_Random.Random (Gen);
			rnd1 := Ada.Numerics.Float_Random.Random (Gen);
			
			-- dividing rand by 4 as rand number is between 0 to 1 and f1 + f2 < 0.5
			f1(rnd / Float(4));
			f2(rnd / Float(4));
			
			-- if it is first time then create 0.5 sec delay before starting f3
			delay until (loopStart + Duration(0.5));

			
			-- call f3 everyother second
			if (s mod 2 = 0) then
				f3(rnd1 / Float(2));
			end if;
			
			s := s + 1;
			
			-- waiting for a second after f1 started.
			delay until (loopStart + d);
			loopStart := loopStart + d;
        end loop;
end cyclicSch;

