Shader "RMFR_Pass15"
{
	Properties
	{
		_MainTex("Texture", 2D) = "white" {}
		_eyeX("_eyeX", float) = 0.5
		_eyeY("_eyeY", float) = 0.5
		_scaleRatio("_scaleRatio", float) = 2.0
		_fx("_fx", float) = 1.0
		_fy("_fy", float) = 1.0
		_iApplyLogMap1("_iApplyRFRMap1", int) = 1
		_SquelchedGridMappingBeta("_SquelchedGridMappingBeta", float ) = 0.0
		_MappingStrategy("_MappingStrategy" , int ) = 0
	}
		SubShader
		{
			// No culling or depth
			Cull Off ZWrite Off ZTest Always

			Pass
			{
				CGPROGRAM
				#pragma vertex vert
				#pragma fragment frag

				#include "UnityCG.cginc"

				struct appdata
				{
					float4 vertex : POSITION;
					float2 uv : TEXCOORD0;
				};

				struct v2f
				{
					float2 uv : TEXCOORD0;
					float4 vertex : SV_POSITION;
				};

				v2f vert(appdata v)
				{
					v2f o;
					o.vertex = UnityObjectToClipPos(v.vertex);
					o.uv = v.uv;
					return o;
				}

				sampler2D _MainTex;
				uniform float _iResolutionX;
				uniform float _iResolutionY;
				uniform float _eyeX;
				uniform float _eyeY;
				uniform float _scaleRatio;
				uniform float _fx;
				uniform float _fy;
				uniform int _iApplyRFRMap1;
				uniform float _SquelchedGridMappingBeta;
				uniform int _MappingStrategy;
				uniform int _DebugMode;

				fixed4 frag(v2f i) : SV_Target
				{
					if (_iApplyRFRMap1 < 0.5)
						return tex2D(_MainTex, i.uv);

				float2 cursorPos = float2(_eyeX, _eyeY); //(0,1)

				float maxDxPos = 1.0 - cursorPos.x;
				float maxDyPos = 1.0 - cursorPos.y;
				float maxDxNeg = cursorPos.x;
				float maxDyNeg = cursorPos.y;

				float norDxPos = _fx * maxDxPos / (_fx + maxDxPos);
				float norDyPos = _fy * maxDyPos / (_fy + maxDyPos);
				float norDxNeg = _fx * maxDxNeg / (_fx + maxDxNeg);
				float norDyNeg = _fy * maxDyNeg / (_fy + maxDyNeg);

				float2 tc = (i.uv - cursorPos); //i.uv.x > cursorPos.x : [0,maxDxPos] i.uv.x < cursorPos.x : [-maxDxNeg, 0]

				float x = tc.x > 0 ? tc.x / maxDxPos : tc.x / maxDxNeg;//[0,1], [-1,0]
				float y = tc.y > 0 ? tc.y / maxDyPos : tc.y / maxDyNeg; 
				if (tc.x >= 0) {
					x = x * norDxPos; //[0,norDxPos]
					x = _fx * x / (_fx - x); //[0, 1]
					x = x + cursorPos.x;
				}
				else {
					x = x * norDxNeg;
					x = _fx * x / (_fx + x);
					x = x + cursorPos.x;
				}

				if (tc.y >= 0) {
					y = y * norDyPos;
					y = _fy * y / (_fy - y);
					y = y + cursorPos.y;
				}
				else {
					y = y * norDyNeg;
					y = _fy * y / (_fy + y);
					y = y + cursorPos.y;
				}

				float2 pq = (float2(x, y)); //0,1 --> 0-1
				fixed4 col = tex2D(_MainTex, pq);


				float u,v;
				x = ( x * 2 ) - 1 ;
				y = ( y * 2 ) - 1 ;
				float xx = pow( x , 2 );
				float yy = pow( y , 2 );



				// elliplical Grid mapping
				// Spuare to Disc
				if( _MappingStrategy == 1 )
				{
					u = x * sqrt( 1 - yy / 2 );
					v = y * sqrt( 1 - xx / 2 );

				}

				//  Squelched Grid Open Mapping
				if( _MappingStrategy == 2 )
				{
					float b = 1.0;
					u = x * sqrt( ( 1 - b * yy ) / ( 1 - b * xx * yy ) );
					v = y * sqrt( ( 1 - b * xx ) / ( 1 - b * xx * yy ) );
					
				}








					
				if( _MappingStrategy > 0 )
				{
					u *= sqrt(2);
					v *= sqrt(2);
				}
				
				u = ( u + 1 ) / 2 ;
				v = ( v + 1 ) / 2 ;


				if( _DebugMode == 0 )
				{
					// if( u < 0.0 || u > 1.0 ){ return fixed4(1,0,0,1); }	
					// if( v < 0.0 || v > 1.0 ){ return fixed4(1,0,0,1); }
					
					u = max( 0 , u );
					u = min( 1 , u );
					v = max( 0 , v );
					v = min( 1 , v );
				}
				if( _DebugMode == 0 )
				{
					if( _MappingStrategy > 0 )
					{
						return tex2D(_MainTex, fixed2( u , v ) );
					}
					else if (_MappingStrategy == 0 )
					{
						return col;
					}
				}
				else if( _DebugMode == 1 )
				{
					if( _MappingStrategy > 0 )
					{
						return fixed4( u , v , 0 , 1 );
					}
					else if( _MappingStrategy == 0 )
					{
						return fixed4( pq , 0 , 1 );
					}
				}

				return col;






					
				
			}
			ENDCG
		}
	}
}