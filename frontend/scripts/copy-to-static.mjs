import { cpSync, rmSync, existsSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { dirname, resolve } from "node:path";

const here = dirname(fileURLToPath(import.meta.url));
const dist = resolve(here, "../dist");
const target = resolve(here, "../../src/main/resources/static");

if (!existsSync(dist)) {
  throw new Error("frontend/dist not found — run `vite build` first");
}

rmSync(target, { recursive: true, force: true });
cpSync(dist, target, { recursive: true });

console.log(`Copied ${dist} -> ${target}`);
