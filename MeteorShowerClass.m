%TODO:Use TIMER
%           - change all the variables and objects to properties - done
%           - create timer in constructor - done
%           - laser stops moving - DONE
%     Avoid using while whenever it is possible
%     Change visibility of text instead of deleting  --- ??
%     Move constants to properties - DONE


classdef MeteorShowerClass < handle
  
  properties (Access = public)
    %game settings
    fps (1,1) double = 25; %optimal = 25
    musicVolume (1,1) double = 5;
    sfxVolume (1,1) double = 50;
    
    %essential variables
    gamePhase = 1;
    introText = [];
    scoreText = [];
    laserCooldownTime = 0;
    laserCooldown = 0;
    movementCooldownTime = 0;
    movementCooldown = 0;
    
    explosionSound = 0;
    explosionRate = 0;
    laserSound = 0;
    laserRate = 0;
    deathSound = 0;
    deathRate = 0;
    BockeyMouseAudio = 0;
    BockeyMouseRate = 0;
    explosionSfx = 0;
    laserSfx = 0;
    deathSfx = 0;
    soundtrack = 0;
    
    laserObj = laser;
    asteroidObj = asteroid;
    ship = starship;
    score = 0;
    frames = 0;
    
    game = [];
    
    i = 0
    j = 0
  end
  
  properties (Access = private)
    
    asteroidSpawnRate = 60; %after how many frames does next asteroid spawn
    finalAsteroidSpawnRate = 10; %biggest cadency of asteroids
    intervalDecrease = 1; %how fast the game gets harder
    
    %controls "dictionary"
    keys = {'w','a','s','d','space','escape'};
    keyStatus = false(1,6);
    
    up = 1;
    left = 2;
    down = 3;
    right = 4;
    space = 5;
    escape = 6;
    
    Ylimit = 100; %optimal = 100
    Xlimit = 10; %optimal = 10
  end
  
  methods
    function this = MeteorShowerClass()
      gameTimer = timer;
      gameTimer.StartFcn = @this.introFcn;
      gameTimer.TimerFcn = @this.gameFcn;
      gameTimer.StopFcn = @this.endFcn;
      gameTimer.Period = 1/this.fps;
      gameTimer.ExecutionMode = 'fixedRate';
      
      start(gameTimer);
    end
    
    %functions for timer
    function introFcn(this,src,event)
      %Parameters to change
      this.laserCooldownTime = this.fps/5; %speed of shooting
      this.laserCooldown = this.laserCooldownTime;
      this.movementCooldownTime = ceil(this.fps/15); %speed of the ship
      this.movementCooldown = this.movementCooldownTime;
      
      %explosion sfx
      [this.explosionSound, this.explosionRate] = audioread('explosion.wav');
      this.explosionSfx = audioplayer((this.explosionSound*7)/(this.sfxVolume/100), this.explosionRate);
      
      %laser sfx
      [this.laserSound, this.laserRate] = audioread('sfx_sounds_damage2.wav');
      this.laserSfx = audioplayer(this.laserSound*(this.sfxVolume/100), this.laserRate);
      
      %death sound sfx
      [this.deathSound, this.deathRate] = audioread('death_sound.wav');
      this.deathSfx = audioplayer(this.deathSound*(this.sfxVolume/100), this.deathRate);
      
      %soundtrack
      [this.BockeyMouseAudio, this.BockeyMouseRate] = audioread('soundtrack.wav');
      this.soundtrack = audioplayer(this.BockeyMouseAudio*(this.musicVolume/100), this.BockeyMouseRate);
      %play(this.soundtrack);
      
      %initialize the objects, score and game over flag
      this.laserObj(1) = laser;
      this.asteroidObj(1) = asteroid;
      this.ship = starship;
      this.ship.posx = this.Xlimit/2;
      this.ship.posy = this.Ylimit/10;
      this.ship.step = this.Xlimit/10;
      this.score = 0;
      this.frames = 0;
      
      %settings for the figure window
      this.game = figure('KeyPressFcn',{@this.KeySniffFcn},...
        'KeyReleaseFcn',{@this.KeyRelFcn},...
        'CloseRequestFcn',{@this.QuitFcn},...
        'Units', 'normalized',...
        'outerposition', [0 0 1 1],...
        'menubar', 'none',...
        'NumberTitle', 'off',...
        'WindowState', 'maximized');
      
      %Makes the axes disappear
      ax = axes(this.game);
      ax.XLim = [0, this.Xlimit];
      ax.YLim = [0, this.Ylimit];
      ax.Color = 'k';
      ax.XTick = [];
      ax.YTick = [];
      hold(ax,'on');
      
      % draws ship and welcome screen
      spawn(this.ship);
      this.introText = text(this.Xlimit/2, this.Ylimit/2, 'WELCOME! PRESS SPACE TO START PLAYING...', 'HorizontalAlignment', 'center', 'Color', [1 1 1],'FontWeight', 'bold', 'FontName', 'Monospaced');
      this.scoreText = text();
    end
    
    function gameFcn(this,~,~)
      switch this.gamePhase
        case 1
          % intro screen
          if this.keyStatus(this.space)
            delete(this.introText);
            this.gamePhase = 2;
          elseif this.keyStatus(this.escape) % ends the game when esc is pressed
            this.gamePhase = 5;
          end
          if ~ishghandle(this.game)
            this.gamePhase = 5;
          end
          pause(0.01);
          
        case 2
          % main game
          
          this.i = 2;
          this.j = 2;
          %if the figure is closed during the game, the script stops
          if ~ishghandle(this.game)
            this.gamePhase = 5;
          end
          this.frames = this.frames + 1;
          %cooldown of movement
          if this.movementCooldown < this.movementCooldownTime
            this.movementCooldown = this.movementCooldown + 1;
          else
            %defining the actions of keystrokes
            if this.keyStatus(this.left) && (this.ship.posx - this.ship.step)>0
              moveLeft(this.ship);
              this.movementCooldown = 1;
            end
            if this.keyStatus(this.right) && (this.ship.posx + this.ship.step)<this.Xlimit
              moveRight(this.ship);
              this.movementCooldown = 1;
            end
            %quit the game when pressing escape
            if this.keyStatus(this.escape)
              close all
              return
            end
          end
          %cooldown of shooting lasers
          if this.laserCooldown < this.laserCooldownTime
            this.laserCooldown = this.laserCooldown + 1;
          else
            if this.keyStatus(this.space)
              play(this.laserSfx);
              this.laserObj(end+1) = laser;
              this.laserObj(end).posx = this.ship.posx;
              this.laserObj(end).posy = this.ship.posy;
              spawn(this.laserObj(end));
              this.laserCooldown = 1;
            end
          end
          %quit the game when Escape is pressed
          if this.keyStatus(this.escape)
            close all
          end
          %spawn enemies
          if mod(this.frames,this.asteroidSpawnRate) == 0
            %asteroidCount = asteroidCount + 1;
            this.asteroidObj(end+1) = asteroid;
            this.asteroidObj(end).posx = 2+ceil(rand(1,1)*7);
            this.asteroidObj(end).posy = this.Ylimit-(1/10)*this.Ylimit;
            spawn(this.asteroidObj(end));
            if this.asteroidSpawnRate > this.finalAsteroidSpawnRate
              this.asteroidSpawnRate = this.asteroidSpawnRate - this.intervalDecrease;
            end
          end
          
          %moves lasers and delete faraway lasers
            while this.i <= numel(this.laserObj)
              if this.laserObj(this.i).posy > this.Ylimit*0.9
                delete(this.laserObj(this.i).body);
                if this.i ~= numel(this.laserObj)
                 for j = this.i+1:numel(this.laserObj)
                    this.j = j;
                    this.laserObj(this.j-1) = this.laserObj(this.j);
                  end
                end
                this.laserObj = this.laserObj(1:end-1);
                continue
              end
              move(this.laserObj(this.i));
              this.i = this.i + 1;
            end
          %moves asteroids and checks if you lost
          this.i = 2;
          this.j = 2;
          
            while this.i <= numel(this.asteroidObj)
              if this.asteroidObj(this.i).posy < this.ship.posy + 2 % the 2 is correction
                play(this.deathSfx);
                delete(this.asteroidObj(this.i).body);
                clear this.asteroidObj(i);
                this.gamePhase = 3;
                for j = this.i+1:numel(this.asteroidObj)
                  this.j = j;
                  this.asteroidObj(this.j-1) = this.asteroidObj(this.j);
                end
                this.asteroidObj = this.asteroidObj(1:end-1);
                continue
              end
              move(this.asteroidObj(this.i))
              this.i = this.i + 1;
            end
          
          %checking collision
          this.i = 1;
          this.j = 1;
          while this.j <= numel(this.asteroidObj)
            while this.i <= numel(this.laserObj)
              if ((abs(this.asteroidObj(this.j).posy - this.laserObj(this.i).posy)) < 7) & (this.laserObj(this.i).posx == this.asteroidObj(this.j).posx)
                %increase score and delete hit objects
                play(this.explosionSfx);
                this.score = this.score + 10;
                delete(this.scoreText);
                this.scoreText = text(this.Xlimit*0.1, this.Ylimit*0.9,...
                  sprintf('SCORE: %d', this.score),...
                  'FontWeight', 'bold',...
                  'FontName', 'Monospaced',...
                  'Color', [1 1 1]);
                delete(this.laserObj(this.i).body);
                delete(this.asteroidObj(this.j).body);
                if this.i ~= numel(this.laserObj)
                  for k = this.i+1:numel(this.laserObj)
                    this.laserObj(k-1) = this.laserObj(k);
                  end
                end
                this.laserObj = this.laserObj(1:end-1);
                if this.j ~= numel(this.asteroidObj)
                  for l = this.j+1:numel(this.asteroidObj)
                    this.asteroidObj(l-1) = this.asteroidObj(l);
                  end
                end
                this.asteroidObj = this.asteroidObj(1:end-1);
                this.i = 1;
                this.j = 1;
              end
              this.i = this.i+1;
            end
            this.i = 1;
            this.j = this.j+1;
          end
          %fps correction
          
          %drawnow()
          
        case 3
          pause(this.soundtrack);
          gameOverText = text((this.Xlimit/2), (this.Ylimit/2), {sprintf('GAME OVER! YOUR SCORE IS %d.', this.score),'PRESS ESCAPE TO QUIT'}, 'HorizontalAlignment', 'center','FontName','Monospaced', 'Color', [1 1 1], 'FontWeight', 'bold');
          pause(1);
          this.gamePhase = 4;
          
        case 4
          if this.keyStatus(this.escape)
            listOfTimers = timerfindall;
            stop(listOfTimers);
            close all
            return
          end
          pause(0.01);
        case 5
          listOfTimers = timerfindall;
          stop(listOfTimers);
          close all
          return
      end
    end
    
    function endFcn(this,src,event)
      listOfTimers = timerfindall;
      delete(listOfTimers);
    end
    
    function errorFunction(this,src,event)
      disp('Error occured');
    end
    %functions for reading key strokes
    function KeySniffFcn(this,src,event)
      key = event.Key;
      this.keyStatus = (strcmp(key, this.keys) | this.keyStatus);
    end
    function KeyRelFcn(this,src,event)
      key = event.Key;
      this.keyStatus = (~strcmp(key, this.keys) & this.keyStatus);
    end
    
    %quitting function callback
    function QuitFcn(this,src,event)
      delete(src);
    end    
  end
end

