#!/usr/bin/env ts-node
/**
 * One-time SnapTrade setup script.
 *
 * Run this ONCE to:
 *   1. Register a SnapTrade user (creates userId + userSecret)
 *   2. Generate a Connection Portal URL so you can link your IBKR account
 *   3. (After linking) list your SnapTrade accounts so you can find your IBKR account ID
 *
 * Prerequisites:
 *   - Create a free SnapTrade developer account at https://dashboard.snaptrade.com
 *   - Set SNAPTRADE_CLIENT_ID and SNAPTRADE_CONSUMER_KEY in .env.local
 *
 * Usage:
 *   npx ts-node scripts/snaptrade-setup.ts            # register + get portal URL
 *   npx ts-node scripts/snaptrade-setup.ts --accounts # list accounts after linking
 *
 * After running, copy the printed SNAPTRADE_USER_SECRET and SNAPTRADE_ACCOUNT_ID
 * into your .env.local file.
 */

import * as dotenv from "dotenv";
import * as path from "path";
import { Snaptrade } from "snaptrade-typescript-sdk";

dotenv.config({ path: path.resolve(__dirname, "../.env.local") });

const clientId = process.env.SNAPTRADE_CLIENT_ID;
const consumerKey = process.env.SNAPTRADE_CONSUMER_KEY;
const userId = process.env.SNAPTRADE_USER_ID ?? "hen";

if (!clientId || !consumerKey) {
  console.error("ERROR: SNAPTRADE_CLIENT_ID and SNAPTRADE_CONSUMER_KEY must be set in .env.local");
  process.exit(1);
}

const snaptrade = new Snaptrade({ clientId, consumerKey });

async function main() {
  const args = process.argv.slice(2);
  const listAccounts = args.includes("--accounts");

  if (listAccounts) {
    // --accounts mode: list accounts for the already-registered user
    const userSecret = process.env.SNAPTRADE_USER_SECRET;
    if (!userSecret) {
      console.error("ERROR: SNAPTRADE_USER_SECRET must be set in .env.local before listing accounts.");
      process.exit(1);
    }

    console.log("\nFetching SnapTrade accounts...\n");
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    const res = await (snaptrade.accountInformation as any).listUserAccounts({ userId, userSecret });
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    const accounts: any[] = res.data ?? [];

    if (accounts.length === 0) {
      console.log("No accounts found. Make sure you completed the brokerage connection in the portal URL.");
      return;
    }

    console.log("Found accounts:");
    accounts.forEach((a, i) => {
      console.log(`  [${i + 1}] ID: ${a.id}`);
      console.log(`       Name: ${a.name ?? "(unnamed)"}`);
      console.log(`       Brokerage: ${a.brokerage_authorization?.brokerage?.name ?? "unknown"}`);
      console.log(`       Number: ${a.number ?? "(none)"}`);
      console.log();
    });

    const ibkrAccount = accounts.find(
      (a) => a.brokerage_authorization?.brokerage?.name?.toLowerCase().includes("interactive"),
    );
    if (ibkrAccount) {
      console.log("=== Add this to your .env.local ===");
      console.log(`SNAPTRADE_ACCOUNT_ID=${ibkrAccount.id}`);
    } else {
      console.log("No Interactive Brokers account found. Use the SNAPTRADE_ACCOUNT_ID from the list above.");
    }
    return;
  }

  // Default mode: register user (idempotent) and print portal URL
  let userSecret = process.env.SNAPTRADE_USER_SECRET;

  if (userSecret) {
    console.log(`\nSNAPTRADE_USER_SECRET already set — skipping user registration.`);
    console.log(`Using existing user: ${userId}`);
  } else {
    console.log(`\nRegistering SnapTrade user: ${userId} ...`);
    try {
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      const regRes = await (snaptrade.authentication as any).registerSnapTradeUser({ userId });
      userSecret = regRes.data?.userSecret;
      if (!userSecret) throw new Error("No userSecret returned from registration");
      console.log("\n=== Add these to your .env.local ===");
      console.log(`SNAPTRADE_USER_ID=${userId}`);
      console.log(`SNAPTRADE_USER_SECRET=${userSecret}`);
    } catch (err: unknown) {
      // User may already exist — try to login instead
      const msg = err instanceof Error ? err.message : String(err);
      if (msg.includes("already exists") || msg.includes("409")) {
        console.log("User already registered, proceeding to generate portal URL...");
        if (!process.env.SNAPTRADE_USER_SECRET) {
          console.error(
            "\nERROR: User exists but SNAPTRADE_USER_SECRET is not set in .env.local.\n" +
              "You must have saved it from the first run. If you lost it, contact SnapTrade support.",
          );
          process.exit(1);
        }
        userSecret = process.env.SNAPTRADE_USER_SECRET;
      } else {
        throw err;
      }
    }
  }

  // Generate a Connection Portal URL for linking the IBKR account
  console.log("\nGenerating IBKR Connection Portal URL...");
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const loginRes = await (snaptrade.authentication as any).loginSnapTradeUser({
    userId,
    userSecret,
    brokerageAuthorizations: undefined, // let user pick brokerage
  });
  const portalUrl: string = loginRes.data?.redirectURI ?? loginRes.data;

  console.log("\n=== NEXT STEPS ===");
  console.log("1. Open this URL in your browser:");
  console.log(`\n   ${portalUrl}\n`);
  console.log("2. Select 'Interactive Brokers' and follow the prompts.");
  console.log("   (SnapTrade uses IBKR Flex Query — you'll generate a Query ID + Token in IBKR.)");
  console.log("3. After linking, run:");
  console.log("   npx ts-node scripts/snaptrade-setup.ts --accounts");
  console.log("4. Copy the SNAPTRADE_ACCOUNT_ID printed by that command into .env.local.");
}

main().catch((err) => {
  console.error("Error:", err);
  process.exit(1);
});
