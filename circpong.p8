pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
-- global constants
-- ball globals
circsize=40
ballsize=4
ball_speed=1.25
-- cpu globals
cpu_mult=1
cpu_zone_min=0.015
cpu_zone_max=0.055
cpu_react_frames=20
-- paddle globals
paddle_speed=0.00625
paddle_accel=0.001

function new_ball(balldir, last_hit)
 -- creates a new ball object heading towards balldir
 
 local ball={}
 ball.x=0
 ball.y=0
 ball.dx=cos(balldir)*ball_speed
 ball.dy=sin(balldir)*ball_speed
 ball.hold=0
 ball.last_hit=last_hit
 return ball
end

function new_paddle(start_pos, col)
 local paddle={}
 paddle.a=start_pos
 paddle.da=0
 paddle.moved=false
 paddle.col=col
 paddle.score=0
 return paddle
end

function new_cpu(paddle_num)
 cpu={}
 cpu.pad=paddle_num
 cpu.zone=(cpu_zone_min+cpu_zone_max)/2
 cpu.react=0
 return cpu
end
 
function _init()
 paddles={}
 paddles[1] = new_paddle(0, 12)
 paddles[2] = new_paddle(0.33, 8)
 paddles[3] = new_paddle(0.66, 11)
 balls={}
 add(balls, new_ball(paddles[1].a, 1))
 cpus={}
 add(cpus, new_cpu(3))
 add(cpus, new_cpu(2))
end

function future_ball_angle(x, y, dx, dy) 
 -- finds future angle by calc future x and y of ball
 -- does intersection of circle formula and ball line
 -- looks like magic but you can rederive it yourself
 
 -- swaps x and y if line is too vertical
 -- prevents integer overflows from happening
 local flipped = false
 if abs(dy/dx) > 2 then
  x, y = y, x
  dx, dy = dy, dx
  flipped = true
 end
 
 -- s for slope
 local s = dy/dx
 -- a, b, and c for quadratic formula terms
 local a = s^2 + 1
 local b = 2*s*(y-s*x)
 local c = (y-s*x)^2 - circsize^2
 -- quadratic formula to find future x value of ball
 local discriminant = sqrt(b^2-4*a*c)
 local fut_x1 = (-b+discriminant)/2/a
 local fut_x2 = (-b-discriminant)/2/a 
 --calculate y values for both possible x vals
 local fut_y1 = y+s*(fut_x1-x)
 local fut_y2 = y+s*(fut_x2-x)
 
 -- find which future point is outside circ when moved in ball dir
 local dist1 = (fut_x1+dx)^2+(fut_y1+dy)^2
 local dist2 = (fut_x2+dx)^2+(fut_y2+dy)^2
 if dist1>dist2 then
  fut_x = fut_x1
  fut_y = fut_y1
 else
  fut_x = fut_x2
  fut_y = fut_y2
 end
 
 if flipped then
  fut_x, fut_y = fut_y, fut_x
 end
 
 return atan2(fut_x, fut_y)
end

function pad_range(pad_num)
 -- calculates the range of a paddle
 
 -- creates a copy of the paddles so that it can be sorted
 local sort_pads = {}
 for _, paddle in pairs(paddles) do
  add(sort_pads, paddle)
 end
 -- sorts the paddles by angle in increasing order
 local sort_pad_num = -1
 for i=1,#sort_pads do
  local j = i
  while j > 1 and 
        sort_pads[j-1].a > sort_pads[j].a do
   sort_pads[j],sort_pads[j-1] = sort_pads[j-1],sort_pads[j]
   j = j - 1
   -- shifts sort_pad_num up if swapped
   if sort_pad_num == j then
    sort_pad_num+=1
   end
  end
  -- stores the pad_num in the sorted array
  if i == pad_num then
   sort_pad_num = j
  end
 end
 
 if sort_pad_num == -1 then
  return nil
 end
 
 -- calculate edge angles of the range
 local left_pad_ang = sort_pads[(sort_pad_num-2)%#sort_pads+1].a
 local pad_ang = sort_pads[sort_pad_num].a
 local right_pad_ang = sort_pads[sort_pad_num%#sort_pads+1].a
 
 local left_edge = (left_pad_ang+pad_ang)/2
 local right_edge = (right_pad_ang+pad_ang)/2
 
 -- shifts edge to real spot if range crosses 0
 if left_pad_ang > pad_ang then
  left_edge+=0.5
 end
 if pad_ang > right_pad_ang then
  right_edge+=0.5
 end
 
 return left_edge%1, right_edge%1
end

function nearest_pad(angle)
 -- calculates the nearest paddle to angle
 local near_pad = 0
 for i=1,#paddles do
  left_edge, right_edge = pad_range(i)
  if left_edge > right_edge then
   if angle > left_edge or angle < right_edge then
    near_pad = i
   end
  else
   if angle > left_edge and angle < right_edge then
    near_pad = i
   end
  end
 end
 return near_pad
end

function _update60()
 for _, ball in pairs(balls) do
  ball.x+=ball.dx
  ball.y+=ball.dy
  
  -- check if the ball hits the circle
  if ball.x^2+ball.y^2 >= circsize^2 then
   near_pad = nearest_pad(atan2(ball.x, ball.y))
   -- adds score to the one who hit the ball last
   -- if own goal, everyone else gets a point
   if near_pad == ball.last_hit then
    for i=1,#paddles do
     if i != near_pad then
      paddles[i].score += 1
     end
    end
   else
    paddles[ball.last_hit].score += 1
   end
   del(balls, ball)
   ball_new=new_ball(paddles[near_pad].a+0.5, near_pad)
   ball_new.x=cos(paddles[near_pad].a)*(circsize-ballsize*2)
   ball_new.y=sin(paddles[near_pad].a)*(circsize-ballsize*2)
   add(balls, ball_new)
  end
  
  for i, paddle in pairs(paddles) do
   xdiff=ball.x-cos(paddle.a)*(circsize+1)
   ydiff=ball.y-sin(paddle.a)*(circsize+1)
   dist=sqrt(xdiff^2+ydiff^2)
   if dist<=ballsize*2 then
    if ball.hold>2 then
     sfx(0)
    end
    ball.hold=0
    ball.dx=xdiff*ball_speed/dist
    ball.dy=ydiff*ball_speed/dist
    ball.last_hit = i
   else
    ball.hold+=1
   end
  end
 end
 
 -- cpu control
 angle=future_ball_angle(balls[1].x, balls[1].y, balls[1].dx, balls[1].dy)
 near_pad = nearest_pad(angle)
 for _, cpu in pairs(cpus) do
  pad_diff = (paddles[cpu.pad].a-angle)%1
  if near_pad != cpu.pad then
   cpu.react = 0
  elseif cpu.react < cpu_react_frames then
   cpu.zone = rnd(1)*(cpu_zone_max-cpu_zone_min)+cpu_zone_min
   cpu.react += 1 
  elseif pad_diff > 0.5 and pad_diff < 1-cpu.zone then
   paddles[cpu.pad].da=min(paddle_speed*cpu_mult,paddles[cpu.pad].da+paddle_accel)
   paddles[cpu.pad].moved = true
  elseif pad_diff < 0.5 and pad_diff > cpu.zone then
   paddles[cpu.pad].da=max(-paddle_speed*cpu_mult,paddles[cpu.pad].da-paddle_accel)
   paddles[cpu.pad].moved = true
  end
 end
 
 if btn(⬅️) then
  paddles[1].da=min(paddle_speed,paddles[1].da+paddle_accel)
  paddles[1].moved=true
 end
 if btn(➡️) then
  paddles[1].da=max(-paddle_speed,paddles[1].da-paddle_accel)
  paddles[1].moved=true
 end
 
 if btn(🅾️) then
  paddles[2].da=min(paddle_speed,paddles[2].da+paddle_accel)
  paddles[2].moved=true
 end
 if btn(❎) then
  paddles[2].da=max(-paddle_speed,paddles[2].da-paddle_accel)
  paddles[2].moved=true
 end
 
 for _, paddle in pairs(paddles) do
  if paddle.da<0 and not paddle.moved then
   paddle.da=min(0,paddle.da+paddle_accel)
  elseif not paddle.moved then
   paddle.da=max(0,paddle.da-paddle_accel)
  end
  
  paddle.a = (paddle.a + paddle.da) % 1
  
  -- reset paddle moved for next frame
  paddle.moved = false
 end
end

function print_center(text, x, y, col)
 str=""..text
 print(str,x-#str*2,y-3,col)
end

function arc(x, y, r, ang1, ang2, c)
 if ang1 < 0 or ang2 < 0 or ang1 >= 1 or ang2 > 1 then return end
 if ang1 > ang2 then
  arc(x, y, r, ang1, 1, c)
  arc(x, y, r, 0, ang2, c)
  return
 end
 for i = 0, .75, .25 do
  local a = ang1
  local b = ang2
  if a > i + .25 then goto next end
  if b < i then goto next end
  if a < i then a = i end
  if b > i + .25 then b = i + .25 end
  local x1 = x + r * cos(a)
  local y1 = y + r * sin(a)
  local x2 = x + r * cos(b)
  local y2 = y + r * sin(b)
  local cx1 = min(x1, x2)
  local cx2 = max(x1, x2)
  local cy1 = min(y1, y2)
  local cy2 = max(y1, y2)
  clip(cx1, cy1, cx2 - cx1 + 2, cy2 - cy1 + 2)
  circ(x, y, r, c)
  clip()
  ::next::
 end
end

function _draw()
 cls()
 for _, ball in pairs(balls) do
  circfill(ball.x+64, ball.y+64, ballsize, 7)
 end
 for i, paddle in pairs(paddles) do
  left_edge, right_edge = pad_range(i)
  arc(64, 64, circsize, left_edge, right_edge, paddle.col)
  circfill(cos(paddle.a)*circsize+64,
           sin(paddle.a)*circsize+64,
           ballsize,
           paddle.col)
 end
 print_center("blue:"..paddles[1].score, 32, 16, 12)
 print_center("red:"..paddles[2].score, 96, 16, 8)
 print_center("green:"..paddles[3].score, 64, 16, 11)
 print("⬅️➡️", 24, 109, 12)
 print("🅾️❎", 88, 109, 8)
end
__gfx__
000cc000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0ccccc80000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0cccc880000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
cccc8888000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
cccc8888000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0cc88880000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0c888880000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00088000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
000100002705027040270302703027030275202752027520275202751027510275102751000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
