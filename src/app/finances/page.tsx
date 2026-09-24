import Link from "next/link";
import { redirect } from "next/navigation";
import { ArrowLeft, WalletCards } from "lucide-react";
import { createClient } from "@/lib/supabase/server";
import { todayIsoDate } from "@/lib/dates";
import { createFinancialEntry, deleteFinancialEntry } from "./actions";

const money = (value: number) => value.toLocaleString("fr-FR", { minimumFractionDigits: 0, maximumFractionDigits: 2 });
const dateFr = (value: string) => new Intl.DateTimeFormat("fr-FR", { day: "2-digit", month: "short", year: "numeric", timeZone: "UTC" }).format(new Date(value + "T00:00:00Z"));

export default async function FinancesPage({ searchParams }: { searchParams: Promise<{ error?: string; success?: string }> }) {
  const params = await searchParams;
  const s = await createClient();
  const { data: { user } } = await s.auth.getUser();
  if (!user) redirect("/login");
  const { data: access } = await s.from("user_artist_access").select("artist_id").eq("user_id", user.id).limit(1).maybeSingle();
  const artistId = access?.artist_id;
  const entries = artistId ? (await s.from("financial_entries").select("id,entry_type,category,label,amount_eur,entry_date,notes,project_id,organization_id").eq("artist_id", artistId).order("entry_date", { ascending: false })).data ?? [] : [];
  const projects = artistId ? (await s.from("projects").select("id,name").eq("artist_id", artistId).order("name")).data ?? [] : [];
  const organizations = artistId ? (await s.from("organizations").select("id,name").eq("artist_id", artistId).order("name")).data ?? [] : [];
  const projectNames = new Map(projects.map((p: any) => [p.id, p.name]));
  const organizationNames = new Map(organizations.map((o: any) => [o.id, o.name]));
  const year = todayIsoDate().slice(0, 4);
  const current = entries.filter((e: any) => String(e.entry_date).startsWith(year));
  const income = current.filter((e: any) => e.entry_type === "income").reduce((n: number, e: any) => n + Number(e.amount_eur), 0);
  const expenses = current.filter((e: any) => e.entry_type === "expense").reduce((n: number, e: any) => n + Number(e.amount_eur), 0);
  return <main className="mx-auto min-h-screen max-w-md bg-white px-5 pb-28 pt-7">
    <Link href="/" className="inline-flex items-center gap-2 text-sm text-neutral-600"><ArrowLeft size={17}/>Cockpit</Link>
    <div className="mt-6 flex items-center gap-3"><div className="rounded-xl bg-neutral-100 p-3"><WalletCards/></div><div><p className="text-sm font-semibold text-neutral-500">ArtistPilot</p><h1 className="text-2xl font-bold">Finances</h1></div></div>
    <p className="mt-3 text-sm text-neutral-600">Suis les recettes et dépenses de ton activité artistique.</p>
    {params.error && <p className="mt-4 rounded-xl bg-neutral-100 p-3 text-sm font-medium">Impossible d’enregistrer cette opération. Vérifie les informations saisies.</p>}
    {params.success && <p className="mt-4 rounded-xl bg-neutral-100 p-3 text-sm font-medium">{params.success === "deleted" ? "Mouvement supprimé." : "Mouvement enregistré."}</p>}
    <section className="mt-6 grid grid-cols-2 gap-3"><div className="rounded-2xl bg-neutral-950 p-4 text-white"><p className="text-xs text-neutral-400">Solde {year}</p><p className="mt-1 text-xl font-bold">{money(income-expenses)} €</p></div><div className="rounded-2xl border p-4"><p className="text-xs text-neutral-500">Recettes {year}</p><p className="font-bold">{money(income)} €</p><p className="mt-1 text-xs">Dépenses {money(expenses)} €</p></div></section>
    <section className="mt-7"><h2 className="font-semibold">Mouvements</h2><div className="mt-3 space-y-2">{entries.length===0?<p className="rounded-2xl border border-dashed p-5 text-sm text-neutral-500">Aucun mouvement enregistré.</p>:entries.map((e:any)=><div key={e.id} className="rounded-2xl border p-4"><div className="flex justify-between gap-3"><div><p className="font-medium">{e.label}</p><p className="text-xs text-neutral-500">{dateFr(String(e.entry_date))}{e.category?" · "+e.category:""}</p></div><p className="shrink-0 font-semibold">{e.entry_type==="income"?"+":"−"}{money(Number(e.amount_eur))} €</p></div>{(e.project_id||e.organization_id)&&<p className="mt-2 text-xs font-medium text-neutral-500">{e.project_id&&projectNames.get(e.project_id)}{e.project_id&&e.organization_id?" · ":""}{e.organization_id&&organizationNames.get(e.organization_id)}</p>}{e.notes&&<p className="mt-2 text-sm text-neutral-600">{e.notes}</p>}<form action={deleteFinancialEntry} className="mt-2"><input type="hidden" name="id" value={e.id}/><button className="text-xs text-neutral-400">Supprimer</button></form></div>)}</div></section>
    <section className="mt-8 rounded-3xl border p-5"><h2 className="font-semibold">Ajouter un mouvement</h2><form action={createFinancialEntry} className="mt-4 space-y-3"><div className="grid grid-cols-2 gap-2"><select name="entry_type" className="h-11 rounded-xl border bg-white px-2"><option value="income">Recette</option><option value="expense">Dépense</option></select><input name="entry_date" type="date" required defaultValue={todayIsoDate()} className="h-11 rounded-xl border px-2"/></div><input name="label" maxLength={160} required placeholder="Libellé" className="h-11 w-full rounded-xl border px-3"/><div className="grid grid-cols-2 gap-2"><input name="amount_eur" type="number" min="0" step="0.01" required placeholder="Montant €" className="h-11 rounded-xl border px-2"/><input name="category" maxLength={80} placeholder="Catégorie" className="h-11 rounded-xl border px-2"/></div><div className="grid grid-cols-2 gap-2"><select name="project_id" className="h-11 rounded-xl border bg-white px-2"><option value="">Sans projet</option>{projects.map((p:any)=><option key={p.id} value={p.id}>{p.name}</option>)}</select><select name="organization_id" className="h-11 rounded-xl border bg-white px-2"><option value="">Sans structure</option>{organizations.map((o:any)=><option key={o.id} value={o.id}>{o.name}</option>)}</select></div><textarea name="notes" maxLength={1000} placeholder="Note (facultatif)" className="min-h-20 w-full rounded-xl border p-3"/><button className="h-11 w-full rounded-xl bg-black font-semibold text-white">Enregistrer</button></form></section>
  </main>;
}
