import { redirect } from "next/navigation";
import { CircleDollarSign, Music2, CalendarDays, FolderOpen, Bell, FolderKanban, Building2, UserRound } from "lucide-react";
import { createClient } from "@/lib/supabase/server";
import { UniversalAdd } from "@/components/universal-add";

const modules = [
  ["Projets", FolderKanban], ["Financements", CircleDollarSign],
  ["Œuvres & droits", Music2], ["Concerts", CalendarDays],
  ["Documents", FolderOpen], ["Organisations", Building2],
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
  if (user) {
    const { data } = await supabase
      .from("user_artist_access")
      .select("artist_profiles(name)")
      .eq("user_id", user.id)
      .limit(1)
      .maybeSingle();
    const profile = data?.artist_profiles as unknown as { name?: string } | null;
    artistName = profile?.name ?? null;
  }

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
        <p className="mt-3 text-sm text-neutral-600">Aucune action pour le moment. Les informations manquantes apparaîtront ici sans être inventées.</p>
      </section>

      <section>
        <h2 className="mb-3 text-lg font-semibold">Cockpit</h2>
        <div className="grid grid-cols-2 gap-3">
          {modules.map(([label, Icon]) => (
            <button key={label} className="min-h-28 rounded-2xl border border-neutral-200 p-4 text-left transition active:scale-[.98]">
              <Icon size={22}/><span className="mt-5 block font-medium">{label}</span>
            </button>
          ))}
        </div>
      </section>
      <UniversalAdd/>
    </main>
  );
}
