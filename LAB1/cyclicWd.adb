with Ada.Calendar, Ada.Text_IO,  Ada.Numerics.Float_Random;
use Ada.Calendar, Ada.Text_IO,  Ada.Numerics.Float_Random;

procedure cyclic_wd is
    Message: constant String := "Cyclic scheduler with watchdog";
    d: Duration := 1.0;
	Start_Time,  loopStart: Time := Clock;
	s: Integer := 0;  -- Count the seconds to trigger F3 everyother second
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
		delay (Duration(eTime)); -- wait for the recieved execution time
	end f2;

	procedure f3 (eTime : Float) is 
		Message: constant String := "f3 executing, time is now";
	begin
		Put(Message);
		Put_Line(Duration'Image(Clock - Start_Time));
		delay (Duration(eTime)); -- wait for the recieved execution time
	end f3;

	task Watchdog is
	    entry Start3;
		entry End3;
	end Watchdog;

	task body Watchdog is
		wdStart : Time := Clock;
		-- taskTime : Duration;
		checkTask : Boolean := False;
	begin
		loop
            select
				accept Start3 do
					-- Remember clock when  f3 starts and set check flag
					wdStart := Clock;
					checkTask := True;
				end Start3;
			or
				accept End3 do
					-- Reset check flag
					checkTask := False;
				end End3;
			else
				if checkTask = True then
					-- checking if the time is exceeded
					-- taskTime :=  Clock - wdStart;
					if ((Clock - wdStart) > 0.5) then
						put_line("Task 3 exceeded its deadline.");
						checkTask := False;
					end if;
				end if;
			end select;
		end loop;
	end Watchdog;

	begin
        loop
		-- Randomly  generating the execution time for all procedures
			rnd := Ada.Numerics.Float_Random.Random (Gen);
			rnd1 := Ada.Numerics.Float_Random.Random (Gen);
			
			f1(rnd / Float(4));
			f2(rnd / Float(4));
			
			-- dividing rand by 4 as rand number is between 0 to 1 and f1 + f2 < 0.5
			delay until (loopStart + Duration(0.5));
			
			if (s mod 2 = 0) then
				Watchdog.Start3; -- Informing watchdog that F3 started
				f3(rnd1); -- Using rand value directly as it can vary from 0 to 1
				Watchdog.End3; -- Informing watchdog that F3 ended
			end if;

			s := s + 1;
			
			-- if the current time is more than the 'usual'
			if (Clock > (loopStart + d)) then
				-- go to next second
				delay until (loopStart + 2*d);
				loopStart := loopStart + 2*d;
			else
				-- 'usual' delay
				delay until (loopStart + d);
				loopStart := loopStart + d;
			end if;
        end loop;
end cyclic_wd;

