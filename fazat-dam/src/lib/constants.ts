export const BLOOD_GROUPS = ["A+", "A-", "B+", "B-", "AB+", "AB-", "O+", "O-"] as const;
export type BloodGroup = (typeof BLOOD_GROUPS)[number];

export const COUNTRIES = ["SD", "SA"] as const;
export type CountryCode = (typeof COUNTRIES)[number];
export const PHONE_PREFIX: Record<CountryCode, string> = { SD: "+249", SA: "+966" };
export const TIMEZONE: Record<CountryCode, string> = { SD: "Africa/Khartoum", SA: "Asia/Riyadh" };

export const REQUEST_STATUSES = [
  "submitted", "under_review", "verified", "matching_donors", "donors_responding",
  "donation_arranged", "completed", "rejected", "cancelled", "expired",
] as const;
export type RequestStatus = (typeof REQUEST_STATUSES)[number];
export const TERMINAL_STATUSES: RequestStatus[] = ["completed", "rejected", "cancelled", "expired"];
/** The happy path, used for the progress timeline */
export const REQUEST_FLOW: RequestStatus[] = [
  "submitted", "under_review", "verified", "matching_donors", "donors_responding", "donation_arranged", "completed",
];

export const URGENCY = ["normal", "urgent", "critical"] as const;
export const RELATIONS = ["self", "family", "friend", "medical_staff", "other"] as const;
export const CONTACT_METHODS = ["in_app", "phone_call", "whatsapp", "sms"] as const;
export const INITIATIVE_CATEGORIES = [
  "blood_drive", "medical_support", "hospital_assistance", "volunteer", "awareness", "partnership",
] as const;
export const SPONSOR_TYPES = ["corporate", "community", "hospital", "blood_bank", "humanitarian_org"] as const;
export const REPORT_REASONS = ["fraud", "spam", "abuse", "privacy", "medical_misinformation", "other"] as const;
export const ROLES = ["donor", "requester", "institution_staff", "organizer", "admin"] as const;
export type Role = (typeof ROLES)[number];

export const MAX_UPLOAD_BYTES = 10 * 1024 * 1024;
export const UPLOAD_TYPES = ["application/pdf", "image/jpeg", "image/png", "image/webp"];
