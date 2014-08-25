package
{
	import com.demonsters.debugger.MonsterDebugger;
	
	import flash.media.Sound;
	import flash.media.SoundChannel;
	import flash.media.SoundTransform;

	public class MusicManager
	{
		private static var _instance:MusicManager;
		
		//VARIABLES
		private var _menu:Sound;
		private var _combat:Sound;
		
		private var _channel:SoundChannel;
		private var _transform:SoundTransform;
		
		private var _currentlyPlaying:String;
		private var _position:Number;
		private var _volume:int;
		
		//FUNCTIONS
		public function MusicManager(singleton:SingletonEnforcer)
		{
			if(!singleton) throw new Error("You cannot instantiate the MusicManager class using the constructor. Please use MusicManager.getInstance() instead.");
			initialize();
		}
		
		static public function getInstance():MusicManager
		{
			if(!_instance)
			{
				_instance = new MusicManager(new SingletonEnforcer());
			}
			return _instance;
		}
		
		public function initialize():void
		{
			_menu = new GameAssets.menuMusic();
			_combat = new GameAssets.combatMusic();
			
			_channel = new SoundChannel();
			_transform = new SoundTransform();

			_currentlyPlaying = "none";
			_position = 0.0;
			_volume = 0;
			
			updateVolume();
		}
		
		public function stopCurrentMusic():void
		{
			_position = _channel.position;
			_channel.stop();
		}
		
		public function fadeCurrentMusic():void
		{
			
		}
		
		public function playMenuMusic():void
		{
			MonsterDebugger.trace(this, "Starting \"menu\" music");
			
			if (_currentlyPlaying != "menu") {
				if (_currentlyPlaying != "none") {
					stopCurrentMusic();
				}
				
				_currentlyPlaying = "menu";
				_position = 0;
				if (_volume != 0) {
					_channel = _menu.play(0, 100, _transform);
				}
			}
		}
		
		public function playCombatMusic():void
		{
			MonsterDebugger.trace(this, "Starting \"combat\" music");
			
			if (_currentlyPlaying != "combat") {
				if (_currentlyPlaying != "none") {
					stopCurrentMusic();
				}
				
				_currentlyPlaying = "combat";
				_position = 0;
				if (_volume != 0) {
					_channel = _combat.play(0, 100, _transform);
				}
			}
		}
		
		public function cycleVolume():void
		{
			_volume += 25;
			if (_volume > 100) {
				_volume = 0;
			}
			updateVolume();
		}
		
		private function updateVolume():void
		{
			if (_volume == 0) {
				stopCurrentMusic();
			}
			if (_volume == 25) {
				if (_currentlyPlaying == "menu") {
					_channel = _menu.play(_position, 100, _transform);
					
				} else if (_currentlyPlaying == "combat") {
					_channel = _combat.play(_position, 100, _transform);
				}
			}
			_transform.volume = (_volume / 100);
			_channel.soundTransform = _transform;
		}
		
		public function get currentVolume():int {
			return _volume;
		}
	}
}

class SingletonEnforcer
{
	public function SingletonEnforcer(){};
}