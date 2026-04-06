function _init()
	pa=0
		
	px=1
	py=3

	x=0
	y=0
	vx=0
	vy=0
	ox=0
	oy=0
	dx=0
	dy=0
	ix=0
	iy=0
	h=35
	cs={13,4,12,3,5}

	mx=0
	my=0
	dmx=0
	dmy=0

	viewdist=16

	viewbounds_x1=px-viewdist
	viewbounds_x2=px+viewdist
	viewbounds_y1=py-viewdist
	viewbounds_y2=py+viewdist

	movspd=0.05
	sensitivity = 0.00005

	wasvertint=false

	floortilebound=128

	-- enables mouse and keyboard
	poke(0x5F2D, 5)
end

function _update60()
	viewbounds_x1=px-viewdist
	viewbounds_x2=px+viewdist
	viewbounds_y1=py-viewdist
	viewbounds_y2=py+viewdist

	if viewbounds_x1<0 then viewbounds_x1=0 end
	if viewbounds_x2>127 then viewbounds_x2=127 end

	if viewbounds_y1<0 then viewbounds_y1=0 end
	if viewbounds_y2>63 then viewbounds_y2=63 end

	controls() 


	if (mget(px-1,py)>0 and mget(px-1,py)<floortilebound) or px<=0 then
		px=max(px,flr(px)+0.2)
	end
	if (mget(px+1,py)>0 and mget(px+1,py)<floortilebound) or px>=31 then
		px=min(px,ceil(px)-0.2)
	end
	if (mget(px,py-1)>0 and mget(px,py-1)<floortilebound) or py<=0 then
		py=max(py,flr(py)+0.2)
	end
	if (mget(px,py+1)>0 and mget(px,py+1)<floortilebound) or py>=31 then
		py=min(py,ceil(py)-0.2)
	end

	mx = stat(32)
	my = stat(33)
	dmx = stat(38)
	dmy = stat(39)
	
	pa -= dmx * sensitivity
end
	
function _draw()
	cls(0)
	--fillp(0b0101101001011010)
	--fillp(🐱)


	--rectfill(0,64,128,128,1)
	drawfloor(px,py,pa) 
	drawceiling(px,py,pa) 
	--rectfill(0,0,128,64,1)
	
	doraycasting()
	flush_printq()

	--print("player tile x="..flr(px),2,115,7)
	--print("player tile y="..flr(py),2,121,7)
	--print("bounds={"..viewbounds_x1..","..viewbounds_x2..","..viewbounds_y1..","..viewbounds_y2.."}",2,109,7)
--
	--local x1 = 7
	--if is_wall(flr(px+1),flr(py)) then		
	--	x1=8
	--else
	--	x1=7
	--end
	--print("N+x:"..(px+1)..","..py,68,115,x1)

	--tline(0, 90, 128, 90, 8, 2, -1/128, 0)
	pset(0,0,11)

end

function drawfloor2() 
	
	for y = 64,127 do
		--vx0=cos(pa+atan2(1,(0-64)/64))
		--vy0=sin(pa+atan2(1,(0-64)/64))
--
		--vx1=cos(pa+atan2(1,(127-64)/64))
		--vy1=sin(pa+atan2(1,(127-64)/64))

		vx0=cos(pa-(0-64)/512)
		vy0=sin(pa-(0-64)/512)

		vx1=cos(pa-(127-64)/512)
		vy1=sin(pa-(127-64)/512)

		local u0 = px + vx0 * (128-y)
		local v0 = py + vy0 * (128-y)
		
		local u1 = px + vx1 * (128-y)
		local v1 = py + vy1 * (128-y)		

		u_step = (u1 - u0) / 128
		v_step = (v1 - v0) / 128

		--(py+vy*d) % 1 * 2 + (mget(x,y)-1) * 2

		--tline(0, y, 128, y, 8, 2, u_step, v_step)
	end
end

function drawfloor3()
  -- camera setup
  local cam_x, cam_y = px, py 
  local cam_h = h -- camera height
  local fov = 128

  for y=0,63 do
    -- perspective calculation for each row
    local p = (y+0.5) / 64 -- normalized vertical position
    local row_depth = cam_h / p -- distance to this row
    
    -- calculate screen bounds
    local x_start = 0
    local x_end = 127
    
    -- map sampling coordinates
    -- this samples from the map based on camera position
    local mx = cam_x - row_depth
    local my = cam_y + row_depth
    
    -- texture slope based on row_depth (perspective scaling)
    local mdx = (row_depth * 2) / 128
    local mdy = 0 -- 0 means horizontal floor mapping
    
    -- draw textured line
    -- note: y+64 fills the bottom half of the screen
    tline(x_start,y+64, x_end,y+64, 
          mx,my, mdx,mdy)
  end
end

-- conceptual code to draw a floor
function drawfloor(cam_x, cam_y, cam_a)
  -- 128x128 screen
  for y=64, 127 do
    -- calculate distance/perspective for this row
    local dist = 32/(y-64)
    
    -- calculate floor space coordinates for left and right edges
    -- of this horizontal scanline based on camera angle (a)
    local x1 = cam_x + (cos(cam_a+0.25)*dist - sin(cam_a+0.25)*dist)
    local y1 = cam_y + (sin(cam_a+0.25)*dist + cos(cam_a+0.25)*dist)
	
    local x2 = cam_x + (cos(cam_a-0.25)*dist + sin(cam_a-0.25)*dist)
    local y2 = cam_y + (sin(cam_a-0.25)*dist - cos(cam_a-0.25)*dist)
    
    -- draw line from left (0,y) to right (127,y)
    -- sampling from map space
    tline(0,y, 127,y, 
          x1,y1,  -- start mapping coordinate (u,v)
          (x2-x1)/128, (y2-y1)/128) -- delta (stepping)
  end
end

-- conceptual code to draw a floor
function drawceiling(cam_x, cam_y, cam_a)
  -- 128x128 screen
  for y=0, 63 do
    -- calculate distance/perspective for this row
    local dist = 32/y
    
    -- calculate floor space coordinates for left and right edges
    -- of this horizontal scanline based on camera angle (a)
    local x1 = cam_x + (cos(cam_a+0.25)*dist - sin(cam_a+0.25)*dist)
    local y1 = cam_y + (sin(cam_a+0.25)*dist + cos(cam_a+0.25)*dist)
	
    local x2 = cam_x + (cos(cam_a-0.25)*dist + sin(cam_a-0.25)*dist)
    local y2 = cam_y + (sin(cam_a-0.25)*dist - cos(cam_a-0.25)*dist)
    
    -- draw line from left (0,y) to right (127,y)
    -- sampling from map space
    tline(0,63-y, 127,63-y, 
          x1,y1,  -- start mapping coordinate (u,v)
          (x2-x1)/128, (y2-y1)/128) -- delta (stepping)
  end
end


function is_wall(x,y)
	if mget(x,y)==0 then
		return false
	else
		return true
	end
end

function controls() 
	local newpx=px
	local newpy=py

	if stat(28, 7) then -- LEFT
		newpx+=cos(pa - 0.25)*movspd
		newpy+=sin(pa - 0.25)*movspd
	end

	if stat(28, 4)then -- RIGHT
		newpx-=cos(pa -0.25)*movspd
		newpy-=sin(pa -0.25)*movspd
	end

	if stat(28,22) then -- BACK
		newpx-=cos(pa)*movspd
		newpy-=sin(pa)*movspd
	end

	if stat(28,26) then -- FORWARD
		newpx+=cos(pa)*movspd
		newpy+=sin(pa)*movspd
	end

	-- if not collision
	px=newpx
	py=newpy


	if btn(⬅️) then		
		pa+=0.01
		if pa>1 then
			pa=0
		end
	end
	
	if btn(➡️) then
		pa-=0.01
		if pa<0 then
			pa=1
		end
	end

	--if btn(⬆️) or btn(2,1) then
	--	px+=cos(pa)*0.1
	--	py+=sin(pa)*0.1
--
	--	--if px>64 then px=64 end
	--	--if py>64 then py=64 end
	--end
	--
	--if btn(⬇️) or btn(3,1) then
	--	px-=cos(pa)*0.1
	--	py-=sin(pa)*0.1
--
	--	--if px<0 then px=0 end
	--	--if py<0 then py=0 end
	--end
	
	--if btn(❎) or btn(4,1) then
	--	px-=cos(pa -0.25)*0.1
	--	py-=sin(pa -0.25)*0.1
	--end
--
	--if (btn(🅾️) or btn(5,1)) then
	--	px+=cos(pa -0.25)*0.1
	--	py+=sin(pa -0.25)*0.1
	--end
end

function queue_spr(n, x, y, w, h, flip_x, flip_y)
  add(drawqueue, {
    n=n, x=x, y=y,
    w=w or 1, h=h or 1,
    fx=flip_x, fy=flip_y
  })
end

function queue_sspr(sx, sy, sw, sh, dx, dy, dw,dh)
  add(tractorqueue, {
    sx=sx, sy=sy, sw=sw, sh=sh, dx=dx, dy=dy, dw=dw,dh=dh
  })
end

function queue_prt(txt, x, y, col)
  add(printqueue, {
    t=txt, x=x, y=y,
    c=col
  })
end

function flush_drawqt()
  for d in all(tractorqueue) do
    sspr(d.sx, d.sy, d.sw, d.sh, d.dx, d.dy, d.dw, d.dh)
  end
  tractorqueue = {}
end

function flush_drawq()
  for d in all(drawqueue) do
    spr(d.n, d.x, d.y, d.w, d.h, d.fx, d.fy)
  end
  drawqueue = {}
end

function flush_printq()
  for d in all(printqueue) do
	print(d.t,d.x,d.y,d.c)
  end
  printqueue = {}
end

function doraycasting()
	for i=0,127 do
		x=px
		y=py
		
		vx=cos(pa+atan2(1,(i-64)/64))
		vy=sin(pa+atan2(1,(i-64)/64))
		fac=cos(atan2(1,(i-64)/64))		
		
		dx=abs(1/vx)
		dy=abs(1/vy)

		ix=vx>0 and 1 or -1
		iy=vy>0 and 1 or -1

		if vx>0 then
			ox=(flr(x)-x+1)/vx
		else
			ox=abs((x-flr(x))/vx)
		end

		if vy>0 then
			oy=(flr(y)-y+1)/vy
		else
			oy=abs((y-flr(y))/vy)
		end
		
		while true do
			if ox<oy then
				x+=ix
				d=ox
				ox+=dx
				if (mget(x,y)>0 and mget(x,y)<floortilebound) or x<viewbounds_x1 or x>viewbounds_x2 or y<viewbounds_y1 or y>viewbounds_y2 then
					tw=flr(64-h/d/fac)
					bw=flr(64+h/d/fac)
					tline(i,tw,i,bw,(py+vy*d)%1*2+(mget(x,y)-1)*2,0,0,2/(bw-tw))
					break
				end
			else 
				y+=iy
				d=oy
				oy+=dy
				if (mget(x,y)>0 and mget(x,y)<floortilebound) or x<viewbounds_x1 or x>viewbounds_x2 or y<viewbounds_y1 or y>viewbounds_y2 then
					tw=flr(64-h/d/fac)
					bw=flr(64+h/d/fac)
					tline(i,tw,i,bw,(px+vx*d)%1*2+(mget(x,y)-1)*2,0,0,2/(bw-tw))
					break
				end
			end

			--printh("mx:"..((px+vx*d)%1*2+(mget(x,y)-1)*2),"log.txt")
		end
	end
end
