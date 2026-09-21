"use server";
import { revalidatePath } from "next/cache";
import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
const tri=(v:FormDataEntryValue|null)=>v==="yes"?true:v==="no"?false:null;
export async function updateOrganizationFacts(formData:FormData){
 const id=String(formData.get("id")??""); if(!id) redirect("/organizations");
 const supabase=await createClient(); const {data:{user}}=await supabase.auth.getUser(); if(!user) redirect("/login");
 const {data:access}=await supabase.from("user_artist_access").select("artist_id").eq("user_id",user.id).limit(1).maybeSingle(); if(!access?.artist_id) redirect("/organizations");
 const payload={
  cnm_affiliated:tri(formData.get("cnm_affiliated")),sacem_affiliated:tri(formData.get("sacem_affiliated")),
  adami_affiliated:tri(formData.get("adami_affiliated")),spedidam_affiliated:tri(formData.get("spedidam_affiliated")),
  scpp_affiliated:tri(formData.get("scpp_affiliated")),sppf_affiliated:tri(formData.get("sppf_affiliated")),
  spectacle_licence:tri(formData.get("spectacle_licence")),employs_artists:tri(formData.get("employs_artists")),
  phonogram_producer:tri(formData.get("phonogram_producer")),owns_masters:tri(formData.get("owns_masters")),
  founded_on:String(formData.get("founded_on")??"")||null,admin_notes:String(formData.get("admin_notes")??"").trim()||null,updated_at:new Date().toISOString()
 };
 const {error}=await supabase.from("organizations").update(payload).eq("id",id).eq("artist_id",access.artist_id);
 if(error) redirect(`/organizations?error=${encodeURIComponent(error.message)}`);
 revalidatePath("/organizations");revalidatePath("/funding");revalidatePath("/");redirect("/organizations?saved=1");
}
