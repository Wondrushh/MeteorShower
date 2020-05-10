%TODO:MeteorShower is an object                      --- DONE
%     Avoid using global variables                   --- DONE
%     Avoid using hold on                            --- DONE
%     Avoid using gca, gcf, use handles instead      --- DONE
%     Avoid using while whenever it is possible
%     Change visibility of text instead of deleting  --- ??

classdef MeteorShowerClass < handle
  
  properties %property zkusit jestli mají podobnou funkci jako glob promenne
    %game settings
    Ylimit = 100; %optimal = 100
    Xlimit = 10; %optimal = 10
    fps (1,1) double = 25; %optimal = 15
    musicVolume (1,1) double = 5;
    sfxVolume (1,1) double = 50;
    
    %controls "dictionary"
    keys = {'w','a','s','d','space','escape'};
    keyStatus = false(1,6);
    
    up = 1;
    left = 2;
    down = 3;
    right = 4;
    space = 5;
    escape = 6;
  end
  
  methods
    function this = MeteorShowerClass()
      %Parameters to change
      asteroidSpawnRate = 30*2; %after how many frames does next asteroid spawn
      finalAsteroidSpawnRate = 5*2; %biggest cadency of asteroids
      intervalDecrease = 0.5*2; %how fast the game gets harder
      
      laserCooldownTime = this.fps/5; %speed of shooting
      laserCooldown = laserCooldownTime;
      movementCooldownTime = ceil(this.fps/15); %speed of the ship
      movementCooldown = movementCooldownTime;
      
      %explosion sfx
      [explosionSound, explosionRate] = audioread('explosion.wav');
      explosionSfx = audioplayer((explosionSound*7)/(this.sfxVolume/100), explosionRate);
      
      %laser sfx
      [laserSound, laserRate] = audioread('sfx_sounds_damage2.wav');
      laserSfx = audioplayer(laserSound*(this.sfxVolume/100), laserRate);
      
      %death sound sfx
      [deathSound, deathRate] = audioread('death_sound.wav');
      deathSfx = audioplayer(deathSound*(this.sfxVolume/100), deathRate);
      
      %soundtrack
      [BockeyMouseAudio, BockeyMouseRate] = audioread('soundtrack.wav');
      soundtrack = audioplayer(BockeyMouseAudio*(this.musicVolume/100), BockeyMouseRate);
      play(soundtrack);
      
      %initialize the objects, score and game over flag
      laserObj(1) = laser;
      asteroidObj(1) = asteroid;
      ship = starship;
      ship.posx = this.Xlimit/2;
      ship.posy = this.Ylimit/10;
      ship.step = this.Xlimit/10;
      score = 0;
      gameOver = 0;
      frames = 0;
      
      %settings for the figure window
      game = figure('KeyPressFcn',{@this.KeySniffFcn},...
        'KeyReleaseFcn',{@this.KeyRelFcn},...
        'CloseRequestFcn',{@this.QuitFcn},...
        'Units', 'normalized',...
        'outerposition', [0 0 1 1],...
        'menubar', 'none',...
        'NumberTitle', 'off',...
        'WindowState', 'maximized');
      
      %Makes the axes disappear
      ax = axes(game);
      ax.XLim = [0, this.Xlimit];
      ax.YLim = [0, this.Ylimit];
      ax.Color = 'k';
      ax.XTick = [];
      ax.YTick = [];
      
      hold(ax,'on');
      
      spawn(ship);
      introText = text(this.Xlimit/2, this.Ylimit/2, 'WELCOME! PRESS SPACE TO START PLAYING...', 'HorizontalAlignment', 'center', 'Color', [1 1 1],'FontWeight', 'bold', 'FontName', 'Monospaced');
      scoreText = text();
      drawnow()
      % intro screen
      buttonPressed = 0;
      while buttonPressed ~= 1
        if this.keyStatus(this.space)
          delete(introText);
          buttonPressed = 1;
        end
        if ~ishghandle(game)
          break
        end
        pause(0.01);
      end
      % main game
      while gameOver ~= 1
        i = 2;
        j = 2;
        %if the figure is closed during the game, the script stops
        if ~ishghandle(game)
          break
        end
        frames = frames + 1;
        tic;
        %cooldown of movement
        if movementCooldown < movementCooldownTime
          movementCooldown = movementCooldown + 1;
        else
          %defining the actions of keystrokes
          if this.keyStatus(this.left) && (ship.posx - ship.step)>0
            moveLeft(ship);
            movementCooldown = 1;
          end
          if this.keyStatus(this.right) && (ship.posx + ship.step)<this.Xlimit
            moveRight(ship);
            movementCooldown = 1;
          end
          %quit the game when pressing escape
          if this.keyStatus(this.escape)
            close all
            return
          end
        end
        %cooldown of shooting lasers
        if laserCooldown < laserCooldownTime
          laserCooldown = laserCooldown + 1;
        else
          if this.keyStatus(this.space)
            play(laserSfx);
            laserObj(end+1) = laser;
            laserObj(end).posx = ship.posx;
            laserObj(end).posy = ship.posy;
            spawn(laserObj(end));
            laserCooldown = 1;
          end
        end
        %quit the game when Escape is pressed
        if this.keyStatus(this.escape)
          close all
        end
        %spawn enemies
        if mod(frames,asteroidSpawnRate) == 0
          %asteroidCount = asteroidCount + 1;
          asteroidObj(end+1) = asteroid;
          asteroidObj(end).posx = 2+ceil(rand(1,1)*7);
          asteroidObj(end).posy = this.Ylimit-(1/10)*this.Ylimit;
          spawn(asteroidObj(end));
          if asteroidSpawnRate > finalAsteroidSpawnRate
            asteroidSpawnRate = asteroidSpawnRate - intervalDecrease;
          end
        end
        
        %moves lasers and delete faraway lasers
        if exist('laserObj')
          while i <= numel(laserObj)
            if laserObj(i).posy > this.Ylimit*0.9
              delete(laserObj(i).body);
              if i ~= numel(laserObj)
                for j = i+1:numel(laserObj)
                  laserObj(j-1) = laserObj(j);
                end
              end
              laserObj = laserObj(1:end-1);
              continue
            end
            move(laserObj(i));
            i = i + 1;
          end
        end
        %moves asteroids and checks if you lost
        i = 2;
        if exist('asteroidObj')
          while i <= numel(asteroidObj)
            if asteroidObj(i).posy < ship.posy + 2 % the 2 is correction
              play(deathSfx);
              delete(asteroidObj(i).body);
              clear asteroidObj(i);
              gameOver = 1;
              for j = i+1:numel(asteroidObj)
                asteroidObj(j-1) = asteroidObj(j);
              end
              asteroidObj = asteroidObj(1:end-1);
              continue
            end
            move(asteroidObj(i))
            i = i + 1;
          end
        end
        
        %checking collision
        i = 1;
        j = 1;
        while j <= numel(asteroidObj)
          while i <= numel(laserObj)
            if ((abs(asteroidObj(j).posy - laserObj(i).posy)) < 7) & (laserObj(i).posx == asteroidObj(j).posx)
              %increase score and delete hit objects
              play(explosionSfx);
              score = score + 10;
              delete(scoreText);
              scoreText = text(this.Xlimit*0.1, this.Ylimit*0.9,...
                sprintf('SCORE: %d', score),...
                'FontWeight', 'bold',...
                'FontName', 'Monospaced',...
                'Color', [1 1 1]);
              delete(laserObj(i).body);
              delete(asteroidObj(j).body);
              if i ~= numel(laserObj)
                for k = i+1:numel(laserObj)
                  laserObj(k-1) = laserObj(k);
                end
              end
              laserObj = laserObj(1:end-1);
              if j ~= numel(asteroidObj)
                for l = j+1:numel(asteroidObj)
                  asteroidObj(l-1) = asteroidObj(l);
                end
              end
              asteroidObj = asteroidObj(1:end-1);
              i = 1;
              j = 1;
            end
            i = i+1;
          end
          i = 1;
          j = j+1;
        end
        %fps correction
        elapsedFrameTime = toc;
        if elapsedFrameTime<(1/this.fps)
          pause((1/this.fps)-elapsedFrameTime)
        end
        drawnow()
      end
      
      if ishghandle(game)
        pause(soundtrack);
        gameOverText = text((this.Xlimit/2), (this.Ylimit/2), {sprintf('GAME OVER! YOUR SCORE IS %d.', score),'PRESS ESCAPE TO QUIT'}, 'HorizontalAlignment', 'center','FontName','Monospaced', 'Color', [1 1 1], 'FontWeight', 'bold');
        buttonPressed = 0;
        pause(1);
        while buttonPressed ~= 1
          if this.keyStatus(this.escape)
            buttonPressed = 1;
            close all
            return
          end
          pause(0.01);
        end
      end
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

