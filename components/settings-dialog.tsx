"use client";

import { useRef, useState } from "react";
import { Icon } from "@iconify/react";
import settingsIcon from "@iconify-icons/ci/settings";
import { Trash2, Upload } from "lucide-react";

import { useSettings } from "@/components/settings-provider";
import { Input } from "@/components/ui/input";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
} from "@/components/ui/dialog";
import { MEMOJIS } from "@/lib/memojis";
import { cn } from "@/lib/utils";

const PROFILE_IMAGE_SIZE = 512;

async function resizeProfileImage(file: File): Promise<string> {
  const objectUrl = URL.createObjectURL(file);

  try {
    const image = new Image();
    image.src = objectUrl;
    await image.decode();

    const side = Math.min(image.naturalWidth, image.naturalHeight);
    const sx = (image.naturalWidth - side) / 2;
    const sy = (image.naturalHeight - side) / 2;

    const canvas = document.createElement("canvas");
    canvas.width = PROFILE_IMAGE_SIZE;
    canvas.height = PROFILE_IMAGE_SIZE;

    const ctx = canvas.getContext("2d");
    if (!ctx) throw new Error("Canvas is not supported");

    ctx.drawImage(image, sx, sy, side, side, 0, 0, PROFILE_IMAGE_SIZE, PROFILE_IMAGE_SIZE);
    return canvas.toDataURL("image/jpeg", 0.88);
  } finally {
    URL.revokeObjectURL(objectUrl);
  }
}

export function SettingsDialog({ triggerClassName }: { triggerClassName?: string }) {
  const { name, memojiId, profileImageUrl, setName, setMemojiId, setProfileImageUrl } =
    useSettings();
  const fileInputRef = useRef<HTMLInputElement>(null);
  const [imageError, setImageError] = useState<string | null>(null);

  const currentMemoji = MEMOJIS.find((m) => m.id === memojiId) ?? MEMOJIS[0];

  async function handleProfileImageChange(file: File | undefined) {
    if (!file) return;
    setImageError(null);

    if (!file.type.startsWith("image/")) {
      setImageError("Choose an image file.");
      return;
    }

    try {
      setProfileImageUrl(await resizeProfileImage(file));
    } catch {
      setImageError("Could not read that image. Try a JPG or PNG.");
    } finally {
      if (fileInputRef.current) fileInputRef.current.value = "";
    }
  }

  return (
    <Dialog>
      <DialogTrigger
        render={
          <button
            title="Settings"
            aria-label="Settings"
            className={cn(
              "flex h-9 w-9 items-center justify-center rounded-lg text-muted-foreground transition-colors hover:bg-muted hover:text-foreground",
              triggerClassName,
            )}
          />
        }
      >
        <Icon icon={settingsIcon} className="size-[17px]" />
      </DialogTrigger>

      <DialogContent className="sm:max-w-md">
        <DialogHeader>
          <DialogTitle>Settings</DialogTitle>
          <DialogDescription>Personalize your dashboard.</DialogDescription>
        </DialogHeader>

        <div className="space-y-5">
          <div className="space-y-2">
            <label htmlFor="settings-name" className="text-sm font-medium">
              Name
            </label>
            <Input
              id="settings-name"
              value={name}
              onChange={(e) => setName(e.target.value)}
              placeholder="Your name"
            />
            <p className="text-xs text-muted-foreground">
              Used in the greeting (&ldquo;Good morning, {name || "…"}&rdquo;).
            </p>
          </div>

          <div className="space-y-2">
            <span className="text-sm font-medium">Avatar</span>
            <div className="flex items-center gap-3 rounded-2xl border border-border bg-muted/25 p-3">
              <div className="h-16 w-16 overflow-hidden rounded-2xl border border-border bg-background shadow-sm">
                {/* eslint-disable-next-line @next/next/no-img-element */}
                <img
                  src={profileImageUrl ?? currentMemoji.url}
                  alt=""
                  className="h-full w-full object-cover"
                />
              </div>
              <div className="min-w-0 flex-1 space-y-2">
                <div className="flex flex-wrap gap-2">
                  <label
                    htmlFor="settings-profile-image"
                    className="inline-flex h-8 cursor-pointer items-center justify-center gap-1.5 rounded-lg border border-border bg-background px-2.5 text-sm font-medium transition-colors hover:bg-muted"
                  >
                    <Upload className="h-4 w-4" />
                    Upload photo
                  </label>
                  {profileImageUrl && (
                    <button
                      type="button"
                      onClick={() => setProfileImageUrl(null)}
                      className="inline-flex h-8 items-center justify-center gap-1.5 rounded-lg px-2.5 text-sm font-medium text-muted-foreground transition-colors hover:bg-muted hover:text-foreground"
                    >
                      <Trash2 className="h-4 w-4" />
                      Remove
                    </button>
                  )}
                </div>
                <p className="text-xs leading-5 text-muted-foreground">
                  Stored only in this browser. If you remove it, Sky uses your selected memoji.
                </p>
                {imageError && <p className="text-xs text-destructive">{imageError}</p>}
              </div>
              <input
                ref={fileInputRef}
                id="settings-profile-image"
                type="file"
                accept="image/*"
                className="sr-only"
                onChange={(e) => handleProfileImageChange(e.currentTarget.files?.[0])}
              />
            </div>
            <div className="grid grid-cols-6 gap-2">
              {MEMOJIS.map((m) => (
                <button
                  key={m.id}
                  type="button"
                  aria-label={`Choose avatar ${m.id}`}
                  aria-pressed={m.id === memojiId}
                  onClick={() => setMemojiId(m.id)}
                  className={cn(
                    "overflow-hidden rounded-full ring-2 ring-transparent transition hover:ring-border",
                    m.id === memojiId && "ring-primary",
                  )}
                >
                  {/* eslint-disable-next-line @next/next/no-img-element */}
                  <img
                    src={m.url}
                    alt=""
                    className="aspect-square h-full w-full object-cover"
                  />
                </button>
              ))}
            </div>
          </div>
        </div>
      </DialogContent>
    </Dialog>
  );
}
