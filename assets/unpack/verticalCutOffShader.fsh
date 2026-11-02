// Shader taken from: http://webglsamples.googlecode.com/hg/electricflower/electricflower.html

#ifdef GL_ES
precision lowp float;
#endif

varying vec4 v_fragmentColor;
varying vec2 v_texCoord;
uniform sampler2D u_texture;

// MGTB_alphaThresholds[0] <- lower value for starting the cut off
// MGTB_alphaThresholds[1] <- top value for ending the cutt off
// MGTB_alphaThresholds[2] <- bottom position of sprite relative to atlas (in percentage)
// MGTB_alphaThresholds[3] <- height of sprite relative to atlas (in percentage)
uniform vec4 MGTB_alphaThresholds;

void main()
{
    float minY = MGTB_alphaThresholds[0];
    float maxY = MGTB_alphaThresholds[1];
    
    float botY = MGTB_alphaThresholds[2];
    float topY = MGTB_alphaThresholds[3];
    
    float yPosition = ((v_texCoord.y - botY) / (topY - botY));
    vec4 fragColor = v_fragmentColor;
	
    float alphaModifier = 1.0;
    
    if (yPosition >= maxY)
    {
        alphaModifier = 0.37;
    }
    else if (yPosition <= minY)
    {
        alphaModifier = 0.0;
    }
    else if (yPosition >= minY)
    {
        alphaModifier =  0.37 * (yPosition - minY) / (maxY - minY);
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
