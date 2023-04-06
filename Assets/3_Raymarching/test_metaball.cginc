#define samples 4
#define numballs 8

float hash1(float n)
{
	return frac(sin(n) * 43758.5453123);
}

float2 hash2(float n)
{
	return frac(sin(float2(n, n + 1.0)) * float2(43758.5453123, 22578.1459123));
}

float3 hash3(float n)
{
	return frac(sin(float3(n, n + 1.0, n + 2.0)) * float3(43758.5453123, 22578.1459123, 19642.3490423));
}


void moveMetaballs() {

	float time = _Time.y;

	// move metaballs
	for (int i = 0; i < numballs; i++)
	{
		float h = float(i) / 8.0;
		blobs[i].xyz = 2.0 * sin(6.2831 * hash3(h * 1.17) + hash3(h * 13.7) * time);
		blobs[i].w = 1.7 + 0.9 * sin(6.28 * hash1(h * 23.13));
	}
}

float testMetalballs(float3 p) {
	moveMetaballs();
	return sdMetaBalls(p);
}