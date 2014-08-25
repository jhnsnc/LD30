package
{
	import com.demonsters.debugger.MonsterDebugger;
	
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.utils.ByteArray;
	
	[SWF(width="1024", height="576", backgroundColor="#333333", frameRate="60")]
	public class Main extends Sprite
	{
		//VARIABLES
		private var _music:MusicManager;
		private var _simpleScreens:MovieClip;
		private var _simpleScreensActive:Boolean;
		private var _defenseGame:DefenseGameView;
		private var _volumeControl:MovieClip;
		
		private var _currentLevel:int;
		
		//FUNCTIONS
		public function Main()
		{
			MonsterDebugger.initialize(this);
			MonsterDebugger.trace(this, "Game is up!");
			
			this.addEventListener(Event.ADDED_TO_STAGE, init, false, 0 , true);
		}
		
		public function init(evt:Event = null):void
		{
			MonsterDebugger.trace(this, "Initializing");
			
			this.removeEventListener(Event.ADDED_TO_STAGE, init);
			
			//initializations
			_music = MusicManager.getInstance();
			
			_defenseGame = new DefenseGameView();
			
			_volumeControl = new GameAssets.volumeControl();
			this.addChild(_volumeControl);
			this.setChildIndex(_volumeControl, this.numChildren - 1);
			_volumeControl.x = 1024;
			_volumeControl.y = 0;
			_volumeControl.buttonMode = true;
			_volumeControl.mouseChildren = false;
			_volumeControl.gotoAndStop("volume" + _music.currentVolume);
			_volumeControl.addEventListener(MouseEvent.CLICK, handleVolumeControlClick, false, 0, true);
			
			_currentLevel = 1;
			//stage.addEventListener(KeyboardEvent.KEY_DOWN, handleKeyPress, false, 0, true); //TODO: REMOVE ME! DEBUG ONLY
			
			setupSimpleScreens();
			showMainTitle();
		}
		
		private function tryStartGame():void
		{
			if (_defenseGame.isReady) {
				startGame();
			} else {
				//TODO: add loading screen
				_defenseGame.addEventListener("READY", startGame, false, 0, true);
			}
		}
		
		private function startGame(evt:Event = null):void
		{
			MonsterDebugger.trace(this, "Starting game");
			
			if (_defenseGame.hasEventListener("READY")) {
				_defenseGame.removeEventListener("READY", startGame);
			}
			
			this.removeChild(_simpleScreens);
			_simpleScreensActive = false;
			showBlank();
			this.addChildAt(_defenseGame, this.getChildIndex(_volumeControl));
			
			_defenseGame.play();
			_music.playCombatMusic();
			//add listeners for game end
			_defenseGame.addEventListener("GAMEOVER", handleGameOver, false, 0, true);
			_defenseGame.addEventListener("LEVELCOMPLETE", handleLevelComplete, false, 0, true);
		}
		
		private function handleGameOver(evt:Event = null):void
		{
			_defenseGame.removeEventListener("GAMEOVER", handleGameOver);
			_defenseGame.removeEventListener("LEVELCOMPLETE", handleLevelComplete);
			
			_currentLevel = 1;
			
			this.removeChild(_defenseGame);
			showGameOver();
		}
		
		private function handleLevelComplete(evt:Event = null):void
		{
			_defenseGame.removeEventListener("GAMEOVER", handleGameOver);
			_defenseGame.removeEventListener("LEVELCOMPLETE", handleLevelComplete);
			
			_currentLevel += 1;
			
			this.removeChild(_defenseGame);
			showLevelResults();
		}
		
		//functions: title screens stuff
		private function setupSimpleScreens():void
		{
			_simpleScreens = new GameAssets.simpleScreens();
			_simpleScreensActive = false;
			
			_simpleScreens.gotoAndStop("title");
		}
		
		private function showMainTitle(evt:MouseEvent = null):void
		{
			_simpleScreens.gotoAndStop("title");
			_music.playMenuMusic();
			
			//buttons
			//_simpleScreens.btnPlay.buttonMode = true;
			//_simpleScreens.btnPlay.mouseChildren = false;
			_simpleScreens.btnPlay.addEventListener(MouseEvent.CLICK, onPlayClicked, false, 0, true);
			//_simpleScreens.btnCredits.buttonMode = true;
			//_simpleScreens.btnCredits.mouseChildren = false;
			_simpleScreens.btnCredits.addEventListener(MouseEvent.CLICK, onCreditsClicked, false, 0, true);
			
			//append if needed
			if (!_simpleScreensActive) {
				this.addChildAt(_simpleScreens, this.getChildIndex(_volumeControl));
				_simpleScreensActive = true;
			}
		}
		
		private function onPlayClicked(evt:MouseEvent = null):void
		{
			MonsterDebugger.trace(this, "\"Play\" clicked");
			
			//cleanup
			_simpleScreens.btnPlay.removeEventListener(MouseEvent.CLICK, onPlayClicked);
			_simpleScreens.btnCredits.removeEventListener(MouseEvent.CLICK, onCreditsClicked);
			//then
			showIntro();
		}
		
		private function onCreditsClicked(evt:MouseEvent = null):void
		{
			MonsterDebugger.trace(this, "\"Credits\" clicked");
			
			//cleanup
			_simpleScreens.btnPlay.removeEventListener(MouseEvent.CLICK, onPlayClicked);
			_simpleScreens.btnCredits.removeEventListener(MouseEvent.CLICK, onCreditsClicked);
			//then
			showCredits();
		}
		
		private function showCredits(evt:MouseEvent = null):void
		{
			_simpleScreens.gotoAndStop("credits");
			
			//buttons
			//_simpleScreens.btnBack.buttonMode = true;
			//_simpleScreens.btnBack.mouseChildren = false;
			_simpleScreens.btnBack.addEventListener(MouseEvent.CLICK, showMainTitle, false, 0, true);
		}
		
		private function onBackClicked(evt:MouseEvent = null):void
		{
			MonsterDebugger.trace(this, "\"Back\" clicked from credits page");
			
			//cleanup
			_simpleScreens.btnBack.removeEventListener(MouseEvent.CLICK, showMainTitle);
			//then
			showMainTitle();
		}
		
		private function showIntro(evt:MouseEvent = null):void
		{
			_simpleScreens.gotoAndStop("intro");
			
			//buttons
			//_simpleScreens.btnReady.buttonMode = true;
			//_simpleScreens.btnReady.mouseChildren = false;
			_simpleScreens.btnReady.addEventListener(MouseEvent.CLICK, onReadyClicked, false, 0, true);
		}
		
		private function onReadyClicked(evt:MouseEvent = null):void
		{
			MonsterDebugger.trace(this, "\"Ready\" clicked from intro page");
			
			//cleanup
			_simpleScreens.btnReady.removeEventListener(MouseEvent.CLICK, onReadyClicked);
			//then
			_defenseGame.reset(_currentLevel);
			tryStartGame();
		}
		
		private function showLevelResults(evt:MouseEvent = null):void
		{
			_simpleScreens.gotoAndStop("levelresults");
			_music.playMenuMusic();
			
			//content
			if (_currentLevel >= 2 && _currentLevel <= 8) { //HACK: offset by one due to sequencing mistake (_currentLevel 2 means player just successfully finished level 1)
				MonsterDebugger.trace(this, "Setting success message");
				MonsterDebugger.trace(this, GameAssets.levelInfo.successMessages[_currentLevel-2]);
				_simpleScreens.levelClearText.text = GameAssets.levelInfo.successMessages[_currentLevel-2];
			} else {
				_simpleScreens.levelClearText.text = "";
			}
			
			//buttons
			//_simpleScreens.btnNextLevel.buttonMode = true;
			//_simpleScreens.btnNextLevel.mouseChildren = false;
			_simpleScreens.btnNextLevel.addEventListener(MouseEvent.CLICK, onNextLevelClicked, false, 0, true);
			
			//append if needed
			if (!_simpleScreensActive) {
				this.addChildAt(_simpleScreens, this.getChildIndex(_volumeControl));
				_simpleScreensActive = true;
			}
		}
		
		private function onNextLevelClicked(evt:MouseEvent = null):void
		{
			MonsterDebugger.trace(this, "\"Next Level\" clicked on level results page");
			
			//cleanup
			_simpleScreens.btnNextLevel.removeEventListener(MouseEvent.CLICK, onNextLevelClicked);
			//then
			if (_currentLevel > 7) {
				_currentLevel = 1;
				showMainTitle();
			} else {
				_defenseGame.reset(_currentLevel);
				tryStartGame();
			}
		}
		
		private function showGameOver(evt:MouseEvent = null):void
		{
			_simpleScreens.gotoAndStop("gameover");
			_music.playMenuMusic();
			
			//buttons
			//_simpleScreens.btnReturnToTitle.buttonMode = true;
			//_simpleScreens.btnReturnToTitle.mouseChildren = false;
			_simpleScreens.btnReturnToTitle.addEventListener(MouseEvent.CLICK, onReturnToTitleClicked, false, 0, true);
			
			//append if needed
			if (!_simpleScreensActive) {
				this.addChildAt(_simpleScreens, this.getChildIndex(_volumeControl));
				_simpleScreensActive = true;
			}
		}
		
		private function onReturnToTitleClicked(evt:MouseEvent = null):void
		{
			MonsterDebugger.trace(this, "\"Return to Title\" clicked on game over page");
			
			//cleanup
			_simpleScreens.btnReturnToTitle.removeEventListener(MouseEvent.CLICK, onReturnToTitleClicked);
			//then
			showMainTitle();
		}
		
		private function showBlank(evt:MouseEvent = null):void
		{
			_simpleScreens.gotoAndStop("blank");
			_music.playMenuMusic();
			
			//append if needed
			if (!_simpleScreensActive) {
				this.addChildAt(_simpleScreens, this.getChildIndex(_volumeControl));
				_simpleScreensActive = true;
			}
		}
		
		//volume control functions
		private function handleVolumeControlClick(evt:MouseEvent = null):void
		{
			MonsterDebugger.trace(this, "Adjusting volume");
			
			_music.cycleVolume();
			_volumeControl.gotoAndStop("volume" + _music.currentVolume);
		}
		
		/*//FOR DEBUGGING ONLY!
		private function handleKeyPress(evt:KeyboardEvent):void
		{
			switch (evt.keyCode)
			{
				case 49: //1
					MonsterDebugger.trace(this, "Manually setting level to 1");
					_currentLevel = 1;
					break;
				case 50: //2
					MonsterDebugger.trace(this, "Manually setting level to 2");
					_currentLevel = 2;
					break;
				case 51: //3
					MonsterDebugger.trace(this, "Manually setting level to 3");
					_currentLevel = 3;
					break;
				case 52: //4
					MonsterDebugger.trace(this, "Manually setting level to 4");
					_currentLevel = 4;
					break;
				case 53: //5
					MonsterDebugger.trace(this, "Manually setting level to 5");
					_currentLevel = 5;
					break;
				case 54: //6
					MonsterDebugger.trace(this, "Manually setting level to 6");
					_currentLevel = 6;
					break;
				case 55: //7
					MonsterDebugger.trace(this, "Manually setting level to 7");
					_currentLevel = 7;
					break;
				case 56: //8
					MonsterDebugger.trace(this, "Manually setting level to 8");
					_currentLevel = 8;
					break;
				case 90: //z
					MonsterDebugger.trace(this, "Going to level results");
					showLevelResults();
					break;
			}
		}*/
	}
}