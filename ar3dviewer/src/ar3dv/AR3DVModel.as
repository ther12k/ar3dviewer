package ar3dv
{
	/* Flash event package*/
	import flash.events.ErrorEvent;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.SecurityErrorEvent;
	import flash.utils.getTimer;
	
	import org.papervision3d.events.FileLoadEvent;
	import org.papervision3d.objects.DisplayObject3D;
	import org.papervision3d.objects.parsers.DAE;
	import org.papervision3d.objects.parsers.Max3DS;
	import org.papervision3d.objects.parsers.KMZ;
	
	public class AR3DVModel extends EventDispatcher
	{
		//variabel untuk mengetahui objek sudah terload atau belum
		private var _loaded:Boolean;
		//nama file
		private var _source:String;
		//source directory
		private var _dir:String;
		//type file
		private var _type:String;
		//nama model
		private var _name:String;
		//variabel objek yang akan di-load, akan di isi dengan DAE, 3DS dan KMZ
		private var _model:DisplayObject3D;
		//id pattern model 3D
		private var _id:int;
		//untuk menghitung lama waktu load objek
		private var _timer:Number;
		
		public function AR3DVModel(name:String,dir:String,source:String,id:int,type:String="") 
		{
			switch(type){
				case "3DS":
					_model = new Max3DS(name);
					break;
				case "DAE":
					_model = new DAE(true,name,true);
					break;	
				case "KMZ":
					_model = new KMZ();
			}
			_name = name;
			_type = type;
			_dir = dir;
			_source = source;
			_id = id;
			_loaded = false;
		}
		
		
		
		public function get type():String{ 
			return _type;
		}
		
		public function get name():String{ 
			return _name;
		}
		
		public function get id():int{ 
			return _id;
		}
		
		public function get timer():Number{ 
			return _timer;
		}
		
		public function get loaded():Boolean{ 
			return _loaded;
		}
		
		public function get model():DisplayObject3D{ 
			return _model;
		}
		
		public function set scale(scale:Number):void{
			_model.scale = scale;
		}
		
		public function load():void{
			if(_loaded) {
				this.debug(_id+" sudah di-load");
				_loaded = true;
				dispatchEvent(new AR3DVModelEvent(AR3DVModelEvent.LOADED,_id));
				return;
			}
			this.addListener();
			this.loadSource();
		}
		
		public function setRotationXYZ(x:int,y:int,z:int):void{
			_model.rotationX = x;
			_model.rotationY = y;
			_model.rotationZ = z;
		}
		
		public function setPositionXYZ(x:int,y:int,z:int):void{
			_model.x = x;
			_model.y = y;
			_model.z = z;
		}
		
		private function debug(info:String):void{
			trace("[AR3DVModel] "+info);
		}
		
		private function addListener():void{
			_model.addEventListener(FileLoadEvent.LOAD_COMPLETE, this.onLoadSucceded);
			_model.addEventListener(FileLoadEvent.LOAD_ERROR, this.onLoadError);
			_model.addEventListener(FileLoadEvent.SECURITY_LOAD_ERROR, this.onLoadError);
			_model.addEventListener(IOErrorEvent.IO_ERROR, this.onLoadError);
		}
		
		private function removeListener():void{
			_model.removeEventListener(FileLoadEvent.LOAD_COMPLETE, this.onLoadSucceded);
			_model.removeEventListener(FileLoadEvent.LOAD_ERROR, this.onLoadError);
			_model.removeEventListener(FileLoadEvent.SECURITY_LOAD_ERROR, this.onLoadError);
			_model.removeEventListener(IOErrorEvent.IO_ERROR, this.onLoadError);
		}
		
		private function loadSource():void{
			_timer = getTimer();
			switch(type){
				case "3DS":
					Max3DS(_model).load(_dir+_source,null,_dir);
					break;
				case "DAE":
					DAE(_model).load(_dir+_source);
					break;
				case "KMZ":
					KMZ(_model).load(_dir+_source);
			}
		}
		
		private function onLoadSucceded (evt:Event) :void {
			this.debug(_name+" sudah di-load dalam waktu "+ String(getTimer() - _timer)+" ms");
			_loaded = true;
			this.removeListener();
			this.dispatchEvent(new AR3DVModelEvent(AR3DVModelEvent.LOADED,_id));
		}
		
		private function onLoadError (evt:Event) :void {
			this.debug(_name+" gagal di-load");
			_loaded = true;
			
			this.removeListener();
			this.dispatchEvent(new AR3DVModelEvent(AR3DVModelEvent.FAILED,_id));
		}
	}
}