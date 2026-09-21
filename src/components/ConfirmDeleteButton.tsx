"use client";

import { useState } from "react";
import { Trash2 } from "lucide-react";

type Props = {
  label: string;
  message: string;
};

export function ConfirmDeleteButton({ label, message }: Props) {
  const [submitting, setSubmitting] = useState(false);

  return (
    <button
      type="submit"
      aria-label={label}
      disabled={submitting}
      onClick={(event) => {
        if (!window.confirm(message)) {
          event.preventDefault();
          return;
        }
        setSubmitting(true);
      }}
      className="rounded-lg p-2 text-neutral-400 hover:bg-neutral-100 hover:text-red-600 disabled:cursor-not-allowed disabled:opacity-50"
    >
      <Trash2 size={18} />
    </button>
  );
}
