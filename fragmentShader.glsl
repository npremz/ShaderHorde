uniform float iTime;
uniform vec2 iResolution;
uniform vec2 iMouse;

#define PI 3.14159

float bounceOut(in float t) {
    const float a = 4.0 / 11.0;
    const float b = 8.0 / 11.0;
    const float c = 9.0 / 10.0;

    const float ca = 4356.0 / 361.0;
    const float cb = 35442.0 / 1805.0;
    const float cc = 16061.0 / 1805.0;

    float t2 = t * t;

    return t < a
        ? 7.5625 * t2
        : t < b
            ? 9.075 * t2 - 9.9 * t + 3.4
            : t < c
                ? ca * t2 - cb * t + cc
                : 10.8 * t * t - 20.52 * t + 10.72;
}

float bounceIn(in float t) { return 1.0 - bounceOut(1.0 - t); }

float bounceInOut(in float t) {
    return t < 0.5
        ? 0.5 * (1.0 - bounceOut(1.0 - t * 2.0))
        : 0.5 * bounceOut(t * 2.0 - 1.0) + 0.5;
}

float psrdnoise(vec2 x, vec2 period, float alpha, out vec2 gradient)
{

	// Transform to simplex space (axis-aligned hexagonal grid)
	vec2 uv = vec2(x.x + x.y*0.5, x.y);

	// Determine which simplex we're in, with i0 being the "base"
	vec2 i0 = floor(uv);
	vec2 f0 = fract(uv);
	// o1 is the offset in simplex space to the second corner
	float cmp = step(f0.y, f0.x);
	vec2 o1 = vec2(cmp, 1.0-cmp);

	// Enumerate the remaining simplex corners
	vec2 i1 = i0 + o1;
	vec2 i2 = i0 + vec2(1.0, 1.0);

	// Transform corners back to texture space
	vec2 v0 = vec2(i0.x - i0.y * 0.5, i0.y);
	vec2 v1 = vec2(v0.x + o1.x - o1.y * 0.5, v0.y + o1.y);
	vec2 v2 = vec2(v0.x + 0.5, v0.y + 1.0);

	// Compute vectors from v to each of the simplex corners
	vec2 x0 = x - v0;
	vec2 x1 = x - v1;
	vec2 x2 = x - v2;

	vec3 iu, iv;
	vec3 xw, yw;

	// Wrap to periods, if desired
	if(any(greaterThan(period, vec2(0.0)))) {
		xw = vec3(v0.x, v1.x, v2.x);
		yw = vec3(v0.y, v1.y, v2.y);
		if(period.x > 0.0)
			xw = mod(vec3(v0.x, v1.x, v2.x), period.x);
		if(period.y > 0.0)
			yw = mod(vec3(v0.y, v1.y, v2.y), period.y);
		// Transform back to simplex space and fix rounding errors
		iu = floor(xw + 0.5*yw + 0.5);
		iv = floor(yw + 0.5);
	} else { // Shortcut if neither x nor y periods are specified
		iu = vec3(i0.x, i1.x, i2.x);
		iv = vec3(i0.y, i1.y, i2.y);
	}

	// Compute one pseudo-random hash value for each corner
	vec3 hash = mod(iu, 289.0);
	hash = mod((hash*51.0 + 2.0)*hash + iv, 289.0);
	hash = mod((hash*34.0 + 10.0)*hash, 289.0);

	// Pick a pseudo-random angle and add the desired rotation
	vec3 psi = hash * 0.07482 + alpha;
	vec3 gx = cos(psi);
	vec3 gy = sin(psi);

	// Reorganize for dot products below
	vec2 g0 = vec2(gx.x,gy.x);
	vec2 g1 = vec2(gx.y,gy.y);
	vec2 g2 = vec2(gx.z,gy.z);

	// Radial decay with distance from each simplex corner
	vec3 w = 0.8 - vec3(dot(x0, x0), dot(x1, x1), dot(x2, x2));
	w = max(w, 0.0);
	vec3 w2 = w * w;
	vec3 w4 = w2 * w2;

	// The value of the linear ramp from each of the corners
	vec3 gdotx = vec3(dot(g0, x0), dot(g1, x1), dot(g2, x2));

	// Multiply by the radial decay and sum up the noise value
	float n = dot(w4, gdotx);

	// Compute the first order partial derivatives
	vec3 w3 = w2 * w;
	vec3 dw = -8.0 * w3 * gdotx;
	vec2 dn0 = w4.x * g0 + dw.x * x0;
	vec2 dn1 = w4.y * g1 + dw.y * x1;
	vec2 dn2 = w4.z * g2 + dw.z * x2;
	gradient = 10.9 * (dn0 + dn1 + dn2);

	// Scale the return value to fit nicely into the range [-1,1]
	return 10.9 * n;
}

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

vec2 rot(vec2 v, float a){
    return mat2x2(
                cos(a), -sin(a), 
                sin(a), cos(a)
            ) * v;
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

	uv = rot(uv, PI/8. + iTime/30.);
	
	//float distance = length(uv);

	vec2 gradient;
	float shapeRes = psrdnoise(uv * vec2(3.) + iMouse, vec2(0.), 1.2 * iTime/4. * PI, gradient);
	float lines = cos((uv.x + shapeRes * 0.15 + 0.2) * PI/2.);
	
	vec3 color = vec3(1.0, 3.0, 2.0);
	
	//shapeRes = sin((shapeRes * 5.0) - iTime)/5.;
	//shapeRes = shapeRes;

	shapeRes = abs(shapeRes);
	//shapeRes = smoothstep(0.0, 0.1, shapeRes);
	shapeRes = 0.02 / shapeRes;
	
	color *= shapeRes;

	gl_FragColor = vec4(
		mix(
			vec3(0.337, 0.522, 0.988), // rgb(242, 143, 147)
            vec3(0.956, 0.965, 1.0), // rgb(126,  12, 214)
			bounceInOut(lines * 0.5 + 0.5)
		),
		1.
	);
}
