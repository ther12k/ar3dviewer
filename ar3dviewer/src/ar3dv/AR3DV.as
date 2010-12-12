package ar3dv
{
	/* FLARManager Framework [http://words.transmote.com/wp/flarmanager/] */ 
	import com.transmote.flar.FLARManager;
	import com.transmote.flar.camera.FLARCamera_PV3D;
	import com.transmote.flar.marker.FLARMarker;
	import com.transmote.flar.marker.FLARMarkerEvent;
	import com.transmote.flar.tracker.FLARToolkitManager;
	import com.transmote.flar.utils.geom.PVGeomUtils;
	
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.ErrorEvent;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.SecurityErrorEvent;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.utils.Dictionary;
	
	import org.libspark.flartoolkit.support.pv3d.FLARCamera3D;
	import org.papervision3d.cameras.Camera3D;
	import org.papervision3d.core.math.Matrix3D;
	import org.papervision3d.lights.PointLight3D;
	import org.papervision3d.materials.shadematerials.FlatShadeMaterial;
	import org.papervision3d.materials.utils.MaterialsList;
	import org.papervision3d.objects.DisplayObject3D;
	import org.papervision3d.objects.parsers.DAE;
	import org.papervision3d.objects.primitives.Cube;
	import org.papervision3d.objects.primitives.Sphere;
	import org.papervision3d.render.LazyRenderEngine;
	import org.papervision3d.scenes.Scene3D;
	import org.papervision3d.view.Viewport3D;
	import org.papervision3d.view.stats.StatsView;
	
	/* model container */
	import ar3dv.AR3DVModelContainer;
	
	/* Setting output */
	[SWF(width="640", height="480", frameRate="60", backgroundColor="#FFFFFF")]
	public class AR3DV extends Sprite {
		/* FLARManager pointer */
		protected var fm:FLARManager;
		/* model config/source */
		protected var ar3dvContainer:AR3DVModelContainer;
		/* Array storing references to all markers on screen, key by pattern id */
		private var _detectedMarkers:Array;
		/* Papervision Scene3D pointer */
		private var _scene3D:Scene3D;
		/* Papervision Viewport3D pointer */
		private var _viewport3D:Viewport3D;
		/* FLARToolkit FLARCamera3D pointer */ 
		private var _camera3D:Camera3D;
		/* Papervision render engine pointer */
		private var _renderEngine:LazyRenderEngine;
		/* Papervision PointLight3D pointer */
		private var _pointLight3D:PointLight3D;
		
		public function AR3DV() {
			this.initModels();
		}
		
		private function debug(info:String):void{
			trace("[AR3DV] "+info);
		}
	
		private function onModelsLoaded(evt:Event):void{
			this.ar3dvContainer.removeEventListener(AR3DVModelContainer.CONFIG_FILE_PARSED,this.onModelsLoaded);
			this.debug("model selesai di-load");	
			this.initAR();
		}
		
		private function initModels():void{
			// load model source dan konfigurasinya
			this.ar3dvContainer = new AR3DVModelContainer("resources/ar3dv/ar3dv.xml");
			this.ar3dvContainer.addEventListener(AR3DVModelContainer.CONFIG_FILE_PARSED,this.onModelsLoaded);
		}
		
		private function onFlarManagerLoad(e:Event):void {
			/* listener dihapus agar fungsi onFlarManagerLoad tidak dijalankan lagi */
			this.fm.removeEventListener(Event.INIT, this.onFlarManagerLoad);
			this.initEngine3D();
		}
		
		/* Inisialisasi AR */
		private function initAR():void {
			/* Inisiliasasi FLARManager */
			this.fm =  new FLARManager("resources/flar/flarConfig.xml", new FLARToolkitManager(), this.stage);
			/* tampilkan webcam */
			this.addChild(Sprite(this.fm.flarSource));
			/* Event listener ketika sebuah marker dikenali */
			this.fm.addEventListener(FLARMarkerEvent.MARKER_ADDED, this.onMarkerAdded);
			/* Event listener ketika sebuah marker tidak terdeteksi lagi*/
			this.fm.addEventListener(FLARMarkerEvent.MARKER_REMOVED, this.onMarkerRemoved);
			/* Event listener jika inisialisasi selesai */
			this.fm.addEventListener(Event.INIT, this.onFlarManagerLoad);
		}
		
		private function initEngine3D():void{
			_scene3D = new Scene3D();
			/* Papervision viewport */
			_viewport3D = new Viewport3D(this.stage.stageWidth, this.stage.stageHeight);
			/* Menambahkan Papervision viewport */
			this.addChild(_viewport3D);
			/* Init FLARCamera3D */
			_camera3D = new FLARCamera_PV3D(this.fm, new Rectangle(0, 0, this.stage.stageWidth, this.stage.stageHeight));
			
			/* Papervision point light */
			_pointLight3D = new PointLight3D(true, false);
			/* light position */
			_pointLight3D.x = 1000;
			_pointLight3D.y = 1000;
			_pointLight3D.z = -1000;
			/* Menambahkan light ke Papervision scene */
			_scene3D.addChild(_pointLight3D);
			
			_detectedMarkers = new Array();
			
			for each(var container:DisplayObject3D in this.ar3dvContainer.containerByPatternId) {
				_scene3D.addChild(container);
			}
			
			/* Papervision render engine Init */
			_renderEngine = new LazyRenderEngine(_scene3D, _camera3D, _viewport3D);
			/* Stats View */
			this.addChild(new StatsView(_renderEngine));
			/* event listener untuk setiap frame */
			this.stage.addEventListener(Event.ENTER_FRAME, this.onEnterFrame);
		}
		
		private function onMarkerAdded (evt:FLARMarkerEvent) :void {
			var marker:FLARMarker = evt.marker;
			var patID:int = marker.patternId;
			this.debug("marker denga pola "+patID+" terdeteksi");
			if(this.ar3dvContainer.hasModel(patID)){
				this.debug("model  :  "+patID+" ditemukan");
				_detectedMarkers[patID] = marker;
				this.ar3dvContainer.setVisible(patID,true);
			}else{
				this.debug("model  :  "+patID+" tidak ditemukan");
			}
		}
		
		private function onMarkerRemoved (evt:FLARMarkerEvent) :void {
			var marker:FLARMarker = evt.marker;
			var patID:int = marker.patternId;
			if(this.ar3dvContainer.hasModel(patID) && _detectedMarkers[patID] != null){
				this.debug("marker dengan pola "+patID+" tidak terdeteksi lagi");
				_detectedMarkers[patID] = null;
				this.ar3dvContainer.setVisible(patID,false);
			}
		}
		
		private function onEnterFrame (evt:Event) :void {
			for each(var marker:FLARMarker in _detectedMarkers){
				if(marker!=null){
					//konversi matriks ke matriks yang bersesuaian dengan PV3D
					var transMatrix:Matrix3D = PVGeomUtils.convertMatrixToPVMatrix(marker.transformMatrix);
					this.ar3dvContainer.setTransform(marker.patternId,transMatrix);			
				}
			}
			// render PV3D engine
			_renderEngine.render();
		}
		
	}
}