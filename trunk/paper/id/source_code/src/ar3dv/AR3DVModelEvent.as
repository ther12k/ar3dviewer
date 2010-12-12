package ar3dv
{
	import flash.events.Event;
	public class AR3DVModelEvent extends Event {
	
		public static const LOADED:String = "loaded";
		
		private var _patternId:int = 0;
		
		public function get patternId():int {
			return _patternId;
		}
		
		public function AR3DVModelEvent(type:String, id:int){
			super(type, true);
			_patternId = id;
		}
		
		public override function clone():Event {
			return new AR3DVModelEvent(type, _patternId);
		}
	}
}