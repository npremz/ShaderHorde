uniform float iTime;
uniform vec2 iResolution;
uniform vec2 iMouse;

float sdParabola( in vec2 pos, in float k )
{
	pos.x = abs(pos.x);
	float ik = 1.0/k;
	float p = ik*(pos.y - 0.5*ik)/3.0;
	float q = 0.25*ik*ik*pos.x;
	float h = q*q - p*p*p;
	float r = sqrt(abs(h));
	float x = (h>0.0) ? 
		pow(q+r,1.0/3.0) - pow(abs(q-r),1.0/3.0)*sign(r-q) :
		2.0*cos(atan(r,q)/3.0)*sqrt(p);
	return length(pos-vec2(x,k*x*x)) * sign(pos.x-x);
}

void main()
{
	vec2 fragCoord = gl_FragCoord.xy;
	//Normalizing
	vec2 uv = fragCoord / iResolution.xy;
	
	//Centering render
	uv = uv - 0.5;
	uv = uv * 2.0;
	
	//Fixing aspect ratio
	uv.x *= iResolution.x / iResolution.y;
	
	float distance = length(uv);
	float shapeRes = sdParabola(vec2(uv.x, uv.y - (iMouse.y - 1.0)), -0.3 * iMouse.x);
	
	vec3 color = vec3(1.0, 3.0, 2.0);
	
	//shapeRes = sin((shapeRes * 5.0) - iTime)/5.;
	//shapeRes = shapeRes;

	shapeRes = abs(shapeRes);
	//shapeRes = smoothstep(0.0, 0.1, shapeRes);
	shapeRes = 0.02 / shapeRes;
	
	color *= shapeRes;

	gl_FragColor = vec4(color, 1.0);
}
