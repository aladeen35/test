import KHome from "kubai-icons-react/icons/home";
import KSearch from "kubai-icons-react/icons/search";
import KDroplet from "kubai-icons-react/icons/droplet";
import KHeartPulse from "kubai-icons-react/icons/heart-pulse";
import KList from "kubai-icons-react/icons/list";
import KUser from "kubai-icons-react/icons/user";
import KBell from "kubai-icons-react/icons/bell";
import KShieldCheck from "kubai-icons-react/icons/shield-check";
import KHospital from "kubai-icons-react/icons/hospital";
import KGlobe from "kubai-icons-react/icons/globe";
import KPhone from "kubai-icons-react/icons/phone";
import KSliders from "kubai-icons-react/icons/sliders";
import KUsers from "kubai-icons-react/icons/users";
import KSparkles from "kubai-icons-react/icons/sparkles";
import KBloodBag from "kubai-icons-react/icons/blood-bag";
import KCalendar from "kubai-icons-react/icons/calendar";
import KMessages from "kubai-icons-react/icons/messages";
import KHandHeart from "kubai-icons-react/icons/hand-heart";
import type { KubaiIconComponent } from "kubai-icons-react";

// Minimal inline icon set (stroke icons, inherit currentColor). Direction-aware where needed.
type P = { className?: string };
const base = "h-6 w-6 shrink-0";
const S = ({ className, children }: P & { children: React.ReactNode }) => (
  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={1.8} strokeLinecap="round" strokeLinejoin="round" aria-hidden="true" className={className ?? base}>{children}</svg>
);
export const HomeLineIcon = (p: P) => <S {...p}><path d="M3 11l9-7 9 7v9a1 1 0 0 1-1 1h-5v-6H9v6H4a1 1 0 0 1-1-1z" /></S>;
export const SearchLineIcon = (p: P) => <S {...p}><circle cx="11" cy="11" r="7" /><path d="M20 20l-3.5-3.5" /></S>;
export const DropLineIcon = (p: P) => <S {...p}><path d="M12 3s6 6.5 6 11a6 6 0 0 1-12 0c0-4.5 6-11 6-11z" /></S>;
export const AlertLineIcon = (p: P) => <S {...p}><path d="M12 3l9.5 17h-19z" /><path d="M12 10v4M12 17.5v.5" /></S>;
export const HeartLineIcon = (p: P) => <S {...p}><path d="M12 20s-7-4.5-9-9a4.8 4.8 0 0 1 9-3 4.8 4.8 0 0 1 9 3c-2 4.5-9 9-9 9z" /></S>;
export const ListLineIcon = (p: P) => <S {...p}><path d="M8 6h12M8 12h12M8 18h12M4 6h.01M4 12h.01M4 18h.01" /></S>;
export const UserLineIcon = (p: P) => <S {...p}><circle cx="12" cy="8" r="4" /><path d="M4 21a8 8 0 0 1 16 0" /></S>;
export const BellLineIcon = (p: P) => <S {...p}><path d="M6 16V11a6 6 0 0 1 12 0v5l2 2H4z" /><path d="M10 20a2 2 0 0 0 4 0" /></S>;
export const ShieldLineIcon = (p: P) => <S {...p}><path d="M12 3l8 3v6c0 4.5-3.4 8.3-8 9-4.6-.7-8-4.5-8-9V6z" /></S>;
export const HospitalLineIcon = (p: P) => <S {...p}><path d="M4 21V5a1 1 0 0 1 1-1h14a1 1 0 0 1 1 1v16M9 21v-4h6v4M12 7v6M9 10h6" /></S>;
export const GlobeLineIcon = (p: P) => <S {...p}><circle cx="12" cy="12" r="9" /><path d="M3 12h18M12 3a14 14 0 0 1 0 18M12 3a14 14 0 0 0 0 18" /></S>;
export const CheckIcon = (p: P) => <S {...p}><path d="M5 12l5 5 9-10" /></S>;
export const PhoneLineIcon = (p: P) => <S {...p}><path d="M5 4h4l2 5-2.5 1.5a11 11 0 0 0 5 5L15 13l5 2v4a2 2 0 0 1-2 2A16 16 0 0 1 3 6a2 2 0 0 1 2-2z" /></S>;
export const OfflineIcon = (p: P) => <S {...p}><path d="M3 3l18 18M8.5 16.5a5 5 0 0 1 7 0M5 13a10 10 0 0 1 5-2.7M19 13a10 10 0 0 0-2.3-1.6M2 9.5a15 15 0 0 1 4.3-2.7M22 9.5A15 15 0 0 0 11 5.1" /></S>;
export const ArrowIcon = (p: P) => <S {...p}><path d="M5 12h14M13 6l6 6-6 6" /></S>;
export const ChevronIcon = (p: P) => <S {...p}><path d="M9 6l6 6-6 6" /></S>;
export const SlidersLineIcon = (p: P) => <S {...p}><path d="M4 7h10M18 7h2M4 17h4M12 17h8" /><circle cx="16" cy="7" r="2" /><circle cx="10" cy="17" r="2" /></S>;
export const ClockIcon = (p: P) => <S {...p}><circle cx="12" cy="12" r="9" /><path d="M12 7v5l3 2" /></S>;
export const PinIcon = (p: P) => <S {...p}><path d="M12 21s-7-6.2-7-11.5A7 7 0 0 1 19 9.5C19 14.8 12 21 12 21z" /><circle cx="12" cy="9.5" r="2.5" /></S>;
export const UsersLineIcon = (p: P) => <S {...p}><circle cx="9" cy="8" r="3.5" /><path d="M2.5 20a6.5 6.5 0 0 1 13 0M16 4.5a3.5 3.5 0 0 1 0 7M18 14a6.5 6.5 0 0 1 3.5 6" /></S>;
export const SparkLineIcon = (p: P) => <S {...p}><path d="M12 3v4M12 17v4M3 12h4M17 12h4M6 6l2.5 2.5M15.5 15.5L18 18M6 18l2.5-2.5M15.5 8.5L18 6" /></S>;


// ---------------------------------------------------------------------------
// Dimensional icons: Kubai Icons (MIT, https://github.com/kubai087/kubai-icons).
// Layered fills with an outside outline, all colours derived from one accent
// (currentColor by default), and a short "object" motion on hover of the
// parent link/button. Motion is skipped under prefers-reduced-motion.
// The *LineIcon versions above stay for tiny sizes and white-on-colour spots.
// ---------------------------------------------------------------------------

type KP = { className?: string; color?: string; size?: number; variant?: "color" | "soft" };
function k(Icon: KubaiIconComponent) {
  return function DimIcon({ className, color, size = 24, variant }: KP) {
    return <Icon size={size} color={color} variant={variant} trigger="parent" className={className ?? base} aria-hidden="true" />;
  };
}
export const HomeIcon = k(KHome);
export const SearchIcon = k(KSearch);
export const DropIcon = k(KDroplet);
export const HeartIcon = k(KHeartPulse);
export const ListIcon = k(KList);
export const UserIcon = k(KUser);
export const BellIcon = k(KBell);
export const ShieldIcon = k(KShieldCheck);
export const HospitalIcon = k(KHospital);
export const GlobeIcon = k(KGlobe);
export const PhoneIcon = k(KPhone);
export const SlidersIcon = k(KSliders);
export const UsersIcon = k(KUsers);
export const SparkIcon = k(KSparkles);
export const AlertIcon = k(KBloodBag);
export const BloodBagIcon = k(KBloodBag);
export const CalendarIcon = k(KCalendar);
export const MessagesIcon = k(KMessages);
export const HandHeartIcon = k(KHandHeart);
