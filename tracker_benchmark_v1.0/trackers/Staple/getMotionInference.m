function motionResponse = getMotionInference(flow, map, sz)
[h,w]=size(map);
flow = round(flow);% should use more precise way. 
motionResponse = zeros(h,w);
ti = -floor(sz(1)/2):floor(sz(1)/2);
tj = -floor(sz(2)/2):floor(sz(2)/2);
for i=1:h
    for j=1:w
        fromx=ti+i;fromy=tj+j;
        tox = fromx + flow(i,j,2); toy=fromy +flow(i,j,1);
        fromx(fromx<1)=1;fromy(fromy<1)=1;fromx(fromx>h)=h;fromy(fromy>w)=w;
        tox(tox<1)=1;toy(toy<1)=1;tox(tox>h)=h;toy(toy>w)=w;
        motionResponse(tox,toy) = motionResponse(tox,toy) + map(fromx,fromy);
    end
end
motionResponse = motionResponse / prod(sz);
end
