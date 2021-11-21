with Ada.Calendar, Ada.Text_IO,  Ada.Numerics.Float_Random;
use Ada.Calendar, Ada.Text_IO,  Ada.Numerics.Float_Random;

procedure cyclicSch is
    Message: constant String := "Cyclic scheduler";
    d: Duration := 1.0;
	Start_Time,  loopStart: Time := Clock;
	s: Integer := 0;
	rnd, rnd1: float;
	Gen : Ada.Numerics.Float_Random.Generator;

	procedure f1 (eTime : Float) is 
		Message: constant String := "f1 executing, time is now";
	begin
		Put(Message);
		Put_Line(Duration'Image(Clock - Start_Time));
		delay (Duration(eTime));
	end f1;

	procedure f2 (eTime : Float) is 
		Message: constant String := "f2 executing, time is now";
	begin
		Put(Message);
		Put_Line(Duration'Image(Clock - Start_Time));
		delay (Duration(eTime));
	end f2;

	procedure f3 (eTime : Float) is 
		Message: constant String := "f3 executing, time is now";
	begin
		Put(Message);
		Put_Line(Duration'Image(Clock - Start_Time));
		delay (Duration(eTime));
	end f3;

	begin
        loop
			rnd := Ada.Numerics.Float_Random.Random (Gen);
			rnd1 := Ada.Numerics.Float_Random.Random (Gen);
			
			f1(rnd / Float(4));
			f2(rnd / Float(4));
			
			if s = 0 then
				delay until (loopStart + Duration(0.5));
			end if;
			
			if (s mod 2 = 0) then
				f3(rnd1 / Float(2));
			end if;
			
			s := s + 1;
			
			delay until (loopStart + d);
			loopStart := loopStart + d;
        end loop;
end cyclicSch;

