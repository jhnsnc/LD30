package
{
	public class Util
	{
		public static function degToRad(degrees:Number):Number
		{
			return degrees * Math.PI / 180; 
		}
		
		public static function radToDeg(radians:Number):Number
		{
			return radians * 180 / Math.PI; 
		}
		
		public static function distSquared(vx:Number, vy:Number, wx:Number, wy:Number):Number
		{
			return Math.pow(vx - wx, 2) + Math.pow(vy - wy, 2); 
		}
		
		public function Util()
		{
		}
	}
}