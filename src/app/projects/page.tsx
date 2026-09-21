import Link from "next/link";
import { redirect } from "next/navigation";
import { ArrowLeft, FolderKanban, Trash2 } from "lucide-react";
import { createClient } from "@/lib/supabase/server";
import { createProject, deleteProject, updateProjectFundingFacts } from "./actions";

const projectTypes = [
  ["album","Album"],["ep","EP"],["single","Single"],["clip","Clip"],
  ["tournee","Tournée"],["spectacle","Spectacle"],["residence","Résidence"],["autre","Autre"],
] as const;
const statuses = [["idea","Idée"],["preparation","Préparation"],["active","En cours"],["completed","Terminé"],["paused","En pause"]] as const;
type SearchParams = Promise<Record<string,string|string[]|undefined>>;

export default async function ProjectsPage({searchParams}:{searchParams:SearchParams}) {
  const supabase=await createClient();
  const {data:{user}}=await supabase.auth.getUser();
  if(!user) redirect("/login");
  const {data:access}=await supabase.from("user_artist_access").select("artist_id").eq("user_id",user.id).limit(1).maybeSingle();

  const projects=access?.artist_id ? (await supabase.from("projects").select("id,name,project_type,status,description,start_date,target_date,organization_id,organizations(name),budget_eur,performance_count,artist_count,international,recording_started,recording_finished").eq("artist_id",access.artist_id).order("created_at",{ascending:false})).data ?? [] : [];
  const organizations=access?.artist_id ? (await supabase.from("organizations").select("id,name").eq("artist_id",access.artist_id).order("name")).data ?? [] : [];
  const params=await searchParams;
  const error=typeof params.error==="string"?params.error:null;

  return <main className="mx-auto min-h-screen max-w-md bg-white px-5 pb-12 pt-7">
    <Link href="/" className="inline-flex items-center gap-2 text-sm font-medium text-neutral-600"><ArrowLeft size={17}/> Cockpit</Link>
    <div className="mt-6 flex items-center gap-3"><div className="rounded-xl bg-neutral-100 p-3"><FolderKanban size={24}/></div><div><p className="text-sm font-semibold text-neutral-500">ArtistPilot</p><h1 className="text-2xl font-bold tracking-tight">Projets</h1></div></div>
    <p className="mt-3 text-sm text-neutral-600">Centralise tes projets artistiques et la structure qui les porte.</p>
    {error&&<p className="mt-5 rounded-xl border border-red-200 bg-red-50 p-3 text-sm text-red-700">{error==="missing_fields"?"Le nom et le type de projet sont obligatoires.":"Impossible d’enregistrer le projet. "+error}</p>}

    <section className="mt-7"><h2 className="font-semibold">Mes projets</h2>
      {projects.length===0?<div className="mt-3 rounded-2xl border border-dashed border-neutral-300 p-5 text-sm text-neutral-600">Aucun projet enregistré pour le moment.</div>:
      <div className="mt-3 space-y-3">{projects.map((p)=><article key={p.id} className="rounded-2xl border border-neutral-200 p-4">
        <div className="flex items-start justify-between gap-3"><div><h3 className="font-semibold">{p.name}</h3>
        <p className="mt-1 text-sm text-neutral-500">{projectTypes.find(([v])=>v===p.project_type)?.[1]??p.project_type} · {statuses.find(([v])=>v===p.status)?.[1]??p.status}</p>
        {p.organizations&&<p className="mt-1 text-xs text-neutral-500">Porté par : {(p.organizations as unknown as {name?:string}).name}</p>}
        {p.target_date&&<p className="mt-1 text-xs text-neutral-500">Échéance cible : {new Intl.DateTimeFormat("fr-FR").format(new Date(p.target_date+"T12:00:00"))}</p>}</div>
        <form action={deleteProject}><input type="hidden" name="id" value={p.id}/><button aria-label="Supprimer le projet" className="rounded-lg p-2 text-neutral-400 hover:bg-neutral-100 hover:text-red-600"><Trash2 size={18}/></button></form></div>
        <form action={updateProjectFundingFacts} className="mt-4 border-t border-neutral-100 pt-4"><input type="hidden" name="id" value={p.id}/><p className="text-sm font-semibold">Informations financement</p><p className="mt-1 text-xs text-neutral-500">Renseigne uniquement ce que tu sais. Une valeur vide reste inconnue.</p><div className="mt-3 grid grid-cols-2 gap-2"><label className="text-xs">Budget (€)<input name="budget_eur" type="number" min="0" step="0.01" defaultValue={p.budget_eur??""} className="mt-1 h-9 w-full rounded-lg border px-2"/></label><label className="text-xs">Concerts prévus<input name="performance_count" type="number" min="0" step="1" defaultValue={p.performance_count??""} className="mt-1 h-9 w-full rounded-lg border px-2"/></label><label className="text-xs">Artistes concernés<input name="artist_count" type="number" min="0" step="1" defaultValue={p.artist_count??""} className="mt-1 h-9 w-full rounded-lg border px-2"/></label></div>{[["international","Projet international",p.international],["recording_started","Enregistrement commencé",p.recording_started],["recording_finished","Enregistrement terminé",p.recording_finished]].map(([name,label,value])=><label key={String(name)} className="mt-3 block text-xs">{String(label)}<select name={String(name)} defaultValue={value===true?"yes":value===false?"no":""} className="mt-1 h-9 w-full rounded-lg border bg-white px-2"><option value="">Je ne sais pas</option><option value="yes">Oui</option><option value="no">Non</option></select></label>)}<button className="mt-3 h-10 w-full rounded-xl bg-neutral-900 text-sm font-semibold text-white">Enregistrer les informations financement</button></form>
      </article>)}</div>}
    </section>

    <section className="mt-8 rounded-2xl border border-neutral-200 p-5"><h2 className="font-semibold">Ajouter un projet</h2>
      <form action={createProject} className="mt-4 space-y-4">
        <div><label htmlFor="name" className="mb-1.5 block text-sm font-medium">Nom *</label><input id="name" name="name" required className="h-11 w-full rounded-xl border border-neutral-300 px-3 outline-none focus:border-black"/></div>
        <div><label htmlFor="project_type" className="mb-1.5 block text-sm font-medium">Type *</label><select id="project_type" name="project_type" required defaultValue="" className="h-11 w-full rounded-xl border border-neutral-300 bg-white px-3"><option value="" disabled>Choisir</option>{projectTypes.map(([v,l])=><option key={v} value={v}>{l}</option>)}</select></div>
        <div><label htmlFor="status" className="mb-1.5 block text-sm font-medium">État</label><select id="status" name="status" defaultValue="idea" className="h-11 w-full rounded-xl border border-neutral-300 bg-white px-3">{statuses.map(([v,l])=><option key={v} value={v}>{l}</option>)}</select></div>
        <div><label htmlFor="organization_id" className="mb-1.5 block text-sm font-medium">Structure porteuse</label><select id="organization_id" name="organization_id" defaultValue="" className="h-11 w-full rounded-xl border border-neutral-300 bg-white px-3"><option value="">Aucune / à définir</option>{organizations.map(o=><option key={o.id} value={o.id}>{o.name}</option>)}</select><p className="mt-1.5 text-xs text-neutral-500">Laisse vide si ce n’est pas encore décidé.</p></div>
        <div><label htmlFor="description" className="mb-1.5 block text-sm font-medium">Description</label><textarea id="description" name="description" rows={3} className="w-full rounded-xl border border-neutral-300 p-3"/></div>
        <div className="grid grid-cols-2 gap-3"><div><label htmlFor="start_date" className="mb-1.5 block text-sm font-medium">Début</label><input id="start_date" name="start_date" type="date" className="h-11 w-full rounded-xl border border-neutral-300 px-2"/></div><div><label htmlFor="target_date" className="mb-1.5 block text-sm font-medium">Échéance cible</label><input id="target_date" name="target_date" type="date" className="h-11 w-full rounded-xl border border-neutral-300 px-2"/></div></div>
        <button className="h-11 w-full rounded-xl bg-black font-semibold text-white">Enregistrer le projet</button>
      </form>
    </section>
  </main>;
}
