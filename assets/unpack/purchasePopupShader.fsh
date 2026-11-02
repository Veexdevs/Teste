// Shader taken from: http://webglsamples.googlecode.com/hg/electricflower/electricflower.html

#ifdef GL_ES
precision lowp float;
#endif

varying vec4 v_fragmentColor;
varying vec2 v_texCoord;
uniform sampler2D u_texture;
uniform vec4 MGTB_alphaThresholds;

void main()
{
    float yPosition = gl_FragCoord.y;
    vec4 fragColor = v_fragmentColor;
	
    float alphaModifier = 1.0;
    
    if (yPosition >= MGTB_alphaThresholds[1])
    {
        alphaModifier = 0.37;
    }
    else if (yPosition <= MGTB_alphaThresholds[0])
    {
        alphaModifier = 0.0;
    }
    else if (yPosition >= MGTB_alphaThresholds[0])
    {
        alphaModifier =  0.37 * ((yPosition - MGTB_alphaThresholds[0]) / (MGTB_alphaThresholds[1] - MGTB_alphaThresholds[0]));
    }
    
    if (alphaModifier != 1.0)
    {
        fragColor.r *= alphaModifier;
        fragColor.g *= alphaModifier;
        fragColor.b *= alphaModifier;
        fragColor.a *= alphaModifier;
    }
    gl_FragColor = fragColor * texture2D(u_texture, v_texCoord);
}
