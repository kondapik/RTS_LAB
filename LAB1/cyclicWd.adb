with Ada.Calendar, Ada.Text_IO,  Ada.Numerics.Float_Random;
use Ada.Calendar, Ada.Text_IO,  Ada.Numerics.Float_Random;

procedure cyclic_wd is
    Message: constant String := "Cyclic scheduler with watchdog";
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

	task Watchdog is
	    entry Start3;
		entry End3;
	end Watchdog;

	task body Watchdog is
		wdStart : Time := Clock;
		taskTime : Duration;
		checkTask : Boolean := False;
	begin
		loop
            select
				accept Start3 do
					wdStart := Clock;
					checkTask := True;
				end Start3;
			or
				accept End3 do
					checkTask := False;
					taskTime :=  Clock - wdStart;
					if (taskTime > 0.5) then
						put_line("Task 3 exceeded its deadline");
					end if;
				end End3;
			end select;

			if checkTask = True then
				-- taskTime :=  Clock - wdStart;
				if ((Clock - wdStart) > 0.5) then
					put_line("Task 3 exceeded its deadline.");
					checkTask := False;
				end if;
			end if;
		end loop;
	end Watchdog;

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
				Watchdog.Start3;
				f3(rnd1);
				Watchdog.End3;
			end if;

			s := s + 1;
			
			if (Clock > (loopStart + d)) then
				delay until (loopStart + 2*d);
				loopStart := loopStart + 2*d;
			else
				delay until (loopStart + d);
				loopStart := loopStart + d;
			end if;
        end loop;
end cyclic_wd;

