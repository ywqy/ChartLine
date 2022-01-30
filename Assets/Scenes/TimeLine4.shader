Shader "Custom/TimeLine4"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _ValueTex("Texture1", 2D) = "black" {}
        _CoorTex("Coordinate", 2D) = "black" {}

        _CoorOffset("Coordinate Offset", vector) = (0.8, 0.2, 0.0, 0.0)
        _CoorSize("Coordinate Size", float) = 0.005

        _BackgroundColor("Background Color", Color) = (0.9, 0.9, 0.9, 1.0)
        _WordColor("Word Color", Color) = (0.1, 0.1, 0.1, 1.0)
        _CurveLineColor("Curve Line Color", Color) = (0.1, 0.1, 0.1, 1.0)

        _LineColor1("Line Color1", vector) = (0.0, 0.0, 0.0, 0.0)
        _LineColor2("Line Color2", vector) = (0.0, 0.0, 0.0, 0.0)
        _LineColor3("Line Color3", vector) = (0.0, 0.0, 0.0, 0.0)
        _LineColor4("Line Color4", vector) = (0.0, 0.0, 0.0, 0.0)


        _Scale ("Scale", vector) = (5.0, 5.0, 0.0, 0.0)
        _MouseUV("MouseUV", vector) = (0.0, 0.0, 0.0, 0.0)

        _Offset("Offset", vector) = (0.0, 0.0, 0.0, 0.0)
        _ScaleUV   ("ScaleUV", vector) = (0.15, 0.15, 0.0 , 0.0)
        _CurveColor ("Curve Color", Color) = (0.1, 0.1, 0.1, 1.0)

        _Line1Len("Line 1 Length", int) = 0
        _Line2Len("Line 2 Length", int) = 0
        _Line2Len("Line 3 Length", int) = 0
        _Line2Len("Line 4 Length", int) = 0

        //_timePMTX_ArrLen("Point Count", int) = 0
        _NeedShowLine1("Need Show Line1", int) = 0
        _NeedShowLine2("Need Show Line2", int) = 0
        _NeedShowLine3("Need Show Line3", int) = 0
        _NeedShowLine4("Need Show Line4", int) = 0

         
         // required for UI.Mask
         _StencilComp ("Stencil Comparison", Float) = 8
         _Stencil ("Stencil ID", Float) = 0
         _StencilOp ("Stencil Operation", Float) = 0
         _StencilWriteMask ("Stencil Write Mask", Float) = 255
         _StencilReadMask ("Stencil Read Mask", Float) = 255
         _ColorMask ("Color Mask", Float) = 15

    }
    SubShader
    {
        Tags
        {
            "RenderType"="Opaque" 
            "Queue"="Transparent"
            "IgnoreProjector"="True"
            "RenderType"="Transparent"
            "PreviewType"="Plane"
            "CanUseSpriteAtlas"="True"
        }
        LOD 100

        // required for UI.Mask
        Stencil
        {
            Ref [_Stencil]
            Comp [_StencilComp]
            Pass [_StencilOp] 
            ReadMask [_StencilReadMask]
            WriteMask [_StencilWriteMask]
        }
        
        Cull Off
        Lighting Off
        ZWrite Off
        ZTest [unity_GUIZTestMode]
        //Blend SrcAlpha OneMinusSrcAlpha
        ColorMask [_ColorMask]

        Pass
        {
            CGPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            #define PI 3.14159265359
            #define Epsilon 0.000001
            //------------------------------
            //主贴图
            sampler2D _MainTex;
            float4 _MainTex_ST;

            uniform float4x4 _RangeMTX;

            float2 _CoorOffset;
            float _CoorSize;

            //全局缩放
            float2 _Scale;
            //偏移
            float2 _Offset;
            //鼠标位置
            float4 _MouseUV;
            //x与y的比例
            float dRatio;
            //------------------------------
            //int _timePMTX_ArrLen;
            //float4x4 _timePMTX_Arr[1000];
            int _Line1Len;
            int _Line1PointNum;
            int _Line2Len;
            int _Line2PointNum;
            int _Line3Len;
            int _Line3PointNum;
            int _Line4Len;
            int _Line4PointNum;
            float4x4 _Line1_Arr[250];
            float4x4 _Line2_Arr[250];
            float4x4 _Line3_Arr[250];
            float4x4 _Line4_Arr[250];

            float4 _LineColor1;
            float4 _LineColor2;
            float4 _LineColor3;
            float4 _LineColor4;
            //------------------------------
            
            float2 _uvScale = float2(0.0f, 0.0f);
            
            float3 _BackgroundColor = float3(.1f, .1f, .1f);
            float3 _WordColor = float3(0.9, 0.9, 0.9);
            float3 _CurveLineColor = float3(0.9, 0.0, 0.0);
            //------------------------------

            float _NeedShowLine1;
            float _NeedShowLine2;
            float _NeedShowLine3;
            float _NeedShowLine4;

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f {
                float4 vertex : SV_POSITION;
                float2 uv: TEXCOORD0;
            };


            

            //变换为等距UV
            float2 SetEquidistantUV(float2 uv){
                //像素数量
                float dx = ddx(uv.x);
                float dy = ddy(uv.y);

                //x与y的比例
                dRatio = dy / dx;

                _uvScale = float2(dRatio * _Scale.x, _Scale.y);

                float2 uv1 = (0.0, 0.0);
                uv1.x = _uvScale.x * uv.x;
                uv1.y = _uvScale.y * uv.y;
                
                return uv1;
            }

            float2 GetUVPoint(float2 p) {

                float2 offsetedUV = p + _CoorOffset * _uvScale;


                return offsetedUV;
            }

            
            

            //划线
            float segment(in float2 p, in float2 a, in float2 b) {
                float2 ba = b - a;
                float2 pa = p - a;
                
                float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);

                float2 d = pa - h * ba;
                //d.y /= _Scale.y;
                //float dx = d.x ;//* _uvScale.x / dRatio;
                //float dy = d.y / 10;
                //return length(float2(dx, dy));

                return length(d);
            }

            float4 DrawLine1(float2 uv) {
               
                float4 col = float4(0,0,0,0);

                float2 preP = _Line1_Arr[0][0].xy;
                for(int i = 0; i < _Line1Len; i++) 
                {
                    for (int r = 0; r < 4; r++) 
                    {
                       for(int c =0; c<2; c++)
                       {
                           if((i * 8 + r * 2 + c) >= _Line1Len) break;
                           float2 p = float2(_Line1_Arr[i][r][c * 2], _Line1_Arr[i][r][c * 2 + 1]);
                           float len = smoothstep(0.1, 0, segment(uv, p, preP));
                           col.rgb += len * _LineColor1;

                           preP = p;
                       }
                    }
                }
                return col;
            }

            float4 DrawLine2(float2 uv) {
               
                float4 col = float4(0,0,0,0);

                float2 preP = _Line2_Arr[0][0].xy;
                for(int i = 0; i < _Line2Len; i++) 
                {
                    for (int r = 0; r < 4; r++) 
                    {
                       for(int c =0; c<2; c++)
                       {
                      if((i * 8 + r * 2 + c) >= _Line2Len) break;
                           float2 p = float2(_Line2_Arr[i][r][c * 2], _Line2_Arr[i][r][c * 2 + 1]);
                           float len = smoothstep(0.1, 0, segment(uv, p, preP));
                           col.rgb +=len * _LineColor2;

                           preP = p;
                       }
                    }
                }
                return col;
            }

            float4 DrawLine3(float2 uv) {
               
                float4 col = float4(0,0,0,0);

                float2 preP = _Line3_Arr[0][0].xy;
                for(int i = 0; i < _Line3Len; i++) 
                {
                    for (int r = 0; r < 4; r++) 
                    {
                       for(int c =0; c<2; c++)
                       {
                      if((i * 8 + r * 2 + c) >= _Line3Len) break;
                           float2 p = float2(_Line3_Arr[i][r][c * 2], _Line3_Arr[i][r][c * 2 + 1]);
                           float len = smoothstep(0.1, 0, segment(uv, p, preP));
                           col.rgb +=len * _LineColor3;

                           preP = p;
                       }
                    }
                }
                return col;
            }

            float4 DrawLine4(float2 uv) {
               
                float4 col = float4(0,0,0,0);

                float2 preP = _Line4_Arr[0][0].xy;
                for(int i = 0; i < _Line4Len; i++) 
                {
                    for (int r = 0; r < 4; r++) 
                    {
                       for(int c =0; c<2; c++)
                       {
                           if((i * 8 + r * 2 + c) >= _Line4Len) break;
                           float2 p = float2(_Line4_Arr[i][r][c * 2], _Line4_Arr[i][r][c * 2 + 1]);
                           float len = smoothstep(0.1, 0, segment(uv, p, preP));
                           col.rgb +=len * _LineColor4;

                           preP = p;
                       }
                    }
                }
                return col;
            }

            float4 DrawMouse(float2 uv){
                float4 col = float4(0.0, 0.0, 0.0, 0.0);

                float2 p = _MouseUV.xy;
                p.x *= _uvScale.x;
                p.y *= _uvScale.y;

                float2 fx = smoothstep(0.1 * _uvScale.x / dRatio, 0, length(uv.x - p.x));
                float2 fy = smoothstep(0.1 * _uvScale.y, 0, length(uv.y - p.y));

                float f = fx * fx * fx * fy * fy * fy;
                col.rgb += smoothstep(float3(0.1,0.1,0.1), float3(1, 1, 1), f);

                int x = p.x - (0.8 * _uvScale.x);

                return col;
            }

            //画坐标上的点
            float4 DrawPoint(float2 uv) {
                float4 col = float4(0.0, 0.0, 0.0, 0.0);

                //使uv以0.1的间隔转换为索引
                int x = round(uv.x * 10.0);
                
                if(_Line1Len == 0) return col;

                for(int i = 0; i < _Line1Len; i++) 
                {
                    for (int r = 0; r < 4; r++) 
                    {
                       for(int c =0; c<2; c++)
                       {
                           
                           float2 p = float2(_Line1_Arr[i][r][c * 2], _Line1_Arr[i][r][c * 2 + 1]);
                           
                           float2 fx = smoothstep(0.05 * _uvScale.x / dRatio, 0, length(uv.x - p.x));
                           float2 fy = smoothstep(0.05 * _uvScale.y, 0, length(uv.y - p.y));
                           
                           float f = fx * fx * fx * fy * fy * fy * 2;
                           float len = smoothstep(1, 0, 1 - f);
                           
                           float3 v = len * _LineColor1;
                           
                           float avg = log10(_Scale.x + _Scale.y);
                           if(v.x < 0.05 * avg) v.x = 0.0;
                           if(v.y < 0.05 * avg) v.y = 0.0;
                           if(v.z < 0.05 * avg) v.z = 0.0;
                           col.rgb += v;
                       }
                    }
                }

                for(int i = 0; i < _Line2Len; i++) 
                {
                    for (int r = 0; r < 4; r++) 
                    {
                       for(int c =0; c<2; c++)
                       {
                      
                           float2 p = float2(_Line2_Arr[i][r][c * 2], _Line2_Arr[i][r][c * 2 + 1]);
                           
                           float2 fx = smoothstep(0.05 * _uvScale.x / dRatio, 0, length(uv.x - p.x));
                           float2 fy = smoothstep(0.05 * _uvScale.y, 0, length(uv.y - p.y));
                           
                           float f = fx * fx * fx * fy * fy * fy * 2;
                           float len = smoothstep(1, 0, 1 - f);
                           
                           float3 v = len * _LineColor2;
                           
                           float avg = log10(_Scale.x + _Scale.y);
                           if(v.x < 0.05 * avg) v.x = 0.0;
                           if(v.y < 0.05 * avg) v.y = 0.0;
                           if(v.z < 0.05 * avg) v.z = 0.0;
                           col.rgb += v;
                       }
                    }
                }

                for(int i = 0; i < _Line3Len; i++) 
                {
                    for (int r = 0; r < 4; r++) 
                    {
                       for(int c =0; c<2; c++)
                       {
                      
                           float2 p = float2(_Line3_Arr[i][r][c * 2], _Line3_Arr[i][r][c * 2 + 1]);
                           
                           float2 fx = smoothstep(0.05 * _uvScale.x / dRatio, 0, length(uv.x - p.x));
                           float2 fy = smoothstep(0.05 * _uvScale.y, 0, length(uv.y - p.y));
                           
                           float f = fx * fx * fx * fy * fy * fy * 2;
                           float len = smoothstep(1, 0, 1 - f);
                           
                           float3 v = len * _LineColor3;
                           
                           float avg = log10(_Scale.x + _Scale.y);
                           if(v.x < 0.05 * avg) v.x = 0.0;
                           if(v.y < 0.05 * avg) v.y = 0.0;
                           if(v.z < 0.05 * avg) v.z = 0.0;
                           col.rgb += v;
                       }
                    }
                }

                for(int i = 0; i < _Line4Len; i++) 
                {
                    for (int r = 0; r < 4; r++) 
                    {
                       for(int c =0; c<2; c++)
                       {
                      
                           float2 p = float2(_Line4_Arr[i][r][c * 2], _Line4_Arr[i][r][c * 2 + 1]);
                           
                           float2 fx = smoothstep(0.05 * _uvScale.x / dRatio, 0, length(uv.x - p.x));
                           float2 fy = smoothstep(0.05 * _uvScale.y, 0, length(uv.y - p.y));
                           
                           float f = fx * fx * fx * fy * fy * fy * 2;
                           float len = smoothstep(1, 0, 1 - f);
                           
                           float3 v = len * _LineColor4;
                           
                           float avg = log10(_Scale.x + _Scale.y);
                           if(v.x < 0.05 * avg) v.x = 0.0;
                           if(v.y < 0.05 * avg) v.y = 0.0;
                           if(v.z < 0.05 * avg) v.z = 0.0;
                           col.rgb += v;
                       }
                    }
                }

               return col;
            }

            


            #define WORDWIDTH 0.7

            float4 GetWord(float2 uv, float ascNum) {
             
                int a = ascNum / 16.0;
                int b = ascNum % 16.0;
                float step = 1.0 / 16.0;

                float2 wuv = uv / 16.0;
                wuv.x = wuv.x + step * b;
                wuv.y = wuv.y + step * (15 - a);

                wuv.x = wuv.x + (1 - WORDWIDTH) / 2.0 / 16.0;//.008;
                
                return tex2D(_MainTex, wuv);
            }

            float4 GetNumber(float2 uv, int index, int num) {
                num += 48.0;
                return GetWord(uv - float2(index, 0.0) * WORDWIDTH + float2(0.2, 0.0), num).x;
            }


            float3 DrawNumber(float2 uv, int val, int div, int units){
                float3 col = float3(0.0, 0.0, 0.0);

                //如果在坐标区间外返回空
                if(uv.x < 0 || uv.x > 1.0 || uv.y < 0 || uv.y > 1.0) return col;

                //坐标区间内的字符数
                int wNum = floor(5.0 / WORDWIDTH);

                //计算字符的个数和起始位置
                int length = floor(log10(val * 1.0 / div)) + 1;
                int start = floor((wNum - length) / 2.0);

                //当字符数量大于可容纳数量，返回错误
                if(length > wNum) return float4(1.0, 1.0, 0.0, 0.0);

                //字符最大长度和单位长度
                float maxW = wNum * WORDWIDTH;
                float percent = maxW / 5.0;

                //居中偏移x
                float fixedX = (2.0 * uv.x - 1.0 + percent) / (percent * 2.0);
                
                if(fixedX < 0.0) {fixedX  = 0.0; col.b = 0.0;}
                if(fixedX > 1.0) {fixedX = 0.0; col.b = 0.0;}
                            
                uv.x = (fixedX * maxW) % WORDWIDTH;
                
                //col.r = uv.x;

                int offs = floor((fixedX * maxW) / WORDWIDTH);
                
                if(offs < start || offs > (start + length)){
                    return col;    
                }

                if(offs == start + length) {
                    col.rgb = GetWord(uv, units).r;
                    return col;
                }

                int exp = (length - 1) - (offs - start);
                int i = floor((val * 1.0 / div) / pow(10, exp)%10);

                //

                col.rgb = GetWord(uv, 48 + i).r;
                

                

                return col;
            }

            
            float3 DrawCoordinateX(float2 uv){
                float3 c = float3(0.0, 0.0, 0.0);

                float timeLogArray[6] = {1.0, 10.0, 60.0, 600.0, 3600.0, 86400.0};
                float timeLogUnitArray[6] = {98.0, 98.0, 99.0, 99.0, 100.0, 100.0};

                float logLevel = log10(_Scale.x);
                

                for(int i = floor(logLevel - 1); i <= floor(logLevel + 1); i++) {
                    if(i < 0 || i > 6) continue;
                    float xlog = timeLogArray[i];
                    int level = floor(xlog);
                    float gap = level;
                    float halfGap = gap * 0.5;
                    float height = halfGap * (_Scale.y / _Scale.x);
                    
                    if(uv.y > 0 && uv.y < height && abs(uv.x / halfGap) > 1.0 ) {
                        //锯齿波
                        float w = abs(abs(uv.x % gap) - halfGap);
                        //-------------(当前级数的坐标宽度) *（级数缩放）
                        //float width =  (0.96 * halfGap) * pow(0.81,  (logLevel - i));
                        float width =  (0.96 * halfGap) * pow(0.81,  (logLevel - i));
                        c.r += step(width, w) * .75 * _CurveLineColor; 
                    }

                    //x坐标值
                    if(abs(uv.x) > halfGap) {
                        float symbol = abs(uv.x) / uv.x;
                        float w = .9 * gap;
                        float h = gap / 5 * (_Scale.y / _Scale.x);

                        float x = (((uv.x + symbol * w / 2) % gap) * symbol) / w;
                        if(uv.x < 0){
                            x = 1.0 - x;
                        }

                        float y = uv.y / h + 1.1;
                        float2 newUV = float2(x, y);

                        //c += DrawScaleplateNumber(newUV);
                        int val = abs((uv.x + symbol * halfGap) / gap);
                        if(i < 2) {
                            c += DrawNumber(newUV, val * timeLogArray[i], 1, 115) * _WordColor;
                        }else if(i < 4) {
                            c += DrawNumber(newUV, val * timeLogArray[i], 60, 109) * _WordColor;
                        }else if(i < 5) {
                            c += DrawNumber(newUV, val * timeLogArray[i], 3600, 104) * _WordColor;
                        }else if(i < 6) {
                            c += DrawNumber(newUV, val * timeLogArray[i], 86400, 100)* _WordColor;
                        }
                        
                    }
                }
                return c;
            }

            float3 DrawCoordinateY(float2 uv){
                float3 c = float3(0.0, 0.0, 0.0);

                float logLevel = log10(_Scale.y);
                

                for(int level = floor(logLevel - 1); level <= floor(logLevel + 1); level++) {
                    float gap = pow(10.0, level * 1.0);
                    float halfGap = gap * 0.5;
                    float height = halfGap * (_Scale.x / _Scale.y);
                    
                    if(uv.x > -height && uv.x < 0.0 && abs(uv.y / halfGap) > 1.0 ) {
                        //锯齿波
                        float w = abs(abs(uv.y % gap) - halfGap);
                        //-------------(当前级数的坐标宽度) *（级数缩放）
                        float width =  (0.96 * halfGap) * pow(0.81,  (logLevel - level));
                        c += step(width, w) * .75f * _CurveLineColor; 
                    }

                    //y坐标值
                    if(abs(uv.y) > halfGap) {
                        float symbol = abs(uv.y) / uv.y;
                        float w = .9 * gap * (_Scale.x / _Scale.y);
                        float h = .9 * gap * .2f ;

                        float x = (uv.x - w * .1) / w;
                        float y = (uv.y + h / 2) % gap / h ;
                        
                        float2 newUV = float2(x, y);

                        int val = abs((uv.y + (symbol * halfGap)) / gap);
                        c += DrawNumber(newUV, round(val * gap), 1, 32) * _WordColor;
                        
                    }
                }
                return c;
            }

          

            //画坐标
            float4 DrawScaleplate(float2 uv) { 
                float4 col = float4(0.0, 0.0, 0.0, 0.0);

                if(abs(uv.x) < _CoorSize * _Scale.x 
                || abs(uv.y) < _CoorSize * _Scale.y) {
                    col.rgb = _CurveLineColor;
                }

                col.rgb += DrawCoordinateX(uv);
                col.rgb += DrawCoordinateY(uv);

                return col;
            }

            
            //画坐标系
            float4 DrawCoordinate(float2 uv) {
                float4 col = float4(0.0, 0.0, 0.0, 0.0);

                //坐标偏移
                float2 offsetedUV = uv - _CoorOffset * _uvScale;

                col += DrawScaleplate(offsetedUV);
                col += DrawPoint(offsetedUV);

                if(_NeedShowLine1 == 1){
                    col += DrawLine1(offsetedUV);
                }
                if(_NeedShowLine2 == 1){
                    col += DrawLine2(offsetedUV);
                }
                if(_NeedShowLine3 == 1){
                    col += DrawLine3(offsetedUV);
                }
                if(_NeedShowLine4 == 1){
                    col += DrawLine4(offsetedUV);
                }
                
                return col;
            }



            //顶点函数
            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            //片元函数
            fixed4 frag (v2f i) : SV_Target
            {
                float4 col = float4(0.0, 0.0, 0.0, 0.0);

                //变换为等距UV，eqUV作用在UI层
                float2 eqUV = SetEquidistantUV(i.uv);

                //显示鼠标点在等距UV上的位置
                col += DrawMouse(eqUV);

                //画坐标图，内部是坐标层
                col += DrawCoordinate(eqUV);


                if(col.r == 0.0 && col.g == 0.0 && col.b == 0.0) {
                    col.rgb = _BackgroundColor;
                }
                return col;
            }
            ENDCG
        }
    }
    FallBack "Diffuse"
}
