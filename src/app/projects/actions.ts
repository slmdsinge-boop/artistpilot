"use server";

import { revalidatePath } from "next/cache";
import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";

async function requireContext() {
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) redirect("/login");
  const { data: access } = await supabase.from("user_artist_access").select("artist_id").eq("user_id", user.id).limit(1).maybeSingle();
  if (access?.artist_id) return { supabase, artistId: access.artist_id as string };
  const fallbackName=(user.user_metadata?.full_name as string|undefined)??user.email?.split("@")[0]??"Mon profil artiste";
  const {data:artistId,error}=await supabase.rpc("bootstrap_artist_profile",{display_name:fallbackName});
  if(error||!artistId) throw new Error(error?.message??"Impossible de créer le profil artiste.");
  return {supabase,artistId:artistId as string};
}

export async function createProject(formData: FormData) {
  const name=String(formData.get("name")??"").trim();
  const projectType=String(formData.get("project_type")??"").trim();
  const status=String(formData.get("status")??"idea").trim();
  const organizationId=String(formData.get("organization_id")??"").trim()||null;
  const description=String(formData.get("description")??"").trim()||null;
  const startDate=String(formData.get("start_date")??"").trim()||null;
  const targetDate=String(formData.get("target_date")??"").trim()||null;
  if(!name||!projectType) redirect("/projects?error=missing_fields");

  const {supabase,artistId}=await requireContext();
  if(organizationId){
    const {data:organization}=await supabase.from("organizations").select("id").eq("id",organizationId).eq("artist_id",artistId).maybeSingle();
    if(!organization) redirect("/projects?error=invalid_organization");
  }

  const {error}=await supabase.from("projects").insert({artist_id:artistId,organization_id:organizationId,name,project_type:projectType,status,description,start_date:startDate,target_date:targetDate});
  if(error) redirect("/projects?error=save_failed");
  revalidatePath("/"); revalidatePath("/projects"); redirect("/projects?created=1");
}

export async function deleteProject(formData: FormData) {
  const id=String(formData.get("id")??""); if(!id) redirect("/projects");
  const {supabase,artistId}=await requireContext();
  const {error}=await supabase.from("projects").delete().eq("id",id).eq("artist_id",artistId);
  if(error?.code==="23503") redirect("/projects?error=project_in_use");
  if(error) redirect("/projects?error=save_failed");
  revalidatePath("/projects"); redirect("/projects?deleted=1");
}


function nullableBoolean(value: FormDataEntryValue | null) {
  if (value === "yes") return true;
  if (value === "no") return false;
  return null;
}

function nullableNonNegativeNumber(value: FormDataEntryValue | null) {
  const raw=String(value??"").trim();
  if(!raw) return null;
  const parsed=Number(raw);
  if(!Number.isFinite(parsed)||parsed<0) throw new Error("invalid_number");
  return parsed;
}

export async function updateProjectFundingFacts(formData: FormData) {
  const id=String(formData.get("id")??"").trim();
  if(!id) redirect("/projects");
  const {supabase,artistId}=await requireContext();
  let budget_eur:number|null, performance_count:number|null, artist_count:number|null;
  try {
    budget_eur=nullableNonNegativeNumber(formData.get("budget_eur"));
    performance_count=nullableNonNegativeNumber(formData.get("performance_count"));
    artist_count=nullableNonNegativeNumber(formData.get("artist_count"));
  } catch {
    redirect("/projects?error=invalid_number");
  }
  const {error}=await supabase.from("projects").update({
    budget_eur,
    performance_count,
    artist_count,
    international:nullableBoolean(formData.get("international")),
    recording_started:nullableBoolean(formData.get("recording_started")),
    recording_finished:nullableBoolean(formData.get("recording_finished")),
  }).eq("id",id).eq("artist_id",artistId);
  if(error) redirect("/projects?error=save_failed");
  revalidatePath("/");
  revalidatePath("/projects");
  revalidatePath("/funding");
  redirect("/projects?updated=1");
}

export async function updateProjectOrganization(formData:FormData){
 const id=String(formData.get("id")??"").trim();
 const organizationId=String(formData.get("organization_id")??"").trim()||null;
 if(!id) redirect("/projects");
 const {supabase,artistId}=await requireContext();
 if(organizationId){const {data}=await supabase.from("organizations").select("id").eq("id",organizationId).eq("artist_id",artistId).maybeSingle();if(!data) redirect("/projects?error=invalid_organization");}
 const {error}=await supabase.from("projects").update({organization_id:organizationId}).eq("id",id).eq("artist_id",artistId);
 if(error) redirect("/projects?error=save_failed");
 revalidatePath("/projects"); revalidatePath("/funding"); revalidatePath("/"); redirect("/projects?carrier_updated=1");
}
