Shader "Unlit/TimeLine"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _CharTex ("CharTexture", 2D) = "white" {}
        _Size("Size", float) = 5.0
        [ShowAsVector2] _SizeScale("Scale", vector)      = (5.0, 5.0, 0.0, 0.0)
        [ShowAsVector2] _Offset("Offset", vector)    = (1.0, 1.0, 0.0, 0.0)
        
        _Thickness("Thickness", float) = 0.1


        _ChartColor("Color", Color)      = (1.0, 0.0, 0.0, 0.0)
        _BackgroundColor("Color", Color) = (0.0, 0.0, 0.0, 0.0)
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100
        
        Pass
        {
            CGPROGRAM

            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog
            
            #include "UnityCG.cginc"
            
            #define Epsilon 0.0001

            struct appdata
            {
              float4 vertex : POSITION;
              float2 uv : TEXCOORD0;
            };
            
            struct v2f
            {
              float2 uv : TEXCOORD0;
              UNITY_FOG_COORDS(1)
              float4 vertex : SV_POSITION;
            };
            
            sampler2D _MainTex;
            float4 _MainTex_ST;
            
            sampler2D _CharTex;
            float4 _CharTex_ST;

            float _Size;
            float2 _Scale;
            float2 _Offset;
            float  _Thickness;

            float2 _SizeScale;

            //像素比例
            float _UIPixelRatio;
            //绘图比例
            float2 _UIDrawRatio;
            //真实比例
            float2 _UIRealRatio;
            //UI绘图空间
            float2 _UIDrawUV;
            //UI真实空间
            float2 _UIRealUV;

            void InputConstraint();
            void InitializeScale(float2 uv);
            
            float4 DrawChart();
            float4 DrawAxis();
            float4 DrawAxisLine(float xory); 
            float4 DrawAxisXY(float thickness, float xory);
            float4 DrawCoordinate(float xory);
                   
            float  DrawSegment(float2 pointA, float2 pointB, float thickness);
            float  DrawAbsoluteSegment(float2 _UIRealUV, float2 pointA, float2 pointB, float thickness);
            float  RoundBy(float value, float step);

            int ConvertValueToTickLevel(float xory);
           
            float4 GetNumber(float2 uv, int index, int num);
            float4 DrawNumber(float2 uv, float val, float div, int units);
            float4 GetWord(float2 uv, float ascNum);



            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }
            
            fixed4 frag (v2f i) : SV_Target
            {
                //初始化颜色
                float4 col = float4(0.0, 0.0, 0.0, 0.0);
                
                i.uv *= _Size;
                _SizeScale = _Size * _SizeScale;

                //输入约束
                InputConstraint();

                
                //通过标准空间初始化几种参数
                InitializeScale(i.uv);

                //画图表
                col += DrawChart();
            
                return col;
            }
            
            void InputConstraint() {
                if(_SizeScale.x < 1) _SizeScale.x = 1;
                if(_SizeScale.y < 0) _SizeScale.y = 1;
            }

            ///初始化尺寸参数
            void InitializeScale(float2 uv) {
                //像素数量
                float dx = ddx(uv.x);
                float dy = ddy(uv.y);
            
                //x与y的像素比
                _UIPixelRatio = dy / dx;
            
                //绘图比例
                _UIDrawRatio = float2(_UIPixelRatio, 1);

                //UI绘图空间
                _UIDrawUV = uv * _UIDrawRatio;
                _UIDrawUV = _UIDrawUV - _Offset;// _SizeScale;

                //真实比例
                _UIRealRatio = float2(_UIPixelRatio * _SizeScale.x, _SizeScale.y);
                //UI真实空间
                _UIRealUV = uv * _UIDrawRatio * _SizeScale;
                //对UI真实空间进行偏移修正
                _UIRealUV -= _Offset * _SizeScale;
            }
            
            //画图表
            float4 DrawChart() {
                float4 col = float4(0.0, 0.0, 0.0, 0.0);
            
                col += DrawAxis();
            
                return col;
              
            }
            
            //画坐标轴
            float4 DrawAxis() {
                float4 col = float4(0.0, 0.0, 0.0, 0.0);
            
                col = max(DrawAxisLine(0.0), col);
                col = max(DrawAxisLine(1.0), col);
            
                return col;
            }
            
            //画坐标轴线
            float4 DrawAxisLine(float xory) {
                float4 col = float4(0.0, 0.0, 0.0, 0.0);
                
                //画坐标轴
                col = max(DrawAxisXY(_Thickness, xory), col);
                col = max(DrawCoordinate(xory), col);

                
                


                
            
                col.r = max(DrawSegment(float2(2,1), float2(4,2), _Thickness / 2.0), col.r);
            
                return col;
            }

            float DrawSegment(float2 pointA, float2 pointB, float thickness) {
                float2 a = pointA / _SizeScale;
                float2 b = pointB / _SizeScale;
                float2 p = _UIDrawUV;
                
                float2 ba = b - a; 
                float2 pa = p - a;
                float  h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
                float2 d = pa - h * ba;
                float  len = length(d);

                return smoothstep(thickness, 0, len);
            }

            float4 DrawAxisXY(float thickness, float xory) {
                float4 col = float4(0.0, 0.0, 0.0, 0.0);
                float  len = abs(lerp(_UIDrawUV.x, _UIDrawUV.y, xory));
                
                col.r = smoothstep(thickness, 0, len);
                
                return col;
            }
            
            float4 DrawCoordinate(float xory) {
                float4 col = float4(0.0, 0.0, 0.0, 0.0);

                float timeLevelArr[7]   = {1,   15,  60,  900,  3600,  21600,  43200};
                float timeUnitArr[7]    = {115, 115, 115, 109,  109,   104,    104};
                float timeUnitDivArr[7] = {1,   1,   1,   60,   60,    3600,   3600};
                float timeRepeatArr[7]  = {60,  60,  60,  3600, 3600,  43200,  43200};
                float normalLevelArr[7] = {1,   10,  100, 1000, 10000, 100000, 100000};



                float coorHeight = 0.5; float curCoorHeight = coorHeight;
                float scale = lerp(_SizeScale.x, _SizeScale.y, xory);
                float scaleOther = lerp(_SizeScale.x, _SizeScale.y, 1.0 - xory);
                float realA  = lerp(_UIRealUV.x, _UIRealUV.y, xory);
                float realB  = lerp(_UIRealUV.y, _UIRealUV.x, xory);
                float drawA  = lerp(_UIDrawUV.y, _UIDrawUV.x, xory);
                float drawB  = lerp(_UIDrawUV.y, _UIDrawUV.x, xory);
                
                //将值转换成级数
                float logLevel = 0.0;
                
                for(int i = 0; i < 6; i++) {
                    float tempMin = lerp(timeLevelArr[i], normalLevelArr[i], xory);
                    float tempMax = lerp(timeLevelArr[i+1], normalLevelArr[i+1], xory);
                    if(scale >= tempMin && scale <= tempMax) {
                        logLevel = i + 0;       
                    }             
                }


                
                float segment = 0.0; 
                float heightAnimation = 0.0;
                float animation = 0.0;
                float alpha = 0.0;
                
                

                //只显示当前级数的周围的三个层级
                for(int curLevel = logLevel; curLevel < min(logLevel + 4, 13); curLevel++) {
                    
                    //将级数转换为级数值
                    int levelVal =  lerp(timeLevelArr[curLevel], normalLevelArr[curLevel], xory);
                    //以指定宽带归类实际值
                    float stepVal = RoundBy(realA, levelVal);

                    animation = clamp(levelVal / scale, 0.0, 1.0);

                    //heightAnimation = clamp(,curLevel,);
                    //线段高度
                    curCoorHeight = coorHeight * (curLevel - (logLevel - 0.0) + 1) / 4.0;
                    
                    float2 pointA = float2(stepVal, curCoorHeight * scaleOther);
                    float2 pointB = float2(stepVal, 0.0);

                    float2 fixedPointA = lerp(pointA.xy, pointA.yx, xory);
                    float2 fixedPointB = lerp(pointB.xy, pointB.yx, xory);

                    //画从坐标轴到上方的线段
                    segment = DrawSegment(fixedPointA, fixedPointB, _Thickness / 2.0);
                    
                    //在缩放时调整每个级数的透明度，达成淡入淡出的效果
                    alpha = 1.0;//clamp(((curLevel / scale) - .05) * 20.0 , 0,1);

                    //叠加多级
                    col.r = max(segment * alpha, col.r);


                    if (curLevel == logLevel && xory == 0) {
                        float halfLen = levelVal * .5;
                        float textWidth = levelVal * 1;
                        float textHeight = textWidth * .2 / _SizeScale.x;
                    
                        float2 textUV = float2((realA - (stepVal - halfLen)) /  (halfLen * 2),
                                               drawB / textHeight + 1); 
                        if(textUV.y > 1.0 || textUV.y < 0) textUV.y = 0.0;
                        if(textUV.x > 1.0 || textUV.x < 0) textUV.x = 0.0;
                        if(textUV.x * textUV.y <= 0) textUV.xy = float2(0.0, 0.0);
                        //(_UIRealUV.y + (_SizeScale.y / 10 + textHeight)) /  textHeight
                    
                        //col.gb = max(textUV.xy, col.gb);

                        //textUV.x = textUV.x % (1/8.0) * 5;

                        col = max(DrawNumber(textUV, stepVal, timeUnitDivArr[curLevel], timeUnitArr[curLevel]), col);


                    }

                   //col.r = max(GetWord(_UIRealUV, 38).r, col.r);
                }

                return col;

            }
            

            float RoundBy(float value, float step) {
                int d = abs(value / step);
                float r = abs(value % step);
                float halfStep = step / 2.0;

                if(r > halfStep) d += 1.0;
               

                return value>0? step * d: -step * d;
            }

            int ConvertValueToTickLevel(float scale) {
                int lvlA = ceil(log10(scale));
                int lvlB = ceil(log10(scale / 5.0));

                return lvlA > lvlB ? (lvlA * 2) : (lvlA * 2 + 1);
            }


             
            #define WORDWIDTH 0.8

            float4 GetWord(float2 uv, float ascNum) {
             
                int a = ascNum / 16.0;
                int b = ascNum % 16.0;
                float step = 1.0 / 16.0;

                float2 wuv = uv / 16.0;
                wuv.x = wuv.x + step * b;
                wuv.y = wuv.y + step * (15 - a);

                wuv.x = wuv.x + (1 - WORDWIDTH) / 2.0 / 16.0;//.008;
                
                return tex2D(_CharTex, wuv);
            }

            float4 GetNumber(float2 uv, int index, int num) {
                num += 48.0;
                return GetWord(uv - float2(index, 0.0) * WORDWIDTH + float2(0.10, 0.0), num).x;
            }

            float4 DrawNumber(float2 uv, float val, float div, int units) {
                float4 col = float4(0.0, 0.0, 0.0, 0.0);

                //如果在坐标区间外返回空
                if(uv.x < 0 || uv.x > 1.0 || uv.y < 0 || uv.y > 1.0) return col;

                //坐标区间内的字符数
                int wNum = floor(5.0 / WORDWIDTH);

                //计算字符的个数和起始位置
                int length = 1; 
                if(val != 0) {
                    //length = floor(log10(abs(val) * 1.0 / div)) + 1;
                    //length = 1;
                    length = floor(log10(abs(val) / (div - Epsilon))) + 1;

                }
                //当字符数量大于可容纳数量，返回错误
                if(length > wNum) return float4(1.0, 1.0, 0.0, 0.0);

                //计算字符的个数和起始位置
                int start = floor((wNum - length) / 2.0);


                //字符最大长度和单位长度
                float maxW = wNum * WORDWIDTH;
                float percent = maxW / 5.0;

                //居中偏移x
                float fixedX = (2.0 * uv.x - 1.0 + percent) / (percent * 2.0);
                
                if(fixedX < 0.0) {fixedX  = 0.0; col.b = 0.0;}
                if(fixedX > 1.0) {fixedX = 0.0; col.b = 0.0;}
                            
                uv.x = (fixedX * maxW) % WORDWIDTH;

                int offs = floor((fixedX * maxW) / WORDWIDTH);
                
                if(offs < start && val >= 0 || offs < start - 1 && val < 0 || offs > (start + length)) {
                    return col;    
                }

                if(offs == start + length) {
                    col.rgb = GetWord(uv, units).r;
                    return col;
                }
                
                int exp = (length - 1) - (offs - start);
                float p =  pow(10.0, exp);
                if(p == 0) p = 1;
                
                //(val * 1.0 / div) 
                int i = floor( val / (div - Epsilon) / p % 10.0);
                
                col.rgb = GetWord(uv, 48 + i).r;
                
                if(val < 0 && offs < start) {
                    col.rgb = GetWord(uv, 45).r;
                }
                
                return col;
            }

            float log(float x, float y) {
                return log10(y) / log10(x);
            }

            ENDCG
        }
    }
}
