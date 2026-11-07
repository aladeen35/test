import "server-only";
import { randomUUID } from "node:crypto";
import { createClient } from "./supabase/server";
import { getDict } from "./i18n/server";
import { errorText } from "./errors";
import { MAX_UPLOAD_BYTES, UPLOAD_TYPES } from "./constants";

const EXT: Record<string, string> = { "application/pdf": "pdf", "image/jpeg": "jpg", "image/png": "png", "image/webp": "webp" };

/** Uploads one private document to storage and records it. Path = <entity id>/<random>.<ext>. */
async function uploadDoc(bucket: string, table: string, fk: string, entityId: string, file: File): Promise<string | null> {
  const { t } = await getDict();
  if (file.size > MAX_UPLOAD_BYTES) return t.errors.file_too_large;
  if (!UPLOAD_TYPES.includes(file.type)) return t.errors.file_type;
  const supabase = await createClient();
  const { data: claims } = await supabase.auth.getClaims();
  const path = `${entityId}/${randomUUID()}.${EXT[file.type]}`;
  const { error: upErr } = await supabase.storage.from(bucket).upload(path, file, { contentType: file.type, upsert: false });
  if (upErr) return errorText(t, upErr);
  const { error } = await supabase.from(table).insert({
    [fk]: entityId, uploaded_by: claims?.claims?.sub, storage_path: path,
    file_name: file.name.slice(0, 120), mime_type: file.type, size_bytes: file.size,
  });
  if (error) {
    await supabase.storage.from(bucket).remove([path]);
    return errorText(t, error);
  }
  return null;
}

export async function uploadFiles(bucket: string, table: string, fk: string, entityId: string, fd: FormData, field = "documents") {
  const files = fd.getAll(field).filter((f): f is File => f instanceof File && f.size > 0).slice(0, 5);
  for (const f of files) {
    const err = await uploadDoc(bucket, table, fk, entityId, f);
    if (err) return err;
  }
  return null;
}

