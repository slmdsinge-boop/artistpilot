"use server";

import { revalidatePath } from "next/cache";
import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
const ORGANIZATION_TYPES=new Set(["association","societe","label","producteur","micro_entreprise","autre"]);

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
  if (!ORGANIZATION_TYPES.has(organizationType)) redirect("/organizations?error=invalid_organization_type");
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
  if (error?.code === "23503") redirect("/organizations?error=organization_in_use");
  if (error?.message?.includes("Project carrier cannot change while funding application history exists")) {
    redirect("/organizations?error=organization_has_funding_history");
  }
  if (error) redirect("/organizations?error=save_failed");

  revalidatePath("/organizations");
  redirect("/organizations?deleted=1");
}
