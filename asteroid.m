classdef asteroid < handle
  %ASTEROID Summary of this class goes here
  %   Detailed explanation goes here
  
  properties
    velocity = (-2*15)/25; %ideal -2 at 15 fps
    posx
    posy
    shape = {'.::.',':::::::',':::::::',''':::'''};
    body
  end
  
  methods
    function spawn(obj)
      obj.body = text(obj.posx, obj.posy, obj.shape, 'HorizontalAlignment', 'center', 'Color', [1 1 1],'FontWeight', 'bold');
    end
    function move(obj)
      obj.posy = obj.posy + obj.velocity;
      delete(obj.body);
      obj.body = text(obj.posx, obj.posy, obj.shape, 'HorizontalAlignment', 'center', 'Color', [1 1 1],'FontWeight', 'bold');
    end
  end
end

