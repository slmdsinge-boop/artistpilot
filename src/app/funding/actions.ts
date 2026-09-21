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

export async function saveEligibilityFact(formData:FormData){
 const subjectType=String(formData.get("subject_type")??"");
 const subjectId=String(formData.get("subject_id")??"");
 const factKey=String(formData.get("fact_key")??"");
 const raw=String(formData.get("value")??"").trim();
 if(!["project","organization","artist","application"].includes(subjectType)||!subjectId||!factKey||raw==="") redirect("/funding?error=invalid_fact");
 const {supabase,artistId}=await context();

 const {data:def}=await supabase.from("fact_definitions").select("subject_type,value_type,options").eq("fact_key",factKey).maybeSingle();
 if(!def||def.subject_type!==subjectType) redirect("/funding?error=invalid_fact_definition");
 const {data:criterion}=await supabase.from("funding_criteria").select("id").eq("criterion_key",factKey).eq("subject_type",subjectType).eq("verification_status","verified").limit(1).maybeSingle();
 if(!criterion) redirect("/funding?error=unverified_fact");

 if(subjectType==="project"){const {data}=await supabase.from("projects").select("id").eq("id",subjectId).eq("artist_id",artistId).maybeSingle();if(!data) redirect("/funding?error=invalid_project");}
 if(subjectType==="organization"){const {data}=await supabase.from("organizations").select("id").eq("id",subjectId).eq("artist_id",artistId).maybeSingle();if(!data) redirect("/funding?error=invalid_organization");}
 if(subjectType==="artist"&&subjectId!==artistId) redirect("/funding?error=invalid_artist");
 if(subjectType==="application"){const {data}=await supabase.from("funding_applications").select("id").eq("id",subjectId).eq("artist_id",artistId).maybeSingle();if(!data) redirect("/funding?error=invalid_application");}

 let value:unknown;
 if(def.value_type==="boolean"){
  if(raw!=="true"&&raw!=="false") redirect("/funding?error=invalid_boolean");
  value=raw==="true";
 } else if(def.value_type==="number"){
  const n=Number(raw); if(!Number.isFinite(n)||n<0) redirect("/funding?error=invalid_number"); value=n;
 } else if(def.value_type==="date"){
  if(!/^\\d{4}-\\d{2}-\\d{2}$/.test(raw)||Number.isNaN(Date.parse(raw+"T12:00:00Z"))) redirect("/funding?error=invalid_date"); value=raw;
 } else if(def.value_type==="enum"){
  const opts=Array.isArray(def.options)?def.options:[]; if(!opts.includes(raw)) redirect("/funding?error=invalid_option"); value=raw;
 } else value=raw;

 const {error}=await supabase.from("entity_facts").upsert({artist_id:artistId,subject_type:subjectType,subject_id:subjectId,fact_key:factKey,value,confirmation_status:"user_confirmed",confirmed_at:new Date().toISOString()},{onConflict:"artist_id,subject_type,subject_id,fact_key"});
 if(error) redirect(`/funding?error=${encodeURIComponent(error.message)}`);
 revalidatePath("/funding"); revalidatePath("/"); redirect("/funding?fact_saved=1");
}
