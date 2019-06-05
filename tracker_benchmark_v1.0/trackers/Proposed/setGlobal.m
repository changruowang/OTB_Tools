function  setGlobal(val1)
    global History;
    global History1;
    global n_frame;

    n_frame = 1;
    History1 =  zeros(val1,1);
    History = zeros(val1,6);
end