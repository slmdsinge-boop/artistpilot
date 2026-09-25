"use server";
import { revalidatePath } from "next/cache";
import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import { isValidIsoDate } from "@/lib/dates";

async function ctx(){const s=await createClient();const {data:{user}}=await s.auth.getUser();if(!user)redirect("/login");const {data:access}=await s.from("user_artist_access").select("artist_id").eq("user_id",user.id).limit(1).maybeSingle();if(!access?.artist_id)redirect("/");return{s,artistId:access.artist_id};}
export async function createWork(f:FormData){const title=String(f.get("title")??"").trim();const workType=String(f.get("work_type")??"song");const status=String(f.get("status")??"draft");const sacemStatus=String(f.get("sacem_status")??"to_do");const releaseDate=String(f.get("release_date")??"").trim()||null;const notes=String(f.get("notes")??"").trim()||null;if(!title||title.length>180||!["song","composition","recording","other"].includes(workType)||!["draft","ready","released"].includes(status)||!["to_do","declared","not_applicable"].includes(sacemStatus)||(releaseDate&&!isValidIsoDate(releaseDate))||(notes?.length??0)>1000)redirect("/works?error=invalid");const{s,artistId}=await ctx();const{error}=await s.from("works").insert({artist_id:artistId,title,work_type:workType,status,sacem_status:sacemStatus,release_date:releaseDate,notes});if(error)redirect("/works?error=save");revalidatePath("/works");redirect("/works?success=created");}
export async function deleteWork(f:FormData){const id=String(f.get("id")??"");if(!id)redirect("/works?error=invalid");const{s,artistId}=await ctx();const{error}=await s.from("works").delete().eq("id",id).eq("artist_id",artistId);if(error)redirect("/works?error=delete");revalidatePath("/works");redirect("/works?success=deleted");}
