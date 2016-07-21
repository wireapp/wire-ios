// 
// Wire
// Copyright (C) 2016 Wire Swiss GmbH
// 
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
// 
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
// 
// You should have received a copy of the GNU General Public License
// along with this program. If not, see http://www.gnu.org/licenses/.
// 


varying highp vec2 textureCoordsOut;

uniform sampler2D textureImage;
uniform mediump float textureAspect;
uniform highp float fractionalWidthOfPixel;


void main()
{
    highp float dotScaling = 0.9;
    
    highp vec2 sampleDivisor = vec2(fractionalWidthOfPixel, fractionalWidthOfPixel / textureAspect);
    highp vec2 samplePos = textureCoordsOut - mod(textureCoordsOut, sampleDivisor) + 0.5 * sampleDivisor;
    highp vec2 textureCoordinateToUse = vec2(textureCoordsOut.x, (textureCoordsOut.y * textureAspect + 0.5 - 0.5 * textureAspect));
    highp vec2 adjustedSamplePos = vec2(samplePos.x, (samplePos.y * textureAspect + 0.5 - 0.5 * textureAspect));
    highp float distanceFromSamplePoint = distance(adjustedSamplePos, textureCoordinateToUse);
    highp float edge0 = (fractionalWidthOfPixel * 0.5) * dotScaling * 0.9;
    highp float edge1 = (fractionalWidthOfPixel * 0.5) * dotScaling * 1.1;
    lowp float checkForPresenceWithinDot = smoothstep(edge1, edge0, distanceFromSamplePoint);
    
    lowp vec4 inputColor = texture2D(textureImage, samplePos);
    
    gl_FragColor = vec4(inputColor.rgb, inputColor.a * checkForPresenceWithinDot);
}
