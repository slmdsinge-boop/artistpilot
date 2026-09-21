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
 let projectOrganizationId:string|null=null;
 if(projectId){const {data}=await supabase.from("projects").select("id,organization_id").eq("id",projectId).eq("artist_id",artistId).maybeSingle();if(!data) redirect("/funding?error=invalid_project");projectOrganizationId=data.organization_id??null;}
 if(organizationId){const {data}=await supabase.from("organizations").select("id").eq("id",organizationId).eq("artist_id",artistId).maybeSingle();if(!data) redirect("/funding?error=invalid_organization");}
 if(projectId&&organizationId&&projectOrganizationId&&organizationId!==projectOrganizationId) redirect("/funding?error=project_organization_mismatch");
 const {data:program}=await supabase.from("funding_programs").select("id,verification_status,deadline_date").eq("id",programId).maybeSingle();
 if(!program||program.verification_status!=="verified") redirect("/funding?error=program_not_verified");
 const today=new Date().toISOString().slice(0,10);
 if(program.deadline_date&&program.deadline_date<today) redirect("/funding?error=program_closed");
 let existingQuery=supabase.from("funding_applications").select("id").eq("artist_id",artistId).eq("funding_program_id",programId);
 existingQuery=projectId?existingQuery.eq("project_id",projectId):existingQuery.is("project_id",null);
 if(!projectId){
   const effectiveOrganizationId=organizationId??projectOrganizationId;
   existingQuery=effectiveOrganizationId?existingQuery.eq("organization_id",effectiveOrganizationId):existingQuery.is("organization_id",null);
 }
 const {data:existing}=await existingQuery.limit(1).maybeSingle();
 if(existing) redirect("/funding?error=already_tracked");
 const {error}=await supabase.from("funding_applications").insert({artist_id:artistId,project_id:projectId,organization_id:organizationId??projectOrganizationId,funding_program_id:programId,status:"to_check"});
 if(error?.code==="23505") redirect("/funding?error=already_tracked");
 if(error) redirect("/funding?error=save_failed");
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
 const {data:criteria}=await supabase.from("funding_criteria").select("id,funding_program_id").eq("criterion_key",factKey).eq("subject_type",subjectType).eq("verification_status","verified");
 if(!criteria?.length) redirect("/funding?error=unverified_fact");
 const programIds=[...new Set(criteria.map(c=>c.funding_program_id))];
 const {data:verifiedPrograms}=await supabase.from("funding_programs").select("id").in("id",programIds).eq("verification_status","verified");
 if(!verifiedPrograms?.length) redirect("/funding?error=unverified_fact");

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
 if(error) redirect("/funding?error=fact_save_failed");
 revalidatePath("/funding"); revalidatePath("/"); redirect("/funding?fact_saved=1");
}

export async function clearEligibilityFact(formData:FormData){
 const subjectType=String(formData.get("subject_type")??"");
 const subjectId=String(formData.get("subject_id")??"");
 const factKey=String(formData.get("fact_key")??"");
 if(!["project","organization","artist","application"].includes(subjectType)||!subjectId||!factKey) redirect("/funding?error=invalid_fact");
 const {supabase,artistId}=await context();
 if(subjectType==="project"){const {data}=await supabase.from("projects").select("id").eq("id",subjectId).eq("artist_id",artistId).maybeSingle();if(!data) redirect("/funding?error=invalid_project");}
 if(subjectType==="organization"){const {data}=await supabase.from("organizations").select("id").eq("id",subjectId).eq("artist_id",artistId).maybeSingle();if(!data) redirect("/funding?error=invalid_organization");}
 if(subjectType==="artist"&&subjectId!==artistId) redirect("/funding?error=invalid_artist");
 if(subjectType==="application"){const {data}=await supabase.from("funding_applications").select("id").eq("id",subjectId).eq("artist_id",artistId).maybeSingle();if(!data) redirect("/funding?error=invalid_application");}
 const {data:fact}=await supabase.from("entity_facts").select("id,confirmation_status").eq("artist_id",artistId).eq("subject_type",subjectType).eq("subject_id",subjectId).eq("fact_key",factKey).maybeSingle();
 if(fact?.confirmation_status==="document_confirmed") redirect("/funding?error=document_confirmed_fact");
 if(fact){const {error}=await supabase.from("entity_facts").delete().eq("id",fact.id);if(error) redirect("/funding?error=fact_clear_failed");}
 revalidatePath("/funding"); revalidatePath("/"); redirect("/funding?fact_cleared=1");
}
