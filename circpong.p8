pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
balls={}
ballsize=4
circsize=40
speed=2.5
paddles={0.5,0}
dpaddle=0.0125
score={0, 0}

function new_ball(balldir)
 ball={}
 ball.x=0
 ball.y=0
 ball.dx=cos(balldir)*speed
 ball.dy=sin(balldir)*speed
 return ball
end
 
function _init()
  add(balls, new_ball(paddles[0]))
end

function _update()
 for _, ball in pairs(balls) do
  ball.x+=ball.dx
  ball.y+=ball.dy
  if ball.x*ball.x+ball.y*ball.y >= circsize*circsize then
   angle=atan2(ball.x, ball.y)
   pad_angs=calc_pad_angs(paddles)
   near_pad=1
   if pad_angs[1]>pad_angs[2] then
    if angle>pad_angs[1] or angle<pad_angs[2] then
     near_pad=2
    end
   else
    if angle>pad_angs[1] and angle<pad_angs[2] then
     near_pad=2
    end
   end
   del(balls, ball)
   ball_new=new_ball(paddles[near_pad]+0.5)
   ball_new.x=cos(paddles[near_pad])*(circsize-ballsize*2)
   ball_new.y=sin(paddles[near_pad])*(circsize-ballsize*2)
   add(balls, ball_new)
   score[(near_pad)%2+1]+=1
  end
  for _, paddle in pairs(paddles) do
   xdiff=ball.x-cos(paddle)*(circsize+1)
   ydiff=ball.y-sin(paddle)*(circsize+1)
   dist=sqrt(xdiff*xdiff+ydiff*ydiff)
   if dist<=ballsize*2 then
    sfx(0, 0)
    ball.dx=xdiff*speed/dist
    ball.dy=ydiff*speed/dist
   end
  end
 end
 
 -- cpu test
 angle=atan2(ball.x, ball.y)
 pad_angs=calc_pad_angs(paddles)
 near_pad=1
 if pad_angs[1]>pad_angs[2] then
  if angle>pad_angs[1] or angle<pad_angs[2] then
   near_pad=2
  end
 else
  if angle>pad_angs[1] and angle<pad_angs[2] then
   near_pad=2
  end
 end
 if (paddles[2]-angle)%1 > 0.5 and near_pad == 2 then
  --faster for harder
  paddles[2]+=dpaddle*1.1
 elseif (paddles[2]-angle)%1 < 0.5 and near_pad == 2 then
  paddles[2]-=dpaddle*1.1
 end
 
 if btn(⬅️) then
  paddles[1]+=dpaddle
 end
 if btn(➡️) then
  paddles[1]-=dpaddle
 end
 if btn(🅾️) then
  paddles[2]+=dpaddle
 end
 if btn(❎) then
  paddles[2]-=dpaddle
 end
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
 circ(64, 64, circsize, 12)
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
000100002707027060270502704027030270302702027020270202701027010270102701000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
