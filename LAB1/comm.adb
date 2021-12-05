with Ada.Calendar, Ada.Text_IO,  Ada.Numerics.Discrete_Random;
use Ada.Calendar, Ada.Text_IO;

procedure comm is
    Message: constant String := "Process communication";
	type randRange is range 0..20; -- sertting range for numbers sent by producer and read by consumer
	package randInt is new ada.numerics.discrete_random(randRange);
	use randInt;
	gen : Generator;

	task buffer is
		entry push(element : in randRange); -- Pushing element into buffer
        entry pop(element : out randRange); -- Popping element from buffer
		entry stopBuffer; -- Stop Buffer task
	end buffer;

	task producer is
        entry stopProducer; -- Stop Producer
	end producer;

	task consumer;

	task body buffer is 
		Message: constant String := "buffer executing";
		type Index is range 0 .. 10; -- Buffer length is 11 
		type myIntArray is array (Index) of randRange;

		fifoBuffer : myIntArray;
		buffLen,buffEmpty : Integer := 11; -- setting buffer length and the number of empty slots
		writeIdx, readIdx : Index := 0; -- initalizing reading and writing index to 0
	begin
		Put_Line(Message);
		loop
            select
				when buffEmpty > 0 => -- Block producer if buffer is full
					accept push(element : in randRange) do
						fifoBuffer(writeIdx) := element;
						writeIdx := Index(Integer(writeIdx + 1) mod buffLen); -- wrapping index
						buffEmpty := buffEmpty - 1; -- reduce the empty slots
					end push;
				or when buffEmpty < buffLen => -- Block consumer if buffer is empty
					accept  pop(element : out randRange) do
						element := fifoBuffer(readIdx);
						readIdx := Index(Integer(readIdx + 1) mod buffLen); -- wrapping index
						buffEmpty := buffEmpty + 1;  -- increment the empty slots
					end pop;
				or
					accept stopBuffer;
					put_line("Exiting Buffer");
					exit;
					-- accept stopBuffer do
					-- 	put_line("Exiting Buffer");
					-- 	exit;
					-- end stopBuffer;
			end select; 
		end loop;
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
				delay Duration((randNo mod 3)); -- wait for random time  before pushing the value
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
			delay Duration((Random(gen) mod 18)); -- wait for random time before popping the value
            buffer.pop(element);
			Put_Line("Popping " & randRange'Image(element) & " from buffer");
			sum := sum + Integer(element); -- sum all popped elements
			if sum > 100 then -- stop producer and buffer if sum is more than 100
				producer.stopProducer;
				buffer.stopBuffer;
				put_line("Exiting Consumer");
				exit;
			end if;
		end loop Main_Cycle;
                -- add your code to stop executions of other tasks     
		exception
			  when TASKING_ERROR =>
				  Put_Line("Buffer finished before producer");
		Put_Line("Ending the consumer");
	end consumer;
begin
	Put_Line(Message);
end comm;
