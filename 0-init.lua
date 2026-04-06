function _init()
	pa=0
		
	px=3
	py=5

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
	cs={13,4,12,3}

	mx=0
	my=0
	dmx=0
	dmy=0

	movspd=0.05
	sensitivity = 0.000125

	wasvertint=false

	-- enables mouse and keyboard
	poke(0x5F2D, 5)
end

function _update60()
	controls() 

	mx = stat(32)
	my = stat(33)
	dmx = stat(38)
	dmy = stat(39)
	
	pa -= dmx * sensitivity
end
	
function _draw()
	cls(0)
	rectfill(0,64,128,128,1)
	rectfill(0,0,128,64,2)
	
	doraycasting2()
	flush_printq()

	--print("mx:"..mx,5,60,7)
	--print("my:"..my,5,70,7)
	--print("dmx:"..dmx,5,80,7)
	--print("dmy:"..dmy,5,90,7)

end

function controls() 
	if stat(28, 7) then
		px+=cos(pa - 0.25)*movspd
		py+=sin(pa - 0.25)*movspd
		--queue_prt("stat(28, 7):"..tostr(stat(28, 7)),5,80,7)
	end

	if stat(28, 4)then
		--queue_prt("stat(28, 4):"..tostr(stat(28, 4)),5,80,7)
		px-=cos(pa -0.25)*movspd
		py-=sin(pa -0.25)*movspd
	end

	if stat(28,22) then
		px-=cos(pa)*movspd
		py-=sin(pa)*movspd
		--queue_prt("stat(28, 22):"..tostr(stat(28, 5)),5,80,7)
	end

	if stat(28,26) then
		px+=cos(pa)*movspd
		py+=sin(pa)*movspd
		--queue_prt("stat(28, 26):"..tostr(stat(28, 5)),5,80,7)
	end

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
		
		--vx=cos(pa-(i-64)/512)
		--vy=sin(pa-(i-64)/512)

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
			else 
				y+=iy
				d=oy
				oy+=dy
			end

			if mget(x,y)>0 or x<0 or x>128 or y<0 or y>128 then
				tw=flr(64-h/d/fac)
				bw=flr(64+h/d/fac)
				--line(i,tw,i,bw,cs[mget(x,y)])

				tline(i,tw,i,bw,
					(px+vx*d)%1*2+(mget(x,y)-1)*2,
					0,
					0,
					2/(bw-tw)
				)
				break
			end
		end
	end
end

function doraycasting2()
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
				if mget(x,y)>0 or x<0 or x>128 or y<0 or y>128 then
					tw=flr(64-h/d/fac)
					bw=flr(64+h/d/fac)
					tline(i,tw,i,bw,(py+vy*d)%1*2+(mget(x,y)-1)*2,0,0,2/(bw-tw))
					break
				end
			else 
				y+=iy
				d=oy
				oy+=dy
				if mget(x,y)>0 or x<0 or x>128 or y<0 or y>128 then
					tw=flr(64-h/d/fac)
					bw=flr(64+h/d/fac)
					tline(i,tw,i,bw,(px+vx*d)%1*2+(mget(x,y)-1)*2,0,0,2/(bw-tw))
					break
				end
			end
		end
	end
end
