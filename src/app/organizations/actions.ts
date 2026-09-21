"use server";

import { revalidatePath } from "next/cache";
import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";

async function requireUserAndArtist() {
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) redirect("/login");

  const { data: access } = await supabase
    .from("user_artist_access")
    .select("artist_id")
    .eq("user_id", user.id)
    .limit(1)
    .maybeSingle();

  if (access?.artist_id) return { supabase, artistId: access.artist_id as string };

  const fallbackName =
    (user.user_metadata?.full_name as string | undefined) ??
    user.email?.split("@")[0] ??
    "Mon profil artiste";

  const { data: artistId, error } = await supabase.rpc("bootstrap_artist_profile", {
    display_name: fallbackName,
  });

  if (error || !artistId) {
    throw new Error(error?.message ?? "Impossible de créer le profil artiste.");
  }

  return { supabase, artistId: artistId as string };
}

export async function createOrganization(formData: FormData) {
  const name = String(formData.get("name") ?? "").trim();
  const organizationType = String(formData.get("organization_type") ?? "").trim();
  const siretRaw = String(formData.get("siret") ?? "").replace(/\s/g, "");
  const siret = siretRaw || null;

  if (!name || !organizationType) {
    redirect("/organizations?error=missing_fields");
  }
  if (siret && !/^\d{14}$/.test(siret)) {
    redirect("/organizations?error=invalid_siret");
  }

  const { supabase, artistId } = await requireUserAndArtist();
  const { error } = await supabase.from("organizations").insert({
    artist_id: artistId,
    name,
    organization_type: organizationType,
    siret,
  });

  if (error) redirect("/organizations?error=save_failed");

  revalidatePath("/");
  revalidatePath("/organizations");
  redirect("/organizations?created=1");
}

export async function deleteOrganization(formData: FormData) {
  const id = String(formData.get("id") ?? "");
  if (!id) redirect("/organizations");

  const { supabase, artistId } = await requireUserAndArtist();
  const { error } = await supabase.from("organizations").delete().eq("id", id).eq("artist_id", artistId);
  if (error) redirect("/organizations?error=save_failed");

  revalidatePath("/organizations");
  redirect("/organizations?deleted=1");
}

const eligibilityOrganizationFacts = [
  ["cnm_affiliated","cnm_affiliated"],["sacem_affiliated","sacem_affiliated"],["sppf_affiliated","sppf_affiliated"],
  ["phonogram_producer","phonogram_producer"],["owns_masters","owns_masters"],["employs_artists","employs_artists"],
] as const;

export async function syncOrganizationEligibilityFacts(organizationId: string, values: Record<string, boolean | null>) {
  const { supabase, artistId } = await requireUserAndArtist();
  const { data: owned } = await supabase.from("organizations").select("id").eq("id", organizationId).eq("artist_id", artistId).maybeSingle();
  if (!owned) throw new Error("Structure introuvable.");

  for (const [column, factKey] of eligibilityOrganizationFacts) {
    const value=values[column];
    const { data: existing, error: lookupError } = await supabase.from("entity_facts")
      .select("id,confirmation_status,source_note")
      .eq("artist_id",artistId).eq("subject_type","organization").eq("subject_id",organizationId).eq("fact_key",factKey)
      .maybeSingle();
    if (lookupError) throw new Error("organization_fact_sync_failed");

    if (value===null || value===undefined) {
      // Clearing a profile field must not erase a stronger fact captured elsewhere.
      if (existing?.source_note==="Synchronisé depuis le profil de la structure") {
        const { error } = await supabase.from("entity_facts").delete().eq("id",existing.id);
        if (error) throw new Error("organization_fact_sync_failed");
      }
      continue;
    }

    // A document-confirmed fact is stronger than a profile edit and must be preserved.
    if (existing?.confirmation_status==="document_confirmed" && existing.source_note!=="Synchronisé depuis le profil de la structure") continue;

    const payload={
      artist_id:artistId,subject_type:"organization",subject_id:organizationId,fact_key:factKey,
      value,confirmation_status:"user_confirmed",source_note:"Synchronisé depuis le profil de la structure",confirmed_at:new Date().toISOString()
    };
    const { error } = existing?.id
      ? await supabase.from("entity_facts").update(payload).eq("id",existing.id)
      : await supabase.from("entity_facts").insert(payload);
    if (error) throw new Error("organization_fact_sync_failed");
  }
}
