"use client";

import { useState } from "react";
import { Plus, X, CalendarDays, CircleDollarSign, FileText, Music2, Mic2, BriefcaseBusiness, Disc3, FolderPlus, Building2 } from "lucide-react";

const types = [
  ["Concert", CalendarDays], ["Dépense", CircleDollarSign], ["Revenu", CircleDollarSign],
  ["Facture / document", FileText], ["Œuvre", Music2], ["Enregistrement", Mic2],
  ["Contrat", BriefcaseBusiness], ["Sortie", Disc3], ["Projet", FolderPlus], ["Organisation", Building2],
] as const;

export function UniversalAdd() {
  const [open, setOpen] = useState(false);
  return <>
    <button onClick={() => setOpen(true)} aria-label="Ajouter"
      className="fixed bottom-6 left-1/2 z-20 flex h-14 w-14 -translate-x-1/2 items-center justify-center rounded-full bg-black text-white shadow-lg">
      <Plus size={28} />
    </button>
    {open && <div className="fixed inset-0 z-30 flex items-end bg-black/35" onClick={() => setOpen(false)}>
      <section className="mx-auto w-full max-w-md rounded-t-3xl bg-white p-5 pb-8" onClick={(e) => e.stopPropagation()}>
        <div className="mb-5 flex items-center justify-between">
          <div><p className="text-xs font-semibold uppercase tracking-wider text-neutral-500">Ajouter</p><h2 className="text-xl font-bold">Qu’est-ce qui vient de se passer ?</h2></div>
          <button onClick={() => setOpen(false)} className="rounded-full bg-neutral-100 p-2"><X size={20}/></button>
        </div>
        <div className="grid grid-cols-2 gap-2">
          {types.map(([label, Icon]) => <button key={label} className="flex min-h-16 items-center gap-3 rounded-xl border border-neutral-200 p-3 text-left text-sm font-medium">
            <Icon size={19}/><span>{label}</span>
          </button>)}
        </div>
        <p className="mt-4 text-xs text-neutral-500">Chaque ajout sera relié aux modules concernés. Les informations manquantes créeront une action « À compléter ».</p>
      </section>
    </div>}
  </>;
}
