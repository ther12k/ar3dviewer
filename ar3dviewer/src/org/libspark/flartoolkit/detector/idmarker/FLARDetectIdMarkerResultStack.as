/* 
 * PROJECT: FLARToolKit
 * --------------------------------------------------------------------------------
 * This work is based on the NyARToolKit developed by
 *   R.Iizuka (nyatla)
 * http://nyatla.jp/nyatoolkit/
 *
 * The FLARToolKit is ActionScript 3.0 version ARToolkit class library.
 * Copyright (C)2008 Saqoosha
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this framework; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 * 
 * For further information please contact.
 *	http://www.libspark.org/wiki/saqoosha/FLARToolKit
 *	<saq(at)saqoosha.net>
 * 
 *	http://nyatla.jp/nyatoolkit/
 *	<airmail(at)ebony.plala.or.jp> or <nyatla(at)nyatla.jp>
 * 
 * For further information of this class, please contact.
 * http://sixwish.jp
 * <rokubou(at)gmail.com>
 */
package org.libspark.flartoolkit.detector.idmarker
{
	import jp.nyatla.nyartoolkit.as3.core.types.stack.NyARObjectStack;
	internal class FLARDetectIdMarkerResultStack extends NyARObjectStack
	{
		public function FLARDetectIdMarkerResultStack(i_length:int)
		{
			super(i_length);
		}
		protected override function createArray(i_length:int):Vector.<Object>
		{
			var ret:Vector.<FLARDetectIdMarkerResult>= new Vector.<FLARDetectIdMarkerResult>(i_length);
			for (var i:int =0; i < i_length; i++){
				ret[i] = new FLARDetectIdMarkerResult();
			}
			return Vector.<Object>(ret);
		}	
	}
}