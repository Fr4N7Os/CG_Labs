float sdBox(vec3 p, vec3 b){
    vec3 d = abs(p)-b;
    return length(max(d,0.0)) + min(max(d.x,max(d.y,d.z)),0.0);
}

float sdSphere(vec3 p,float r){
    return length(p)-r;
}

float sdPlane(vec3 p){
    return p.y;
}

// barrel SDF
float sdBarrel(vec3 p, vec3 pos, vec3 dir){
    p -= pos;
    p -= dir * clamp(dot(p,dir), 0.0, 0.9);
    return length(p) - 0.03;
}

float mapScene(vec3 p, vec3 shellPos, vec3 barrelPos, vec3 barrelDir, out int id){
    float d = sdPlane(p);
    id = 0;

    // ships
    vec3 s1 = vec3(-0.5,0.05,3.0);
    vec3 s2 = vec3( 0.5,0.05,4.0);

    float d1 = sdBox(p-s1,vec3(0.3,0.05,0.6));
    if(d1<d){d=d1; id=1;}

    float d2 = sdBox(p-s2,vec3(0.3,0.05,0.6));
    if(d2<d){d=d2; id=2;}

    // barrel
    float db = sdBarrel(p, barrelPos, barrelDir);
    if(db<d){d=db; id=4;}

    // shell
    float ds = sdSphere(p-shellPos,0.05);
    if(ds<d){d=ds; id=3;}

    return d;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord){
    vec2 uv = (fragCoord/iResolution.xy)*2.0-1.0;
    uv.x *= iResolution.x/iResolution.y;

    float L = texture(iChannel0,vec2(37./256.,0)).r;
    float R = texture(iChannel0,vec2(39./256.,0)).r;
    float U = texture(iChannel0,vec2(38./256.,0)).r;
    float D = texture(iChannel0,vec2(40./256.,0)).r;
    float fire = texture(iChannel0,vec2(32./256.,0)).r;

    float yaw   = (R-L)*1.2;
    float pitch = clamp((U-D)*0.6, -0.2, 0.8);

    // camera (horizontal only)
    vec3 camPos = vec3(0.0,0.6,-0.9);
    vec3 camDir = normalize(vec3(sin(yaw),0.0,cos(yaw)));
    vec3 right  = normalize(cross(camDir,vec3(0,1,0)));
    vec3 up     = cross(right,camDir);
    vec3 rayDir = normalize(camDir + uv.x*right + uv.y*up);

    // barrel
    vec3 barrelPos = camPos + camDir*0.6;
    vec3 barrelDir = normalize(vec3(sin(yaw),pitch,cos(yaw)));

    // shell lifetime
    float firePeriod = 2.0;
    float t = mod(iTime, firePeriod);

    vec3 shellPos = vec3(1000);
    if(t < 1.5 && fire>0.0){
        shellPos = barrelPos + barrelDir*6.0*t;
        shellPos.y -= 2.5*t*t;
    }

    vec3 p = camPos;
    float dist=0.0;
    int id=0;

    for(int i=0;i<90;i++){
        float d = mapScene(p,shellPos,barrelPos,barrelDir,id);
        if(d<0.001) break;
        dist+=d;
        p = camPos + rayDir*dist;
    }

    vec3 col = vec3(0.15,0.18,0.2);

    float wave = sin(p.x*2.0+iTime)*0.02 + sin(p.z*1.5)*0.02;
    if(p.y < wave) col = vec3(0.1,0.25,0.35);
    if(id==1||id==2) col=vec3(0.8,0.1,0.1);
    if(id==3) col=vec3(1.0,0.9,0.3);
    if(id==4) col=vec3(0.3,0.3,0.3);

    fragColor = vec4(col,1.0);
}
