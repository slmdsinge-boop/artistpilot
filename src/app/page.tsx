import { Plus, CircleDollarSign, Music2, CalendarDays, FolderOpen, Bell } from "lucide-react";

const modules = [
  ["Financements", CircleDollarSign],
  ["Œuvres & droits", Music2],
  ["Concerts", CalendarDays],
  ["Documents", FolderOpen],
];

export default function Home() {
  return (
    <main className="mx-auto min-h-screen max-w-md bg-white px-5 pb-28 pt-8 shadow-sm">
      <header className="mb-8">
        <p className="text-sm font-medium text-neutral-500">ArtistPilot</p>
        <h1 className="mt-1 text-3xl font-bold tracking-tight">Bonjour 👋</h1>
        <p className="mt-2 text-neutral-600">Qu’est-ce que je dois faire maintenant ?</p>
      </header>

      <section className="mb-8 rounded-2xl border border-neutral-200 p-4">
        <div className="flex items-center gap-2">
          <Bell size={18} />
          <h2 className="font-semibold">À FAIRE</h2>
        </div>
        <p className="mt-3 text-sm text-neutral-600">
          Aucune action pour le moment. Les informations manquantes apparaîtront ici sans être inventées.
        </p>
      </section>

      <section>
        <h2 className="mb-3 text-lg font-semibold">Cockpit</h2>
        <div className="grid grid-cols-2 gap-3">
          {modules.map(([label, Icon]) => {
            const ModuleIcon = Icon as typeof Music2;
            return (
              <button key={label as string} className="min-h-28 rounded-2xl border border-neutral-200 p-4 text-left">
                <ModuleIcon size={22} />
                <span className="mt-5 block font-medium">{label as string}</span>
              </button>
            );
          })}
        </div>
      </section>

      <button
        aria-label="Ajouter"
        className="fixed bottom-6 left-1/2 flex h-14 w-14 -translate-x-1/2 items-center justify-center rounded-full bg-black text-white shadow-lg"
      >
        <Plus size={28} />
      </button>
    </main>
  );
}
