import type { CloudState } from "./cloud-state";

const GREETINGS: Record<CloudState, { primary: string; secondary: string }> = {
  sleeping:   { primary: "Good night, {name}",      secondary: "Time to rest. Sky will be here in the morning." },
  stretching: { primary: "Good morning, {name}",    secondary: "Fresh start. Let's see what today brings." },
  happy:      { primary: "You're on fire, {name}",  secondary: "Great momentum today. Keep it going." },
  confident:  { primary: "Looking good, {name}",    secondary: "Portfolio's green today." },
  droopy:     { primary: "Hey {name}",              secondary: "Quiet day. That's okay too." },
  calm:       { primary: "Winding down, {name}",    secondary: "Good day. Time to wrap up." },
  hero:       { primary: "Hey {name}",              secondary: "Welcome to Sky." },
};

export function getCloudGreeting(
  state: CloudState,
  userName: string,
): { primary: string; secondary: string } {
  const template = GREETINGS[state];
  return {
    primary: template.primary.replace("{name}", userName),
    secondary: template.secondary.replace("{name}", userName),
  };
}
