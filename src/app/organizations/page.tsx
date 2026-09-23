import Link from "next/link";
import { redirect } from "next/navigation";
import { ArrowLeft, Building2 } from "lucide-react";
import { ConfirmDeleteButton } from "@/components/ConfirmDeleteButton";
import { createClient } from "@/lib/supabase/server";
import { createOrganization, deleteOrganization } from "./actions";
import { updateOrganizationFacts } from "./profile-actions";

const organizationTypes = [
  ["association", "Association"],
  ["societe", "Société"],
  ["label", "Label"],
  ["producteur", "Producteur"],
  ["micro_entreprise", "Micro-entreprise"],
  ["autre", "Autre"],
] as const;

type SearchParams = Promise<Record<string, string | string[] | undefined>>;

export default async function OrganizationsPage({ searchParams }: { searchParams: SearchParams }) {
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) redirect("/login");

  const { data: access } = await supabase
    .from("user_artist_access")
    .select("artist_id")
    .eq("user_id", user.id)
    .limit(1)
    .maybeSingle();

  const organizations = access?.artist_id
    ? (await supabase
        .from("organizations")
        .select("id,name,organization_type,siret,created_at,cnm_affiliated,sacem_affiliated,adami_affiliated,spedidam_affiliated,scpp_affiliated,sppf_affiliated,spectacle_licence,employs_artists,phonogram_producer,owns_masters,founded_on,admin_notes")
        .eq("artist_id", access.artist_id)
        .order("created_at", { ascending: false })).data ?? []
    : [];

  const params = await searchParams;
  const error = typeof params.error === "string" ? params.error : null;

  return (
    <main className="mx-auto min-h-screen max-w-md bg-white px-5 pb-12 pt-7">
      <Link href="/" className="inline-flex items-center gap-2 text-sm font-medium text-neutral-600">
        <ArrowLeft size={17} /> Cockpit
      </Link>

      <div className="mt-6 flex items-center gap-3">
        <div className="rounded-xl bg-neutral-100 p-3"><Building2 size={24}/></div>
        <div>
          <p className="text-sm font-semibold text-neutral-500">ArtistPilot</p>
          <h1 className="text-2xl font-bold tracking-tight">Organisations</h1>
        </div>
      </div>
      <p className="mt-3 text-sm text-neutral-600">
        Associations, sociétés, labels et autres structures juridiques liées à ton activité.
      </p>

      {error && (
        <p className="mt-5 rounded-xl border border-red-200 bg-red-50 p-3 text-sm text-red-700">
          {error === "missing_fields" ? "Le nom et le type de structure sont obligatoires." :
           error === "invalid_siret" ? "Le SIRET doit contenir exactement 14 chiffres." :
           error === "organization_in_use" ? "Cette structure est utilisée par un projet ou un dossier de financement. Retire d’abord ces liens avant de la supprimer." :
           error === "organization_has_funding_history" ? "Cette structure ne peut pas être supprimée car elle porte un projet ayant un historique de financement. Cet historique administratif doit être conservé." :
           error === "profile_setup_failed" ? "Impossible de préparer ton profil artiste pour le moment. Réessaie dans quelques instants." :
           error === "save_failed" ? "Impossible d’enregistrer cette modification pour le moment." :
           "Impossible d’enregistrer cette modification pour le moment."}
        </p>
      )}

      <section className="mt-7">
        <h2 className="font-semibold">Mes structures</h2>
        {organizations.length === 0 ? (
          <div className="mt-3 rounded-2xl border border-dashed border-neutral-300 p-5 text-sm text-neutral-600">
            Aucune organisation enregistrée pour le moment.
          </div>
        ) : (
          <div className="mt-3 space-y-3">
            {organizations.map((organization) => (
              <article key={organization.id} className="rounded-2xl border border-neutral-200 p-4">
                <div className="flex items-start justify-between gap-3">
                  <div>
                    <h3 className="font-semibold">{organization.name || "Sans nom"}</h3>
                    <p className="mt-1 text-sm text-neutral-500">
                      {organizationTypes.find(([value]) => value === organization.organization_type)?.[1] ?? organization.organization_type}
                    </p>
                    {organization.siret && <p className="mt-1 text-xs text-neutral-500">SIRET : {organization.siret}</p>}
                  </div>
                  <form action={deleteOrganization}>
                    <input type="hidden" name="id" value={organization.id}/>
                    <ConfirmDeleteButton label="Supprimer la structure" message="Supprimer cette structure ? Cette action est définitive." />
                  </form>
                </div>
              <form action={updateOrganizationFacts} className="mt-4 border-t border-neutral-100 pt-4">
<input type="hidden" name="id" value={organization.id}/>
<p className="text-sm font-semibold">Profil administratif</p>
<p className="mt-1 text-xs text-neutral-500">Réponds seulement à ce que tu sais. « Je ne sais pas » reste une vraie information manquante.</p>
<div className="mt-3 grid grid-cols-2 gap-2">
<label className="text-xs">Affilié CNM<select name="cnm_affiliated" defaultValue={organization.cnm_affiliated===true?"yes":organization.cnm_affiliated===false?"no":""} className="mt-1 h-9 w-full rounded-lg border bg-white px-2"><option value="">Je ne sais pas</option><option value="yes">Oui</option><option value="no">Non</option></select></label><label className="text-xs">Affilié SACEM<select name="sacem_affiliated" defaultValue={organization.sacem_affiliated===true?"yes":organization.sacem_affiliated===false?"no":""} className="mt-1 h-9 w-full rounded-lg border bg-white px-2"><option value="">Je ne sais pas</option><option value="yes">Oui</option><option value="no">Non</option></select></label><label className="text-xs">Affilié ADAMI<select name="adami_affiliated" defaultValue={organization.adami_affiliated===true?"yes":organization.adami_affiliated===false?"no":""} className="mt-1 h-9 w-full rounded-lg border bg-white px-2"><option value="">Je ne sais pas</option><option value="yes">Oui</option><option value="no">Non</option></select></label><label className="text-xs">Affilié SPEDIDAM<select name="spedidam_affiliated" defaultValue={organization.spedidam_affiliated===true?"yes":organization.spedidam_affiliated===false?"no":""} className="mt-1 h-9 w-full rounded-lg border bg-white px-2"><option value="">Je ne sais pas</option><option value="yes">Oui</option><option value="no">Non</option></select></label><label className="text-xs">Affilié SCPP<select name="scpp_affiliated" defaultValue={organization.scpp_affiliated===true?"yes":organization.scpp_affiliated===false?"no":""} className="mt-1 h-9 w-full rounded-lg border bg-white px-2"><option value="">Je ne sais pas</option><option value="yes">Oui</option><option value="no">Non</option></select></label><label className="text-xs">Affilié SPPF<select name="sppf_affiliated" defaultValue={organization.sppf_affiliated===true?"yes":organization.sppf_affiliated===false?"no":""} className="mt-1 h-9 w-full rounded-lg border bg-white px-2"><option value="">Je ne sais pas</option><option value="yes">Oui</option><option value="no">Non</option></select></label><label className="text-xs">Licence spectacle<select name="spectacle_licence" defaultValue={organization.spectacle_licence===true?"yes":organization.spectacle_licence===false?"no":""} className="mt-1 h-9 w-full rounded-lg border bg-white px-2"><option value="">Je ne sais pas</option><option value="yes">Oui</option><option value="no">Non</option></select></label><label className="text-xs">Emploie les artistes<select name="employs_artists" defaultValue={organization.employs_artists===true?"yes":organization.employs_artists===false?"no":""} className="mt-1 h-9 w-full rounded-lg border bg-white px-2"><option value="">Je ne sais pas</option><option value="yes">Oui</option><option value="no">Non</option></select></label><label className="text-xs">Producteur phonographique<select name="phonogram_producer" defaultValue={organization.phonogram_producer===true?"yes":organization.phonogram_producer===false?"no":""} className="mt-1 h-9 w-full rounded-lg border bg-white px-2"><option value="">Je ne sais pas</option><option value="yes">Oui</option><option value="no">Non</option></select></label><label className="text-xs">Détient les masters<select name="owns_masters" defaultValue={organization.owns_masters===true?"yes":organization.owns_masters===false?"no":""} className="mt-1 h-9 w-full rounded-lg border bg-white px-2"><option value="">Je ne sais pas</option><option value="yes">Oui</option><option value="no">Non</option></select></label>
</div>
<label className="mt-3 block text-xs">Date de création<input name="founded_on" type="date" defaultValue={organization.founded_on??""} className="mt-1 h-9 w-full rounded-lg border px-2"/></label>
<label className="mt-3 block text-xs">Notes administratives<textarea name="admin_notes" defaultValue={organization.admin_notes??""} rows={2} className="mt-1 w-full rounded-lg border p-2"/></label>
<button className="mt-3 h-10 w-full rounded-xl bg-neutral-900 text-sm font-semibold text-white">Enregistrer le profil administratif</button>
</form></article>
            ))}
          </div>
        )}
      </section>

      <section className="mt-8 rounded-2xl border border-neutral-200 p-5">
        <h2 className="font-semibold">Ajouter une structure</h2>
        <form action={createOrganization} className="mt-4 space-y-4">
          <div>
            <label htmlFor="name" className="mb-1.5 block text-sm font-medium">Nom *</label>
            <input id="name" name="name" required placeholder="Nom de l’association, société…"
              className="h-11 w-full rounded-xl border border-neutral-300 px-3 outline-none focus:border-black"/>
          </div>
          <div>
            <label htmlFor="organization_type" className="mb-1.5 block text-sm font-medium">Type *</label>
            <select id="organization_type" name="organization_type" required defaultValue=""
              className="h-11 w-full rounded-xl border border-neutral-300 bg-white px-3 outline-none focus:border-black">
              <option value="" disabled>Choisir un type</option>
              {organizationTypes.map(([value, label]) => <option key={value} value={value}>{label}</option>)}
            </select>
          </div>
          <div>
            <label htmlFor="siret" className="mb-1.5 block text-sm font-medium">SIRET</label>
            <input id="siret" name="siret" inputMode="numeric" placeholder="14 chiffres"
              className="h-11 w-full rounded-xl border border-neutral-300 px-3 outline-none focus:border-black"/>
            <p className="mt-1.5 text-xs text-neutral-500">Facultatif. ArtistPilot ne complètera jamais ce numéro à ta place.</p>
          </div>
          <button className="h-11 w-full rounded-xl bg-black font-semibold text-white">Enregistrer la structure</button>
        </form>
      </section>
    </main>
  );
}
