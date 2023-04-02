%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 2020年度CIT研究用実験プログラム
% ETG-4000(fNIRS計測)とPolymate V(多チャンネル生理反応計測)上に
% 同時にトリガー信号を送るように設計
% 20220415 PC19-3用にスクリーンサイズを修正
% ※デバック後は，「disp_rep」「ISI」の設定を必ず確認すること。
% 

% 
%% version 2 Simon Kuwahara
% StimTrackerコード挿入及び保守性改善のためリファクタリング。
% 
% 環境 laalllaaalalllallallllaaa
%   Ubuntu 22.04.1 LTS
%   MATLAB R2022a update 4
%   UTF-8 LF
%   Psychtoolbox 3 l llllllllllllllllllllllllllll
% **dependencies**
%   MATLAB R2019b or later.
% 
% StimTrackerの出力チャンネルは以下の通り
%   start (USB 0)  = ch1 (0b00000001)
%   end   (USB 1)  = ch2 (0b00000010)
%   stimulus onset = ライトセンサーのソケット番号に依存
%                    例) socket1 = ch8 (0b10000000)
% 
% MATLAB-USB経由のTTLは時間精度が低いので刺激提示には必ずライトセンサーを用いること。
% 変数"dummyMode"はStimTrackerを接続していない状態でテストするためのパラメーター。
% 計測実施時は"dummyMode = false"を必ず確認すること。
% チャンネル対応表及びStimTracker制御のコマンド群はCedrus公式サポートページ参照。
% 関数の説明は"Psychtoolboxのお勉強"内の関連デモコードを参照。
% 
% 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 本番実施前に以下のパラメーターを確認！
% dummyMode  = false;
% switch_dir = 1;
% disp_rep   = 2;
% ISI        = [16 17 18 19 20];
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% version history
% v1.0              K.Niioka    original               
% v2.0  Aug26,2022  S.Kuwahara  StimTracker integration 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


clear all
sca
PsychDefaultSetup(2);

ID = input('参加者番号を入力してください。　例.20200913a\n','s');% 日本語
% ID = input(''Please type subject ID.　 e.g.,20190913a]\n','s');% 英語


%% initial parameters %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
dummyMode = false;
% dummyMode = true; % for testing StimTracker非接続時

% Sync error
oldSync = Screen('Preference', 'SyncTestSettings', 0.002); % 消しても動くなら消すこと

% directory
switch_dir = 1;
% switch_dir = 0; % for testing
if switch_dir==1
    cd('C:\MATLAB\CIT_Program\Experiment');% 本実験プログラムのスクリプトのあるフォルダへ移動
    switch_dir = 0;
end
currDir = cd;

% StimTracker
pulseT    = 1000; % USB経由のTTLトリガーパルスの長さ（ms）
litSenX   = 15;   % ライトセンサー位置X
litSenY   = 15;   % ライトセンサー位置Y
litDiam   = 10;   % 発光範囲直径
litT      = 1.0;  % 発光時間秒  % NB: must be SMALLER than both "stim_presentation" and "wait_fixation" 

% 文字の大きさ
text_size  = 30;
text_size2 = 50;
% Screen('Preference', 'DefaultFontName', 'Noto'); % for testing in Linux

% スクリーン番号
screenNumber = max(Screen('Screens'));

% color
white = WhiteIndex(screenNumber);
black = BlackIndex(screenNumber); 
gray  = (white+black)*200/255;
stim  = black;
back  = gray;

% 注視点
fix_val  = [0,1,0;1,1,1;0,1,0]*(stim-back) + back;
fix_size = 30; % 10

% CIT設定
category_n        = 1;   % 質問対象の種類
item_num          = 5;   % 各質問対象の項目数(個)（1つの裁決質問とN-1の非裁決質問）
disp_rep          = 5;   % 1つの質問の繰り返しの数(回)
stim_presentation = 1.5; % 刺激の呈示時間(sec)
wait_fixation     = 2;   % 注視点の時間(sec)
END_INST          = 30;  % 30
ISI  = [16 17 18 19 20]; % ISIを設定(sec) 行ベクトル内からランダムに設定
%   ISI = [1 2 3 4 5];%デバッグ用

% 教示文　1行ごとに記述
intro1 = double('これから, 本検査を行います。');
intro2 = double('いくつかの質問文が呈示されるので, ');
intro3 = double('全ての質問について、「いいえ」と回答した後に');
intro4 = double('左右いずれかの対応するボタンを押してください。');
intro5 = double('準備ができたらスペースキーを押してください。');

% 呈示する文章　category_nの増加に伴ってquestion2,question3を用意する必要あり
question0 = {'日本の首都は 東京 ですか？';
    '日本の首都は 福岡 ですか？';
    '日本の首都は 仙台 ですか？';
    '日本の首都は 大阪 ですか？';
    '日本の首都は 京都 ですか？'};

question1 = {'あなたは 指輪 を盗みましたか？';
    'あなたは ネックレス を盗みましたか？';
    'あなたは　ブレスレット を盗みましたか？';
    'あなたは ブローチ を盗みましたか？';
    'あなたは ピアス を盗みましたか？'};

% question1 = {'あなたが盗んだのは 指輪 ですか？';
%          'あなたが盗んだのは ネックレス ですか？';
%          'あなたが盗んだのは ブローチ ですか？';
%          'あなたが盗んだのは ブレスレット ですか？';
%          'あなたが盗んだのは ピアス ですか？'};
% question2 = {'あなたは凶器の ナイフ を使いましたか？';
%          'あなたは凶器の アイスピック を使いましたか？';
%          'あなたは凶器の 果物ナイフ を使いましたか？';
%          'あなたは凶器の ハサミ を使いましたか？';
%          'あなたは凶器の 包丁 を使いましたか？'};

% 回答の文章
answer1 = {'はい'}; answer2 = {'いいえ'};


%% StimTracker初期設定 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if dummyMode == false

    % search serial ports
    device_found = 0;
    ports = serialportlist("available");
    
    for p = 1:length(ports)
        device = serialport(ports(p),115200,"Timeout",1);
        device.flush()
        write(device,"_c1","char")
        query_return = read(device,5,"char");

        % Cedrus device detected
        if ~isempty(query_return) && query_return == "_xid0"
            device_found = 1;
            break
        end
    end
    
    % Cedrus device undetected
    if device_found == 0
        disp("No XID device found. Exiting.")
        return % exit script
    end

    % Set pulse duration for "mh" command
    setPulseDuration(device, pulseT);

    % Lower all lines; "mh" 0b00000000
    write(device, [0x6D, 0x68, 0x00, 0x00], "uint8");
end


%% キーボードの設定 set Keyboard %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
enterKey=KbName('return'); spaceKey=KbName('space'); %Small: not ten key
wKey=KbName('w');aKey=KbName('a');sKey=KbName('s');dKey=KbName('d');
fKey=KbName('f');jKey=KbName('j');aKey=KbName('a');lKey=KbName('l');
wKey=KbName('w');aKey=KbName('a');lKey=KbName('l');sKey=KbName('s');
dKey=KbName('d');fKey=KbName('f');jKey=KbName('j');zKey=KbName('z');
xKey=KbName('x');cKey=KbName('c');vKey=KbName('v');bKey=KbName('b');
nKey=KbName('n');mKey=KbName('m');f1Key=KbName('f1');f2Key=KbName('f2');
f3Key=KbName('f3');f4Key=KbName('f4');f5Key=KbName('f5');f6Key=KbName('f6');
f7Key=KbName('f7');f8Key=KbName('f8');f9Key=KbName('f9');f10Key=KbName('f10');
f11Key=KbName('f11');f12Key=KbName('f12');qKey=KbName('q');


try

    %% OpenWindow %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    [expWin, rect] = PsychImaging('OpenWindow', screenNumber, back);    
    
    %% window parameters
    Priority(1);
    ListenChar(2); 
    hz = Screen('NominalFramerate', expWin, 1);
    Screen('BlendFunction', expWin, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    Screen('TextSize', expWin, text_size); % 12             % テキストサイズを設定 
    [cent_x,cent_y] = RectCenter(rect);                     % スクリーンの中心の座標を定義
    [width,height]  = Screen('WindowSize',expWin);
    
    % textures
    fixTexture      = Screen('MakeTexture',expWin,fix_val); % 注視点texture pointer
    bg              = ones(height,width)*back;              % 背景を定義
    bgTexture       = Screen('MakeTexture',expWin,bg);      % background texture pointer
    
    HideCursor;  % 本番ではコメントアウトを解除する
    WaitSecs(0); %【重要】時間精度を出すためにタスク開始前に関数をコンパイルする
    lop_int = 0;
    
    % 刺激の呈示順のランダム化
    [Randomized_Order] = DateRandom4CIT;
    cd('rand')
    csvwrite(['rand-',ID,'.csv'], Randomized_Order); cd('../');
    cd('stimlist')
    stimlist = [Randomized_Order(1,:),Randomized_Order(2,:),Randomized_Order(3,:),Randomized_Order(4,:),Randomized_Order(5,:)];
    csvwrite(['stimlist-',ID,'.csv'], stimlist); cd('../');
    
    % ISIのランダム化
    SEED = str2num(datestr(now,'MMSS'));
    ISI_rand = nan(1,category_n*item_num*disp_rep);
    for isi = 1:1:size(ISI_rand,2)
        for L=1:1:100
            A = Shuffle(1:1:length(ISI));
        end
        ISI_rand(isi) = A(1);
    end
    for i=1:1:SEED
        ISI_rand = Shuffle(ISI_rand);
    end
    cd('ISI')
    csvwrite(['ISI-',ID,'.csv'], ISI(ISI_rand)); cd('../');
    

%% 課題の開始 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    %% 教示文開始
    tic;
    Screen('Drawtext',expWin,intro1,cent_x-500,200, stim); % cent_x-700
    Screen('Drawtext',expWin,intro2,cent_x-500,400, stim);
    Screen('Drawtext',expWin,intro3,cent_x-500,500, stim);
    Screen('Drawtext',expWin,intro4,cent_x-500,600, stim);
    Screen('Drawtext',expWin,intro5,cent_x-500,800, stim);
    Screen('gluDisk', expWin, black, litSenX, litSenY, litDiam); % light sensor Lo
    Screen('Flip',expWin);
    
    while true
        [keyIsDown, secs, keyCode] = KbCheck;
        if keyCode(spaceKey)
            %% 本番 space key
            practice = false;
            question = question1;
            break;
        elseif keyCode(f1Key)
            %% 練習 F1 key
            practice = true;
            question = question0;
            disp_rep = 1;
            break;
        end
    end

    %% start task %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    Screen('DrawTexture',expWin,bgTexture);
    Screen('gluDisk', expWin, black, litSenX, litSenY, litDiam);
    Screen('Flip',expWin);
    tic;
    
    % fixation cross
    Screen('DrawTexture',expWin,fixTexture,[],[cent_x-fix_size,cent_y-fix_size,cent_x+fix_size,cent_y+fix_size],[],[0]);
    Screen('gluDisk', expWin, black, litSenX, litSenY, litDiam);
    Screen('Flip',expWin);

    %% TTL "Start" %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    if dummyMode == false
        write(device,sprintf("mh%c%c", 1, 0), "char"); % USB0(0b00000001)
    end

    WaitSecs(15); % NIRSキャリブレーション
    WaitSecs(20); % band fileter

    Screen('gluDisk', expWin, black, litSenX, litSenY, litDiam); % light sensor Lo
    Screen('Flip',expWin);

    for D = 1:1:disp_rep
        for i=1:item_num

            s_id=Randomized_Order(D,i);
            Q = question(s_id);
            lg_tx = (length(double(cell2mat(Q)))-1)/2;
            dice_a=randi([0,1],1,1);
            rng('shuffle');

            if dice_a==0
                text1=double(cell2mat(answer1));
                text2=double(cell2mat(answer2));
                Dice = 1;
            elseif dice_a==1
                text1=double(cell2mat(answer2));
                text2=double(cell2mat(answer1));
                Dice =0;
            end

            %% stimulus %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            Screen('DrawText',expWin,double(cell2mat(Q)),cent_x-lg_tx*text_size2+100,500, stim);
            Screen('gluDisk', expWin, white, litSenX, litSenY, litDiam); % light sensor Hi
            stimOnT = Screen('Flip',expWin); % stim onset
            img_st  = toc; % mark Aが入力された時間を取得 
           
            Screen('DrawText',expWin,double(cell2mat(Q)),cent_x-lg_tx*text_size2+100,500, stim);
            Screen('gluDisk', expWin, black, litSenX, litSenY, litDiam); % light sensor Lo
            Screen('Flip', expWin, stimOnT+litT-0.5/hz); % litT secs after stimulus onset
            
            Screen('DrawText',expWin,double(cell2mat(Q)),cent_x-lg_tx*text_size2+100,500, stim);
            Screen('DrawText',expWin,text1,cent_x-450,650, stim);
            Screen('DrawText',expWin,text2,cent_x+350,650, stim);
            Screen('gluDisk', expWin, black, litSenX, litSenY, litDiam); % light sensor Lo
            Screen('Flip', expWin, stimOnT+stim_presentation-0.5/hz); % stim_presentation secs after stimulus onset

            %% keypress %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            Screen('DrawText',expWin,double(cell2mat(Q)),cent_x-lg_tx*text_size2+100,500, stim);
            Screen('DrawText',expWin,text1,cent_x-450,650, stim);
            Screen('DrawText',expWin,text2,cent_x+350,650, stim);
            Screen('gluDisk', expWin, white, litSenX, litSenY, litDiam); % light sensor Hi
            
            while true
                [keyIsDown, secs, keyCode] = KbCheck;
                if keyCode(aKey)
                    %% A key
                    press = 0;
                    break;
                elseif keyCode(lKey)
                    %% L key
                    press = 1;
                    break;
                end
            end

            keyPressT = Screen('Flip', expWin); 
            rt_abs=toc;

            if i==1&&lop_int==0
                rt_stor=[s_id, img_st,rt_abs,(rt_abs-img_st-stim_presentation),press,Dice];
                lop_int=1;
            else
                rt_stor=[rt_stor;[s_id, img_st,rt_abs,(rt_abs-img_st-stim_presentation),press,Dice]];
            end

            %% 注視点の呈示 % 20191114追加 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            Screen('DrawTexture',expWin,fixTexture,[],[cent_x-fix_size,cent_y-fix_size,cent_x+fix_size,cent_y+fix_size],[],[0]);
            Screen('gluDisk', expWin, white, litSenX, litSenY, litDiam); % light sensor Hi
            fixOnT = Screen('Flip', expWin); % fixation onset
            
            Screen('DrawTexture',expWin,fixTexture,[],[cent_x-fix_size,cent_y-fix_size,cent_x+fix_size,cent_y+fix_size],[],[0]);
            Screen('gluDisk', expWin, black, litSenX, litSenY, litDiam); % light senso Lo
            Screen('Flip', expWin, keyPressT+litT-0.5/hz);

            waitT = wait_fixation + ISI(ISI_rand(1,(D-1)*item_num+i));
            Screen('gluDisk', expWin, black, litSenX, litSenY, litDiam);
            Screen('Flip', expWin, fixOnT+waitT-0.5/hz);
            
        end % trial loop
    end

    WaitSecs(20);
    Screen('gluDisk', expWin, black, litSenX, litSenY, litDiam);
    Screen('Flip',expWin);

    %% TTL "End" %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    if dummyMode == false
        write(device,sprintf("mh%c%c", 2, 0), "char"); % USB1(0b00000010)
    end

    %% data export %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    cd('RT');
    if practice == true
        csvwrite(['exp_rt-',ID,'-practice.csv'],rt_stor); cd('../'); % 練習
    else
        csvwrite(['exp_rt-',ID,'.csv'],rt_stor); cd('../'); % 本番
    end
    
    Screen('Drawtext',expWin,double('実験者をお呼びください。'),cent_x-lg_tx*text_size,500, stim);
    Screen('gluDisk', expWin, black, litSenX, litSenY, litDiam);
    Screen('Flip',expWin);

    WaitSecs(END_INST);
    
    %% 終了処理 
    cd(currDir);
    ShowCursor;
    ListenChar(0);
    Screen('CloseAll');

catch me
    sca
    ListenChar(0);
    rethrow(me)    
end
sca

%% CedrusXID "mp"コマンドでパルス長さを設定する関数 %%%%%%%%%%%%%%%%%%%%%%%%%%%
% ソースはCedrus公式サイト公開のmatlab_output_sample.m
% https://www.cedrus.com/support/stimtracker/tn1920_other_resources.htm
function byte = getByte(val, index)
    byte = bitand(bitshift(val,-8*(index-1)), 255);
end
function setPulseDuration(device, duration)
    write(device, sprintf("mp%c%c%c%c", getByte(duration,1),...
        getByte(duration,2), getByte(duration,3),...
        getByte(duration,4)), "char")
end