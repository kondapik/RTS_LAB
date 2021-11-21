with Ada.Calendar, Ada.Text_IO,  Ada.Numerics.Discrete_Random;
use Ada.Calendar, Ada.Text_IO;

procedure commProtected is
    Message: constant String := "Process communication";
	type randRange is range 0..20;
	package randInt is new ada.numerics.discrete_random(randRange);
	use randInt;
	gen : Generator;

	type Index is range 0 .. 10; -- Buffer length is 11 
	type myIntArray is array (Index) of randRange;

	protected  buffer is
        entry push(element : in randRange); -- Pushing element into buffer
		entry pop(element : out randRange); -- Popping element from buffer
	private
		fifoBuffer : myIntArray;
		buffLen,buffEmpty : Integer := 11;
		writeIdx, readIdx : Index := 0;
	end buffer;

	task producer is
        entry stopProducer;
	end producer;

	task consumer;

	protected body buffer is 
        entry  push(element : in randRange)
			when  buffEmpty > 0 is
		begin
			fifoBuffer(writeIdx) := element;
			writeIdx := Index(Integer(writeIdx + 1) mod buffLen);
			buffEmpty := buffEmpty - 1;
		end push;

		entry pop(element : out randRange)
			when buffEmpty < buffLen is
		begin
			element := fifoBuffer(readIdx);
			readIdx := Index(Integer(readIdx + 1) mod buffLen);
			buffEmpty := buffEmpty + 1;
		end pop;

	end buffer;

	task body producer is 
		Message: constant String := "producer executing";
		randNo : randRange;
	begin
		Put_Line(Message);
		Reset(gen);
		loop
			randNo := Random(gen);
			select
				accept stopProducer;
				put_line("Exiting Producer");
				exit;
				-- accept stopProducer do
				-- 	put_line("Exiting Producer");
				-- 	exit;
				-- end stopProducer;
			or
				delay Duration((randNo mod 3));
				Put_Line("Pushing " & randRange'Image(randNo) & " into buffer");
				buffer.push(randNo);
			end select;
		end loop;
	end producer;


	task body consumer is 
		Message: constant String := "consumer executing";
		element : randRange; 
		sum : Integer := 0;
	begin
		Put_Line(Message);
		Main_Cycle:
		loop
			delay Duration((Random(gen) mod 18));
            buffer.pop(element);
			Put_Line("Popping " & randRange'Image(element) & " from buffer");
			sum := sum + Integer(element);
			if sum > 100 then
				producer.stopProducer;
				put_line("Exiting Consumer");
				exit;
			end if;
		end loop Main_Cycle;
                -- add your code to stop executions of other tasks     
		Put_Line("Ending the consumer");
	end consumer;
begin
	Put_Line(Message);
end commProtected;