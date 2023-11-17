%% demo for StimTracker TTL Trigger input
% @author: Simon Kuwahara
% MATLAB R2022a
% Ubuntu 22.04
% UTF-8
% Dell S2319HS 1920*1080 60Hz
% -------------------------------------------------------------------------
% v0.0 Aug.17,2022 SK Based on Psychtoolbox_demo_Japanese/demo_StimTracker.m
% v1.0 Mar.16,2023 SK English translation/revision for multimodal-psych
% -------------------------------------------------------------------------
% 
% This script is a basic demo of synchronization using the Cedrus StimTracker 
% and Psychtoolbox3. 
% 
% Information in this script might be old and inaccurate for future readers.
% Please make it a habbit to check the original sources and if you find any
% inaccurate information, we would appreciate if you could let us know or 
% even better, send a pull request.
% 
% **dependencies**
% MATLAB R2019b or later.
% Requires Psychtoolbox 3.
% 
% **references**
% Please refer to the official documents from Cedrus, Psychtoolbox and MATLAB.
% 
% matlab_output_sample.m : from Cedrus's official support page.
% https://www.cedrus.com/support/stimtracker/tn1920_other_resources.htm
% 
% Also, check out the list of XID commands on Cedrus's official support page.
% https://www.cedrus.com/support/xid/commands.htm
% 
% 
%% Overview of StimTracker control via MATLAB
% 
% 
% In this demo script, we will look into two of the many functions of the 
% StimTracker.
% - Sending TTL triggers by detecting light emittion by the monitor.
% - Sending TTL triggers via USB via MATLAB command.
% 
% Though these two functionalities are used together in this demo script,
% keep in mind that these two function completely differently and could be 
% used independently. 
% 
% TTL output is taken from the DIN connector on the backside of the StimTracker.
% The StimTracker is a 5V system. Be careful when mixing with 3.3V systems.
% - Lo:0V
% - Hi:+5V
% 
% 
% There are many other functions that are NOT explained in this demo script.
% - Inputs by external response pads/devices.
% - Signal passthrough from external devices.
% - Converting sensor inputs to ASCII string with timestamp via USB.
% See Cedrus's support page for more information.
% 
% 
%% TTL trigger via the light sensor
% 
% Light sensors are completely passive.
% When the light sensor detects light, it sends out a TTL signal.
% Place the light sensor on the display and use PTB to control the color lit
% underneath the light sensor; white is Hi/black is Lo.
% 
% Pre-measurement testing with the actual hardware is mandatory.
% - software: Adjust position parameters light sensor.
% - hardware: Adjust sensitivity of light sensor using the controls on the
% front panel on the StimTracker.
% See Cedrus's supprot page for details.
% https://www.cedrus.com/support/stimtracker/tn1906_using_st.htm
% https://www.cedrus.com/support/stimtracker/tn1908_onset_visual.htm
% 
% Always check if the light sensor is plugged in the correct jack.
% See Cedrus's supprot page for pin-out.
% https://www.cedrus.com/support/stimtracker/tn1960_quad_ttl_output.htm
% 
% 
%% TTL trigger via USB
% 
% USB drivers
% - Linux:   Integrated in kernel.
% - Windows: Windows Update will usually grab it. If it fails, install it
% manually from:
% https://ftdichip.com/drivers/vcp-drivers/
% 
% NOTE: Running PTB on Windows10/11 (or later) is a bad idea unless you 
% really know what you're doing. If in doubt, go Linux.
% 
% StimTracker uses RS-232C aka serial through USB.
% If you're new to serial, google "RS-232C". It's a widely used protocol in
% industrial equipment, servers/switches/routers, and many more.
% StimTracker is controlled by sending ASCII strings in little-endian.
% 
% Use the "serialport" function. Run:
% help serialport
% https://www.mathworks.com/help/matlab/serial-port-devices.html
% The "serial" function is deprecated. Do NOT use it.
% 
% When using RS-232C, you will often send command strings in ASCII.
% If you're new, try familiarizing yourself in converting ASCII characters 
% to hexadecimal or binary.
% Commands used in RS-232C are predefined differently for each device.
% Cedrus devices use the command "XID Version2".
% Official documentation:
% https://www.cedrus.com/support/xid/commands.htm
% 
% **IMPORTANT**
% Sending TTL using RS-232C from MATLAB will have latency.
% MATLAB: 5-6ms
% C++:    2-3ms
% If timing is important, always use the light sensor or at least parallel port.
% If you need to use RS-232C with accurate timing, write a mex function from C++. 
% 
% 
%% contents of this demo
% 
% This demo is written for dell S2319HS(23'、1920*1080、60Hz) with a light
% sensor attached to the top left corner.
% Adjust parameters for your environment.
% 
% This demo assumes that the light sensor is conncted to jack #1 of the Stim Tracker.
% From the pin out table on Cedrus's official support page, we know jack #1 outputs TTL to channel 8.
% https://www.cedrus.com/support/stimtracker/tn1960_quad_ttl_output.htm
% 
% In order to lower the risk of human error, we recomend not sharing the 
% channel for the light sensor(in this case ch.8) with the channles for 
% the USB input.
% 
% In this demo, we will use the following 4 channels.
% USB bit0 :       channel 1
% USB bit1 :       channel 2
% USB bit2 :       channel 3
% Light Sensor 1 : channel 8
% 
% 
% overall flow
% 
% {START}
% 
% Search serial port and locate Stim Tracker.
% 
% Set TTL pulse duration to 1 sec.
% 
% Set up PTB and openwindow.
% 
% TTL ch.1(USB0) 1s
% 
% for 3 iterations 
%   fixation cross 2s
% 
%   text stimuli 5s
%   TTL ch.8(light) 2s
%   TTL ch.2(USB1)  1s
% 
%   isi 0.5s
% end
% 
% TTL ch.3(USB2) 1s
% 
% {END}
% 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clear all
clear device
commandwindow
homeDir = fileparts(mfilename('fullpath'));
sca
GetSecs(0);
PsychDefaultSetup(2);
% Screen('Preference', 'SyncTestSettings', 0.002); % uncommnet only when noisy


%% detect StimTracker and open serial port %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Search serial port and identify StimTracker, then do initial setup.

% parameters
deviceFound = 0;
ports = serialportlist("available");

% search serial ports
for p = 1:length(ports)

    device = serialport(ports(p),115200,"Timeout",1);
    % create serial port object
    % defaul boudrate for Cedrus devices: 115k
    % Caution when mixing devices with different boudrate
    
    device.flush()
    % clear I/O buffer
    
    write(device,"_c1","char")
    queryReturn = read(device,5,"char");
    % if you send the text "_c1"(in char array) to a Cedrus device via sereal, it will respond 
    %  by sending a text such as "_xid0"
    % This response text is in the format:
    % "_xid" + "number that indicates the mode"
    % 
    % StimTracker only has XID mode so the response text will always be "_xid0"
    % Some Cedrus devices have other modes so be aware.
    
    % Cedrus device detected
    if ~isempty(queryReturn) && queryReturn == "_xid0"
        deviceFound = 1;
        break
    end
end

% Cedrus devices not detected
if deviceFound == 0
    disp("No XID device found. Exiting.")
    return % exit script
end

%% Initial setup： set TTL duration for using "mp" command via USB
% 
% In the experiment, we will use the "mh" command to send a TTL trigger
% from a specified channel.
% We will need to predefine the TTL trigger duration (the length of time that
% the line is "Hi" for each call of the "mh" command) using the "mp" command.
% In this demo, we will set the defaul TTL duration to 1000ms.
% 
% We send the string: "mp" + "duration in 4byte number"
% 
% duration in 4byte number: pulse duration in ms、default=0(unlimited)
% 
% NOTE: byte order is little endian
% 
% example: duration = 1000ms
% 
%  m    p            1000
% 0x6D 0x70   0xE8 0x03 0x00 0x00   <- hex
% 109  112    232   3    0    0     <- ASCII
% 
write(device, [0x6D, 0x70, 0xE8, 0x03, 0x00, 0x00], "uint8"); % input by hex 
% write(device, sprintf("mp%c%c%c%c", 232, 3, 0, 0), "char"); % alternate input by ASCII


%% Sending TTL trigger using the "mh" command via USB
% 
% We send the TTL trigger using the "mh" command.
% As stated above, TTL trigger will end after the duration length preset by
% the "mp" command.
% 
% We send the string: "mh" + "channels in 2bytes"
% 
% channels in 2 bytes: For each of the 8 TTL channels, set each digit 1=Hi/0=Lo.
% StimTracker only has 8 channels so we ignore the first 8 of the 16 digits.
% 
% NOTE: byte order is little endian;
% set digits in order of: ch8,ch7,...,ch2,ch1,0,0,0,0,0,0,0,0
% 
% example: send TTL only on ch.1,2,3(USB0,1,2)
% 
%  m    h    0b00000111 0b00000000
% 0x6D 0x68     0x07       0x00     <- hex
% 109  104       7          0       <- ASCII
% 
% write(device, [0x6D, 0x68, 0xE0, 0x00], "uint8");    % input by hex
% write(device, [0x6d, 0x68, 0b00000111, 0], "uint8"); % input by hex & binary
% write(device, sprintf("mh%c%c", 7, 0), "char");      % input by ASCII

% It's a good habit to initialize by lowering all lines
write(device, [0x6D, 0x68, 0x00, 0x00], "uint8"); % lower all lines


%% PTB Parameters %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
scr   = max(Screen('Screens'));
bkClr = BlackIndex(scr);
whClr = WhiteIndex(scr);

% light sensor parameters Set these parameters appropriately to your monitor.
litSenX = 15;  %light sensor position X in px
litSenY = 15;  %light sensor position Y in px
litDiam = 10;  %light sensor diameter   in px
litT    = 2.0; %light-on     duration   in sec

% task parameters
bgClr   = (bkClr+whClr)/2; % bg:background
fixClr  = bkClr;
stimClr = bkClr;
swchT   = 0.5;
fixT    = 2.0;
stimT   = 5.0;
stimTxt = 'STIM ON';

% fixation cross
fixMat = [0,1,0; 1,1,1; 0,1,0]*fixClr + [1,0,1; 0,0,0; 1,0,1]*bgClr;                           
fixSz  = 30;

try

    %% open window %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    
    [wptr, wRect] = PsychImaging('OpenWindow', scr, bgClr);

    % initial settings
    Priority(1);
    hz = Screen('NominalFrameRate', wptr, 1);
    Screen('BlendFunction', wptr, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    [xCntr, yCntr] = RectCenter(wRect);
    
    % fixation cross
    fixPos = [xCntr-fixSz, yCntr-fixSz, xCntr+fixSz, yCntr+fixSz];
    fixTex = Screen('MakeTexture', wptr, fixMat);
    
    HideCursor;


    %% Start Task %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  

    Screen('gluDisk', wptr, bkClr, litSenX, litSenY, litDiam); %light sensor(ch8) Lo
    % Always draw black or white under the light sensor for all the frames.
    % Using the 'gluDisk' function with the parameters set above is easy.
    flipT = Screen('Flip', wptr);
    write(device, [0x6d, 0x68, 0b00000001, 0], "uint8"); %USB0(ch1)
    
    for i = 1:3
    
        % display fixation cross
        Screen('gluDisk', wptr, bkClr, litSenX, litSenY, litDiam); %light sensor(ch8) Lo
        Screen('DrawTexture', wptr, fixTex, [], fixPos, [],0); %fixation cross
        flipT = Screen('Flip', wptr, flipT+swchT-0.5/hz);
        
        % start stim presentation
        Screen('gluDisk', wptr, whClr, litSenX, litSenY, litDiam); %light sensor(ch8) Hi
        DrawFormattedText(wptr, stimTxt, 'center', 'center', stimClr); %visual stimulus
        stimStartT = Screen('Flip', wptr, flipT+fixT-0.5/hz);
        write(device, [0x6d, 0x68, 0b00000010, 0], "uint8"); %USB1(ch2)

        % if litT < stimT , turn off the light sensor after litT seconds, keeping everything else as the same
        Screen('gluDisk', wptr, bkClr, litSenX, litSenY, litDiam); %light sensor(ch8) Lo
        DrawFormattedText(wptr, stimTxt, 'center', 'center', stimClr); %render so it looks the same
        flipT = Screen('Flip', wptr, flipT+litT-0.5/hz);

        % end stim presentation
        Screen('gluDisk', wptr, bkClr, litSenX, litSenY, litDiam); %light sensor(ch8) Lo
        flipT = Screen('Flip', wptr, stimStartT+stimT-0.5/hz);
    
    end
    write(device, [0x6d, 0x68, 0b00000100, 0], "uint8"); %USB2(ch3)
    WaitSecs(2); % If calling WaitSecs(), call GetSecs(0) in advance for time accuracy.
    sca

catch me    
    sca
    ListenChar(0);
    rethrow(me)

end
sca
clear device