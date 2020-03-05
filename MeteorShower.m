%TODO: 

function MeteorShower()
%Parameters to change
Ylimit = 100; %optimal = 100 
Xlimit = 10; %optimal = 10
fps = 25; %optimal = 15
musicVolume = 30;
sfxVolume = 100;

asteroidSpawnRate = 30*2; %after how many frames does next asteroid spawn
finalAsteroidSpawnRate = 5*2; %biggest cadency of asteroids
intervalDecrease = 0.5*2; %how fast the game gets harder

laserCooldownTime = fps/5; %speed of shooting
laserCooldown = laserCooldownTime;
movementCooldownTime = ceil(fps/15); %speed of the ship
movementCooldown = movementCooldownTime;

%explosion sfx
[explosionSound, explosionRate] = audioread('explosion.wav');
explosionSfx = audioplayer((explosionSound*7)/(sfxVolume/100), explosionRate);

%laser sfx
[laserSound, laserRate] = audioread('sfx_sounds_damage2.wav');
laserSfx = audioplayer(laserSound*(sfxVolume/100), laserRate);

%death sound sfx
[deathSound, deathRate] = audioread('death_sound.wav');
deathSfx = audioplayer(deathSound*(sfxVolume/100), deathRate);

%soundtrack
[BockeyMouseAudio, BockeyMouseRate] = audioread('soundtrack.wav');
soundtrack = audioplayer(BockeyMouseAudio*(musicVolume/100), BockeyMouseRate);
play(soundtrack);

%initialize the objects, score and game over flag
laserObj(1) = laser;
asteroidObj(1) = asteroid;
ship = starship;
ship.posx = Xlimit/2;
ship.posy = Ylimit/10;
ship.step = Xlimit/10;
score = 0;
gameOver = 0;
frames = 0;

%controls "dictionary"
keys = {'w','a','s','d','space','escape'};
keyStatus = false(1,numel(keys));

KEY.up = 1;
KEY.left = 2;
KEY.down = 3;
KEY.right = 4;
KEY.space = 5;
KEY.escape = 6;

%settings for the figure window
game = figure('KeyPressFcn',{@KeySniffFcn},...
              'KeyReleaseFcn',{@KeyRelFcn},...
              'CloseRequestFcn',{@QuitFcn},...
              'Units', 'normalized',...
              'outerposition', [0 0 1 1],...
              'menubar', 'none',...
              'NumberTitle', 'off');
axis([0,Xlimit,0,Ylimit])

%Makes the axes disappear
set(gca,'xtick',[],'ytick',[],'xcolor', [1 1 1],'ycolor', [1 1 1], 'Color', 'k');
set(gcf, 'WindowState', 'maximized');

hold on
spawn(ship);
introText = text(Xlimit/2, Ylimit/2, 'WELCOME! PRESS SPACE TO START PLAYING...', 'HorizontalAlignment', 'center', 'Color', [1 1 1],'FontWeight', 'bold', 'FontName', 'Monospaced');
scoreText = text();
drawnow()
% intro screen
buttonPressed = 0;
while buttonPressed ~= 1
  if keyStatus(KEY.space)
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
    if keyStatus(KEY.left) && (ship.posx - ship.step)>0
      moveLeft(ship);
      movementCooldown = 1;
    end
    if keyStatus(KEY.right) && (ship.posx + ship.step)<Xlimit
      moveRight(ship);
      movementCooldown = 1;
    end
    %quit the game when pressing escape
    if keyStatus(KEY.escape)
      close all
      return
    end
  end
  %cooldown of shooting lasers
  if laserCooldown < laserCooldownTime
    laserCooldown = laserCooldown + 1;
  else
    if keyStatus(KEY.space)
      play(laserSfx);
      laserObj(end+1) = laser;
      laserObj(end).posx = ship.posx;
      laserObj(end).posy = ship.posy;
      spawn(laserObj(end));
      laserCooldown = 1;
    end
  end
  %quit the game when Escape is pressed
  if keyStatus(KEY.escape)
      close all
  end
  %spawn enemies
  if mod(frames,asteroidSpawnRate) == 0
    %asteroidCount = asteroidCount + 1;
    asteroidObj(end+1) = asteroid;
    asteroidObj(end).posx = 2+ceil(rand(1,1)*7);
    asteroidObj(end).posy = Ylimit-(1/10)*Ylimit;
    spawn(asteroidObj(end));
    if asteroidSpawnRate > finalAsteroidSpawnRate
      asteroidSpawnRate = asteroidSpawnRate - intervalDecrease;
    end
  end
  
  %moves lasers and delete faraway lasers
  if exist('laserObj')
    while i <= numel(laserObj)
      if laserObj(i).posy > Ylimit*0.9
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
          scoreText = text(Xlimit*0.1, Ylimit*0.9,...
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
    if elapsedFrameTime<(1/fps)
      pause((1/fps)-elapsedFrameTime)
    end
  drawnow()
end

if ishghandle(game)
  pause(soundtrack);
  gameOverText = text((Xlimit/2), (Ylimit/2), {sprintf('GAME OVER! YOUR SCORE IS %d.', score),'PRESS ESCAPE TO QUIT'}, 'HorizontalAlignment', 'center','FontName','Monospaced', 'Color', [1 1 1], 'FontWeight', 'bold');
  buttonPressed = 0;
  pause(1);
  while buttonPressed ~= 1
    if keyStatus(KEY.escape)
      buttonPressed = 1;
      close all
      return
    end
    pause(0.01);
  end
end

%functions for reading key strokes
  function KeySniffFcn(src,event)
    %KEYSNIFFFCN Summary of this function goes here
    %   Detailed explanation goes
    key = event.Key;
    keyStatus = (strcmp(key, keys) | keyStatus);
  end

  function KeyRelFcn(src,event)
    %KEYRELFCN Summary of this function goes here
    %   Detailed explanation goes here
    key = event.Key;
    keyStatus = (~strcmp(key, keys) & keyStatus);
  end

  function QuitFcn(src,event)
    %QUITFCN Summary of this function goes here
    %   Detailed explanation goes here
    stop(soundtrack);
    stop(laserSfx);
    stop(deathSfx);
    stop(explosionSfx);
    delete(src);
    return;
  end
end