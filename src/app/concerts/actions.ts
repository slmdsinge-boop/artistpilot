"use server";

import { revalidatePath } from "next/cache";
import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import { isValidIsoDate } from "@/lib/dates";

const STATUSES=new Set(["planned","confirmed","completed","cancelled"]);
const CONTRACT_STATUSES=new Set(["unknown","pending","signed"]);
const PAYMENT_STATUSES=new Set(["unknown","pending","paid"]);

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
 const contractStatus=String(formData.get("contract_status")??"unknown").trim();
 const paymentStatus=String(formData.get("payment_status")??"unknown").trim();
 const employerName=String(formData.get("employer_name")??"").trim()||null;
 const payslipReceived=formData.get("payslip_received")==="yes"?true:formData.get("payslip_received")==="no"?false:null;
 const aemReceived=formData.get("aem_received")==="yes"?true:formData.get("aem_received")==="no"?false:null;
 if(!title||title.length>240||!performanceDate)redirect("/concerts?error=missing_fields");
 if(!isValidIsoDate(performanceDate))redirect("/concerts?error=invalid_date");
 if(!STATUSES.has(status)||!CONTRACT_STATUSES.has(contractStatus)||!PAYMENT_STATUSES.has(paymentStatus))redirect("/concerts?error=invalid_status");
 if(employerName&&employerName.length>240)redirect("/concerts?error=invalid_employer");
 if(notes&&notes.length>5000)redirect("/concerts?error=notes_too_long");
 let fee:number|null,paidHours:number|null,cachetCount:number|null;
 try{fee=nullableNumber(formData.get("fee_eur"));paidHours=nullableNumber(formData.get("paid_hours"));cachetCount=nullableNumber(formData.get("cachet_count"));}catch{redirect("/concerts?error=invalid_number");}
 if(cachetCount!==null&&(!Number.isInteger(cachetCount)||cachetCount>28))redirect("/concerts?error=invalid_cachet_count");
 const {supabase,artistId}=await context();
 if(projectId){const {data}=await supabase.from("projects").select("id").eq("id",projectId).eq("artist_id",artistId).maybeSingle();if(!data)redirect("/concerts?error=invalid_project");}
 if(organizationId){const {data}=await supabase.from("organizations").select("id").eq("id",organizationId).eq("artist_id",artistId).maybeSingle();if(!data)redirect("/concerts?error=invalid_organization");}
 const {error}=await supabase.from("concerts").insert({artist_id:artistId,project_id:projectId,organization_id:organizationId,title,venue,city,performance_date:performanceDate,status,fee_eur:fee,paid_hours:paidHours,notes,contract_status:contractStatus,payment_status:paymentStatus,employer_name:employerName,payslip_received:payslipReceived,aem_received:aemReceived,cachet_count:cachetCount});
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
