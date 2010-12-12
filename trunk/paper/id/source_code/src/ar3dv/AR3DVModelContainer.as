package ar3dv
{
	import flash.events.ErrorEvent;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.SecurityErrorEvent;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.utils.Dictionary;
	
	import org.papervision3d.core.math.Matrix3D;
	import org.papervision3d.objects.DisplayObject3D;
	import org.papervision3d.objects.parsers.DAE;
	import org.papervision3d.objects.parsers.Max3DS;
	
	public class AR3DVModelContainer extends EventDispatcher
	{
		public static const CONFIG_FILE_LOADED:String = "configFileLoaded";
		public static const CONFIG_FILE_PARSED:String = "configFileParsed";
		
		private var _configFileLoader:URLLoader;
		private var _containerByPatternId:Array;
		private var _modelContainers:Array;
		private var _modelAR3DV:AR3DVModel;
		
		public function AR3DVModelContainer(url:String) 
		{
			_configFileLoader = new URLLoader();
			_configFileLoader.addEventListener(IOErrorEvent.IO_ERROR, this.onConfigLoaded);
			_configFileLoader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, this.onConfigLoaded);
			_configFileLoader.addEventListener(Event.COMPLETE, this.onConfigLoaded);
			_configFileLoader.load(new URLRequest(url));
		}
		
		private function debug(info:String):void{
			trace("[AR3DVModelContainer] "+info);
		}
		
		public function get containerByPatternId():Array{
			return _containerByPatternId;
		}
		
		public function getModelContainer(id:int):DisplayObject3D{	
			if(this.hasModel(id)){
				return _containerByPatternId[id];	
			}else{
				return null;
			}
		}
		
		public function setVisible(id:int,visibility:Boolean):void{
			this.getModelContainer(id).visible = visibility;
		}
		
		public function setTransform(id:int,matrix:Matrix3D):void{
			this.getModelContainer(id).transform = matrix;
		}
		
		public function hasModel(id:int):Boolean{
			return _containerByPatternId[id]!=null;
		}
		
		private function onConfigLoaded (evt:Event) :void {
			_configFileLoader.removeEventListener(IOErrorEvent.IO_ERROR, this.onConfigLoaded);
			_configFileLoader.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, this.onConfigLoaded);
			_configFileLoader.removeEventListener(Event.COMPLETE, this.onConfigLoaded);
			
			if (evt is ErrorEvent) {
				var errorEvent:ErrorEvent = new ErrorEvent(ErrorEvent.ERROR);
				errorEvent.text =  ErrorEvent(evt).text;
				this.dispatchEvent(errorEvent);
				return;
			}
			
			this.debug("proses file konfigurasi...");
			this.parseConfigFile(new XML(_configFileLoader.data as String));
			_configFileLoader.close();
			_configFileLoader = null;
		}
		
		private function parseConfigFile(data:XML):void{
			var modelList:XMLList = data.models;
			_containerByPatternId = new Array();
			_modelContainers = new Array();
			for each (var elem:XML in modelList.model) {
				this.debug("load model :"+elem.@name);
				var modelAR3DV:AR3DVModel = new AR3DVModel(elem.@name,elem.@source_dir,elem.@source,int(elem.@pattern),elem.@type);
				if(modelAR3DV.model!=null){
					modelAR3DV.addEventListener(AR3DVModelEvent.LOADED,this.onModelsLoaded);
					modelAR3DV.setRotationXYZ(int(elem.@x),int(elem.@y),int(elem.@z));
					modelAR3DV.scale = int(elem.@scale);
					modelAR3DV.load();
				}			
				_modelContainers[int(elem.@pattern)] = modelAR3DV;
			}
		}
		
		private function onModelsLoaded(evt:AR3DVModelEvent):void{
			var modelAR3DV:AR3DVModel = _modelContainers[evt.patternId];
			var container:DisplayObject3D = new DisplayObject3D();
			/*
			if(modelAR3DV.type == "DAE"){
				container.addChild(DAE(modelAR3DV.model));
			}else{
				container.addChild(Max3DS(modelAR3DV.model));
			}
			*/
			container.addChild(modelAR3DV.model);
			container.visible = false;
			_containerByPatternId[evt.patternId] = container;
			
			var parsed:Boolean = true;
			//cek apakah sudah semua model ter-load
			for(var i:String in _modelContainers){
				parsed = parsed && _modelContainers[int(i)].loaded;
			}
			
			if (parsed) {
				this.debug(" PARSED");
				_modelContainers[evt.patternId].removeEventListener(AR3DVModelEvent.LOADED,this.onModelsLoaded);
				this.dispatchEvent(new Event(CONFIG_FILE_PARSED));
			}
		}
	}
}