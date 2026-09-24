"use server";

import { revalidatePath } from "next/cache";
import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import { isValidIsoDate } from "@/lib/dates";

async function ctx() {
  const s = await createClient();
  const { data: { user } } = await s.auth.getUser();
  if (!user) redirect("/login");
  const { data: access } = await s.from("user_artist_access").select("artist_id").eq("user_id", user.id).limit(1).maybeSingle();
  if (!access?.artist_id) redirect("/");
  return { s, artistId: access.artist_id };
}

export async function createFinancialEntry(f: FormData) {
  const type = String(f.get("entry_type") ?? "");
  const label = String(f.get("label") ?? "").trim();
  const date = String(f.get("entry_date") ?? "");
  const amountRaw = String(f.get("amount_eur") ?? "").trim().replace(",", ".");
  const amount = amountRaw === "" ? Number.NaN : Number(amountRaw);
  const category = String(f.get("category") ?? "").trim() || null;
  const notes = String(f.get("notes") ?? "").trim() || null;
  if (!["income", "expense"].includes(type) || !label || label.length > 160 || !isValidIsoDate(date) || !Number.isFinite(amount) || amount < 0 || (category?.length ?? 0) > 80 || (notes?.length ?? 0) > 1000) redirect("/finances?error=invalid");
  const { s, artistId } = await ctx();
  const { error } = await s.from("financial_entries").insert({ artist_id: artistId, entry_type: type, label, entry_date: date, amount_eur: amount, category, notes });
  if (error) redirect("/finances?error=save");
  revalidatePath("/finances");
  redirect("/finances?success=created");
}

export async function deleteFinancialEntry(f: FormData) {
  const id = String(f.get("id") ?? "");
  if (!id) redirect("/finances?error=invalid");
  const { s, artistId } = await ctx();
  const { error } = await s.from("financial_entries").delete().eq("id", id).eq("artist_id", artistId);
  if (error) redirect("/finances?error=delete");
  revalidatePath("/finances");
  redirect("/finances?success=deleted");
}
