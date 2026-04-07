function _init()
   poke( 0x5f2e, 1 ) --enable hidden colors
   custom_palette = {[0]=0,128,133,5,6,7,1,140,12,3,139,11,130,132,4,15}
   reset_pal()

	pa=0
	lpa=1
		
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
	h=32
	cs={13,4,12,3,5}

	mx=0
	my=0
	dmx=0
	dmy=0

	viewdist=12

	viewbounds_x1=px-viewdist
	viewbounds_x2=px+viewdist
	viewbounds_y1=py-viewdist
	viewbounds_y2=py+viewdist

	movspd=0.05
	sensitivity = 0.00005

	wasvertint=false

	floortilebound=128

	texturesize=2 --*8

	facing="North"

	looking_ray_x=0
	looking_ray_y=0

	looking_nx=0
	looking_ny=0

	looking_mx=0
	looking_my=0

	notfound=true

	lx,ly=0

	-- enables mouse and keyboard
	poke(0x5F2D, 5)
	--palt(0, false)
end

function reset_pal()
	pal()
	--pal( custom_palette, 1 )
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
	domap()


	if (mget(px-1,py)>0 and mget(px-1,py)<floortilebound) or px<=0 then
		px=max(px,flr(px)+0.2)
	end
	if (mget(px+1,py)>0 and mget(px+1,py)<floortilebound) or px>=127 then
		px=min(px,ceil(px)-0.2)
	end
	if (mget(px,py-1)>0 and mget(px,py-1)<floortilebound) or py<=0 then
		py=max(py,flr(py)+0.2)
	end
	if (mget(px,py+1)>0 and mget(px,py+1)<floortilebound) or py>=63 then
		py=min(py,ceil(py)-0.2)
	end

	mx = stat(32)
	my = stat(33)
	dmx = stat(38)
	dmy = stat(39)
	
	
	pa -= dmx * sensitivity

	if pa>1 then pa = 0 end
	if pa<0 then pa = 1 end

	if pa>=0.125 and pa<0.375 then 
		facing = "east" 
	elseif pa>=0.375 and pa<0.625 then 
		facing = "north" 
	elseif pa>=0.625 and pa<0.875 then 
		facing = "west" 
	else
		facing = "south" 
	end
end
	
function _draw()
	cls(0)
	--fillp(0b0101101001011010)
	--fillp(🐱)


	rectfill(0,0,127,63,5)
	--rectfill(0,64,127,127,5)
	drawfloor(px,py,pa) 
	--drawceiling(px,py,pa) 
	lpa=pa
	
	doraycasting()
	flush_printq()
	flush_drawq()
	flush_drawqt()

	--pset(0,0,11)
	--print("mget(px,py)"..mget(lx,ly),5,110,7)
	lx,ly=lookingat()
	--print("looking at ("..lx..","..ly..") sprite="..mget(lx,ly),5,120,7)

	spr(16,64,64)
end

function drawfloor(cam_x, cam_y, cam_a)
  for sy=64,127 do
    local dy = sy - 64
    local dist = 31.5 / dy

    local x1 = cam_x + (cos(cam_a+0.25)*dist - sin(cam_a+0.25)*dist)
    local y1 = cam_y + (sin(cam_a+0.25)*dist + cos(cam_a+0.25)*dist)

    local x2 = cam_x + (cos(cam_a-0.25)*dist + sin(cam_a-0.25)*dist)
    local y2 = cam_y + (sin(cam_a-0.25)*dist - cos(cam_a-0.25)*dist)

    tline(0, sy, 127, sy,
      x1, y1,
      (x2-x1)/128, (y2-y1)/128
    )
  end
end

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

	if stat(34)==1 then
		--queue_spr(16,64,64,1,1,false,false)
		if mget(lx,ly)==5 then
			mset(lx, ly, 130)
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

function doraycasting()
	for sx=0,127 do
		cam_x=px
		cam_y=py
		
		ray_x=cos(pa+atan2(1,(sx-64)/64))
		ray_y=sin(pa+atan2(1,(sx-64)/64))

		fac=cos(atan2(1,(sx-64)/64))		
		
		dx=abs(1/ray_x)
		dy=abs(1/ray_y)

		ix=ray_x>0 and 1 or -1
		iy=ray_y>0 and 1 or -1

		if ray_x>0 then
			ox=(flr(cam_x)-cam_x+1)/ray_x
		else
			ox=abs((cam_x-flr(cam_x))/ray_x)
		end

		if ray_y>0 then
			oy=(flr(cam_y)-cam_y+1)/ray_y
		else
			oy=abs((cam_y-flr(cam_y))/ray_y)
		end
		
		while true do
			if ox<oy then
				cam_x+=ix
				d=ox
				ox+=dx
				if (mget(cam_x,cam_y)>0 and mget(cam_x,cam_y)<floortilebound) or cam_x<viewbounds_x1 or cam_x>viewbounds_x2 or cam_y<viewbounds_y1 or cam_y>viewbounds_y2 then
					tw=flr(64-h/d/fac)
					bw=flr(64+h/d/fac)
					tline(
						sx,tw,sx,bw,
						(py+ray_y*d)%1*texturesize+(mget(cam_x,cam_y)-1)*2,0,
						0,texturesize/(bw-tw)
					)
					break
				end
			else 
				cam_y+=iy
				d=oy
				oy+=dy
				if (mget(cam_x,cam_y)>0 and mget(cam_x,cam_y)<floortilebound) or cam_x<viewbounds_x1 or cam_x>viewbounds_x2 or cam_y<viewbounds_y1 or cam_y>viewbounds_y2 then
					tw=flr(64-h/d/fac)
					bw=flr(64+h/d/fac)
					tline(
						sx,tw,sx,bw,
						(px + ray_x * d) % 1 * texturesize + (mget(cam_x,cam_y)-1)*2,0,
						0,texturesize/(bw-tw)
					)					
					break
				end
			end
		end
	end
end

function lookingat()
	ray_x = cos(pa)*0.005
	ray_y = sin(pa)*0.005

	nx=px+ray_x
	ny=py+ray_y

	mx=flr(nx)
	my=flr(ny)

	--queue_prt("ray_x="..ray_x..", ray_y="..ray_y,5,10,7)
	--queue_prt("nx="..nx..",ny="..ny..",mx="..mx..",my="..my,5,20,7)
	--queue_prt("mget(mx,my)"..mget(mx,my),5,30,7)

	--printh("Start While...","log.txt")
	while notfound do
		if (mget(mx,my)>=floortilebound) then
			nx+=ray_x
			ny+=ray_y
	--
			mx=flr(nx)
			my=flr(ny)
			--printh("mx="..mx..", my="..my,"log.txt")
		else
			notfound=false
		end
	end
	notfound=true
	--printh("End While...mget("..mx..","..my..")"..mget(mx,my),"log.txt")
	return mx,my
end

function domap()
	local mapx=flr(px)
	local mapy=flr(py)

	local spr
	local offx=3
	local offy=3

	--printh("","log.txt",true)
	
	for iy = mapy-5,mapy+5 do
		for ix = mapx-5,mapx+5 do			

			spr=mget(ix,iy)
			if (spr>0 and spr <16) then
				queue_sspr(spr*8,0,3,3,offx,offy,3,3)
			else
				queue_sspr(8,8,3,3,offx,offy,3,3)
			end

			if ix==mapx and iy==mapy then
				queue_sspr(64,0,2,2,19,19,2,2)
			end


			offx+=3
			--printh("ix="..ix..", iy="..iy..", spr="..spr,"log.txt")
		end
		offy+=3
		offx=3
	end


	--(sx, sy, sw, sh, dx, dy, dw,dh)
end