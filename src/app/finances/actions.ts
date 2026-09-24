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
  const projectId = String(f.get("project_id") ?? "").trim() || null;
  const organizationId = String(f.get("organization_id") ?? "").trim() || null;
  if (!["income", "expense"].includes(type) || !label || label.length > 160 || !isValidIsoDate(date) || !Number.isFinite(amount) || amount < 0 || (category?.length ?? 0) > 80 || (notes?.length ?? 0) > 1000) redirect("/finances?error=invalid");
  const { s, artistId } = await ctx();
  if (projectId) { const { data } = await s.from("projects").select("id").eq("id", projectId).eq("artist_id", artistId).maybeSingle(); if (!data) redirect("/finances?error=scope"); }
  if (organizationId) { const { data } = await s.from("organizations").select("id").eq("id", organizationId).eq("artist_id", artistId).maybeSingle(); if (!data) redirect("/finances?error=scope"); }
  const { error } = await s.from("financial_entries").insert({ artist_id: artistId, entry_type: type, label, entry_date: date, amount_eur: amount, category, notes, project_id: projectId, organization_id: organizationId });
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

export async function updateFinancialEntry(f: FormData) {
  const id = String(f.get("id") ?? "").trim();
  const type = String(f.get("entry_type") ?? "");
  const label = String(f.get("label") ?? "").trim();
  const date = String(f.get("entry_date") ?? "");
  const amountRaw = String(f.get("amount_eur") ?? "").trim().replace(",", ".");
  const amount = amountRaw === "" ? Number.NaN : Number(amountRaw);
  const category = String(f.get("category") ?? "").trim() || null;
  const notes = String(f.get("notes") ?? "").trim() || null;
  const projectId = String(f.get("project_id") ?? "").trim() || null;
  const organizationId = String(f.get("organization_id") ?? "").trim() || null;
  if (!id || !["income", "expense"].includes(type) || !label || label.length > 160 || !isValidIsoDate(date) || !Number.isFinite(amount) || amount < 0 || (category?.length ?? 0) > 80 || (notes?.length ?? 0) > 1000) redirect("/finances?error=invalid");
  const { s, artistId } = await ctx();
  if (projectId) { const { data } = await s.from("projects").select("id").eq("id", projectId).eq("artist_id", artistId).maybeSingle(); if (!data) redirect("/finances?error=scope"); }
  if (organizationId) { const { data } = await s.from("organizations").select("id").eq("id", organizationId).eq("artist_id", artistId).maybeSingle(); if (!data) redirect("/finances?error=scope"); }
  const { error } = await s.from("financial_entries").update({ entry_type: type, label, entry_date: date, amount_eur: amount, category, notes, project_id: projectId, organization_id: organizationId }).eq("id", id).eq("artist_id", artistId);
  if (error) redirect("/finances?error=save");
  revalidatePath("/finances");
  redirect("/finances?success=updated");
}

export async function saveFinancialBudget(f: FormData) {
  const year = Number(String(f.get("budget_year") ?? ""));
  const incomeTarget = Number(String(f.get("income_target_eur") ?? "").replace(",", "."));
  const expenseLimit = Number(String(f.get("expense_limit_eur") ?? "").replace(",", "."));
  if (!Number.isInteger(year) || year < 2000 || year > 2100 || !Number.isFinite(incomeTarget) || incomeTarget < 0 || !Number.isFinite(expenseLimit) || expenseLimit < 0) redirect("/finances?error=budget");
  const { s, artistId } = await ctx();
  const { error } = await s.from("financial_budgets").upsert({ artist_id: artistId, budget_year: year, income_target_eur: incomeTarget, expense_limit_eur: expenseLimit, updated_at: new Date().toISOString() }, { onConflict: "artist_id,budget_year" });
  if (error) redirect("/finances?error=budget");
  revalidatePath("/finances");
  redirect(`/finances?year=${year}&success=budget`);
}
