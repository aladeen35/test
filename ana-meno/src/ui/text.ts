// All user-facing Arabic strings live here (single source of truth).
import type { GameErrorCode } from '../game/types';

export const T = {
  appName: 'أنا مِنو 🤔',
  appNameShort: 'أنا مِنو',
  tagline: 'خَمِّن الشخصية... واكتشف المهنة!',
  twoPlayerBlurb: 'لعبة تخمين لشخصين',
  howBlurb: 'اسأل، استبعد، وخمّن!',

  // Home
  createGame: 'إنشاء لعبة',
  joinGame: 'الانضمام إلى لعبة',
  howToPlay: 'طريقة اللعب',
  settings: 'الإعدادات',
  enterYourName: 'اكتب اسمك',
  yourName: 'اسمك',
  continueBtn: 'متابعة',
  nameTooShort: 'اكتب اسماً من حرفين على الأقل.',

  // Audio
  sounds: 'الأصوات',
  soundsOn: 'الأصوات: تشغيل',
  soundsOff: 'الأصوات: إيقاف',
  music: 'الموسيقى',
  effects: 'المؤثرات',
  on: 'تشغيل',
  off: 'إيقاف',

  // Create room
  createRoomTitle: 'إنشاء لعبة جديدة',
  gameMode: 'نمط اللعب',
  normalMode: 'اللعب العادي',
  characterCount: '30 شخصية',
  randomSelection: 'اختيار الشخصيات: عشوائي',
  diverseCharacters: 'شخصيات متنوعة',
  diverseProfessions: 'المهن: متنوعة',
  createRoomBtn: 'إنشاء الغرفة',
  creatingRoom: 'جاري إنشاء الغرفة...',
  roomCode: 'رمز الغرفة',
  copyCode: 'نسخ الرمز',
  copied: 'تم النسخ ✓',
  shareCode: 'مشاركة الرمز',
  waitingForPlayer2: 'بانتظار اللاعب الثاني...',
  waitingSeat: 'بانتظار لاعب...',

  // Join room
  joinRoomTitle: 'الانضمام إلى لعبة',
  enterRoomCode: 'أدخل رمز الغرفة',
  joinBtn: 'انضمام',
  joining: 'جاري الانضمام...',

  // Lobby
  playersReady: 'اكتمل اللاعبون!',
  preparingGame: 'جاري تجهيز اللعبة...',
  preparingCharacters: 'جاري تجهيز الشخصيات...',
  startingGame: 'جاري بدء اللعبة...',
  player1: 'اللاعب الأول',
  player2: 'اللاعب الثاني',
  vs: 'ضد',

  // Game board
  yourTurn: 'دورك',
  opponentTurn: 'انتظر دور خصمك',
  askQuestion: 'اسأل سؤالاً',
  guessCharacter: 'خمّن الشخصية',
  questionLog: 'سجل الأسئلة',
  eliminate: 'استبعاد',
  undoEliminate: 'إلغاء الاستبعاد',
  yourSecretCharacter: 'شخصيتك السرية',
  secretHint: 'هذه شخصيتك! خصمك يحاول تخمينها.',
  questionsLabel: 'الأسئلة',
  timeLabel: 'الوقت',
  scoreLabel: 'النقاط',
  resultLabel: 'النتيجة',
  remaining: 'المتبقي',
  question: 'السؤال',
  answerTheQuestion: 'أجب عن السؤال',
  waitingAnswer: 'بانتظار إجابة خصمك...',
  opponentAsking: 'خصمك يفكر في سؤال...',
  yes: 'نعم',
  no: 'لا',
  confirm: 'تأكيد',
  cancel: 'إلغاء',
  close: 'إغلاق',
  areYouSure: 'هل أنت متأكد؟',
  confirmGuess: 'نعم، هذا تخميني',
  chooseCharacterToGuess: 'اختر الشخصية التي تعتقد أنها شخصية خصمك',
  turnTimedOut: 'انتهى وقت الدور!',
  opponentGuessed: 'خصمك خمّن شخصية...',

  // Result
  wellDone: 'أحسنت! 🎉',
  winnerIs: 'الفائز هو...',
  badLuck: 'هذه المرة لم يحالفك الحظ 😄',
  correctCharacterWas: 'الشخصية الصحيحة كانت...',
  characterWas: 'الشخصية كانت:',
  playAgain: 'إعادة اللعب',
  backToHome: 'العودة للرئيسية',
  exitToHome: 'الخروج إلى الرئيسية',
  waitingOtherPlayer: 'بانتظار اللاعب الآخر...',
  rematchRequested: 'طلب خصمك إعادة اللعب!',
  youWonByForfeit: 'انسحب خصمك من اللعبة، أنت الفائز!',
  wonByWrongGuess: 'خمّن خصمك شخصية خاطئة، أنت الفائز!',
  lostByWrongGuess: 'للأسف، كان تخمينك خاطئاً.',

  // Connection
  connected: 'متصل',
  connecting: 'جاري الاتصال...',
  offline: 'لا يوجد اتصال بالإنترنت',
  reconnecting: 'جاري استعادة الاتصال...',
  connectionLost: 'انقطع الاتصال...',
  connectionRestored: 'تم استعادة الاتصال',
  opponentDisconnected: 'انقطع اتصال اللاعب الآخر. ننتظر عودته...',
  opponentReconnected: 'عاد اللاعب الآخر!',
  opponentLeft: 'غادر اللاعب الآخر اللعبة.',

  // Tutorial
  tutorialTitle: 'طريقة اللعب',
  skip: 'تخطي',
  next: 'التالي',
  done: 'يلا نبدأ!',
  tutorialSteps: [
    { icon: '🕵️', title: 'شخصيتك السرية', text: 'احصل على شخصيتك السرية. خصمك لا يعرفها!' },
    { icon: '❓', title: 'اسأل بذكاء', text: 'اسأل خصمك أسئلة تساعدك على استبعاد الشخصيات.' },
    { icon: '❌', title: 'استبعد', text: 'استبعد الشخصيات غير المحتملة من لوحتك.' },
    { icon: '🎯', title: 'خمّن', text: 'خمّن الشخصية قبل خصمك.' },
    { icon: '⭐', title: 'اجمع النقاط', text: 'كلما خمّنت بسرعة وبأسئلة أقل، حصلت على نقاط أكثر.' },
  ],

  // Settings / about
  aboutGame: 'حول اللعبة',
  aboutText: 'لعبة تخمين اجتماعية لشخصين',
  version: 'الإصدار 1.0',

  // Generic errors
  errorGeneric: 'حدث خطأ. حاول مرة أخرى.',
  errorCreateRoom: 'تعذر إنشاء الغرفة.',
  errorServer: 'تعذر الاتصال بالخادم.',

  landscapeHint: 'للحصول على أفضل تجربة، استخدم الوضع الرأسي 📱',
} as const;

export const ERROR_MESSAGES: Record<GameErrorCode, string> = {
  ROOM_NOT_FOUND: 'هذه الغرفة غير موجودة.',
  ROOM_FULL: 'الغرفة مكتملة.',
  ROOM_EXPIRED: 'انتهت صلاحية الغرفة.',
  ROOM_ALREADY_STARTED: 'لا يمكن الانضمام إلى هذه الغرفة.',
  INVALID_CODE: 'رمز الغرفة غير صحيح.',
  INVALID_NAME: 'اكتب اسماً صحيحاً.',
  NOT_IN_ROOM: 'لست عضواً في هذه الغرفة.',
  GAME_NOT_ACTIVE: 'انتهت هذه الجولة.',
  NOT_YOUR_TURN: 'ليس دورك الآن.',
  PENDING_QUESTION: 'هناك سؤال بانتظار الإجابة.',
  NO_PENDING_QUESTION: 'لا يوجد سؤال للإجابة عليه.',
  NOT_DEFENDER: 'لا يمكنك تنفيذ هذا الإجراء الآن.',
  INVALID_QUESTION: 'هذا السؤال غير متاح.',
  INVALID_CHARACTER: 'هذه الشخصية غير موجودة.',
  TURN_NOT_EXPIRED: 'لم ينته وقت الدور بعد.',
  REMATCH_NOT_ALLOWED: 'لا يمكن إعادة اللعب الآن.',
  NETWORK: 'تعذر الاتصال بالخادم.',
  UNKNOWN: 'حدث خطأ. حاول مرة أخرى.',
};

export function errorMessage(code: string | undefined): string {
  return ERROR_MESSAGES[(code as GameErrorCode) ?? 'UNKNOWN'] ?? ERROR_MESSAGES.UNKNOWN;
}
