import { AppProvider, useApp } from './state/store';
import { HomeScreen } from './screens/HomeScreen';
import { CreateRoomScreen } from './screens/CreateRoomScreen';
import { JoinRoomScreen } from './screens/JoinRoomScreen';
import { LobbyScreen } from './screens/LobbyScreen';
import { GameScreen } from './screens/GameScreen';
import { ResultScreen } from './screens/ResultScreen';
import { SettingsScreen } from './screens/SettingsScreen';
import { TutorialScreen } from './screens/TutorialScreen';
import { ConnectionBanner, LandscapeHint, Toasts } from './components/StatusBars';
import { SceneBackground } from './components/SceneBackground';

function CurrentScreen() {
  const { state } = useApp();
  switch (state.screen) {
    case 'home': return <HomeScreen />;
    case 'create': return <CreateRoomScreen />;
    case 'join': return <JoinRoomScreen />;
    case 'lobby': return <LobbyScreen />;
    case 'game': return <GameScreen />;
    case 'result': return <ResultScreen />;
    case 'settings': return <SettingsScreen />;
    case 'tutorial': return <TutorialScreen />;
    default: return <HomeScreen />;
  }
}

export default function App() {
  return (
    <AppProvider>
      <SceneBackground />
      <div className="relative z-10 flex-1 flex flex-col">
        <ConnectionBanner />
        <LandscapeHint />
        <CurrentScreen />
      </div>
      <Toasts />
    </AppProvider>
  );
}
