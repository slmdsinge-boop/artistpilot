"use server";
import { revalidatePath } from "next/cache";
import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";

async function context(){
 const supabase=await createClient(); const {data:{user}}=await supabase.auth.getUser(); if(!user) redirect("/login");
 const {data:access}=await supabase.from("user_artist_access").select("artist_id").eq("user_id",user.id).limit(1).maybeSingle();
 if(!access?.artist_id) redirect("/projects");
 return {supabase,artistId:access.artist_id as string};
}
export async function trackFunding(formData:FormData){
 const programId=String(formData.get("funding_program_id")??"");
 const projectId=String(formData.get("project_id")??"")||null;
 const organizationId=String(formData.get("organization_id")??"")||null;
 if(!programId) redirect("/funding?error=missing_program");
 const {supabase,artistId}=await context();
 if(projectId){const {data}=await supabase.from("projects").select("id").eq("id",projectId).eq("artist_id",artistId).maybeSingle();if(!data) redirect("/funding?error=invalid_project");}
 if(organizationId){const {data}=await supabase.from("organizations").select("id").eq("id",organizationId).eq("artist_id",artistId).maybeSingle();if(!data) redirect("/funding?error=invalid_organization");}
 const {error}=await supabase.from("funding_applications").insert({artist_id:artistId,project_id:projectId,organization_id:organizationId,funding_program_id:programId,status:"to_check"});
 if(error) redirect(`/funding?error=${encodeURIComponent(error.message)}`);
 revalidatePath("/funding"); redirect("/funding?tracked=1");
}
