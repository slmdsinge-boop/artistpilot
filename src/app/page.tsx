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

  const matches = artistId ? (await supabase.rpc("project_funding_matches", { target_artist: artistId })).data ?? [] : [];
  const missing = matches.filter((m: { match_status?: string }) => m.match_status === "needs_info");
  const todoItems = Array.from(new Map(missing.map((m: { project_id: string; project_name: string; provider_name: string; program_name: string; reason: string }) => [
    m.project_id + ":" + m.provider_name,
    { project: m.project_name, provider: m.provider_name, program: m.program_name, reason: m.reason }
  ])).values()).slice(0, 5) as { project: string; provider: string; program: string; reason: string }[];

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
          <p className="mt-3 text-sm text-neutral-600">Aucune information manquante détectée pour les financements analysés.</p>
        ) : (
          <div className="mt-3 space-y-3">
            {todoItems.map((item, index) => (
              <Link key={item.project + item.provider + index} href="/organizations" className="block rounded-xl bg-amber-50 p-3">
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
