"use client";

import { FormEvent, useState } from "react";
import { Mail, Loader2 } from "lucide-react";
import { createClient } from "@/lib/supabase/client";

export default function LoginPage() {
  const [email, setEmail] = useState("");
  const [sent, setSent] = useState(false);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");

  async function submit(event: FormEvent) {
    event.preventDefault();
    setLoading(true);
    setError("");
    const supabase = createClient();
    const { error } = await supabase.auth.signInWithOtp({
      email,
      options: { emailRedirectTo: `${window.location.origin}/auth/callback` },
    });
    setLoading(false);
    if (error) return setError(error.message);
    setSent(true);
  }

  return (
    <main className="mx-auto flex min-h-screen max-w-md flex-col justify-center bg-white px-6">
      <p className="text-sm font-semibold text-neutral-500">ArtistPilot</p>
      <h1 className="mt-2 text-3xl font-bold tracking-tight">Connexion</h1>
      <p className="mt-2 text-neutral-600">Ton copilote administratif et financier pour la musique.</p>

      {sent ? (
        <div className="mt-8 rounded-2xl border border-neutral-200 p-5">
          <Mail className="mb-3" />
          <h2 className="font-semibold">Vérifie ta boîte mail</h2>
          <p className="mt-2 text-sm text-neutral-600">Un lien de connexion vient d’être envoyé à {email}.</p>
        </div>
      ) : (
        <form onSubmit={submit} className="mt-8 space-y-4">
          <label className="block text-sm font-medium" htmlFor="email">Adresse e-mail</label>
          <input id="email" type="email" required value={email} onChange={(e) => setEmail(e.target.value)}
            placeholder="toi@exemple.fr"
            className="h-12 w-full rounded-xl border border-neutral-300 px-4 outline-none focus:border-black" />
          {error && <p className="text-sm text-red-600">{error}</p>}
          <button disabled={loading} className="flex h-12 w-full items-center justify-center gap-2 rounded-xl bg-black font-semibold text-white disabled:opacity-60">
            {loading && <Loader2 size={18} className="animate-spin" />}
            Recevoir mon lien de connexion
          </button>
        </form>
      )}
    </main>
  );
}
