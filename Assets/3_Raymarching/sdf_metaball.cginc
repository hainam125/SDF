#define samples 4
#define numballs 8

float4 blobs[numballs];

float sdMetaBalls(float3 pos)
{
	float m = 0.0;
	float p = 0.0;
	float dmin = 1e20;

	float h = 1.0; // track Lipschitz constant

	for (int i = 0; i < numballs; i++)
	{
		// bounding sphere for ball
		float db = length(blobs[i].xyz - pos);
		if (db < blobs[i].w)
		{
			float x = db / blobs[i].w;
			p += 1.0 - x * x * x * (x * (x * 6.0 - 15.0) + 10.0);
			m += 1.0;
			h = max(h, 0.5333 * blobs[i].w);
		}
		else // bouncing sphere distance
		{
			dmin = min(dmin, db - blobs[i].w);
		}
	}
	float d = dmin + 0.1;

	if (m > 0.5)
	{
		float th = 0.2;
		d = h * (th - p);
	}

	return d;
}