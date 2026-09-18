# ArtistPilot — architecture V1

## Principes
- Compte utilisateur, artiste, structure juridique et projet sont des entités distinctes.
- Une donnée est saisie une fois puis réutilisée.
- Les règles réglementaires critiques sont déterministes et versionnées.
- Le LLM explique et accompagne ; il n'est pas la source de vérité réglementaire.
- Toute donnée manquante produit une action à compléter plutôt qu'une invention.

## Socle
- Next.js / React / TypeScript
- Tailwind CSS
- PostgreSQL / Supabase
- Supabase Auth et RLS
- Déploiement prévu sur Vercel

## État
Ce document décrit le socle technique initial réellement versionné dans le dépôt.
