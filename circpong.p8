pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
ballsize=4
circsize=40
ball_speed=1.25
--faster for harder
cpu_mult=0.9
cpu_zone=0.015
cpu_react_frames=20
paddles={0.5,0}
paddle_speed=0.00625
paddle_accel=0.001

function new_ball(balldir)
 ball={}
 ball.hold=0
 ball.x=0
 ball.y=0
 ball.dx=cos(balldir)*ball_speed
 ball.dy=sin(balldir)*ball_speed
 return ball
end
 
function _init()
 balls={}
 add(balls, new_ball(paddles[1]))
 score={0, 0}
 dpaddles={0,0}
 cpu_react=0
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

function nearest_pad(angle)
 local pad_angs=calc_pad_angs(paddles)
 local near_pad=1
 if pad_angs[1]>pad_angs[2] then
  if angle>pad_angs[1] or angle<pad_angs[2] then
   near_pad=2
  end
 else
  if angle>pad_angs[1] and angle<pad_angs[2] then
   near_pad=2
  end
 end
 return near_pad
end

function _update60()
 for _, ball in pairs(balls) do
  ball.x+=ball.dx
  ball.y+=ball.dy
  if ball.x^2+ball.y^2 >= circsize^2 then
   near_pad = nearest_pad(atan2(ball.x, ball.y))
   del(balls, ball)
   ball_new=new_ball(paddles[near_pad]+0.5)
   ball_new.x=cos(paddles[near_pad])*(circsize-ballsize*2)
   ball_new.y=sin(paddles[near_pad])*(circsize-ballsize*2)
   add(balls, ball_new)
   score[(near_pad)%2+1]+=1
  end
  for i, paddle in pairs(paddles) do
   xdiff=ball.x-cos(paddle)*(circsize+1)
   ydiff=ball.y-sin(paddle)*(circsize+1)
   dist=sqrt(xdiff^2+ydiff^2)
   if dist<=ballsize*2 then
    if ball.hold>2 then
     sfx(0)
    end
    ball.hold=0
    ball.dx=xdiff*ball_speed/dist
    ball.dy=ydiff*ball_speed/dist
   else
    ball.hold+=1
   end
  end
 end
 
 -- cpu test
 angle=future_ball_angle(balls[1].x, balls[1].y, balls[1].dx, balls[1].dy)
 near_pad = nearest_pad(angle)
 pad_diff = (paddles[2]-angle)%1
 moved = false
 if near_pad == 1 then
  cpu_react = 0
 elseif cpu_react < cpu_react_frames then
  cpu_react += 1 
 elseif pad_diff > 0.5 and pad_diff < 1-cpu_zone then
  dpaddles[2]=min(paddle_speed*cpu_mult,dpaddles[2]+paddle_accel)
  moved = true
 elseif pad_diff < 0.5 and pad_diff > cpu_zone then
  dpaddles[2]=max(-paddle_speed*cpu_mult,dpaddles[2]-paddle_accel)
  moved = true
 end
 if dpaddles[2]<0 and not moved then
  dpaddles[2]=min(0,dpaddles[2]+paddle_accel)
 elseif not moved then
  dpaddles[2]=max(0,dpaddles[2]-paddle_accel)
 end
 
 if btn(⬅️) then
  dpaddles[1]=min(paddle_speed,dpaddles[1]+paddle_accel)
 elseif btn(➡️) then
  dpaddles[1]=max(-paddle_speed,dpaddles[1]-paddle_accel)
 else
  if dpaddles[1]<0 then
   dpaddles[1]=min(0,dpaddles[1]+paddle_accel)
  else
   dpaddles[1]=max(0,dpaddles[1]-paddle_accel)
  end
 end
 paddles[1]+=dpaddles[1]
 if btn(🅾️) then
  paddles[2]+=paddle_speed
 end
 if btn(❎) then
  paddles[2]-=paddle_speed
 end
 paddles[2]+=dpaddles[2]
 
 paddles[1]=paddles[1]%1
 paddles[2]=paddles[2]%1
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

function calc_pad_angs(paddles)
 midang1 = (paddles[1]+paddles[2])/2
 midang2 = (paddles[1]+paddles[2]+1)/2
 if paddles[1] < paddles[2] then
  return {midang1, midang2%1}
 else
  return {midang2%1, midang1}
 end
end

function _draw()
 cls()
 for _, ball in pairs(balls) do
  circfill(ball.x+64, ball.y+64, ballsize, 7)
 end
 circ(64, 64, circsize,12)
 pad_angs = calc_pad_angs(paddles)
 arc(64, 64, circsize, pad_angs[1], pad_angs[2], 8)
 circfill(cos(paddles[1])*circsize+64,sin(paddles[1])*circsize+64,ballsize,12)
 circfill(cos(paddles[2])*circsize+64,sin(paddles[2])*circsize+64,ballsize,8)
 print_center("blue:"..score[1], 32, 16, 12)
 print_center("red:"..score[2], 96, 16, 8)
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
