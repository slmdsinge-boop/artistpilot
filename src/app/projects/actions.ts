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
  if(error) redirect(`/projects?error=${encodeURIComponent(error.message)}`);
  revalidatePath("/"); revalidatePath("/projects"); redirect("/projects?created=1");
}

export async function deleteProject(formData: FormData) {
  const id=String(formData.get("id")??""); if(!id) redirect("/projects");
  const {supabase,artistId}=await requireContext();
  const {error}=await supabase.from("projects").delete().eq("id",id).eq("artist_id",artistId);
  if(error) redirect(`/projects?error=${encodeURIComponent(error.message)}`);
  revalidatePath("/projects"); redirect("/projects?deleted=1");
}
