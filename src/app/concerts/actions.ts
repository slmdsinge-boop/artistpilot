"use server";

import { revalidatePath } from "next/cache";
import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import { isValidIsoDate } from "@/lib/dates";

const STATUSES=new Set(["planned","confirmed","completed","cancelled"]);

async function context(){
 const supabase=await createClient();
 const {data:{user}}=await supabase.auth.getUser();
 if(!user) redirect("/login");
 const {data:access}=await supabase.from("user_artist_access").select("artist_id").eq("user_id",user.id).limit(1).maybeSingle();
 if(!access?.artist_id) redirect("/?error=profile_required");
 return {supabase,artistId:access.artist_id as string};
}

function nullableNumber(value:FormDataEntryValue|null){
 const raw=String(value??"").trim(); if(!raw)return null;
 const n=Number(raw); if(!Number.isFinite(n)||n<0)throw new Error("invalid_number"); return n;
}

export async function createConcert(formData:FormData){
 const title=String(formData.get("title")??"").trim();
 const performanceDate=String(formData.get("performance_date")??"").trim();
 const status=String(formData.get("status")??"planned").trim();
 const venue=String(formData.get("venue")??"").trim()||null;
 const city=String(formData.get("city")??"").trim()||null;
 const projectId=String(formData.get("project_id")??"").trim()||null;
 const organizationId=String(formData.get("organization_id")??"").trim()||null;
 const notes=String(formData.get("notes")??"").trim()||null;
 if(!title||title.length>240||!performanceDate)redirect("/concerts?error=missing_fields");
 if(!isValidIsoDate(performanceDate))redirect("/concerts?error=invalid_date");
 if(!STATUSES.has(status))redirect("/concerts?error=invalid_status");
 if(notes&&notes.length>5000)redirect("/concerts?error=notes_too_long");
 let fee:number|null,paidHours:number|null;
 try{fee=nullableNumber(formData.get("fee_eur"));paidHours=nullableNumber(formData.get("paid_hours"));}catch{redirect("/concerts?error=invalid_number");}
 const {supabase,artistId}=await context();
 if(projectId){const {data}=await supabase.from("projects").select("id").eq("id",projectId).eq("artist_id",artistId).maybeSingle();if(!data)redirect("/concerts?error=invalid_project");}
 if(organizationId){const {data}=await supabase.from("organizations").select("id").eq("id",organizationId).eq("artist_id",artistId).maybeSingle();if(!data)redirect("/concerts?error=invalid_organization");}
 const {error}=await supabase.from("concerts").insert({artist_id:artistId,project_id:projectId,organization_id:organizationId,title,venue,city,performance_date:performanceDate,status,fee_eur:fee,paid_hours:paidHours,notes});
 if(error)redirect("/concerts?error=save_failed");
 revalidatePath("/concerts");revalidatePath("/");redirect("/concerts?created=1");
}

export async function deleteConcert(formData:FormData){
 const id=String(formData.get("id")??"").trim();if(!id)redirect("/concerts");
 const {supabase,artistId}=await context();
 const {error}=await supabase.from("concerts").delete().eq("id",id).eq("artist_id",artistId);
 if(error)redirect("/concerts?error=save_failed");
 revalidatePath("/concerts");revalidatePath("/");redirect("/concerts?deleted=1");
}
