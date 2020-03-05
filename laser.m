classdef laser < handle
  properties
    velocity = (5*15)/25; %5 at 15 FPS
    posx
    posy
    shape = '|'
    body
  end
  
  methods
    function spawn(obj)
      obj.body = text(obj.posx, obj.posy+5, obj.shape, 'HorizontalAlignment', 'center', 'Color', [1 1 1]);
    end
    function move(obj)
      obj.posy = obj.posy + obj.velocity;
      delete(obj.body);
      obj.body = text(obj.posx, obj.posy, obj.shape, 'HorizontalAlignment', 'center', 'Color', [1 1 1]);
    end
  end
end