import { redirect } from "next/navigation";
import Link from "next/link";
import { CircleDollarSign, Music2, CalendarDays, FolderOpen, Bell, FolderKanban, Building2, UserRound } from "lucide-react";
import { createClient } from "@/lib/supabase/server";
import { UniversalAdd } from "@/components/universal-add";

const modules = [
  ["Projets", FolderKanban, "/projects"], ["Financements", CircleDollarSign, "/funding"],
  ["Œuvres & droits", Music2, null], ["Concerts", CalendarDays, null],
  ["Documents", FolderOpen, null], ["Organisations", Building2, "/organizations"],
] as const;

export default async function Home() {
  const hasUrl = Boolean(process.env.NEXT_PUBLIC_SUPABASE_URL);
  const hasKey = Boolean(process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY);

  if (!hasUrl || !hasKey) {
  return (
      <main className="mx-auto min-h-screen max-w-md bg-white px-5 py-10">
        <p className="text-sm font-semibold text-neutral-500">ArtistPilot</p>
        <h1 className="mt-2 text-2xl font-bold">Configuration Supabase incomplète</h1>
        <p className="mt-4 text-neutral-600">
          Le déploiement fonctionne, mais Vercel ne transmet pas encore toutes les variables au serveur.
        </p>
        <div className="mt-6 space-y-2 rounded-2xl border border-neutral-200 p-4 text-sm">
          <p>NEXT_PUBLIC_SUPABASE_URL : <strong>{hasUrl ? "présente" : "absente"}</strong></p>
          <p>NEXT_PUBLIC_SUPABASE_ANON_KEY : <strong>{hasKey ? "présente" : "absente"}</strong></p>
        </div>
      </main>
    );
  }

  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();

  if (!user) {
    redirect("/login");
  }

  let artistName: string | null = null;
  let artistId: string | null = null;
  if (user) {
    const { data } = await supabase
      .from("user_artist_access")
      .select("artist_id,artist_profiles(name)")
      .eq("user_id", user.id)
      .limit(1)
      .maybeSingle();
    const profile = data?.artist_profiles as unknown as { name?: string } | null;
    artistName = profile?.name ?? null;
    artistId = (data as { artist_id?: string } | null)?.artist_id ?? null;
  }

  const projects=artistId?(await supabase.from("projects").select("id,name,organization_id").eq("artist_id",artistId).order("created_at",{ascending:false})).data??[]:[];
  const todoCandidates:{project:string;provider:string;program:string;reason:string;impact:number;href?:string}[]=[];
  if(artistId) for(const project of projects){
    const [{data},{data:readiness}]=await Promise.all([
      supabase.rpc("evaluate_funding_eligibility_v23",{target_artist:artistId,target_project:project.id,target_organization:project.organization_id??null}),
      supabase.rpc("funding_program_readiness",{target_artist:artistId,target_project:project.id})
    ]);
    const readyPrograms=new Set((readiness??[]).filter((r:any)=>r.readiness_status==="ready").map((r:any)=>r.funding_program_id));
    const grouped=new Map<string,{project:string;provider:string;program:string;reason:string;impact:number;href?:string}>();
    for(const row of data??[]){
      if(!readyPrograms.has(row.funding_program_id)) continue;
      if(!["missing_information","pending_context"].includes(row.criterion_status)||!row.blocking||row.criterion_kind!=="eligibility") continue;
      const key=project.id+"|"+row.funding_program_id;
      const current=grouped.get(key)??{project:project.name,provider:row.provider_name,program:row.program_name,reason:row.criterion_status==="pending_context"?"Contexte nécessaire pour déterminer la règle applicable.":"Une information nécessaire à l’éligibilité manque.",impact:0,href:"/funding"};
      current.impact++; grouped.set(key,current);
    }
    todoCandidates.push(...grouped.values());
  }
  const fundingApplications=artistId?(await supabase.from("funding_applications").select("id,status,requested_amount_eur,awarded_amount_eur,submitted_at,decision_at,funding_programs(name,provider_name,deadline_date),projects(name)").eq("artist_id",artistId).order("updated_at",{ascending:false})).data??[]:[];
  const fundingSummary=fundingApplications.reduce((acc:any,a:any)=>{if(a.status==="submitted")acc.pending++;if(a.status==="awarded"){acc.awardedCount++;acc.awarded+=Number(a.awarded_amount_eur??0);}return acc;},{pending:0,awardedCount:0,awarded:0});\n  const today=new Date().toISOString().slice(0,10);
  const incompleteFundingTodos=fundingApplications.flatMap((a:any)=>{const fp=a.funding_programs as {name?:string;provider_name?:string}|null;const pr=a.projects as {name?:string}|null;const missing:string[]=[];if(["submitted","awarded","rejected"].includes(a.status)&&!a.submitted_at)missing.push("date de dépôt");if(["awarded","rejected"].includes(a.status)&&!a.decision_at)missing.push("date de décision");if(a.status==="awarded"&&a.awarded_amount_eur===null)missing.push("montant accordé");return missing.length?[{project:pr?.name??"Dossier",provider:fp?.provider_name??"Financement",program:fp?.name??"Dispositif",reason:`Information${missing.length>1?"s":""} obligatoire${missing.length>1?"s":""} manquante${missing.length>1?"s":""} : ${missing.join(", ")}.`,impact:1600+missing.length,href:"/funding"}]:[];});\n  const fundingTodos=fundingApplications.flatMap((a:any)=>{
    const fp=a.funding_programs as {name?:string;provider_name?:string;deadline_date?:string}|null;
    const pr=a.projects as {name?:string}|null;
    const days=fp?.deadline_date?Math.ceil((new Date(fp.deadline_date+"T12:00:00").getTime()-new Date(today+"T12:00:00").getTime())/86400000):null;
    if(["identified","to_check","preparing"].includes(a.status)&&days!==null&&days<0) return [{project:pr?.name??"Dossier",provider:fp?.provider_name??"Financement",program:fp?.name??"Dispositif",reason:`Échéance dépassée depuis ${Math.abs(days)} jour${Math.abs(days)>1?"s":""}. Mets à jour le dossier si la demande n’a pas été déposée.`,impact:2000+Math.abs(days),href:"/funding"}];\n    if(["identified","to_check","preparing"].includes(a.status)&&days!==null&&days>=0&&days<=30) return [{project:pr?.name??"Dossier",provider:fp?.provider_name??"Financement",program:fp?.name??"Dispositif",reason:days===0?"Échéance de dépôt aujourd’hui.":`Échéance de dépôt dans ${days} jour${days>1?"s":""}.`,impact:1000-days,href:"/funding"}];
    if(a.status==="submitted"&&a.submitted_at){const waitingDays=Math.floor((new Date(today+"T12:00:00").getTime()-new Date(a.submitted_at+"T12:00:00").getTime())/86400000);if(waitingDays>=60)return [{project:pr?.name??"Dossier",provider:fp?.provider_name??"Financement",program:fp?.name??"Dispositif",reason:`Dossier déposé depuis ${waitingDays} jours sans décision enregistrée. Vérifie son avancement.`,impact:500+waitingDays,href:"/funding"}];}
    return [];
  });
  const todoItems=Array.from([...fundingTodos,...incompleteFundingTodos,...todoCandidates].reduce((map,item)=>{const key=`${item.project}::${item.provider}::${item.program}`;const current=map.get(key);if(!current||item.impact>current.impact)map.set(key,item);return map;},new Map<string,{project:string;provider:string;program:string;reason:string;impact:number;href?:string}>()).values()).sort((a,b)=>b.impact-a.impact).slice(0,5);

  return (
    <main className="mx-auto min-h-screen max-w-md bg-white px-5 pb-28 pt-8 shadow-sm">
      <header className="mb-7 flex items-start justify-between">
        <div>
          <p className="text-sm font-semibold text-neutral-500">ArtistPilot</p>
          <h1 className="mt-1 text-3xl font-bold tracking-tight">{artistName ? `Bonjour, ${artistName}` : "Bonjour 👋"}</h1>
          <p className="mt-2 text-neutral-600">Qu’est-ce que je dois faire maintenant ?</p>
        </div>
        <div className="rounded-full bg-neutral-100 p-2.5"><UserRound size={20}/></div>
      </header>

      <section className="mb-7 rounded-2xl border border-neutral-200 p-4">
        <div className="flex items-center gap-2"><Bell size={18}/><h2 className="font-semibold">À FAIRE</h2></div>
        {todoItems.length === 0 ? (
          <p className="mt-3 text-sm text-neutral-600">Aucune information utilisateur prioritaire à compléter pour les dispositifs actuellement vérifiés.</p>
        ) : (
          <div className="mt-3 space-y-3">
            {todoItems.map((item, index) => (
              <Link key={item.project + item.provider + index} href={item.href??"/funding"} className="block rounded-xl bg-amber-50 p-3">
                <p className="text-sm font-semibold">Compléter les informations pour {item.project}</p>
                <p className="mt-1 text-xs text-neutral-600">{item.provider} · {item.program}</p>
                <p className="mt-1 text-xs text-neutral-500">{item.reason}</p>
              </Link>
            ))}
          </div>
        )}
      </section>

      <section>
        <h2 className="mb-3 text-lg font-semibold">Cockpit</h2>
        {fundingApplications.length>0&&<Link href="/funding" className="mb-3 block rounded-2xl border border-neutral-200 p-4"><div className="flex items-center justify-between gap-3"><p className="font-semibold">Financements</p><span className="text-xs text-neutral-500">{fundingApplications.length} dossier{fundingApplications.length>1?"s":""}</span></div><div className="mt-3 grid grid-cols-3 gap-2 text-center"><div><p className="text-lg font-bold">{fundingSummary.pending}</p><p className="text-[11px] text-neutral-500">En attente</p></div><div><p className="text-lg font-bold">{fundingSummary.awardedCount}</p><p className="text-[11px] text-neutral-500">Accordé{fundingSummary.awardedCount>1?"s":""}</p></div><div><p className="text-lg font-bold">{fundingSummary.awarded.toLocaleString("fr-FR")} €</p><p className="text-[11px] text-neutral-500">Obtenu</p></div></div></Link>}
        <div className="grid grid-cols-2 gap-3">
          {modules.map(([label, Icon, href]) => href ? (
            <Link key={label} href={href} className="min-h-28 rounded-2xl border border-neutral-200 p-4 text-left transition active:scale-[.98]">
              <Icon size={22}/><span className="mt-5 block font-medium">{label}</span>
            </Link>
          ) : (
            <div key={label} className="min-h-28 rounded-2xl border border-neutral-200 p-4 text-left text-neutral-500">
              <Icon size={22}/><span className="mt-5 block font-medium">{label}</span>
            </div>
          ))}
        </div>
      </section>
      <UniversalAdd/>
    </main>
  );
}
