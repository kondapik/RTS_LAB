with Ada.Text_IO;    use Ada.Text_IO;
with Ada.Real_Time;  use Ada.Real_Time;
with System;

with Webots_API;   use Webots_API;

package body Tasks is
  -------------
  --  Tasks  --
  -------------   
  task HelloworldTask is
    -- define its priority higher than the main procedure --
    -- main procedure priority is declared at main.adb:9
    pragma Priority (System.Default_Priority);

  end HelloworldTask;

  task body HelloworldTask is
    Next_Time : Time := Time_Zero;
    randCtrl : Integer := 0;
    ctrlTout : Integer := 50;
  begin      
    -- task body starts here ---

    loop
      -- read sensors and print (have a look at webots_api.ads) ----
      Put_Line("First Light Sensor Value: " & Integer'Image(read_light_sensor(LS1)));
      Put_Line("Second Light Sensor Value: " & Integer'Image(read_light_sensor(LS2)));
      Put_Line("Third Light Sensor Value: " & Integer'Image(read_light_sensor(LS3)));

      if (randCtrl = ctrlTout) then
        set_motor_speed (LeftMotor, 500);
        set_motor_speed (RightMotor, 500);
      elsif (randCtrl = ctrlTout*2) then
        set_motor_speed (LeftMotor, 500);
        set_motor_speed (RightMotor, 300);
      elsif (randCtrl = ctrlTout*3) then
        set_motor_speed (LeftMotor, -500);
        set_motor_speed (RightMotor, -500);
      elsif (randCtrl = ctrlTout*4) then
        set_motor_speed (LeftMotor, 300);
        set_motor_speed (RightMotor, 500);
        randCtrl := 0;
      end if;

      randCtrl := randCtrl + 1;

      Next_Time := Next_Time + Period_Display;
      delay until Next_Time;

      exit when simulation_stopped;
    end loop;
  end HelloworldTask;

  -- Background procedure required for package
  procedure Background is begin
    while not simulation_stopped loop
      delay 0.25;
    end loop;
  end Background;

end Tasks;
